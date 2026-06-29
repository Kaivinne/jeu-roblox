--!strict
-- HUD persistant : phase courante, timer, rôle, format de partie.
-- Visible en permanence pendant la partie.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local UIUtils = require(script.Parent.UIUtils)
local AudioController = require(script.Parent.Parent.AudioController)

local HUD = {}

-- Références aux labels (créées une seule fois dans setup)
local phaseLabel: TextLabel? = nil
local timerLabel: TextLabel? = nil
local roleLabel: TextLabel? = nil
local infoLabel: TextLabel? = nil
local roleBadge: Frame? = nil

-- Phases où le countdown audio est actif
local COUNTDOWN_PHASES: { [string]: boolean } = {
	Testimony = true,
	Deliberation = true,
	Verdict = true,
}

local timeLeft: number = 0
local _heartbeatConn: RBXScriptConnection? = nil
-- Dernière seconde entière sur laquelle un son a été joué (-1 = aucune)
-- Réinitialisé à chaque changement de phase pour éviter les doublons après resync
local _lastCountdownBeat: number = -1
local _currentPhaseAudio: string = ""

local PHASE_FR: { [string]: string } = {
	Lobby = "SALLE D'ATTENTE",
	Matchmaking = "PRÉPARATION",
	Intro = "INTRODUCTION",
	Testimony = "TÉMOIGNAGE",
	Deliberation = "DÉLIBÉRATION",
	Verdict = "VERDICT",
	PostVerdict = "RÉSULTATS",
	Cleanup = "PAUSE",
}

local ROLE_FR: { [string]: string } = {
	HonestWitness = "TÉMOIN",
	Liar = "MENTEUR",
	Prosecutor = "AVOCAT",
	Defense = "DÉFENSE",
	Juror = "JURÉ",
}

local ROLE_COLOR: { [string]: Color3 } = {
	HonestWitness = Color3.fromRGB(34, 139, 34),
	Liar = UIUtils.Color.Crimson,
	Prosecutor = UIUtils.Color.Navy,
	Defense = Color3.fromRGB(120, 80, 160),
	Juror = Color3.fromRGB(100, 100, 160),
}

function HUD.setup()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local gui = Instance.new("ScreenGui")
	gui.Name = "HUDGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 10
	gui.Parent = playerGui

	-- Barre supérieure
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 54)
	bar.Position = UDim2.new(0, 0, 0, 0)
	bar.BackgroundColor3 = UIUtils.Color.Navy
	bar.BackgroundTransparency = 0.12
	bar.BorderSizePixel = 0
	bar.Parent = gui

	-- Séparateur doré en bas de la barre
	local separator = Instance.new("Frame")
	separator.Size = UDim2.new(1, 0, 0, 2)
	separator.Position = UDim2.new(0, 0, 1, -2)
	separator.BackgroundColor3 = UIUtils.Color.Gold
	separator.BorderSizePixel = 0
	separator.Parent = bar

	-- Phase (gauche)
	local pLabel = Instance.new("TextLabel")
	pLabel.Size = UDim2.new(0.38, -8, 1, 0)
	pLabel.Position = UDim2.new(0, 14, 0, 0)
	pLabel.BackgroundTransparency = 1
	pLabel.Text = "SALLE D'ATTENTE"
	pLabel.TextColor3 = UIUtils.Color.Gold
	pLabel.Font = UIUtils.Font.Title
	pLabel.TextSize = 15
	pLabel.TextXAlignment = Enum.TextXAlignment.Left
	pLabel.TextTruncate = Enum.TextTruncate.AtEnd
	pLabel.Parent = bar
	phaseLabel = pLabel

	-- Timer (centre)
	local tLabel = Instance.new("TextLabel")
	tLabel.Size = UDim2.new(0.24, 0, 1, 0)
	tLabel.Position = UDim2.new(0.38, 0, 0, 0)
	tLabel.BackgroundTransparency = 1
	tLabel.Text = "--:--"
	tLabel.TextColor3 = UIUtils.Color.White
	tLabel.Font = UIUtils.Font.Title
	tLabel.TextSize = 22
	tLabel.TextXAlignment = Enum.TextXAlignment.Center
	tLabel.Parent = bar
	timerLabel = tLabel

	-- Badge de rôle (droite, haut)
	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(0.34, -14, 0, 28)
	badge.Position = UDim2.new(0.66, 0, 0, 6)
	badge.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	badge.BorderSizePixel = 0
	badge.Parent = bar
	UIUtils.round(badge, 6)
	roleBadge = badge

	local rLabel = Instance.new("TextLabel")
	rLabel.Size = UDim2.new(1, 0, 1, 0)
	rLabel.BackgroundTransparency = 1
	rLabel.Text = "RÔLE NON ASSIGNÉ"
	rLabel.TextColor3 = UIUtils.Color.Ivory
	rLabel.Font = UIUtils.Font.Title
	rLabel.TextSize = 13
	rLabel.TextXAlignment = Enum.TextXAlignment.Center
	rLabel.Parent = badge
	roleLabel = rLabel

	-- Info format/joueurs (droite, bas)
	local iLabel = Instance.new("TextLabel")
	iLabel.Size = UDim2.new(0.34, -14, 0, 16)
	iLabel.Position = UDim2.new(0.66, 0, 0, 36)
	iLabel.BackgroundTransparency = 1
	iLabel.Text = ""
	iLabel.TextColor3 = UIUtils.Color.Muted
	iLabel.Font = UIUtils.Font.Body
	iLabel.TextSize = 11
	iLabel.TextXAlignment = Enum.TextXAlignment.Right
	iLabel.Parent = bar
	infoLabel = iLabel

	-- Décompte local (corrigé périodiquement par le serveur via TimerSync)
	_heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		if timeLeft > 0 then
			timeLeft = math.max(0, timeLeft - dt)
			if timerLabel then
				timerLabel.Text = UIUtils.formatTime(timeLeft)
			end
		end
		-- Countdown audio : uniquement sur Testimony / Deliberation / Verdict
		if COUNTDOWN_PHASES[_currentPhaseAudio] then
			local beat = math.floor(timeLeft)
			if beat >= 1 and beat <= 5 and beat ~= _lastCountdownBeat then
				_lastCountdownBeat = beat
				AudioController.play("countdown")
			elseif beat == 0 and _lastCountdownBeat ~= 0 then
				_lastCountdownBeat = 0
				AudioController.play("timer_end")
			end
		end
	end)
end

function HUD.setPhase(phase: string, duration: number)
	timeLeft = duration
	-- Réinitialiser le tracking countdown pour la nouvelle phase
	_currentPhaseAudio = phase
	_lastCountdownBeat = -1
	if phaseLabel then
		phaseLabel.Text = PHASE_FR[phase] or phase
	end
	if timerLabel then
		timerLabel.Text = UIUtils.formatTime(duration)
	end
end

-- Correction serveur du timer (appelée sur TimerSync)
function HUD.syncTimer(remaining: number)
	timeLeft = remaining
end

function HUD.setRole(role: string)
	if roleLabel then
		roleLabel.Text = ROLE_FR[role] or role
	end
	if roleBadge then
		roleBadge.BackgroundColor3 = ROLE_COLOR[role] or Color3.fromRGB(60, 60, 80)
	end
end

function HUD.setInfo(format: string, playerCount: number)
	if infoLabel then
		infoLabel.Text = format:upper() .. " · " .. tostring(playerCount) .. " joueurs"
	end
end

return HUD
