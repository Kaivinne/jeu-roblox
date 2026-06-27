--!strict
-- Écran boutique de cosmétiques Milestone 2.7.
-- Affiche le catalogue, permet l'achat et l'équipement via Jetons uniquement.
-- Les actions sont toutes validées côté serveur.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)

local UIUtils = require(script.Parent.UIUtils)

local ShopScreen = {}

local shopGui: ScreenGui? = nil
local _panel: Frame? = nil
local _bg: Frame? = nil
local isOpen = false
local jetonsDisplay: TextLabel? = nil
local itemList: ScrollingFrame? = nil

local SLOT_LABELS: { [string]: string } = {
	frame = "Cadre de profil",
	badge = "Badge",
	effect = "Effet de verdict",
}

local PANEL_W = 460
local PANEL_H = 460
local ROW_H = 60

local function buildRows(items: { { [string]: any } }, jetons: number)
	local list = itemList
	if not list then
		return
	end

	-- Effacer les anciennes lignes
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") or child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 0)
	layout.Parent = list

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
	end)

	-- Mettre à jour le label Jetons
	if jetonsDisplay then
		jetonsDisplay.Text = string.format("Jetons disponibles : %d", jetons)
	end

	for i, rawItem in ipairs(items) do
		local item = rawItem :: { [string]: any }
		local itemId = tostring(item.Id)
		local itemName = tostring(item.Name)
		local itemDesc = tostring(item.Description)
		local itemPrice = if type(item.Price) == "number" then item.Price :: number else 0
		local itemSlot = tostring(item.Slot)
		local owned = item.Owned == true
		local equipped = item.Equipped == true

		local row = Instance.new("Frame")
		row.Name = "Row_" .. itemId
		row.Size = UDim2.new(1, 0, 0, ROW_H)
		row.BackgroundColor3 = if i % 2 == 0
			then Color3.fromRGB(16, 16, 30)
			else Color3.fromRGB(12, 12, 24)
		row.BorderSizePixel = 0
		row.LayoutOrder = i
		row.Parent = list

		-- Séparateur bas
		local sep = Instance.new("Frame")
		sep.Size = UDim2.new(1, 0, 0, 1)
		sep.Position = UDim2.new(0, 0, 1, -1)
		sep.BackgroundColor3 = UIUtils.Color.Charcoal
		sep.BackgroundTransparency = 0.4
		sep.BorderSizePixel = 0
		sep.Parent = row

		-- Nom
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -170, 0, 20)
		nameLbl.Position = UDim2.new(0, 12, 0, 8)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = itemName
		nameLbl.TextColor3 = UIUtils.Color.Ivory
		nameLbl.Font = UIUtils.Font.Title
		nameLbl.TextSize = 14
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		nameLbl.Parent = row

		-- Description
		local descLbl = Instance.new("TextLabel")
		descLbl.Size = UDim2.new(1, -170, 0, 14)
		descLbl.Position = UDim2.new(0, 12, 0, 28)
		descLbl.BackgroundTransparency = 1
		descLbl.Text = itemDesc
		descLbl.TextColor3 = UIUtils.Color.Muted
		descLbl.Font = UIUtils.Font.Body
		descLbl.TextSize = 11
		descLbl.TextXAlignment = Enum.TextXAlignment.Left
		descLbl.TextTruncate = Enum.TextTruncate.AtEnd
		descLbl.Parent = row

		-- Slot
		local slotLbl = Instance.new("TextLabel")
		slotLbl.Size = UDim2.new(1, -170, 0, 12)
		slotLbl.Position = UDim2.new(0, 12, 0, 44)
		slotLbl.BackgroundTransparency = 1
		slotLbl.Text = SLOT_LABELS[itemSlot] or itemSlot
		slotLbl.TextColor3 = UIUtils.Color.Gold
		slotLbl.Font = UIUtils.Font.Body
		slotLbl.TextSize = 11
		slotLbl.TextXAlignment = Enum.TextXAlignment.Left
		slotLbl.Parent = row

		-- Prix
		local priceLbl = Instance.new("TextLabel")
		priceLbl.Size = UDim2.new(0, 62, 0, 20)
		priceLbl.Position = UDim2.new(1, -156, 0, 8)
		priceLbl.BackgroundTransparency = 1
		priceLbl.Text = tostring(itemPrice) .. " J"
		priceLbl.TextColor3 = if owned then UIUtils.Color.Muted else UIUtils.Color.Gold
		priceLbl.Font = UIUtils.Font.Title
		priceLbl.TextSize = 13
		priceLbl.TextXAlignment = Enum.TextXAlignment.Center
		priceLbl.Parent = row

		-- Bouton d'action
		local actionBtn = Instance.new("TextButton")
		actionBtn.Size = UDim2.new(0, 100, 0, 28)
		actionBtn.Position = UDim2.new(1, -112, 0.5, -14)
		actionBtn.BorderSizePixel = 0
		actionBtn.AutoButtonColor = false
		actionBtn.Parent = row
		UIUtils.round(actionBtn, 8)

		if equipped then
			actionBtn.Text = "✓ ÉQUIPÉ"
			actionBtn.BackgroundColor3 = UIUtils.Color.Charcoal
			actionBtn.TextColor3 = UIUtils.Color.Muted
			actionBtn.Font = UIUtils.Font.Title
			actionBtn.TextSize = 13
			actionBtn.Active = false
		elseif owned then
			actionBtn.Text = "ÉQUIPER"
			actionBtn.BackgroundColor3 = UIUtils.Color.Success
			actionBtn.TextColor3 = UIUtils.Color.White
			actionBtn.Font = UIUtils.Font.Title
			actionBtn.TextSize = 13
			actionBtn.Active = true
			UIUtils.hoverButton(actionBtn)
			actionBtn.MouseButton1Click:Connect(function()
				Net.getEvent(RemoteNames.ShopEquip):FireServer({ ItemId = itemId })
			end)
		else
			local canAfford = jetons >= itemPrice
			actionBtn.Text = "ACHETER"
			actionBtn.BackgroundColor3 = if canAfford then UIUtils.Color.Navy else UIUtils.Color.Charcoal
			actionBtn.TextColor3 = if canAfford then UIUtils.Color.White else UIUtils.Color.Muted
			actionBtn.Font = UIUtils.Font.Title
			actionBtn.TextSize = 13
			actionBtn.Active = canAfford
			if canAfford then
				UIUtils.hoverButton(actionBtn)
				actionBtn.MouseButton1Click:Connect(function()
					Net.getEvent(RemoteNames.ShopPurchase):FireServer({ ItemId = itemId })
				end)
			end
		end
	end
