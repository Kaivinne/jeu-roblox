--!strict
-- Interface de déclaration par template contraint.
-- Aucune saisie libre : le joueur choisit parmi des options prédéfinies.
-- Visible pour les témoins (HonestWitness / Liar) pendant Testimony.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)

local UIUtils = require(script.Parent.UIUtils)

local DeclarationBuilder = {}

local gui: ScreenGui? = nil
local submitBtn: TextButton? = nil
local canSubmit = false

-- Options disponibles par champ (placeholders MVP — remplacées par les vrais scénarios en 1.5)
type FieldDef = {
	label: string,
	options: { string },
}

local FIELDS: { FieldDef } = {
	{ label = "LIEU", options = { "Bibliothèque", "Parc", "Bureau", "Café", "Gare" } },
	{ label = "PERSONNE", options = { "Seul(e)", "Avec quelqu'un", "En groupe", "En binôme" } },
	{ label = "HEURE", options = { "Matin", "Midi", "Après-midi", "Soir", "Nuit" } },
}

-- Index courant par champ
local selectedIndex: { number } = { 1, 1, 1 }

local fieldValueLabels: { TextLabel } = {}

local function fireServer(eventName: string, payload: { [string]: any })
	Net.getEvent(eventName):FireServer(payload)
end

local function getCurrentValues(): { string }
	local values: { string } = {}
	for i, field in ipairs(FIELDS) do
		table.insert(values, field.options[selectedIndex[i]])
	end
	return values
end

