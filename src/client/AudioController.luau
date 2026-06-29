--!strict
-- Gestion audio et feedbacks visuels légers côté client.
-- M3.5 : ambiances différentes par phase avec transitions douces.
-- M4.3 : direction sonore cohérente — table TODO_REPLACE_SOUND_IDS centralisée.
--
-- Pour remplacer un son :
--   1. Uploader l'asset sur Roblox Studio (son libre de droits uniquement).
--   2. Copier le rbxassetid dans TODO_REPLACE_SOUND_IDS à la clé correspondante.
--   3. Relancer le jeu — aucune autre modification nécessaire.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local AudioController = {}

-- ─── Table des sons à remplacer ───────────────────────────────────────────────
-- Toutes les clés "rbxassetid://REPLACE_*" sont des marqueurs intentionnels.
-- Le fallback silencieux (pcall sur Play) garantit qu'un ID invalide ne fait pas crasher.
-- Remplacer chaque entrée par un rbxassetid valide et libre de droits.
--
-- ┌────────────────────────┬──────────────────────────────────────────────────────┐
-- │ Clé                    │ Description du son attendu                           │
-- ├────────────────────────┼──────────────────────────────────────────────────────┤
-- │ gavel_hit              │ Coup de marteau solennel. Court (0.5–1 s), grave.    │
-- │                        │ Vol cible : 0.65 · Pitch : 0.85.                     │
-- │                        │ Usage : VerdictReveal.                                │
-- ├────────────────────────┼──────────────────────────────────────────────────────┤
-- │ paper_slide            │ Glissement de papier ou tampon de dossier.           │
-- │                        │ Court (0.4–0.7 s), discret.                          │
-- │                        │ Vol cible : 0.28 · Pitch : 1.10.                     │
-- │                        │ Usage : Declaration (dépôt de formulaire).           │
-- ├────────────────────────┼──────────────────────────────────────────────────────┤
-- │ low_ding               │ Tintement doux, confirmation neutre.                 │
-- │                        │ Court (0.3–0.6 s), ni agressif ni festif.            │
-- │                        │ Vol cible : 0.22 · Pitch : 1.00.                     │
-- │                        │ Usage : Vote (confirmation de vote).                 │
-- ├────────────────────────┼──────────────────────────────────────────────────────┤
-- │ tension_sting          │ Accent musical bref, tension croissante.             │
-- │                        │ Court (0.6–1.2 s), grave, non-mélodique.             │
-- │                        │ Vol cible : 0.36 · Pitch : 0.90.                     │
-- │                        │ Usage : PhaseChange (Testimony, Verdict).            │
-- ├────────────────────────┼──────────────────────────────────────────────────────┤
-- │ alarm_short            │ Alerte brève, désagréable sans être agressive.       │
-- │                        │ Très court (0.3–0.5 s), pitch bas.                   │
-- │                        │ Vol cible : 0.48 · Pitch : 0.72.                     │
-- │                        │ Usage : Contradiction.                                │
-- ├────────────────────────┼──────────────────────────────────────────────────────┤
-- │ reward_chime           │ Tintement positif, récompense légère.               │
-- │                        │ Court (0.5–1 s), aigu et clair.                      │
-- │                        │ Vol cible : 0.42 · Pitch : 1.45.                     │
-- │                        │ Usage : Reward (jetons accordés).                    │
-- ├────────────────────────┼──────────────────────────────────────────────────────┤
-- │ ambience_courtroom     │ Ambiance salle de tribunal : silence pesant,         │
-- │                        │ légers bruits de foule distants, ventilation douce.  │
-- │                        │ Loop 15–30 s · Vol cible : 0.04–0.05.               │
-- │                        │ Usage : Lobby, Matchmaking, PostVerdict, Cleanup.    │
-- ├────────────────────────┼──────────────────────────────────────────────────────┤
-- │ ambience_tension       │ Drone bas et rythmé, pression psychologique douce.  │
-- │                        │ Loop 15–30 s · Vol cible : 0.06–0.08.               │
-- │                        │ Usage : Intro, Testimony, Deliberation.              │
-- ├────────────────────────┼──────────────────────────────────────────────────────┤
-- │ ambience_dramatic      │ Drone dramatique, pic d'intensité bref et sombre.   │
-- │                        │ Loop 10–20 s · Vol cible : 0.07–0.09.               │
-- │                        │ Usage : Verdict.                                      │
-- └────────────────────────┴──────────────────────────────────────────────────────┘

