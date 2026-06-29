--!strict
-- Panneau de délibération : récapitulatif du contexte + opinion non engageante.
-- Affiché pour tous les joueurs durant la phase Deliberation.
-- DisplayOrder = 35 — au-dessus du ProfilePanel (5), sous SummaryScreen (50).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UIUtils = require(script.Parent.UIUtils)
local AudioController = require(script.Parent.Parent.AudioController)

local DeliberationScreen = {}

-- ─── État interne ─────────────────────────────────────────────────────────────

local _gui: ScreenGui? = nil
local _panel: Frame? = nil
local _prepLabel: TextLabel? = nil
local _declLabel: TextLabel? = nil
local _accusationLabel: TextLabel? = nil
local _contextLabel: TextLabel? = nil
local _noteLbl: TextLabel? = nil
local _opinionMentBtn: TextButton? = nil
local _opinionVraiBtn: TextButton? = nil
local _opinionVoted = false

-- ─── Construction UI (lazy) ───────────────────────────────────────────────────

local function ensureGui()
	if _gui then
		return
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local gui = Instance.new("ScreenGui")
	gui.Name = "DeliberationScreenGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 35
	gui.Enabled = false
	gui.Parent = playerGui
	_gui = gui

	-- Fond légèrement assombri pour la lisibilité
	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = UIUtils.Color.Black
	backdrop.BackgroundTransparency = 0.72
	backdrop.BorderSizePixel = 0
	backdrop.Parent = gui

	-- Panneau principal centré
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 520, 0, 280)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.BorderSizePixel = 0
	panel.Parent = gui
	_panel = panel
	UIUtils.responsivePanel(panel, 520)
	UIUtils.premiumPanel(panel, 14)

	-- Titre (haut-gauche)
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(0.6, 0, 0, 24)
	titleLbl.Position = UDim2.new(0, 12, 0, 10)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = "DÉLIBÉRATION"
	titleLbl.TextColor3 = UIUtils.Color.Gold
	titleLbl.Font = UIUtils.Font.Title
	titleLbl.TextSize = UIUtils.TextSize.H2
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = panel

	-- Sous-titre adaptatif (haut-droit)
	local prepLbl = Instance.new("TextLabel")
	prepLbl.Size = UDim2.new(0.5, -12, 0, 24)
	prepLbl.Position = UDim2.new(0.5, 0, 0, 10)
	prepLbl.BackgroundTransparency = 1
	prepLbl.TextColor3 = UIUtils.Color.Ivory
	prepLbl.Font = UIUtils.Font.Body
	prepLbl.TextSize = UIUtils.TextSize.H3
	prepLbl.TextXAlignment = Enum.TextXAlignment.Right
	prepLbl.Parent = panel
	_prepLabel = prepLbl

	-- Séparateur titre
	local sep1 = Instance.new("Frame")
	sep1.Size = UDim2.new(1, -16, 0, 1)
	sep1.Position = UDim2.new(0, 8, 0, 38)
	sep1.BackgroundColor3 = UIUtils.Color.Gold
	sep1.BackgroundTransparency = 0.60
	sep1.BorderSizePixel = 0
	sep1.Parent = panel

	-- En-tête section déclaration
	local declHeader = Instance.new("TextLabel")
	declHeader.Size = UDim2.new(1, -16, 0, 14)
	declHeader.Position = UDim2.new(0, 8, 0, 46)
	declHeader.BackgroundTransparency = 1
	declHeader.Text = "Déclaration du témoin :"
	declHeader.TextColor3 = UIUtils.Color.Muted
	declHeader.Font = UIUtils.Font.Body
	declHeader.TextSize = UIUtils.TextSize.Caption
	declHeader.TextXAlignment = Enum.TextXAlignment.Left
	declHeader.Parent = panel

	-- Boîte de déclaration (fond sombre, bordure or)
	local declBox = Instance.new("Frame")
	declBox.Size = UDim2.new(1, -16, 0, 46)
	declBox.Position = UDim2.new(0, 8, 0, 62)
	declBox.BackgroundColor3 = UIUtils.Color.SurfaceDeep
	declBox.BackgroundTransparency = 0.15
	declBox.BorderSizePixel = 0
	declBox.Parent = panel
	UIUtils.round(declBox, 6)
	UIUtils.stroke(declBox, UIUtils.Color.Gold, 1)

	local declLbl = Instance.new("TextLabel")
	declLbl.Size = UDim2.new(1, -16, 1, 0)
	declLbl.Position = UDim2.new(0, 8, 0, 0)
	declLbl.BackgroundTransparency = 1
	declLbl.TextColor3 = UIUtils.Color.Ivory
	declLbl.Font = UIUtils.Font.Body
	declLbl.TextSize = UIUtils.TextSize.Body
	declLbl.TextXAlignment = Enum.TextXAlignment.Left
	declLbl.TextWrapped = true
	declLbl.Parent = declBox
	_declLabel = declLbl

	-- Accusation (Y=116)
	local accusationLbl = Instance.new("TextLabel")
	accusationLbl.Size = UDim2.new(1, -16, 0, 32)
	accusationLbl.Position = UDim2.new(0, 8, 0, 116)
	accusationLbl.BackgroundTransparency = 1
	accusationLbl.TextColor3 = UIUtils.Color.Muted
	accusationLbl.Font = UIUtils.Font.Body
	accusationLbl.TextSize = UIUtils.TextSize.Caption
	accusationLbl.TextXAlignment = Enum.TextXAlignment.Left
	accusationLbl.TextWrapped = true
	accusationLbl.Parent = panel
	_accusationLabel = accusationLbl

	-- Texte contextuel format (Y=154)
	local contextLbl = Instance.new("TextLabel")
	contextLbl.Size = UDim2.new(1, -16, 0, 22)
	contextLbl.Position = UDim2.new(0, 8, 0, 154)
	contextLbl.BackgroundTransparency = 1
	contextLbl.TextColor3 = UIUtils.Color.Gold
	contextLbl.Font = UIUtils.Font.Body
	contextLbl.TextSize = UIUtils.TextSize.Caption
	contextLbl.TextXAlignment = Enum.TextXAlignment.Left
	contextLbl.TextWrapped = true
	contextLbl.Parent = panel
	_contextLabel = contextLbl

	-- Séparateur avant boutons
	local sep2 = Instance.new("Frame")
	sep2.Size = UDim2.new(1, -16, 0, 1)
	sep2.Position = UDim2.new(0, 8, 0, 182)
	sep2.BackgroundColor3 = UIUtils.Color.Gold
	sep2.BackgroundTransparency = 0.70
	sep2.BorderSizePixel = 0
	sep2.Parent = panel

	-- Bouton "Je pense qu'il ment" (Y=190, moitié gauche)
	local mentBtn = Instance.new("TextButton")
	mentBtn.Size = UDim2.new(0.5, -12, 0, 40)
	mentBtn.Position = UDim2.new(0, 8, 0, 190)
	mentBtn.BackgroundColor3 = UIUtils.Color.Crimson
	mentBtn.BackgroundTransparency = 0.10
	mentBtn.BorderSizePixel = 0
	mentBtn.Text = "Je pense qu'il ment"
	mentBtn.TextColor3 = UIUtils.Color.White
	mentBtn.Font = UIUtils.Font.Title
	mentBtn.TextSize = UIUtils.TextSize.H3
	mentBtn.AutoButtonColor = false
	mentBtn.Parent = panel
	UIUtils.round(mentBtn, 8)
	UIUtils.hoverButton(mentBtn, 0.12)
	_opinionMentBtn = mentBtn

	-- Bouton "Je pense qu'il dit vrai" (Y=190, moitié droite)
	local vraiBtn = Instance.new("TextButton")
	vraiBtn.Size = UDim2.new(0.5, -12, 0, 40)
	vraiBtn.Position = UDim2.new(0.5, 4, 0, 190)
	vraiBtn.BackgroundColor3 = UIUtils.Color.Success
	vraiBtn.BackgroundTransparency = 0.10
	vraiBtn.BorderSizePixel = 0
	vraiBtn.Text = "Je pense qu'il dit vrai"
	vraiBtn.TextColor3 = UIUtils.Color.White
	vraiBtn.Font = UIUtils.Font.Title
	vraiBtn.TextSize = UIUtils.TextSize.H3
	vraiBtn.AutoButtonColor = false
	vraiBtn.Parent = panel
	UIUtils.round(vraiBtn, 8)
	UIUtils.hoverButton(vraiBtn, 0.12)
	_opinionVraiBtn = vraiBtn

	-- Note bas de panneau (Y=240)
	local noteLbl = Instance.new("TextLabel")
	noteLbl.Size = UDim2.new(1, -16, 0, 18)
	noteLbl.Position = UDim2.new(0, 8, 0, 240)
	noteLbl.BackgroundTransparency = 1
	noteLbl.TextColor3 = UIUtils.Color.Muted
	noteLbl.Font = UIUtils.Font.Body
	noteLbl.TextSize = UIUtils.TextSize.Caption
	noteLbl.TextXAlignment = Enum.TextXAlignment.Center
	noteLbl.Parent = panel
	_noteLbl = noteLbl

	-- Connexion des boutons d'opinion (cosmétique uniquement, aucun effet sur le vote)
	local function recordOpinion(picked: TextButton, other: TextButton)
		if _opinionVoted then
			return
		end
		_opinionVoted = true
		TweenService
			:Create(other, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.70 })
			:Play()
		TweenService
			:Create(picked, TweenInfo.new(0.10, Enum.EasingStyle.Quad), { BackgroundTransparency = 0 })
			:Play()
		UIUtils.pulse(picked)
	end

	mentBtn.MouseEnter:Connect(function()
		AudioController.play("ui_hover")
	end)
	vraiBtn.MouseEnter:Connect(function()
		AudioController.play("ui_hover")
	end)
	mentBtn.MouseButton1Click:Connect(function()
		AudioController.play("ui_click")
		recordOpinion(mentBtn, vraiBtn)
	end)
	vraiBtn.MouseButton1Click:Connect(function()
		AudioController.play("ui_click")
		recordOpinion(vraiBtn, mentBtn)
	end)