local function makeFieldRow(parent: Frame, fieldIndex: number, def: FieldDef): TextLabel
	local ROW_H = 52

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, ROW_H)
	row.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	row.BorderSizePixel = 0
	row.Parent = parent
	UIUtils.round(row, 8)

	-- Étiquette du champ
	local fieldLabel = Instance.new("TextLabel")
	fieldLabel.Size = UDim2.new(0, 110, 1, 0)
	fieldLabel.Position = UDim2.new(0, 12, 0, 0)
	fieldLabel.BackgroundTransparency = 1
	fieldLabel.Text = def.label
	fieldLabel.TextColor3 = UIUtils.Color.Gold
	fieldLabel.Font = UIUtils.Font.Title
	fieldLabel.TextSize = 13
	fieldLabel.TextXAlignment = Enum.TextXAlignment.Left
	fieldLabel.Parent = row

	-- Bouton précédent
	local btnLeft = Instance.new("TextButton")
	btnLeft.Size = UDim2.new(0, 36, 0, 36)
	btnLeft.Position = UDim2.new(0, 122, 0.5, -18)
	btnLeft.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	btnLeft.BorderSizePixel = 0
	btnLeft.Text = "<"
	btnLeft.TextColor3 = UIUtils.Color.White
	btnLeft.Font = UIUtils.Font.Title
	btnLeft.TextSize = 18
	btnLeft.AutoButtonColor = false
	btnLeft.Parent = row
	UIUtils.round(btnLeft, 6)

	-- Valeur courante
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(1, -220, 1, 0)
	valueLabel.Position = UDim2.new(0, 164, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = def.options[1]
	valueLabel.TextColor3 = UIUtils.Color.Ivory
	valueLabel.Font = UIUtils.Font.Title
	valueLabel.TextSize = 15
	valueLabel.TextXAlignment = Enum.TextXAlignment.Center
	valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
	valueLabel.Parent = row

	-- Bouton suivant
	local btnRight = Instance.new("TextButton")
	btnRight.Size = UDim2.new(0, 36, 0, 36)
	btnRight.Position = UDim2.new(1, -46, 0.5, -18)
	btnRight.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	btnRight.BorderSizePixel = 0
	btnRight.Text = ">"
	btnRight.TextColor3 = UIUtils.Color.White
	btnRight.Font = UIUtils.Font.Title
	btnRight.TextSize = 18
	btnRight.AutoButtonColor = false
	btnRight.Parent = row
	UIUtils.round(btnRight, 6)

	local idx = fieldIndex
	local opts = def.options

	btnLeft.MouseButton1Click:Connect(function()
		selectedIndex[idx] = ((selectedIndex[idx] - 2) % #opts) + 1
		valueLabel.Text = opts[selectedIndex[idx]]
	end)

	btnRight.MouseButton1Click:Connect(function()
		selectedIndex[idx] = (selectedIndex[idx] % #opts) + 1
		valueLabel.Text = opts[selectedIndex[idx]]
	end)

	return valueLabel
end

function DeclarationBuilder.setup()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local screen = Instance.new("ScreenGui")
	screen.Name = "DeclarationBuilderGui"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 30
	screen.Enabled = false
	screen.Parent = playerGui
	gui = screen

	-- Fond semi-transparent
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = UIUtils.Color.Black
	overlay.BackgroundTransparency = 0.45
	overlay.BorderSizePixel = 0
	overlay.Parent = screen

	-- Panneau central
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 520, 0, 290)
	panel.Position = UDim2.new(0.5, -260, 0.5, -145)
	panel.BackgroundColor3 = Color3.fromRGB(14, 14, 26)
	panel.BorderSizePixel = 0
	panel.Parent = screen
	UIUtils.round(panel, 14)
	UIUtils.stroke(panel, UIUtils.Color.Gold, 2)

	-- Titre
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 36)
	title.Position = UDim2.new(0, 12, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "DÉCLAREZ CE QUE VOUS AVEZ OBSERVÉ"
	title.TextColor3 = UIUtils.Color.Gold
	title.Font = UIUtils.Font.Title
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = panel

	-- Champs de sélection
	local fieldsFrame = Instance.new("Frame")
	fieldsFrame.Size = UDim2.new(1, -24, 0, 172)
	fieldsFrame.Position = UDim2.new(0, 12, 0, 50)
	fieldsFrame.BackgroundTransparency = 1
	fieldsFrame.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = fieldsFrame

	for i, def in ipairs(FIELDS) do
		local valueLabel = makeFieldRow(fieldsFrame, i, def)
		fieldValueLabels[i] = valueLabel
	end

	-- Bouton Valider
	local submit = Instance.new("TextButton")
	submit.Size = UDim2.new(1, -24, 0, 44)
	submit.Position = UDim2.new(0, 12, 1, -54)
	submit.BackgroundColor3 = UIUtils.Color.Navy
	submit.BorderSizePixel = 0
	submit.Text = "VALIDER MA DÉCLARATION"
	submit.TextColor3 = UIUtils.Color.White
	submit.Font = UIUtils.Font.Title
	submit.TextSize = 15
	submit.AutoButtonColor = false
	submit.Parent = panel
	UIUtils.round(submit, 10)
	UIUtils.stroke(submit, UIUtils.Color.Gold, 1)
	submitBtn = submit

	submit.MouseButton1Click:Connect(function()
		if not canSubmit then
			return
		end
		canSubmit = false

		local values = getCurrentValues()
		fireServer(RemoteNames.DeclarationSubmitted, {
			Fields = values,
		})

		-- Feedback : bouton grisé + texte confirmé
		submit.Text = "DÉCLARATION SOUMISE"
		submit.BackgroundColor3 = Color3.fromRGB(40, 40, 60)

		TweenService:Create(screen, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			-- L'overlay disparaît après soumission
		}):Play()

		task.delay(1.2, function()
			DeclarationBuilder.hide()
		end)
	end)
end

function DeclarationBuilder.show()
	if gui then
		gui.Enabled = true
		canSubmit = true

		-- Réinitialiser la sélection et le bouton
		selectedIndex = { 1, 1, 1 }
		for i, def in ipairs(FIELDS) do
			if fieldValueLabels[i] then
				fieldValueLabels[i].Text = def.options[1]
			end
		end

		if submitBtn then
			submitBtn.Text = "VALIDER MA DÉCLARATION"
			submitBtn.BackgroundColor3 = UIUtils.Color.Navy
		end
	end
end

function DeclarationBuilder.hide()
	if gui then
		gui.Enabled = false
		canSubmit = false
	end
end

return DeclarationBuilder
