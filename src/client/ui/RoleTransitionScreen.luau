--!strict
-- Transition de rôle : fondu dramatique lors du passage Lobby → Intro.
-- Affiche le rôle et l'objectif brièvement avant que la salle soit révélée.
-- DisplayOrder = 140 — entre OnboardingScreen (120) et VerdictSequence (150).
-- Non-bloquant : retourne immédiatement, dure 1.30 s au total.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UIUtils = require(script.Parent.UIUtils)

local RoleTransitionScreen = {}

-- ─── État interne ─────────────────────────────────────────────────────────────

local _gui: ScreenGui? = nil
local _backdrop: Frame? = nil
local _iconLabel: TextLabel? = nil
local _roleLabel: TextLabel? = nil
local _objectiveLabel: TextLabel? = nil
local _playing = false

-- ─── Helpers rôle ────────────────────────────────────────────────────────────

local function getRoleName(role: string): string
	local names: { [string]: string } = {
		HonestWitness = "TÉMOIN HONNÊTE",
		Liar = "MENTEUR",
		Prosecutor = "AVOCAT",
		Defense = "DÉFENSEUR",
		Juror = "JURÉ",
	}
	return names[role] or role:upper()
end

local function getRoleColor(role: string): Color3
	if role == "Liar" then
		return UIUtils.Color.Crimson
	elseif role == "HonestWitness" then
		return UIUtils.Color.Success
	else
		return UIUtils.Color.Gold
	end
end

-- ─── Construction UI (lazy) ───────────────────────────────────────────────────

local function ensureGui()
	if _gui then
		return
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local gui = Instance.new("ScreenGui")
	gui.Name = "RoleTransitionGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 140
	gui.Enabled = false
	gui.Parent = playerGui
	_gui = gui

	-- Fond noir plein écran
	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = UIUtils.Color.Black
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel = 0
	backdrop.Parent = gui
	_backdrop = backdrop

	-- Icône du rôle (◆ coloré selon le rôle)
	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size = UDim2.new(0, 28, 0, 28)
	iconLbl.AnchorPoint = Vector2.new(0.5, 0.5)
	iconLbl.Position = UDim2.new(0.5, 0, 0.5, -54)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Text = "◆"
	iconLbl.TextColor3 = UIUtils.Color.Gold
	iconLbl.Font = UIUtils.Font.Title
	iconLbl.TextSize = 22
	iconLbl.TextXAlignment = Enum.TextXAlignment.Center
	iconLbl.TextTransparency = 1
	iconLbl.Parent = backdrop
	_iconLabel = iconLbl

	-- Nom du rôle ("VOUS ÊTES : MENTEUR")
	local roleLbl = Instance.new("TextLabel")
	roleLbl.Size = UDim2.new(0.8, 0, 0, 36)
	roleLbl.AnchorPoint = Vector2.new(0.5, 0.5)
	roleLbl.Position = UDim2.new(0.5, 0, 0.5, -14)
	roleLbl.BackgroundTransparency = 1
	roleLbl.Text = "VOUS ÊTES : —"
	roleLbl.TextColor3 = UIUtils.Color.Gold
	roleLbl.Font = UIUtils.Font.Title
	roleLbl.TextSize = UIUtils.TextSize.H1
	roleLbl.TextXAlignment = Enum.TextXAlignment.Center
	roleLbl.TextTransparency = 1
	roleLbl.Parent = backdrop
	_roleLabel = roleLbl

	-- Objectif du rôle (texte court, enroulé)
	local objLbl = Instance.new("TextLabel")
	objLbl.Size = UDim2.new(0.65, 0, 0, 44)
	objLbl.AnchorPoint = Vector2.new(0.5, 0)
	objLbl.Position = UDim2.new(0.5, 0, 0.5, 12)
	objLbl.BackgroundTransparency = 1
	objLbl.Text = ""
	objLbl.TextColor3 = UIUtils.Color.Muted
	objLbl.Font = UIUtils.Font.Body
	objLbl.TextSize = UIUtils.TextSize.Caption
	objLbl.TextXAlignment = Enum.TextXAlignment.Center
	objLbl.TextWrapped = true
	objLbl.TextTransparency = 1
	objLbl.Parent = backdrop
	_objectiveLabel = objLbl
end

-- ─── API publique ─────────────────────────────────────────────────────────────

-- Joue la transition de rôle (non-bloquant, 1.30 s).
-- Ignoré si role est vide ou si une transition est déjà en cours.
function RoleTransitionScreen.play(role: string, objective: string)
	if role == "" or _playing then
		return
	end
	_playing = true
	ensureGui()

	local g = _gui :: ScreenGui
	local backdrop = _backdrop :: Frame
	local iconLbl = _iconLabel :: TextLabel
	local roleLbl = _roleLabel :: TextLabel
	local objLbl = _objectiveLabel :: TextLabel

	-- Mettre à jour le contenu
	local roleColor = getRoleColor(role)
	iconLbl.TextColor3 = roleColor
	roleLbl.Text = "VOUS ÊTES : " .. getRoleName(role)
	roleLbl.TextColor3 = roleColor
	objLbl.Text = objective

	-- Réinitialiser les transparences avant l'animation
	backdrop.BackgroundTransparency = 1
	iconLbl.TextTransparency = 1
	roleLbl.TextTransparency = 1
	objLbl.TextTransparency = 1

	g.Enabled = true

	-- Phase 1 : fondu vers le noir (0 → 0.28 s)
	TweenService:Create(
		backdrop,
		TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0 }
	):Play()

	-- Phase 2 : apparition du texte (0.20 s → 0.50 s)
	task.delay(0.20, function()
		if not g.Enabled then
			return
		end
		local ti = TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(iconLbl, ti, { TextTransparency = 0 }):Play()
		TweenService:Create(roleLbl, ti, { TextTransparency = 0 }):Play()
		TweenService:Create(objLbl, ti, { TextTransparency = 0 }):Play()
	end)

	-- Phase 3 : disparition de tout (0.80 s → 1.20 s)
	task.delay(0.80, function()
		if not g.Enabled then
			return
		end
		local ti = TweenInfo.new(0.40, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(backdrop, ti, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(iconLbl, ti, { TextTransparency = 1 }):Play()
		TweenService:Create(roleLbl, ti, { TextTransparency = 1 }):Play()
		TweenService:Create(objLbl, ti, { TextTransparency = 1 }):Play()
	end)

	-- Désactivation finale (1.30 s — 0.10 s de marge après la fin du tween)
	task.delay(1.30, function()
		g.Enabled = false
		_playing = false
	end)
end

return RoleTransitionScreen
