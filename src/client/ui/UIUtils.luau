--!strict
-- Constantes visuelles et helpers partagés par tous les modules UI.

local UIUtils = {}

UIUtils.Color = {
	Navy = Color3.fromRGB(26, 35, 126),
	Ivory = Color3.fromRGB(255, 255, 240),
	Gold = Color3.fromRGB(212, 175, 55),
	Crimson = Color3.fromRGB(139, 0, 0),
	Charcoal = Color3.fromRGB(30, 30, 30),
	Success = Color3.fromRGB(34, 139, 34),
	White = Color3.fromRGB(255, 255, 255),
	Black = Color3.fromRGB(0, 0, 0),
	Muted = Color3.fromRGB(160, 160, 185),
}

UIUtils.Font = {
	Title = Enum.Font.GothamBold,
	Body = Enum.Font.Gotham,
}

-- Applique des coins arrondis
function UIUtils.round(obj: GuiObject, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = obj
end

-- Applique une bordure visible
function UIUtils.stroke(obj: GuiObject, color: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Parent = obj
end

-- Rend un panneau centré responsive : 90 % de largeur écran sur mobile,
-- plafonné à maxWidth sur PC. Impose AnchorPoint.X = 0.5.
-- À appeler juste après avoir créé le panneau dans setup().
function UIUtils.responsivePanel(panel: Frame, maxWidth: number)
	panel.AnchorPoint = Vector2.new(0.5, panel.AnchorPoint.Y)
	panel.Size = UDim2.new(0.9, 0, panel.Size.Y.Scale, panel.Size.Y.Offset)
	panel.Position = UDim2.new(0.5, 0, panel.Position.Y.Scale, panel.Position.Y.Offset)
	local c = Instance.new("UISizeConstraint")
	c.MaxSize = Vector2.new(maxWidth, math.huge)
	c.Parent = panel
end

-- Formate un nombre de secondes en "MM:SS"
function UIUtils.formatTime(seconds: number): string
	local m = math.floor(seconds / 60)
	local s = math.floor(seconds % 60)
	return string.format("%02d:%02d", m, s)
end

-- Crée un TextButton stylisé avec fond et texte
function UIUtils.makeButton(
	parent: GuiObject,
	text: string,
	bgColor: Color3,
	size: UDim2,
	position: UDim2
): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = size
	btn.Position = position
	btn.BackgroundColor3 = bgColor
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = UIUtils.Color.White
	btn.Font = UIUtils.Font.Title
	btn.TextSize = 16
	btn.AutoButtonColor = false
	btn.Parent = parent
	UIUtils.round(btn, 10)
	return btn
end

return UIUtils
