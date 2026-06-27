--!strict
-- Constantes visuelles et helpers partagés par tous les modules UI.
-- M3.0 : helpers d'animation centralisés (animateIn / animateOut / hoverButton / pulse).

local TweenService = game:GetService("TweenService")

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

-- ─── Helpers structurels ──────────────────────────────────────────────────────

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

-- ─── Animation helpers ────────────────────────────────────────────────────────

-- Slide un GuiObject depuis un léger décalage vers sa position réelle (Quint Out).
-- Lit la position courante comme cible — non-destructif et re-entrant.
-- dir : "bottom" (défaut) | "top" | "left" | "right"
-- dur : durée en secondes (défaut 0.22)
function UIUtils.animateIn(frame: GuiObject, dir: string?, dur: number?)
	local direction = dir or "bottom"
	local duration = dur or 0.22
	local OFFSET = 16
	local target = frame.Position
	-- Initialise avec la variante "bottom" ; les branches if écrasent si besoin.
	local start = UDim2.new(target.X.Scale, target.X.Offset, target.Y.Scale, target.Y.Offset + OFFSET)
	if direction == "top" then
		start = UDim2.new(target.X.Scale, target.X.Offset, target.Y.Scale, target.Y.Offset - OFFSET)
	elseif direction == "left" then
		start = UDim2.new(target.X.Scale, target.X.Offset - OFFSET, target.Y.Scale, target.Y.Offset)
	elseif direction == "right" then
		start = UDim2.new(target.X.Scale, target.X.Offset + OFFSET, target.Y.Scale, target.Y.Offset)
	end
	frame.Position = start
	TweenService:Create(
		frame,
		TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = target }
	):Play()
end

-- Slide un GuiObject vers un léger décalage (Quad In), puis appelle onComplete.
-- Remet la position d'origine après la complétion pour que le prochain
-- animateIn parte du bon endroit.
-- dur : durée en secondes (défaut 0.18)
function UIUtils.animateOut(frame: GuiObject, onComplete: (() -> ())?, dur: number?)
	local duration = dur or 0.18
	local OFFSET = 10
	local origin = frame.Position
	local dest = UDim2.new(origin.X.Scale, origin.X.Offset, origin.Y.Scale, origin.Y.Offset + OFFSET)
	local t = TweenService:Create(
		frame,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = dest }
	)
	t:Play()
	t.Completed:Connect(function()
		frame.Position = origin
		if onComplete ~= nil then
			onComplete()
		end
	end)
end

-- Ajoute un effet hover subtil à un TextButton : éclaircit au survol.
-- amt : réduction de BackgroundTransparency au survol (défaut 0.12).
-- Capture la valeur de base au moment de l'appel.
function UIUtils.hoverButton(btn: TextButton, amt: number?)
	local amount = amt or 0.12
	local base = btn.BackgroundTransparency
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
			BackgroundTransparency = math.max(0, base - amount),
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
			BackgroundTransparency = base,
		}):Play()
	end)
end

-- Pulse de taille unique et discret — signale un événement important.
-- Utilisé sur les panneaux au moment d'une révélation.
function UIUtils.pulse(frame: GuiObject)
	local origin = frame.Size
	local grown = UDim2.new(origin.X.Scale, origin.X.Offset + 6, origin.Y.Scale, origin.Y.Offset + 6)
	TweenService:Create(frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = grown,
	}):Play()
	task.delay(0.14, function()
		TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = origin,
		}):Play()
	end)
end

-- Fondu d'une Frame de fond : cible la transparence donnée sur la durée donnée.
function UIUtils.fadeBg(bg: Frame, targetTransparency: number, dur: number?)
	TweenService:Create(bg, TweenInfo.new(dur or 0.20, Enum.EasingStyle.Quad), {
		BackgroundTransparency = targetTransparency,
	}):Play()
end

return UIUtils