end

-- ─── API publique ─────────────────────────────────────────────────────────────

function DeliberationScreen.show(
	format: string,
	role: string,
	declaration: string,
	accusation: string,
	reactions: { string }
)
	ensureGui()

	-- Réinitialiser l'état des boutons pour ce nouveau match
	_opinionVoted = false
	local mb = _opinionMentBtn
	local vb = _opinionVraiBtn
	if mb then
		mb.BackgroundTransparency = 0.10
	end
	if vb then
		vb.BackgroundTransparency = 0.10
	end

	-- Sous-titre selon le rôle
	local pl = _prepLabel
	if pl then
		pl.Text = if role == "Juror" then "Prépare ton verdict" else "Analyse en cours"
	end

	-- Déclaration
	local dl = _declLabel
	if dl then
		dl.Text = if declaration ~= "" then declaration else "Aucune déclaration reçue pour l'instant."
	end

	-- Accusation
	local al = _accusationLabel
	if al then
		al.Text = if accusation ~= "" then "Accusation : " .. accusation else ""
	end

	-- Contexte format-spécifique
	local cl = _contextLabel
	if cl then
		if format == "Solo" then
			cl.Text = "Compare la déclaration avec les indices."
		elseif format == "Duel" and #reactions > 0 then
			cl.Text = "Réactions : " .. table.concat(reactions, " · ")
		else
			cl.Text = ""
		end
	end

	-- Note bas adaptée au rôle
	local nl = _noteLbl
	if nl then
		nl.Text = if role == "Juror"
			then "Ton vote viendra à la phase de verdict."
			else "Le jury délibère — le verdict sera annoncé bientôt."
	end

	local g = _gui :: ScreenGui
	local p = _panel :: Frame
	p.Position = UDim2.new(0.5, 0, 0.47, 0)
	g.Enabled = true
	TweenService:Create(
		p,
		TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0.5, 0) }
	):Play()
end

function DeliberationScreen.hide()
	local g = _gui
	if g then
		g.Enabled = false
	end
end

return DeliberationScreen
