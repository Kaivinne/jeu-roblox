--!strict
-- Panneau de profil persistant : Jetons, Rang, Perspicacité.
-- Affiché en bas à gauche pendant toute la session.
-- Mis à jour via ProfileUpdated (push serveur uniquement).

local Players = game:GetService("Players")

local UIUtils = require(script.Parent.UIUtils)

local ProfilePanel = {}

local _gui: ScreenGui? = nil
local jetonsLabel: TextLabel? = nil
local rangLabel: TextLabel? = nil
local _perspBar: Frame? = nil
local perspFill: Frame? = nil
local perspLabel: TextLabel? = nil

function ProfilePanel.setup()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local screen = Instance.new("ScreenGui")
	screen.Name = "ProfilePanelGui"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 5
	screen.Parent = playerGui
	_gui = screen

	-- Panneau principal (bas-gauche)
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 190, 0, 80)
	panel.Position = UDim2.new(0, 12, 1, -92)
	panel.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
	panel.BackgroundTransparency = 0.25
	panel.BorderSizePixel = 0
	panel.Parent = screen
	UIUtils.round(panel, 10)
	UIUtils.stroke(panel, UIUtils.Color.Gold, 1)

	-- Jetons
	local jLabel = Instance.new("TextLabel")
	jLabel.Size = UDim2.new(1, -12, 0, 22)
	jLabel.Position = UDim2.new(0, 10, 0, 8)
	jLabel.BackgroundTransparency = 1
	jLabel.Text = "Jetons : 0"
	jLabel.TextColor3 = UIUtils.Color.Gold
	jLabel.Font = UIUtils.Font.Title
	jLabel.TextSize = 13
	jLabel.TextXAlignment = Enum.TextXAlignment.Left
	jLabel.Parent = panel
	jetonsLabel = jLabel

	-- Rang
	local rLabel = Instance.new("TextLabel")
	rLabel.Size = UDim2.new(1, -12, 0, 18)
	rLabel.Position = UDim2.new(0, 10, 0, 30)
	rLabel.BackgroundTransparency = 1
	rLabel.Text = "Rang : Novice"
	rLabel.TextColor3 = UIUtils.Color.Ivory
	rLabel.Font = UIUtils.Font.Body
	rLabel.TextSize = 12
	rLabel.TextXAlignment = Enum.TextXAlignment.Left
	rLabel.Parent = panel
	rangLabel = rLabel

	-- Barre de Perspicacité
	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -12, 0, 10)
	barBg.Position = UDim2.new(0, 6, 0, 52)
	barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	barBg.BorderSizePixel = 0
	barBg.Parent = panel
	UIUtils.round(barBg, 4)
	_perspBar = barBg

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0.5, 0, 1, 0) -- 50% par défaut
	fill.Position = UDim2.new(0, 0, 0, 0)
	fill.BackgroundColor3 = Color3.fromRGB(80, 160, 220)
	fill.BorderSizePixel = 0
	fill.Parent = barBg
	UIUtils.round(fill, 4)
	perspFill = fill

	local pLabel = Instance.new("TextLabel")
	pLabel.Size = UDim2.new(1, -12, 0, 12)
	pLabel.Position = UDim2.new(0, 10, 0, 64)
	pLabel.BackgroundTransparency = 1
	pLabel.Text = "Perspicacité : 50"
	pLabel.TextColor3 = UIUtils.Color.Muted
	pLabel.Font = UIUtils.Font.Body
	pLabel.TextSize = 10
	pLabel.TextXAlignment = Enum.TextXAlignment.Left
	pLabel.Parent = panel
	perspLabel = pLabel
end

-- Met à jour l'affichage avec les données reçues du serveur
function ProfilePanel.update(jetons: number, rang: string, perspicacite: number)
	if jetonsLabel then
		jetonsLabel.Text = string.format("Jetons : %d", jetons)
	end
	if rangLabel then
		rangLabel.Text = "Rang : " .. rang
	end
	if perspFill then
		local ratio = math.clamp(perspicacite / 100, 0, 1)
		perspFill.Size = UDim2.new(ratio, 0, 1, 0)
		-- Couleur de la barre selon la valeur
		if ratio >= 0.7 then
			perspFill.BackgroundColor3 = Color3.fromRGB(60, 200, 100) -- vert
		elseif ratio >= 0.4 then
			perspFill.BackgroundColor3 = Color3.fromRGB(80, 160, 220) -- bleu
		else
			perspFill.BackgroundColor3 = Color3.fromRGB(200, 80, 80) -- rouge
		end
	end
	if perspLabel then
		perspLabel.Text = string.format("Perspicacité : %d / 100", perspicacite)
	end
end

return ProfilePanel
