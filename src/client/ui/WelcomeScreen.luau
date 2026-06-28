--!strict
-- Bannière d'accueil affichée en bas d'écran à l'entrée du lobby.
-- Slide depuis le bas, disparaît automatiquement après DISPLAY_SECONDS
-- ou au premier appel de dismiss() (déclenché par GamePhaseChanged).
-- DisplayOrder=10 — sous tous les panneaux de jeu.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local WelcomeScreen = {}

-- ─── Constantes ───────────────────────────────────────────────────────────────

local DISPLAY_SECONDS = 4.5
local SLIDE_IN = 0.55 -- secondes pour l'entrée
local SLIDE_OUT = 0.45 -- secondes pour la sortie

local PANEL_HEIGHT = 94 -- pixels

-- ─── État interne (singleton par session) ────────────────────────────────────

local _gui: ScreenGui? = nil
local _panel: Frame? = nil
local _dismissed = false
local _dismissTask: thread? = nil

-- ─── Initialisation lazy ──────────────────────────────────────────────────────

local function ensureGui()
	if _gui then
		return
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local gui = Instance.new("ScreenGui")
	gui.Name = "WelcomeScreenGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 10 -- sous tous les panneaux gameplay
	gui.Enabled = false
	gui.Parent = playerGui
	_gui = gui

	-- Panneau principal — positionné hors écran en bas au repos
	local panel = Instance.new("Frame")
	panel.Name = "WelcomePanel"
	panel.Size = UDim2.new(1, 0, 0, PANEL_HEIGHT)
	panel.Position = UDim2.new(0, 0, 1, PANEL_HEIGHT) -- hors écran
	panel.BackgroundColor3 = Color3.fromRGB(6, 6, 18)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Parent = gui
	_panel = panel

	-- Liseré doré en haut du panneau
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 2)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.BackgroundColor3 = Color3.fromRGB(200, 158, 48)
	topBar.BackgroundTransparency = 0
	topBar.BorderSizePixel = 0
	topBar.Parent = panel

	-- Titre du jeu
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 38)
	title.Position = UDim2.new(0, 12, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "THE WITNESS BOX"
	title.TextColor3 = Color3.fromRGB(200, 158, 48)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = panel

	-- Sous-titre
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -24, 0, 20)
	subtitle.Position = UDim2.new(0, 12, 0, 48)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Tribunal d'assises — Découvrez la vérité"
	subtitle.TextColor3 = Color3.fromRGB(175, 158, 120)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 13
	subtitle.TextXAlignment = Enum.TextXAlignment.Center
	subtitle.Parent = panel

	-- Message d'attente
	local msg = Instance.new("TextLabel")
	msg.Size = UDim2.new(1, -24, 0, 16)
	msg.Position = UDim2.new(0, 12, 0, 72)
	msg.BackgroundTransparency = 1
	msg.Text = "Le procès commence bientôt…"
	msg.TextColor3 = Color3.fromRGB(120, 108, 85)
	msg.Font = Enum.Font.Gotham
	msg.TextSize = 11
	msg.TextXAlignment = Enum.TextXAlignment.Center
	msg.Parent = panel
end

-- ─── API publique ─────────────────────────────────────────────────────────────

-- Affiche la bannière d'accueil avec un slide depuis le bas.
-- Sans effet si déjà affiché ou déjà rejeté.
function WelcomeScreen.show()
	if _dismissed then
		return
	end
	ensureGui()

	local gui = _gui :: ScreenGui
	local panel = _panel :: Frame

	-- Position de départ : légèrement sous le bas de l'écran
	panel.Position = UDim2.new(0, 0, 1, PANEL_HEIGHT)
	gui.Enabled = true

	-- Slide vers le haut pour amener le panneau à la hauteur voulue
	TweenService:Create(
		panel,
		TweenInfo.new(SLIDE_IN, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, 0, 1, -PANEL_HEIGHT) }
	):Play()

	-- Auto-dismiss après DISPLAY_SECONDS
	_dismissTask = task.spawn(function()
		task.wait(DISPLAY_SECONDS)
		WelcomeScreen.dismiss()
	end)
end

-- Rejette la bannière avec un slide vers le bas.
-- Idempotent — sans effet si déjà rejeté.
function WelcomeScreen.dismiss()
	if _dismissed then
		return
	end
	_dismissed = true

	if _dismissTask then
		task.cancel(_dismissTask)
		_dismissTask = nil
	end

	local gui = _gui
	local panel = _panel
	if not gui or not panel then
		return
	end

	TweenService:Create(
		panel,
		TweenInfo.new(SLIDE_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(0, 0, 1, PANEL_HEIGHT) }
	):Play()

	task.delay(SLIDE_OUT, function()
		local g = _gui
		if g then
			g.Enabled = false
		end
	end)
end

return WelcomeScreen
