--!strict
-- Interface de déclaration par template contraint.
-- Aucune saisie libre : le joueur choisit parmi des options prédéfinies.
-- Visible pour les témoins (HonestWitness / Liar) pendant Testimony.
-- Les options sont chargées dynamiquement via loadCase() à la phase Intro.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)

local UIUtils = require(script.Parent.UIUtils)

local DeclarationBuilder = {}

local gui: ScreenGui? = nil
local fieldsFrame: Frame? = nil
local titleLabel: TextLabel? = nil
local hintLabel: TextLabel? = nil
local submitBtn: TextButton? = nil
local canSubmit = false

type FieldDef = {
	key: string,
	label: string,
	options: { string },
}

-- Champs courants (chargés par loadCase, vides par défaut)
local currentFields: { FieldDef } = {}
-- Index courant par champ (remis à 1 à chaque loadCase et show)
local selectedIndex: { number } = {}

-- Références aux value labels pour la réinitialisation
local fieldValueLabels: { TextLabel } = {}

local function fireServer(eventName: string, payload: { [string]: any })
	Net.getEvent(eventName):FireServer(payload)
end

-- Construit le payload { FieldKey → selectedIndex } pour le serveur
local function getFieldPayload(): { [string]: number }
	local payload: { [string]: number } = {}
	for i, field in ipairs(currentFields) do
		payload[field.key] = selectedIndex[i] or 1
	end
	return payload
end

