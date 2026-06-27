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
local frameStroke: UIStroke? = nil
local shopClickCallback: (() -> ())? = nil

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
	panel.Size = UDim2.new(0, 190, 0, 112)
	panel.Position = UDim2.new(0, 12, 1, -124)
	panel.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
	panel.BackgroundTransparency = 0.25
	panel.BorderSizePixel = 0
	panel.Parent = screen
	UIUtils.round(panel, 10)
	local stroke = Instance.new("UIStroke")
	stroke.Color = UIUtils.Color.Gold
	stroke.Thickness = 1
	stroke.Parent = panel
	frameStroke = stroke

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
	pLabel.TextSize = 11
	pLabel.TextXAlignment = Enum.TextXAlignment.Left
	pLabel.Parent = panel
	perspLabel = pLabel

	-- Bouton boutique
	local boutBtn = Instance.new("TextButton")
	boutBtn.Size = UDim2.new(1, -12, 0, 24)
	boutBtn.Position = UDim2.new(0, 6, 0, 82)
	boutBtn.BackgroundColor3 = UIUtils.Color.Navy
	boutBtn.BackgroundTransparency = 0.3
	boutBtn.BorderSizePixel = 0
	boutBtn.Text = "BOUTIQUE"
	boutBtn.TextColor3 = UIUtils.Color.Gold
	boutBtn.Font = UIUtils.Font.Title
	boutBtn.TextSize = 12
	boutBtn.AutoButtonColor = false
	boutBtn.Parent = panel
	UIUtils.round(boutBtn, 6)
	boutBtn.MouseButton1Click:Connect(function()
		if shopClickCallback ~= nil then
			shopClickCallback()
		end
	end)
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

function ProfilePanel.setOnShopClick(cb: () -> ())
	shopClickCallback = cb
end

-- Applique la couleur du cadre équipé sur le contour du panneau.
-- frameId: "frame_bronze" | "frame_silver" | nil (pas de cadre → or par défaut)
function ProfilePanel.setFrame(frameId: string?)
	local s = frameStroke
	if not s then
		return
	end
	if frameId == "frame_bronze" then
		s.Color = Color3.fromRGB(184, 115, 51)
		s.Thickness = 2
	elseif frameId == "frame_silver" then
		s.Color = Color3.fromRGB(192, 192, 192)
		s.Thickness = 2
	else
		s.Color = UIUtils.Color.Gold
		s.Thickness = 1
	end
end

return ProfilePanel
