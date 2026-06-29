--!strict
-- M4.2 — Character Animation Layer
-- Couche de posture corporelle sur le personnage local : oscillation respiratoire,
-- lean par rôle, réaction one-shot au verdict.
-- Fonctionne en parallèle de CharacterPresenceController (joints distincts) :
--   M4.1 écrit sur HumanoidRootPart.CFrame et Neck.C0.
--   M4.2 écrit sur Waist.C0 (R15) ou RootJoint.C0 (R6) uniquement.
-- Client uniquement — aucun gameplay, aucun réseau.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CharacterAnimationLayer = {}

-- ─── Configuration de posture par rôle ───────────────────────────────────────
-- lean  : inclinaison avant/arrière (radians, + = avant)
-- sway  : amplitude de l'oscillation respiratoire (radians)
-- freq  : fréquence de respiration (Hz)
-- roll  : oscillation latérale additionnelle (radians, 0 = aucune)
-- Note : le signe réel de lean dépend de l'orientation du joint en Studio.
--        Ajuster lean/roll si la direction est inversée sur le rig.

type PostureCfg = { lean: number, sway: number, freq: number, roll: number }

local POSTURE: { [string]: PostureCfg } = {
	Juror = { lean = 0.03, sway = 0.009, freq = 0.22, roll = 0.000 }, -- légère attention, respiration calme
	Liar = { lean = 0.02, sway = 0.014, freq = 0.32, roll = 0.008 }, -- légèrement nerveux, oscillation plus marquée
	HonestWitness = { lean = 0.00, sway = 0.006, freq = 0.18, roll = 0.000 }, -- posture ouverte, respiration posée
	Prosecutor = { lean = -0.03, sway = 0.007, freq = 0.20, roll = 0.000 }, -- assuré, légèrement en retrait
	Defense = { lean = -0.025, sway = 0.007, freq = 0.21, roll = 0.000 }, -- posé, contrôlé
}

local DEFAULT_POSTURE: PostureCfg = { lean = 0.00, sway = 0.008, freq = 0.20, roll = 0.000 }

-- ─── État interne ─────────────────────────────────────────────────────────────

local _role: string = ""
local _time: number = 0 -- temps accumulé depuis le dernier onRoleAssigned (évite les sauts)
local _active: boolean = false -- désactivé en Lobby et Cleanup
local _heartbeatConn: RBXScriptConnection? = nil

-- Cache personnage — invalidé à chaque respawn
local _cachedChar: Model? = nil
local _torsoJoint: Motor6D? = nil -- Waist (R15) ou RootJoint (R6)
local _torsoDefaultC0: CFrame = CFrame.identity

-- Réaction one-shot au verdict
local _reactionKind: string = "neutral"
local _reactionElapsed: number = 0
local _reactionDuration: number = 0 -- 0 = aucune réaction en cours

-- ─── Cache du joint de torse ─────────────────────────────────────────────────

local function refreshCache()
	local char = Players.LocalPlayer.Character
	if char == _cachedChar then
		return
	end
	_cachedChar = char
	_torsoJoint = nil
	_torsoDefaultC0 = CFrame.identity
	if not char then
		return
	end
	-- R15 : Waist dans LowerTorso (Part0 = LowerTorso, Part1 = UpperTorso)
	local lowerTorso = char:FindFirstChild("LowerTorso") :: BasePart?
	if lowerTorso then
		local waist = lowerTorso:FindFirstChild("Waist") :: Motor6D?
		if waist then
			_torsoJoint = waist
			_torsoDefaultC0 = waist.C0
			return
		end
	end
	-- R6 fallback : RootJoint dans HumanoidRootPart (Part0 = HRP, Part1 = Torso)
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		local rootJoint = hrp:FindFirstChild("RootJoint") :: Motor6D?
		if rootJoint then
			_torsoJoint = rootJoint
			_torsoDefaultC0 = rootJoint.C0
		end
	end
end

-- ─── Calcul de la pose combinée ───────────────────────────────────────────────

local function computePose(dt: number): CFrame
	_time += dt
	local cfg = POSTURE[_role] or DEFAULT_POSTURE
	local tau = _time * cfg.freq * math.pi * 2

	-- Oscillation respiratoire (pitch avant/arrière)
	local breath = math.sin(tau) * cfg.sway

	-- Micro-oscillation latérale (roll, fréquence légèrement désynchronisée)
	local roll = math.sin(tau * 1.3 + 1.2) * cfg.roll

	local pitch = cfg.lean + breath

	-- Réaction one-shot au verdict (enveloppe sin — montée et retour doux)
	if _reactionDuration > 0 then
		_reactionElapsed += dt
		local progress = math.min(1, _reactionElapsed / _reactionDuration)
		local envelope = math.sin(progress * math.pi)

		if _reactionKind == "shame" then
			-- Liar démasqué : affaissement vers l'avant + légère torsion
			pitch += envelope * 0.12
			roll += envelope * 0.04
		elseif _reactionKind == "success" then
			-- Juré correct / Témoin cru : redressement positif
			pitch -= envelope * 0.06
		end
		-- "neutral" : aucun ajout — la posture de base s'applique normalement

		if _reactionElapsed >= _reactionDuration then
			_reactionDuration = 0
		end
	end

	pitch = math.clamp(pitch, -0.25, 0.25)
	roll = math.clamp(roll, -0.10, 0.10)

	return _torsoDefaultC0 * CFrame.Angles(pitch, 0, roll)
end

-- ─── Boucle Heartbeat ─────────────────────────────────────────────────────────

local function tick_animation(dt: number)
	if not _active then
		return
	end
	refreshCache()
	local joint = _torsoJoint
	if not joint then
		return
	end
	joint.C0 = computePose(dt)
end

-- ─── API publique ─────────────────────────────────────────────────────────────

-- Démarre la boucle. Appelé une seule fois depuis init.client.
function CharacterAnimationLayer.setup()
	if _heartbeatConn then
		return
	end
	_heartbeatConn = RunService.Heartbeat:Connect(function(dt: number)
		tick_animation(dt)
	end)
end

-- Enregistre le rôle et repart à t=0 pour éviter un saut d'oscillation.
function CharacterAnimationLayer.onRoleAssigned(role: string)
	_role = role
	_time = 0
end

-- Active ou suspend l'animation selon la phase.
function CharacterAnimationLayer.onPhaseChanged(phase: string)
	_active = phase ~= "Lobby" and phase ~= "Cleanup"
end

-- Déclenche une réaction physique one-shot.
-- kind : "shame" (Menteur démasqué), "success" (Juré correct / Témoin cru), "neutral"
-- duration : durée en secondes (recommandé : 1.8–2.5)
function CharacterAnimationLayer.triggerReaction(kind: string, duration: number)
	_reactionKind = kind
	_reactionElapsed = 0
	_reactionDuration = duration
end

return CharacterAnimationLayer
