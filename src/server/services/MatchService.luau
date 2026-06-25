--!strict
-- Orchestre le cycle de vie d'une partie.
-- Valide toutes les actions client avant traitement.
-- Le client n'a aucun accès direct à l'état du match.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Types = require(Shared.Types)
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)

local Server = script.Parent.Parent
local MatchStateMachine = require(Server.MatchStateMachine)
local RoleService = require(Server.services.RoleService)

local MatchService = {}

local state: Types.MatchState = {
	MatchId = "",
	Phase = "Lobby",
	Format = "Duel",
	PlayerRoles = {},
	Votes = {},
	PhaseStartedAt = 0,
	PhaseTimer = nil,
}

local function newMatchId(): string
	return tostring(math.floor(tick())) .. "_" .. tostring(math.random(1000, 9999))
end

local function selectFormat(count: number): Types.GameFormat
	if count <= 1 then
		return "Solo"
	elseif count == 2 then
		return "Duel"
	elseif count <= 4 then
		return "Mini"
	else
		return "Full"
	end
end

-- Synchro du timer côté client toutes les N secondes pendant les phases actives
local function startTimerSync(capturedPhase: Types.MatchPhase, duration: number)
	task.spawn(function()
		local interval = Config.TimerSyncIntervalSeconds
		local elapsed = 0
		while elapsed < duration and state.Phase == capturedPhase do
			task.wait(interval)
			elapsed += interval
			if state.Phase == capturedPhase then
				Net.broadcast(RemoteNames.TimerSync, {
					TimeLeft = math.max(0, duration - elapsed),
				})
			end
		end
	end)
end

-- Calcule le verdict à partir des votes Juré et le diffuse à tous
local function computeAndBroadcastVerdict()
	local guiltyCount = 0
	local innocentCount = 0
	for userId, vote in pairs(state.Votes) do
		if state.PlayerRoles[userId] == "Juror" then
			if vote == "Guilty" then
				guiltyCount += 1
			else
				innocentCount += 1
			end
		end
	end
	-- Tie = Innocent (doute raisonnable, cf. GDD)
	local verdict: Types.VerdictValue = if guiltyCount > innocentCount then "Guilty" else "Innocent"
	Net.broadcast(RemoteNames.VerdictRevealed, {
		Verdict = verdict,
		GuiltyCount = guiltyCount,
	})
	print(
		string.format(
			"[MatchService] Verdict: %s (%d coupable / %d innocent)",
			verdict,
			guiltyCount,
			innocentCount
		)
	)
end

local function scheduleNextPhase(phase: Types.MatchPhase, duration: number)
	state.PhaseTimer = task.delay(duration, function()
		local next = MatchStateMachine.nextPhase(phase)
		if next then
			MatchService.transitionTo(next)
		end
	end)
end