end

function ShopScreen.setup()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local screen = Instance.new("ScreenGui")
	screen.Name = "ShopScreenGui"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 60
	screen.Enabled = false
	screen.Parent = playerGui
	shopGui = screen

	-- Fond assombri
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(4, 4, 10)
	bg.BackgroundTransparency = 0.35
	bg.BorderSizePixel = 0
	bg.Parent = screen
	_bg = bg

	-- Panneau principal
	local panel = Instance.new("Frame")
	panel.Name = "ShopPanel"
	panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
	panel.BorderSizePixel = 0
	panel.Parent = screen
	_panel = panel
	UIUtils.round(panel, 16)
	UIUtils.stroke(panel, UIUtils.Color.Gold, 2)
	UIUtils.responsivePanel(panel, PANEL_W)

	-- En-tête
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 52)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundTransparency = 1
	header.BorderSizePixel = 0
	header.Parent = panel

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -52, 1, 0)
	titleLbl.Position = UDim2.new(0, 16, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = "BOUTIQUE DES COSMÉTIQUES"
	titleLbl.TextColor3 = UIUtils.Color.Gold
	titleLbl.Font = UIUtils.Font.Title
	titleLbl.TextSize = 18
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.TextYAlignment = Enum.TextYAlignment.Center
	titleLbl.Parent = header

	-- Bouton X (fermer) en haut à droite
	local closeX = Instance.new("TextButton")
	closeX.Size = UDim2.new(0, 32, 0, 32)
	closeX.Position = UDim2.new(1, -42, 0, 10)
	closeX.BackgroundColor3 = UIUtils.Color.Charcoal
	closeX.BorderSizePixel = 0
	closeX.Text = "✕"
	closeX.TextColor3 = UIUtils.Color.Muted
	closeX.Font = UIUtils.Font.Title
	closeX.TextSize = 16
	closeX.AutoButtonColor = false
	closeX.Parent = header
	UIUtils.round(closeX, 8)
	closeX.MouseButton1Click:Connect(function()
		ShopScreen.hide()
	end)

	-- Affichage Jetons
	local jDisplay = Instance.new("TextLabel")
	jDisplay.Size = UDim2.new(1, -24, 0, 28)
	jDisplay.Position = UDim2.new(0, 12, 0, 52)
	jDisplay.BackgroundTransparency = 1
	jDisplay.Text = "Jetons disponibles : —"
	jDisplay.TextColor3 = UIUtils.Color.Ivory
	jDisplay.Font = UIUtils.Font.Body
	jDisplay.TextSize = 13
	jDisplay.TextXAlignment = Enum.TextXAlignment.Right
	jDisplay.Parent = panel
	jetonsDisplay = jDisplay

	-- Séparateur
	local sep1 = Instance.new("Frame")
	sep1.Size = UDim2.new(1, -24, 0, 1)
	sep1.Position = UDim2.new(0, 12, 0, 82)
	sep1.BackgroundColor3 = UIUtils.Color.Gold
	sep1.BackgroundTransparency = 0.6
	sep1.BorderSizePixel = 0
	sep1.Parent = panel

	-- Liste d'items
	local list = Instance.new("ScrollingFrame")
	list.Name = "ItemList"
	list.Size = UDim2.new(1, -24, 0, ROW_H * 5)
	list.Position = UDim2.new(0, 12, 0, 85)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 4
	list.ScrollBarImageColor3 = UIUtils.Color.Gold
	list.CanvasSize = UDim2.new(0, 0, 0, ROW_H * 5)
	list.Parent = panel
	itemList = list

	-- Séparateur bas
	local sep2 = Instance.new("Frame")
	sep2.Size = UDim2.new(1, -24, 0, 1)
	sep2.Position = UDim2.new(0, 12, 0, 85 + ROW_H * 5 + 4)
	sep2.BackgroundColor3 = UIUtils.Color.Charcoal
	sep2.BackgroundTransparency = 0.4
	sep2.BorderSizePixel = 0
	sep2.Parent = panel

	-- Bouton fermer en bas
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0.5, 0, 0, 40)
	closeBtn.Position = UDim2.new(0.25, 0, 1, -52)
	closeBtn.BackgroundColor3 = UIUtils.Color.Charcoal
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "FERMER"
	closeBtn.TextColor3 = UIUtils.Color.Ivory
	closeBtn.Font = UIUtils.Font.Title
	closeBtn.TextSize = 14
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = panel
	UIUtils.round(closeBtn, 10)
	closeBtn.MouseButton1Click:Connect(function()
		ShopScreen.hide()
	end)
end

function ShopScreen.open()
	isOpen = true
	local g = shopGui
	if not g then
		return
	end
	g.Enabled = true
	if _bg then
		_bg.BackgroundTransparency = 1
		TweenService:Create(_bg, TweenInfo.new(0.20, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 0.35,
		}):Play()
	end
	local p = _panel
	if p then
		UIUtils.animateIn(p, "bottom", 0.28)
	end
end

function ShopScreen.hide()
	isOpen = false
	local g = shopGui
	if not g then
		return
	end
	if _bg then
		TweenService:Create(_bg, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 1,
		}):Play()
	end
	local p = _panel
	if p then
		UIUtils.animateOut(p, function()
			-- Vérifie que la boutique n'a pas été rouverte pendant l'animation de sortie.
			if not isOpen then
				g.Enabled = false
			end
		end, 0.18)
	else
		g.Enabled = false
	end
end

function ShopScreen.updateItems(items: { { [string]: any } }, jetons: number)
	if not isOpen then
		return
	end
	buildRows(items, jetons)
end

function ShopScreen.show(items: { { [string]: any } }, jetons: number)
	isOpen = true
	if shopGui then
		shopGui.Enabled = true
	end
	buildRows(items, jetons)
end

return ShopScreen
