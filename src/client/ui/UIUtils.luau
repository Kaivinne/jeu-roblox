--!strict
-- Constantes visuelles et helpers partagés par tous les modules UI.
-- M3.0 : helpers d'animation centralisés.
-- M3.1 : design system — TextSize, Spacing, Surface colors.
-- M3.2 : visual surface polish — gradient, button styles, premium panel.

local TweenService = game:GetService("TweenService")

local UIUtils = {}

-- ─── Palette ──────────────────────────────────────────────────────────────────

UIUtils.Color = {
	-- Identité
	Navy = Color3.fromRGB(26, 35, 126),
	Gold = Color3.fromRGB(212, 175, 55),
	Crimson = Color3.fromRGB(139, 0, 0),
	Success = Color3.fromRGB(34, 139, 34),
	-- Texte
	Ivory = Color3.fromRGB(255, 255, 240), -- texte primaire
	Muted = Color3.fromRGB(160, 160, 185), -- texte secondaire / métadonnées
	White = Color3.fromRGB(255, 255, 255),
	Black = Color3.fromRGB(0, 0, 0),
	-- Surfaces (fonds de panneaux)
	Surface = Color3.fromRGB(14, 14, 26), -- panneau principal
	SurfaceAlt = Color3.fromRGB(20, 20, 35), -- ligne alternée, champ
	SurfaceDeep = Color3.fromRGB(10, 10, 22), -- fond assombri (ProfilePanel)
	-- Utilitaires (conservés pour compatibilité)
	Charcoal = Color3.fromRGB(30, 30, 30),
}

-- ─── Police ───────────────────────────────────────────────────────────────────

UIUtils.Font = {
	Title = Enum.Font.GothamBold,
	Body = Enum.Font.Gotham,
}

-- ─── Tailles de texte ─────────────────────────────────────────────────────────
--
-- 6 niveaux hiérarchiques. Chaque module doit rester dans cette échelle.
--
--   Display (26) — révélation majeure, titre principal d'affaire
--   H1      (22) — titre de panneau, timer HUD
--   H2      (18) — bouton CTA principal, titre de boutique
--   H3      (15) — sous-titre, phase HUD, bouton secondaire
--   Body    (13) — corps de texte, descriptions
--   Caption (11) — métadonnées, labels de section, informations tertiaires
--
-- Règle : ne pas utiliser de valeur hors de cette table sans justification.

UIUtils.TextSize = {
	Display = 26,
	H1 = 22,
	H2 = 18,
	H3 = 15,
	Body = 13,
	Caption = 11,
}

-- ─── Espacements ──────────────────────────────────────────────────────────────
--
-- Multiples de 4 px. Utiliser pour marges, padding et gaps.

UIUtils.Spacing = {
	XS = 4,
	S = 8,
	M = 12,
	L = 16,
	XL = 24,
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
	btn.TextSize = UIUtils.TextSize.H3
	btn.AutoButtonColor = false
	btn.Parent = parent
	UIUtils.round(btn, 10)
	return btn
end

-- ─── Visual surface polish (M3.2) ─────────────────────────────────────────────

-- Applique un gradient discret haut-clair → bas-sombre sur un panneau.
-- Règle BackgroundColor3 à blanc pour que le gradient contrôle entièrement la couleur.
-- À appeler APRÈS responsivePanel() (la taille finale doit être fixée).
-- topColor / bottomColor : couleurs du gradient (defaults : navy clair → navy profond).
function UIUtils.panelGradient(frame: Frame, topColor: Color3?, bottomColor: Color3?)
	frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	local g = Instance.new("UIGradient")
	g.Rotation = 90 -- 90° = clé 0 en haut, clé 1 en bas
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, topColor or Color3.fromRGB(22, 22, 42)),
		ColorSequenceKeypoint.new(1, bottomColor or Color3.fromRGB(8, 8, 20)),
	})
	g.Parent = frame
end

-- Gradient de profondeur multiplicatif sur un bouton : haut inchangé, bas assombri.
-- Fonctionne avec le BackgroundColor3 existant du bouton (ne le remplace pas).
-- Convient pour texturer des boutons de n'importe quelle couleur sémantique.
function UIUtils.buttonGradient(btn: GuiObject)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), -- haut : pas de changement
		ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 148, 148)), -- bas  : ≈ 58 % = assombri
	})
	g.Parent = btn
end

-- Style de panneau complet en une seule ligne : coins + stroke doré + gradient de profondeur.
-- Ne pas appeler si round() / stroke() / panelGradient() ont déjà été appliqués séparément.
function UIUtils.premiumPanel(frame: Frame, cornerRadius: number?)
	UIUtils.round(frame, cornerRadius or 16)
	UIUtils.stroke(frame, UIUtils.Color.Gold, 2)
	UIUtils.panelGradient(frame)
end

-- Bouton CTA principal : fond Navy + stroke doré + gradient.
-- Usage : création de nouveaux boutons. Ne pas appeler sur des boutons déjà stylisés.
function UIUtils.buttonPrimary(btn: TextButton, cornerRadius: number?)
	btn.BackgroundColor3 = UIUtils.Color.Navy
	btn.TextColor3 = UIUtils.Color.White
	btn.Font = UIUtils.Font.Title
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	UIUtils.round(btn, cornerRadius or 10)
	UIUtils.stroke(btn, UIUtils.Color.Gold, 1)
	UIUtils.buttonGradient(btn)
end

-- Bouton secondaire : fond Charcoal sombre, texte Ivory, gradient discret.
function UIUtils.buttonSecondary(btn: TextButton, cornerRadius: number?)
	btn.BackgroundColor3 = UIUtils.Color.Charcoal
	btn.TextColor3 = UIUtils.Color.Ivory
	btn.Font = UIUtils.Font.Title
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	UIUtils.round(btn, cornerRadius or 10)
	UIUtils.buttonGradient(btn)
end

-- Bouton danger / action destructrice : fond Crimson, gradient assombri.
function UIUtils.buttonDanger(btn: TextButton, cornerRadius: number?)
	btn.BackgroundColor3 = UIUtils.Color.Crimson
	btn.TextColor3 = UIUtils.Color.White
	btn.Font = UIUtils.Font.Title
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	UIUtils.round(btn, cornerRadius or 10)
	UIUtils.buttonGradient(btn)
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
