--!strict
-- Gestion audio et feedbacks visuels légers côté client.
-- M3.5 : ambiances différentes par phase avec transitions douces.
-- Les SoundId sont des placeholders — remplacer uniquement les IDs dans SFX
-- et PHASE_AMBIENT sans toucher au code de déclenchement.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local AudioController = {}

-- ─── Configuration SFX ───────────────────────────────────────────────────────
-- id    : rbxassetid placeholder.
-- vol   : volume (0–1).
-- pitch : PlaybackSpeed — > 1 aigu, < 1 grave.

type SoundCfg = { id: string, vol: number, pitch: number }

local SFX: { [string]: SoundCfg } = {
	PhaseChange = { id = "rbxassetid://4612379735", vol = 0.40, pitch = 1.00 },
	Declaration = { id = "rbxassetid://4612379717", vol = 0.25, pitch = 1.35 },
	Contradiction = { id = "rbxassetid://4612356684", vol = 0.55, pitch = 0.70 },
	Vote = { id = "rbxassetid://4612379735", vol = 0.30, pitch = 0.85 },
	VerdictReveal = { id = "rbxassetid://4612356684", vol = 0.65, pitch = 0.50 },
	Reward = { id = "rbxassetid://4612379717", vol = 0.45, pitch = 1.65 },
}

-- ─── Ambiances par phase ──────────────────────────────────────────────────────
-- id  : rbxassetid placeholder — remplacer par l'asset final de chaque phase.
-- vol : volume cible, volontairement bas pour ne pas fatiguer le joueur.
--
-- Intention sonore par phase (à conserver lors du remplacement des assets) :
--   Lobby / Matchmaking  → calme, neutre, attente
--   Intro                → tension douce, présentation du scénario
--   Testimony            → tension plus présente, attention accrue
--   Deliberation         → tension basse et rythmée, réflexion
--   Verdict              → dramatique, court pic d'intensité
--   PostVerdict          → retour au calme, résolution
--   Cleanup              → très léger, transition invisible

type AmbientCfg = { id: string, vol: number }

local PHASE_AMBIENT: { [string]: AmbientCfg } = {
	Lobby = { id = "rbxassetid://1847354696", vol = 0.05 },
	Matchmaking = { id = "rbxassetid://1847354696", vol = 0.05 },
	Intro = { id = "rbxassetid://4612379735", vol = 0.07 },
	Testimony = { id = "rbxassetid://4612356684", vol = 0.08 },
	Deliberation = { id = "rbxassetid://4612356684", vol = 0.06 },
	Verdict = { id = "rbxassetid://4612379717", vol = 0.09 },
	PostVerdict = { id = "rbxassetid://1847354696", vol = 0.05 },
	Cleanup = { id = "rbxassetid://1847354696", vol = 0.04 },
}

-- ─── Paramètres de fondu ─────────────────────────────────────────────────────

local FADE_OUT = 0.80 -- secondes pour descendre à 0
local FADE_IN = 0.80 -- secondes pour monter au volume cible

-- ─── État interne ─────────────────────────────────────────────────────────────

local sounds: { [string]: Sound } = {}
local activeAmbient: Sound? = nil
local flashFrame: Frame? = nil
local _ambientTask: thread? = nil
local _currentTween: Tween? = nil
local _currentPhase: string = ""

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function makeSound(cfg: SoundCfg): Sound
	local s = Instance.new("Sound")
	s.SoundId = cfg.id
	s.Volume = cfg.vol
	s.PlaybackSpeed = cfg.pitch
	s.Parent = SoundService
	return s
end

-- Interrompt toute transition d'ambiance en cours.
local function cancelAmbientTransition()
	if _ambientTask then
		task.cancel(_ambientTask)
		_ambientTask = nil
	end
	if _currentTween then
		_currentTween:Cancel()
		_currentTween = nil
	end
end