function MatchService.transitionTo(newPhase: Types.MatchPhase)
	if not MatchStateMachine.canTransition(state.Phase, newPhase) then
		warn("[MatchService] Transition invalide:", state.Phase, "→", newPhase)
		return
	end

	local oldPhase = state.Phase

	if state.PhaseTimer then
		task.cancel(state.PhaseTimer)
		state.PhaseTimer = nil
	end

	-- Préparer le nouvel état avant le broadcast
	if newPhase == "Matchmaking" then
		state.MatchId = newMatchId()
		state.Format = selectFormat(#Players:GetPlayers())
		state.Votes = {}
	elseif newPhase == "Lobby" then
		state.PlayerRoles = {}
		state.Votes = {}
		state.MatchId = ""
	end

	state.Phase = newPhase
	state.PhaseStartedAt = tick()

	local duration = Config.PhaseDuration[newPhase] or 30
	local playerCount = #Players:GetPlayers()

	Net.broadcast(RemoteNames.GamePhaseChanged, {
		Phase = newPhase,
		Duration = duration,
		MatchId = state.MatchId,
		Format = state.Format,
		PlayerCount = playerCount,
	})

	print(
		string.format(
			"[MatchService] %s → %s (%ds | %s | %d joueur(s))",
			oldPhase,
			newPhase,
			duration,
			state.Format,
			playerCount
		)
	)

	-- Actions spécifiques post-broadcast
	if newPhase == "Matchmaking" then
		local players = Players:GetPlayers()
		state.PlayerRoles = RoleService.assignForMatch(players, state.Format)
		print(string.format("[MatchService] Match %s | %d joueur(s)", state.MatchId, #players))
		RoleService.broadcastRoles(players, state.PlayerRoles, state.MatchId)
	elseif newPhase == "Testimony" or newPhase == "Deliberation" or newPhase == "Verdict" then
		startTimerSync(newPhase, duration)
	elseif newPhase == "PostVerdict" then
		computeAndBroadcastVerdict()
	end

	-- Programmer la prochaine transition automatique
	if newPhase == "Cleanup" then
		state.PhaseTimer = task.delay(duration, function()
			MatchService.transitionTo("Lobby")
		end)
	elseif newPhase ~= "Lobby" then
		scheduleNextPhase(newPhase, duration)
	end
end

function MatchService.startMatch()
	if state.Phase ~= "Lobby" then
		warn("[MatchService] startMatch() ignoré — phase:", state.Phase)
		return
	end
	MatchService.transitionTo("Matchmaking")
end

function MatchService.getPublicState(): {
	Phase: Types.MatchPhase,
	Format: Types.GameFormat,
	MatchId: string,
}
	return { Phase = state.Phase, Format = state.Format, MatchId = state.MatchId }
end

-- Notifie le client qu'une action a été refusée et log le motif
local function rejectAction(player: Player, reason: string)
	Net.fire(player, RemoteNames.ActionRejected, { Message = reason })
	warn(string.format("[MatchService] Action refusée [%s] : %s", player.DisplayName, reason))
end

function MatchService.init()
	Net.getFunction(RemoteNames.GetCurrentMatchState).OnServerInvoke = function(_player: Player)
		return MatchService.getPublicState()
	end

	-- Déclaration : acceptée uniquement en Testimony pour les témoins
	Net.onServer(RemoteNames.DeclarationSubmitted, function(player, payload)
		if state.Phase ~= "Testimony" then
			rejectAction(player, "Déclaration hors phase de témoignage")
			return
		end
		local role = state.PlayerRoles[player.UserId]
		if role ~= "HonestWitness" and role ~= "Liar" then
			rejectAction(player, "Seuls les témoins soumettent des déclarations")
			return
		end
		print(
			string.format(
				"[MatchService] Déclaration reçue de %s (%s) — champs: %s",
				player.DisplayName,
				tostring(role),
				tostring(payload.Fields)
			)
		)
		-- Stockage et analyse des contradictions en Milestone 1.5
	end)

	-- Réaction : acceptée uniquement en Testimony pour les observateurs
	Net.onServer(RemoteNames.ReactionSent, function(player, payload)
		if state.Phase ~= "Testimony" then
			rejectAction(player, "Réaction hors phase de témoignage")
			return
		end
		local role = state.PlayerRoles[player.UserId]
		if role ~= "Juror" and role ~= "Prosecutor" and role ~= "Defense" then
			rejectAction(player, "Rôle non autorisé à réagir")
			return
		end
		local reactionType = tostring(payload.ReactionType or "")
		print(
			string.format(
				"[MatchService] Réaction de %s (%s) : %s",
				player.DisplayName,
				tostring(role),
				reactionType
			)
		)
		-- Broadcast à tous (affichage seulement — pas d'effet gameplay en 1.3)
		Net.broadcast(RemoteNames.ReactionBroadcast, {
			FromUserId = player.UserId,
			ReactionType = reactionType,
		})
	end)

	-- Vote : accepté uniquement en Verdict pour les Jurés
	Net.onServer(RemoteNames.VoteCast, function(player, payload)
		if state.Phase ~= "Verdict" then
			rejectAction(player, "Vote hors phase de verdict")
			return
		end
		local role = state.PlayerRoles[player.UserId]
		if role ~= "Juror" then
			rejectAction(player, "Seuls les jurés votent")
			return
		end
		if state.Votes[player.UserId] then
			rejectAction(player, "Vous avez déjà voté")
			return
		end
		local vote = payload.Vote
		if vote ~= "Guilty" and vote ~= "Innocent" then
			rejectAction(player, "Valeur de vote invalide")
			return
		end
		state.Votes[player.UserId] = vote :: Types.VerdictValue
		print(string.format("[MatchService] Vote de %s : %s", player.DisplayName, tostring(vote)))
	end)

	-- Objection : fonctionnalité Phase 2
	Net.onServer(RemoteNames.ObjectionRaised, function(player, _payload)
		rejectAction(player, "Les objections arrivent en Phase 2")
	end)

	-- Auto-démarrage quand le seuil Duel est atteint
	Players.PlayerAdded:Connect(function(_player)
		if state.Phase == "Lobby" and #Players:GetPlayers() >= Config.Format.Duel.Min then
			task.delay(Config.PhaseDuration.Lobby, function()
				if state.Phase == "Lobby" then
					MatchService.startMatch()
				end
			end)
		end
	end)

	-- Mode Studio : démarrage forcé pour tests rapides
	if RunService:IsStudio() then
		task.delay(5, function()
			if state.Phase == "Lobby" and #Players:GetPlayers() >= 1 then
				print("[MatchService] Studio : démarrage forcé")
				MatchService.startMatch()
			end
		end)
	end

	print("[MatchService] Initialisé")
end

return MatchService