-- Crée une ligne de champ (label + < value > )
-- correctIndex: si fourni, affiche ✓ quand l'option correcte est sélectionnée
local function makeFieldRow(
	parent: Frame,
	fieldIndex: number,
	def: FieldDef,
	correctIndex: number?
): TextLabel
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
	fieldLabel.TextSize = 12
	fieldLabel.TextXAlignment = Enum.TextXAlignment.Left
	fieldLabel.Parent = row

	-- Bouton précédent
	local btnLeft = Instance.new("TextButton")
	btnLeft.Size = UDim2.new(0, 34, 0, 34)
	btnLeft.Position = UDim2.new(0, 122, 0.5, -17)
	btnLeft.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	btnLeft.BorderSizePixel = 0
	btnLeft.Text = "<"
	btnLeft.TextColor3 = UIUtils.Color.White
	btnLeft.Font = UIUtils.Font.Title
	btnLeft.TextSize = 16
	btnLeft.AutoButtonColor = false
	btnLeft.Parent = row
	UIUtils.round(btnLeft, 6)

	-- Valeur courante
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(1, -230, 1, 0)
	valueLabel.Position = UDim2.new(0, 162, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = def.options[1] or "—"
	valueLabel.TextColor3 = UIUtils.Color.Ivory
	valueLabel.Font = UIUtils.Font.Title
	valueLabel.TextSize = 14
	valueLabel.TextXAlignment = Enum.TextXAlignment.Center
	valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
	valueLabel.Parent = row

	-- Indicateur de vérité (✓ si option correcte — visible pour HonestWitness)
	local indicator = Instance.new("TextLabel")
	indicator.Size = UDim2.new(0, 20, 1, 0)
	indicator.Position = UDim2.new(1, -56, 0, 0)
	indicator.BackgroundTransparency = 1
	indicator.Text = ""
	indicator.Font = UIUtils.Font.Title
	indicator.TextSize = 16
	indicator.TextXAlignment = Enum.TextXAlignment.Center
	indicator.Parent = row

	-- Bouton suivant
	local btnRight = Instance.new("TextButton")
	btnRight.Size = UDim2.new(0, 34, 0, 34)
	btnRight.Position = UDim2.new(1, -46, 0.5, -17)
	btnRight.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	btnRight.BorderSizePixel = 0
	btnRight.Text = ">"
	btnRight.TextColor3 = UIUtils.Color.White
	btnRight.Font = UIUtils.Font.Title
	btnRight.TextSize = 16
	btnRight.AutoButtonColor = false
	btnRight.Parent = row
	UIUtils.round(btnRight, 6)

	local idx = fieldIndex
	local opts = def.options

	local function updateIndicator()
		if correctIndex == nil then
			indicator.Text = ""
			return
		end
		if selectedIndex[idx] == correctIndex then
			indicator.Text = "✓"
			indicator.TextColor3 = UIUtils.Color.Success
		else
			indicator.Text = ""
		end
	end

	btnLeft.MouseButton1Click:Connect(function()
		selectedIndex[idx] = ((selectedIndex[idx] - 2) % #opts) + 1
		valueLabel.Text = opts[selectedIndex[idx]]
		updateIndicator()
	end)

	btnRight.MouseButton1Click:Connect(function()
		selectedIndex[idx] = (selectedIndex[idx] % #opts) + 1
		valueLabel.Text = opts[selectedIndex[idx]]
		updateIndicator()
	end)

	updateIndicator()
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
	panel.Size = UDim2.new(0, 520, 0, 330)
	panel.Position = UDim2.new(0.5, -260, 0.5, -165)
	panel.BackgroundColor3 = Color3.fromRGB(14, 14, 26)
	panel.BorderSizePixel = 0
	panel.Parent = screen
	UIUtils.round(panel, 14)
	UIUtils.stroke(panel, UIUtils.Color.Gold, 2)

	-- Titre (mis à jour selon le rôle dans loadCase)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 36)
	title.Position = UDim2.new(0, 12, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "VOTRE DÉCLARATION"
	title.TextColor3 = UIUtils.Color.Gold
	title.Font = UIUtils.Font.Title
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = panel
	titleLabel = title

	-- Conteneur des champs (rempli par loadCase)
	local fFrame = Instance.new("Frame")
	fFrame.Size = UDim2.new(1, -24, 0, 180)
	fFrame.Position = UDim2.new(0, 12, 0, 52)
	fFrame.BackgroundTransparency = 1
	fFrame.Parent = panel
	fieldsFrame = fFrame

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = fFrame

	-- Hint pour Menteur (caché par défaut)
	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(1, -24, 0, 36)
	hint.Position = UDim2.new(0, 12, 0, 240)
	hint.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
	hint.BackgroundTransparency = 0.5
	hint.BorderSizePixel = 0
	hint.Text = ""
	hint.TextColor3 = UIUtils.Color.Crimson
	hint.Font = UIUtils.Font.Body
	hint.TextSize = 12
	hint.TextXAlignment = Enum.TextXAlignment.Center
	hint.Visible = false
	hint.Parent = panel
	UIUtils.round(hint, 6)
	hintLabel = hint

	-- Bouton Valider
	local submit = Instance.new("TextButton")
	submit.Size = UDim2.new(1, -24, 0, 44)
	submit.Position = UDim2.new(0, 12, 1, -52)
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

		fireServer(RemoteNames.DeclarationSubmitted, {
			Fields = getFieldPayload(),
		})

		submit.Text = "DÉCLARATION SOUMISE"
		submit.BackgroundColor3 = Color3.fromRGB(40, 40, 60)

		task.delay(1.5, function()
			DeclarationBuilder.hide()
		end)
	end)
end

-- Chargement de l'affaire — reconstruit les champs avec les vraies options
-- truthGuide: FieldKey → index (nil pour les observateurs, non utilisé ici)
-- isLiar: affiche le hint de mensonge si vrai
function DeclarationBuilder.loadCase(
	fields: { { Key: string, Label: string, Options: { string } } },
	truthGuide: { [string]: number }?,
	liarHint: string?
)
	-- Convertir au format interne
	currentFields = {}
	for _, f in ipairs(fields) do
		table.insert(currentFields, { key = f.Key, label = f.Label, options = f.Options })
	end
	-- Réinitialiser la sélection
	selectedIndex = {}
	for i = 1, #currentFields do
		selectedIndex[i] = 1
	end

	-- Reconstruire les lignes de champ
	if fieldsFrame then
		for _, child in ipairs(fieldsFrame:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		fieldValueLabels = {}
		for i, def in ipairs(currentFields) do
			local correctIdx: number? = nil
			if truthGuide then
				correctIdx = truthGuide[def.key]
			end
			local vLabel = makeFieldRow(fieldsFrame, i, def, correctIdx)
			fieldValueLabels[i] = vLabel
		end
	end

	-- Mettre à jour le titre selon la présence d'un hint Menteur
	if titleLabel then
		if liarHint then
			titleLabel.Text = "VOTRE DÉCLARATION (MENTEZ BIEN)"
		else
			titleLabel.Text = "DÉCLAREZ CE QUI S'EST RÉELLEMENT PASSÉ"
		end
	end

	-- Afficher le hint Menteur si fourni
	if hintLabel then
		if liarHint and liarHint ~= "" then
			hintLabel.Text = liarHint
			hintLabel.Visible = true
		else
			hintLabel.Text = ""
			hintLabel.Visible = false
		end
	end
end

function DeclarationBuilder.show()
	if gui then
		-- Si aucun champ n'a été chargé, ne pas afficher
		if #currentFields == 0 then
			return
		end
		gui.Enabled = true
		canSubmit = true

		-- Réinitialiser la sélection et les labels
		for i = 1, #currentFields do
			selectedIndex[i] = 1
		end
		for i, def in ipairs(currentFields) do
			if fieldValueLabels[i] then
				fieldValueLabels[i].Text = def.options[1] or "—"
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

-- Animation de feedback de soumission (tween à ajouter si nécessaire)
local _tweenRef: Tween? = nil

return DeclarationBuilder
