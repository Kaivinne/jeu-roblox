--!strict
-- Contrôle la caméra côté client selon la phase de jeu.
-- Milestone 2.4 : caméra fixe par phase + fade noir entre transitions.
-- Fallback automatique vers la caméra joueur en cas d'erreur.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local CameraController = {}

-- Caméra active (capturée une fois, toujours la même en cours de session).
local camera = workspace.CurrentCamera

-- Overlay de fondu (Frame noire plein-écran).
local fadeOverlay: Frame? = nil

-- ─── Constantes ───────────────────────────────────────────────────────────────

local MOVE_TWEEN = TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local FADE_TO_BLACK = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FADE_TO_CLEAR = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

-- ─── Setup ────────────────────────────────────────────────────────────────────

function CameraController.setup()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local screen = Instance.new("ScreenGui")
	screen.Name = "CameraFadeGui"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 100 -- au-dessus de tous les autres panneaux
	screen.Parent = playerGui

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 1 -- transparent au départ
	overlay.BorderSizePixel = 0
	overlay.Parent = screen
	fadeOverlay = overlay
end

-- ─── Helpers internes ─────────────────────────────────────────────────────────

-- Restaure la caméra joueur par défaut.
local function restorePlayerCamera()
	pcall(function()
		camera.CameraType = Enum.CameraType.Custom
	end)
end

-- Passe en mode scriptable et tween vers la CFrame cible.
-- Restaure la caméra joueur si la manipulation échoue.
local function setFixed(eye: Vector3, target: Vector3)
	local ok = pcall(function()
		camera.CameraType = Enum.CameraType.Scriptable
		local cf = CFrame.lookAt(eye, target)
		TweenService:Create(camera, MOVE_TWEEN, { CFrame = cf }):Play()
	end)
	if not ok then
		restorePlayerCamera()
	end
end

-- Fade vers noir → callback → fade retour au transparent.
local function withFade(callback: () -> ())
	local overlay = fadeOverlay
	if not overlay then
		callback()
		return
	end
	TweenService:Create(overlay, FADE_TO_BLACK, { BackgroundTransparency = 0 }):Play()
	task.delay(0.22, function()
		callback()
		TweenService:Create(overlay, FADE_TO_CLEAR, { BackgroundTransparency = 1 }):Play()
	end)
end

-- ─── Positions de caméra par phase ───────────────────────────────────────────
-- Coordonnées calées sur le WorldBuilder 2.2+ (Y=0 = sol de la salle).

local PHASE_CAMERAS: { [string]: (() -> ())? } = {
	-- Vue large depuis la galerie — montre toute la salle
	Intro = function()
		setFixed(Vector3.new(0, 12, 22), Vector3.new(0, 3, -28))
	end,
	-- Focalisée sur le box du témoin (côté gauche)
	Testimony = function()
		setFixed(Vector3.new(-4, 7, -6), Vector3.new(-16, 2, -22))
	end,
	-- Face au box des jurés (côté droit)
	Deliberation = function()
		setFixed(Vector3.new(4, 8, 0), Vector3.new(20, 3, -14))
	end,
	-- Estrade du juge en plan moyen
	Verdict = function()
		setFixed(Vector3.new(0, 7, -12), Vector3.new(0, 4, -28))
	end,
	-- Même position qu'en Verdict
	PostVerdict = function()
		setFixed(Vector3.new(0, 7, -12), Vector3.new(0, 4, -28))
	end,
}

-- ─── API publique ─────────────────────────────────────────────────────────────

-- Appelé depuis init.client.luau à chaque GamePhaseChanged.
function CameraController.onPhaseChanged(phase: string)
	local phaseFn = PHASE_CAMERAS[phase]
	if phaseFn ~= nil then
		withFade(phaseFn)
	else
		-- Lobby, Matchmaking, Cleanup → caméra joueur normale (Follow)
		withFade(restorePlayerCamera)
	end
end

return CameraController
