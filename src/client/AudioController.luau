--!strict
-- Gestion audio et feedbacks visuels légers côté client.
-- Milestone 2.5 : sons placeholder + flash contradiction + ambiance salle.
-- Les SoundId sont des placeholders : remplacer les valeurs dans SFX
-- sans modifier le code de déclenchement.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local AudioController = {}

-- ─── Configuration des sons ───────────────────────────────────────────────────
-- id    : rbxassetid à remplacer par l'asset final.
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

local AMBIENT_ID = "rbxassetid://1847354696"
local AMBIENT_VOL = 0.06

-- ─── État interne ─────────────────────────────────────────────────────────────

local sounds: { [string]: Sound } = {}
local ambience: Sound? = nil
local flashFrame: Frame? = nil

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function makeSound(cfg: SoundCfg): Sound
	local s = Instance.new("Sound")
	s.SoundId = cfg.id
	s.Volume = cfg.vol
	s.PlaybackSpeed = cfg.pitch
	s.Parent = SoundService
	return s
end

-- ─── API publique ─────────────────────────────────────────────────────────────

-- Crée toutes les instances Sound et l'overlay de flash.
-- Doit être appelé une seule fois depuis init.client après PlayerGui disponible.
function AudioController.setup()
	for name, cfg in pairs(SFX) do
		sounds[name] = makeSound(cfg)
	end

	-- Ambiance salle d'audience (boucle silencieuse, volume très faible)
	local amb = Instance.new("Sound")
	amb.SoundId = AMBIENT_ID
	amb.Volume = AMBIENT_VOL
	amb.Looped = true
	amb.Parent = SoundService
	ambience = amb
	pcall(function()
		amb:Play()
	end)

	-- Overlay de flash rouge (transparent au repos, DisplayOrder sous le fondu caméra)
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

-- Joue le son de changement de phase seulement pour les phases marquantes.
function AudioController.onPhaseChanged(phase: string)
	if phase == "Intro" or phase == "Testimony" or phase == "Verdict" then
		AudioController.play("PhaseChange")
	end
end

-- Flash rouge bref (58 % opacité → transparent en 500 ms).
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

-- Active ou suspend l'ambiance sonore (activée par défaut dans setup).
function AudioController.setAmbientEnabled(enabled: boolean)
	local amb = ambience
	if not amb then
		return
	end
	pcall(function()
		if enabled then
			amb:Play()
		else
			amb:Pause()
		end
	end)
end

return AudioController
