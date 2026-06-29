--!strict
-- M4.1 — Character Presence
-- Oriente le personnage local et incline la tête selon la phase et le rôle.
-- Cosmétique pur — aucun gameplay, aucun réseau, aucun changement serveur.
-- Chaque client gère uniquement son propre personnage.
-- Positions calibrées sur WorldBuilder 2.2+ (même référence que CameraController).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CharacterPresenceController = {}

-- ─── Positions de référence (WorldBuilder 2.2+) ───────────────────────────────

local POS_JUDGE = Vector3.new(0, 4, -28)
local POS_WITNESS = Vector3.new(-16, 2, -22)
local POS_JURY = Vector3.new(20, 3, -14)

-- ─── État interne ─────────────────────────────────────────────────────────────

local _role: string = ""
local _targetPos: Vector3? = nil
local _heartbeatConn: RBXScriptConnection? = nil

-- Cache du personnage — invalidé automatiquement à chaque respawn.
local _cachedChar: Model? = nil
local _cachedRoot: BasePart? = nil
local _cachedNeck: Motor6D? = nil
local _neckDefaultC0: CFrame = CFrame.identity

-- ─── Vitesses d'orientation par rôle ─────────────────────────────────────────
-- Facteur lerp/seconde. Plus élevé = corps se tourne plus vite.

local TURN_SPEED: { [string]: number } = {
	HonestWitness = 2.5, -- posture ouverte, naturelle
	Liar = 1.6, -- légèrement hésitant — regard moins direct
	Prosecutor = 3.5, -- alerte, décisif
	Defense = 2.8, -- posé, contrôlé
	Juror = 3.8, -- observateur actif
}

-- ─── Offset de pitch par rôle ─────────────────────────────────────────────────
-- En radians, additif à l'angle géométrique. Positif = regard vers le haut.

local PITCH_OFFSET: { [string]: number } = {
	HonestWitness = 0.03, -- regard franc, légèrement relevé
	Liar = -0.05, -- regard discret, légèrement baissé
	Prosecutor = 0.02,
	Defense = 0.02,
	Juror = 0.05, -- suit le podium surélevé du juge
}

-- ─── Résolution de la cible par phase et rôle ────────────────────────────────

local function resolveTarget(phase: string, role: string): Vector3?
	if phase == "Testimony" then
		-- Le témoin regarde le jury pendant sa déposition.
		-- Les observateurs (jurés, avocats) regardent le témoin.
		if role == "HonestWitness" or role == "Liar" then
			return POS_JURY
		else
			return POS_WITNESS
		end
	elseif
		phase == "Intro"
		or phase == "Verdict"
		or phase == "PostVerdict"
		or phase == "Matchmaking"
		or phase == "Deliberation"
	then
		return POS_JUDGE
	end
	-- Lobby, Cleanup → pas d'orientation forcée (caméra joueur libre).
	return nil
end

-- ─── Mise à jour du cache personnage ─────────────────────────────────────────
-- Appelé à chaque Heartbeat — n'alloue de mémoire qu'en cas de changement.

local function refreshCache()
	local char = Players.LocalPlayer.Character
	if char == _cachedChar then
		return
	end
	_cachedChar = char
	_cachedRoot = nil
	_cachedNeck = nil
	_neckDefaultC0 = CFrame.identity
	if not char then
		return
	end
	_cachedRoot = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	for _, v in ipairs(char:GetDescendants()) do
		if v.Name == "Neck" and v:IsA("Motor6D") then
			_cachedNeck = v :: Motor6D
			_neckDefaultC0 = (v :: Motor6D).C0
			break
		end
	end
end

-- ─── Logique Heartbeat ────────────────────────────────────────────────────────

local function tick_presence(dt: number)
	local target = _targetPos
	if not target then
		return
	end
	refreshCache()
	local root = _cachedRoot
	if not root then
		return
	end

	-- Rotation du corps vers la cible (axe Y uniquement — corps reste vertical).
	local pos = root.Position
	local dir = target - pos
	local flatDir = Vector3.new(dir.X, 0, dir.Z)
	if flatDir.Magnitude > 0.5 then
		local speed = TURN_SPEED[_role] or 2.5
		local targetCF = CFrame.new(pos, pos + flatDir.Unit)
		root.CFrame = root.CFrame:Lerp(targetCF, math.min(1, dt * speed))
	end

	-- Inclinaison subtile de la tête via le joint Neck (pitch seulement).
	-- Appliqué après le cycle animator (Heartbeat) — visible jusqu'au prochain frame.
	local neck = _cachedNeck
	if neck then
		local headPos = pos + Vector3.new(0, 1.4, 0)
		local toTarget = target - headPos
		local pitchGeom: number = 0
		if toTarget.Magnitude > 0.5 then
			pitchGeom = math.asin(math.clamp(toTarget.Unit.Y, -1, 1)) * 0.35
		end
		local pitchRole = PITCH_OFFSET[_role] or 0
		local pitch = math.clamp(pitchGeom + pitchRole, -0.20, 0.20)
		neck.C0 = _neckDefaultC0 * CFrame.Angles(pitch, 0, 0)
	end
end

-- ─── API publique ─────────────────────────────────────────────────────────────

-- Démarre la boucle d'orientation. Appelé une seule fois depuis init.client.
function CharacterPresenceController.setup()
	if _heartbeatConn then
		return
	end
	_heartbeatConn = RunService.Heartbeat:Connect(function(dt: number)
		tick_presence(dt)
	end)
end

-- Met à jour la cible de regard en fonction de la phase et du rôle courant.
function CharacterPresenceController.onPhaseChanged(phase: string)
	_targetPos = resolveTarget(phase, _role)
end

-- Enregistre le rôle local pour adapter la vitesse et le pitch.
function CharacterPresenceController.onRoleAssigned(role: string)
	_role = role
end

return CharacterPresenceController