local TODO_REPLACE_SOUND_IDS: { [string]: string } = {
	gavel_hit = "rbxassetid://REPLACE_GAVEL_HIT",
	paper_slide = "rbxassetid://REPLACE_PAPER_SLIDE",
	low_ding = "rbxassetid://REPLACE_LOW_DING",
	tension_sting = "rbxassetid://REPLACE_TENSION_STING",
	alarm_short = "rbxassetid://REPLACE_ALARM_SHORT",
	reward_chime = "rbxassetid://REPLACE_REWARD_CHIME",
	ambience_courtroom = "rbxassetid://REPLACE_AMBIENCE_COURTROOM",
	ambience_tension = "rbxassetid://REPLACE_AMBIENCE_TENSION",
	ambience_dramatic = "rbxassetid://REPLACE_AMBIENCE_DRAMATIC",
}

-- ─── Configuration SFX ───────────────────────────────────────────────────────
-- id    : clé vers TODO_REPLACE_SOUND_IDS.
-- vol   : volume cible (0–1). Calibré pour une écoute au casque sans pic agressif.
-- pitch : PlaybackSpeed. > 1 = aigu, < 1 = grave.

type SoundCfg = { id: string, vol: number, pitch: number }

local SFX: { [string]: SoundCfg } = {
	-- Transition de phase marquante (Testimony, Verdict) — accent sobre et grave
	PhaseChange = { id = TODO_REPLACE_SOUND_IDS.tension_sting, vol = 0.36, pitch = 0.90 },
	-- Dépôt d'une déclaration — bruit de manipulation de document
	Declaration = { id = TODO_REPLACE_SOUND_IDS.paper_slide, vol = 0.28, pitch = 1.10 },
	-- Incohérence détectée — alerte brève, différenciée du verdict
	Contradiction = { id = TODO_REPLACE_SOUND_IDS.alarm_short, vol = 0.48, pitch = 0.72 },
	-- Confirmation de vote — discret, neutre
	Vote = { id = TODO_REPLACE_SOUND_IDS.low_ding, vol = 0.22, pitch = 1.00 },
	-- Révélation du verdict — le son le plus impactant du jeu
	VerdictReveal = { id = TODO_REPLACE_SOUND_IDS.gavel_hit, vol = 0.65, pitch = 0.85 },
	-- Récompense accordée — positif sans être festif
	Reward = { id = TODO_REPLACE_SOUND_IDS.reward_chime, vol = 0.42, pitch = 1.45 },
}

-- ─── Ambiances par phase ──────────────────────────────────────────────────────
-- Trois niveaux d'intensité : neutre (courtroom) → tension → dramatique.
-- vol : volontairement bas — l'ambiance ne doit jamais couvrir les sons SFX.

type AmbientCfg = { id: string, vol: number }

local PHASE_AMBIENT: { [string]: AmbientCfg } = {
	Lobby = { id = TODO_REPLACE_SOUND_IDS.ambience_courtroom, vol = 0.05 },
	Matchmaking = { id = TODO_REPLACE_SOUND_IDS.ambience_courtroom, vol = 0.04 },
	Intro = { id = TODO_REPLACE_SOUND_IDS.ambience_tension, vol = 0.06 },
	Testimony = { id = TODO_REPLACE_SOUND_IDS.ambience_tension, vol = 0.07 },
	Deliberation = { id = TODO_REPLACE_SOUND_IDS.ambience_tension, vol = 0.05 },
	Verdict = { id = TODO_REPLACE_SOUND_IDS.ambience_dramatic, vol = 0.08 },
	PostVerdict = { id = TODO_REPLACE_SOUND_IDS.ambience_courtroom, vol = 0.04 },
	Cleanup = { id = TODO_REPLACE_SOUND_IDS.ambience_courtroom, vol = 0.03 },
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