-- Fondu croisé : descente → échange d'asset → montée.
-- Silencieux si l'asset cible échoue (pcall sur Play).
local function crossfadeTo(cfg: AmbientCfg)
	local s = activeAmbient
	if not s then
		return
	end
	cancelAmbientTransition()

	_ambientTask = task.spawn(function()
		-- Fade-out de l'ambiance courante
		local twOut = TweenService:Create(
			s,
			TweenInfo.new(FADE_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Volume = 0,
			}
		)
		_currentTween = twOut
		twOut:Play()
		task.wait(FADE_OUT)

		-- Échange de l'asset — silencieux si l'ID est invalide
		pcall(function()
			s.SoundId = cfg.id
			s.Volume = 0
			s:Play()
		end)

		-- Fade-in vers le volume cible
		local twIn =
			TweenService:Create(s, TweenInfo.new(FADE_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Volume = cfg.vol,
			})
		_currentTween = twIn
		twIn:Play()
		task.wait(FADE_IN)

		_currentTween = nil
		_ambientTask = nil
	end)
end

-- ─── API publique ─────────────────────────────────────────────────────────────

-- Crée toutes les instances Sound et l'overlay de flash.
-- Doit être appelé une seule fois depuis init.client après PlayerGui disponible.
function AudioController.setup()
	for name, cfg in pairs(SFX) do
		sounds[name] = makeSound(cfg)
	end

	-- Ambiance initiale : Lobby
	local initCfg = PHASE_AMBIENT.Lobby
	local amb = Instance.new("Sound")
	amb.SoundId = initCfg.id
	amb.Volume = initCfg.vol
	amb.Looped = true
	amb.Parent = SoundService
	activeAmbient = amb
	pcall(function()
		amb:Play()
	end)
	_currentPhase = "Lobby"

	-- Overlay de flash rouge (transparent au repos)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
	local screen = Instance.new("ScreenGui")
	screen.Name = "AudioFlashGui"
	screen.DisplayOrder = 98
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.Parent = playerGui

	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.Parent = screen
	flashFrame = flash
end

-- Joue un son SFX par nom. Silencieux si l'asset échoue ou est absent.
function AudioController.play(name: string)
	pcall(function()
		local s = sounds[name]
		if s then
			s:Play()
		end
	end)
end

-- Adapte l'ambiance à la phase de jeu et joue un SFX ponctuel si pertinent.
-- Ignoré si la phase est identique à la courante (évite les transitions inutiles).
function AudioController.onPhaseChanged(phase: string)
	if phase == _currentPhase then
		return
	end
	_currentPhase = phase

	-- SFX ponctuel pour les phases marquantes
	if phase == "Intro" or phase == "Testimony" or phase == "Verdict" then
		AudioController.play("PhaseChange")
	end

	-- Transition d'ambiance vers la phase
	local cfg = PHASE_AMBIENT[phase]
	if cfg then
		crossfadeTo(cfg)
	end
end

-- Flash rouge bref (contradiction visuelle).
function AudioController.flashContradiction()
	local flash = flashFrame
	if not flash then
		return
	end
	TweenService:Create(flash, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
		BackgroundTransparency = 0.50,
	}):Play()
	task.delay(0.08, function()
		TweenService:Create(flash, TweenInfo.new(0.50, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 1,
		}):Play()
	end)
end

-- Active ou suspend l'ambiance sonore avec fondu.
function AudioController.setAmbientEnabled(enabled: boolean)
	local s = activeAmbient
	if not s then
		return
	end
	cancelAmbientTransition()
	if enabled then
		local cfg = PHASE_AMBIENT[_currentPhase]
		local targetVol: number = if cfg then cfg.vol else 0.05
		pcall(function()
			s:Play()
		end)
		local tw =
			TweenService:Create(s, TweenInfo.new(FADE_IN, Enum.EasingStyle.Quad), { Volume = targetVol })
		_currentTween = tw
		tw:Play()
	else
		local tw = TweenService:Create(s, TweenInfo.new(FADE_OUT, Enum.EasingStyle.Quad), { Volume = 0 })
		_currentTween = tw
		tw:Play()
		task.delay(FADE_OUT, function()
			pcall(function()
				s:Pause()
			end)
		end)
	end
end

return AudioController
