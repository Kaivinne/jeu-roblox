--!strict
-- Onboarding first-time : 3 slides pour les nouveaux joueurs.
-- Affiché uniquement si HasSeenOnboarding = false (contrôlé côté serveur).
-- replay() permet de revoir l'onboarding depuis le bouton AIDE du ProfilePanel.
-- DisplayOrder = 120 — au-dessus de CameraFadeGui (100), sous VerdictSequence (150).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UIUtils = require(script.Parent.UIUtils)
local AudioController = require(script.Parent.Parent.AudioController)

local OnboardingScreen = {}

-- ─── Contenu des slides ───────────────────────────────────────────────────────

type Slide = { step: string, icon: string, title: string, desc: string }

local SLIDES: { Slide } = {
	{
		step = "ÉTAPE 1 / 3",
		icon = "1",
		title = "Écoute les déclarations",
		desc = "Chaque partie, un ou plusieurs témoins s'expriment devant le tribunal.\nLis attentivement leur déclaration.",
	},
	{
		step = "ÉTAPE 2 / 3",
		icon = "2",
		title = "Repère les incohérences",
		desc = "Compare ce que dit le témoin avec les faits officiels.\nUne contradiction peut révéler le mensonge.",
	},
	{
		step = "ÉTAPE 3 / 3",
		icon = "3",
		title = "Vote Coupable ou Innocent",
		desc = "En tant que juré, exprime ton verdict.\nLa vérité est révélée pour tous en fin de partie.",
	},
}

-- ─── État interne (singleton) ─────────────────────────────────────────────────

local _gui: ScreenGui? = nil
local _panel: Frame? = nil
local _stepLabel: TextLabel? = nil
local _iconLabel: TextLabel? = nil
local _titleLabel: TextLabel? = nil
local _descLabel: TextLabel? = nil
local _dots: { Frame } = {}
local _nextBtn: TextButton? = nil
local _skipBtn: TextButton? = nil

local _currentSlide: number = 1
local _onDone: (() -> ())? = nil
local _buttonsConnected = false

-- ─── Construction UI (lazy) ───────────────────────────────────────────────────

local function ensureGui()
	if _gui then
		return
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local gui = Instance.new("ScreenGui")
	gui.Name = "OnboardingScreenGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 120
	gui.Enabled = false
	gui.Parent = playerGui
	_gui = gui

	-- Fond semi-transparent plein écran (non cliquable pour fermer)
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = UIUtils.Color.Black
	backdrop.BackgroundTransparency = 0.45
	backdrop.BorderSizePixel = 0
	backdrop.Parent = gui

	-- Panneau centré
	local panel = Instance.new("Frame")
	panel.Name = "OnboardingPanel"
	panel.Size = UDim2.new(0, 500, 0, 370)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.BorderSizePixel = 0
	panel.Parent = gui
	_panel = panel
	UIUtils.responsivePanel(panel, 500)
	UIUtils.premiumPanel(panel, 16)

	-- Indicateur d'étape (haut-droit)
	local stepLbl = Instance.new("TextLabel")
	stepLbl.Name = "StepLabel"
	stepLbl.Size = UDim2.new(1, -16, 0, 20)
	stepLbl.Position = UDim2.new(0, 8, 0, 12)
	stepLbl.BackgroundTransparency = 1
	stepLbl.TextColor3 = UIUtils.Color.Muted
	stepLbl.Font = UIUtils.Font.Body
	stepLbl.TextSize = UIUtils.TextSize.Caption
	stepLbl.TextXAlignment = Enum.TextXAlignment.Right
	stepLbl.Parent = panel
	_stepLabel = stepLbl

	-- Cercle icône numéroté (centré, Y=36)
	local circle = Instance.new("Frame")
	circle.Name = "IconCircle"
	circle.Size = UDim2.new(0, 72, 0, 72)
	circle.AnchorPoint = Vector2.new(0.5, 0)
	circle.Position = UDim2.new(0.5, 0, 0, 36)
	circle.BackgroundColor3 = UIUtils.Color.Navy
	circle.BorderSizePixel = 0
	circle.Parent = panel
	UIUtils.round(circle, 36)
	UIUtils.stroke(circle, UIUtils.Color.Gold, 2)

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Name = "IconLabel"
	iconLbl.Size = UDim2.new(1, 0, 1, 0)
	iconLbl.BackgroundTransparency = 1
	iconLbl.TextColor3 = UIUtils.Color.Gold
	iconLbl.Font = UIUtils.Font.Title
	iconLbl.TextSize = 32
	iconLbl.TextXAlignment = Enum.TextXAlignment.Center
	iconLbl.TextYAlignment = Enum.TextYAlignment.Center
	iconLbl.Parent = circle
	_iconLabel = iconLbl

	-- Titre (Y=120)
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "TitleLabel"
	titleLbl.Size = UDim2.new(1, -32, 0, 40)
	titleLbl.Position = UDim2.new(0, 16, 0, 120)
	titleLbl.BackgroundTransparency = 1
	titleLbl.TextColor3 = UIUtils.Color.Gold
	titleLbl.Font = UIUtils.Font.Title
	titleLbl.TextSize = UIUtils.TextSize.H1
	titleLbl.TextXAlignment = Enum.TextXAlignment.Center
	titleLbl.TextWrapped = true
	titleLbl.Parent = panel
	_titleLabel = titleLbl

	-- Description (Y=168)
	local descLbl = Instance.new("TextLabel")
	descLbl.Name = "DescLabel"
	descLbl.Size = UDim2.new(1, -48, 0, 80)
	descLbl.Position = UDim2.new(0, 24, 0, 168)
	descLbl.BackgroundTransparency = 1
	descLbl.TextColor3 = UIUtils.Color.Ivory
	descLbl.Font = UIUtils.Font.Body
	descLbl.TextSize = UIUtils.TextSize.Body
	descLbl.TextXAlignment = Enum.TextXAlignment.Center
	descLbl.TextWrapped = true
	descLbl.Parent = panel
	_descLabel = descLbl

	-- Points de progression (Y=264, centrés)
	local dotsRow = Instance.new("Frame")
	dotsRow.Name = "DotsRow"
	dotsRow.Size = UDim2.new(0, 40, 0, 12)
	dotsRow.AnchorPoint = Vector2.new(0.5, 0)
	dotsRow.Position = UDim2.new(0.5, 0, 0, 264)
	dotsRow.BackgroundTransparency = 1
	dotsRow.BorderSizePixel = 0
	dotsRow.Parent = panel

	_dots = {}
	for i = 1, 3 do
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 10, 0, 10)
		dot.Position = UDim2.new(0, (i - 1) * 15, 0, 1)
		dot.BackgroundColor3 = UIUtils.Color.Muted
		dot.BorderSizePixel = 0
		dot.Parent = dotsRow
		UIUtils.round(dot, 5)
		table.insert(_dots, dot)
	end

	-- Bouton "Passer" (bas-gauche, Y=298)
	local skipBtn = Instance.new("TextButton")
	skipBtn.Name = "SkipBtn"
	skipBtn.Size = UDim2.new(0, 90, 0, 36)
	skipBtn.Position = UDim2.new(0, 12, 0, 298)
	skipBtn.BackgroundColor3 = UIUtils.Color.SurfaceAlt
	skipBtn.BackgroundTransparency = 0.2
	skipBtn.BorderSizePixel = 0
	skipBtn.Text = "Passer"
	skipBtn.TextColor3 = UIUtils.Color.Muted
	skipBtn.Font = UIUtils.Font.Body
	skipBtn.TextSize = UIUtils.TextSize.H3
	skipBtn.AutoButtonColor = false
	skipBtn.Parent = panel
	UIUtils.round(skipBtn, 8)
	UIUtils.hoverButton(skipBtn, 0.1)
	_skipBtn = skipBtn

	-- Bouton "Suivant" / "Terminer" (bas-droite, Y=298)
	local nextBtn = Instance.new("TextButton")
	nextBtn.Name = "NextBtn"
	nextBtn.Size = UDim2.new(0, 140, 0, 36)
	nextBtn.Position = UDim2.new(1, -152, 0, 298)
	nextBtn.BorderSizePixel = 0
	nextBtn.Font = UIUtils.Font.Title
	nextBtn.TextSize = UIUtils.TextSize.H3
	nextBtn.AutoButtonColor = false
	nextBtn.Parent = panel
	UIUtils.buttonPrimary(nextBtn, 8)
	UIUtils.hoverButton(nextBtn, 0.12)
	_nextBtn = nextBtn
end

-- ─── Navigation interne ───────────────────────────────────────────────────────

local function updateSlide(n: number)
	local slide = SLIDES[n]
	if _stepLabel then
		_stepLabel.Text = slide.step
	end
	if _iconLabel then
		_iconLabel.Text = slide.icon
	end
	if _titleLabel then
		_titleLabel.Text = slide.title
	end
	if _descLabel then
		_descLabel.Text = slide.desc
	end
	for i, dot in ipairs(_dots) do
		dot.BackgroundColor3 = if i == n then UIUtils.Color.Gold else UIUtils.Color.Muted
	end
	local btn = _nextBtn
	if btn then
		btn.Text = if n == #SLIDES then "TERMINER" else "SUIVANT"
	end
end

local function closePanel(fireCallback: boolean)
	local g = _gui
	if not g then
		return
	end
	local p = _panel
	if p then
		TweenService:Create(
			p,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 0.62, 0) }
		):Play()
	end
	task.delay(0.22, function()
		g.Enabled = false
		if fireCallback and _onDone ~= nil then
			local cb = _onDone
			_onDone = nil
			cb()
		end
	end)
end

local function openPanel()
	local g = _gui :: ScreenGui
	local p = _panel :: Frame
	_currentSlide = 1
	updateSlide(1)
	p.Position = UDim2.new(0.5, 0, 0.42, 0)
	g.Enabled = true
	TweenService:Create(
		p,
		TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0.5, 0) }
	):Play()
end

local function connectButtons()
	if _buttonsConnected then
		return
	end
	_buttonsConnected = true
	local nb = _nextBtn
	local sb = _skipBtn
	if nb then
		nb.MouseEnter:Connect(function()
			AudioController.play("ui_hover")
		end)
		nb.MouseButton1Click:Connect(function()
			if _currentSlide < #SLIDES then
				AudioController.play("ui_click") -- navigation entre slides
				_currentSlide += 1
				updateSlide(_currentSlide)
			else
				AudioController.play("ui_confirm") -- TERMINER
				closePanel(true)
			end
		end)
	end
	if sb then
		sb.MouseEnter:Connect(function()
			AudioController.play("ui_hover")
		end)
		sb.MouseButton1Click:Connect(function()
			AudioController.play("ui_cancel") -- Passer
			closePanel(true)
		end)
	end
end

-- ─── API publique ─────────────────────────────────────────────────────────────

-- Affiche l'onboarding pour un nouveau joueur.
-- onDone est appelé une seule fois à la fin (skip ou terminer) — notifie le serveur.
function OnboardingScreen.show(onDone: () -> ())
	ensureGui()
	connectButtons()
	_onDone = onDone
	openPanel()
end

-- Réaffiche l'onboarding depuis le bouton AIDE — sans notifier le serveur.
function OnboardingScreen.replay()
	ensureGui()
	connectButtons()
	_onDone = nil
	openPanel()
end

return OnboardingScreen
