--!strict
-- Orchestre le cycle de vie d'une partie.
-- Utilise MatchStateMachine pour valider les transitions,
-- Net pour broadcaster les changements de phase,
-- Config pour les durées.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Types = require(Shared.Types)
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)

local Server = script.Parent.Parent
local MatchStateMachine = require(Server.MatchStateMachine)

local MatchService = {}

-- État courant de la partie (une seule partie par serveur au MVP)
local state: Types.MatchState = {
	MatchId = "",
	Phase = "Lobby",
	Format = "Duel",
	PlayerRoles = {},
	Votes = {},
	PhaseStartedAt = 0,
	PhaseTimer = nil,
}

-- Génère un ID unique de partie
local function newMatchId(): string
	return tostring(math.floor(tick())) .. "_" .. tostring(math.random(1000, 9999))
end

-- Sélectionne le format selon le nombre de joueurs
local function selectFormat(playerCount: number): Types.GameFormat
	if playerCount <= 1 then
		return "Solo"
	elseif playerCount == 2 then
		return "Duel"
	elseif playerCount <= 4 then
		return "Mini"
	else
		return "Full"
	end
end

-- Passe à la phase suivante après `duration` secondes (annulable)
local function scheduleNextPhase(currentPhase: Types.MatchPhase, duration: number)
	if state.PhaseTimer then
		task.cancel(state.PhaseTimer)
		state.PhaseTimer = nil
	end

	state.PhaseTimer = task.delay(duration, function()
		local next = MatchStateMachine.nextPhase(currentPhase)
		if next then
			MatchService.transitionTo(next)
		end
	end)
end

-- Transition vers une nouvelle phase
function MatchService.transitionTo(newPhase: Types.MatchPhase)
	if not MatchStateMachine.canTransition(state.Phase, newPhase) then
		warn("[MatchService] Transition invalide:", state.Phase, "→", newPhase)
		return
	end

	-- Annuler le timer en cours
	if state.PhaseTimer then
		task.cancel(state.PhaseTimer)
		state.PhaseTimer = nil
	end

	state.Phase = newPhase
	state.PhaseStartedAt = tick()

	local duration = Config.PhaseDuration[newPhase] or 30

	-- Broadcaster le changement à tous les clients
	Net.broadcast(RemoteNames.GamePhaseChanged, {
		Phase = newPhase,
		Duration = duration,
		MatchId = state.MatchId,
	})

	print(string.format("[MatchService] %s → %s (durée: %ds)", state.Phase, newPhase, duration))

	-- Actions spécifiques à certaines phases
	if newPhase == "Matchmaking" then
		state.MatchId = newMatchId()
		state.Format = selectFormat(#Players:GetPlayers())
		state.PlayerRoles = {}
		state.Votes = {}
		print("[MatchService] Nouvelle partie:", state.MatchId, "| Format:", state.Format)
	elseif newPhase == "Cleanup" then
		-- Après Cleanup, reboucler en Lobby automatiquement
		task.delay(duration, function()
			MatchService.transitionTo("Lobby")
		end)
		return -- pas de scheduleNextPhase (on gère manuellement)
	end

	-- Programmer la transition automatique vers la phase suivante
	if newPhase ~= "Lobby" then
		scheduleNextPhase(newPhase, duration)
	end
end

-- Démarre une partie (Lobby → Matchmaking)
function MatchService.startMatch()
	if state.Phase ~= "Lobby" then
		warn("[MatchService] startMatch() ignoré — phase courante:", state.Phase)
		return
	end
	MatchService.transitionTo("Matchmaking")
end

-- Retourne un snapshot de l'état sans les rôles des autres joueurs
function MatchService.getPublicState(): {
	Phase: Types.MatchPhase,
	Format: Types.GameFormat,
	MatchId: string,
}
	return {
		Phase = state.Phase,
		Format = state.Format,
		MatchId = state.MatchId,
	}
end

function MatchService.init()
	-- RemoteFunction : le client peut demander l'état public de la partie
	local fn = Net.getFunction(RemoteNames.GetCurrentMatchState)
	fn.OnServerInvoke = function(_player: Player)
		return MatchService.getPublicState()
	end

	-- Démarrer automatiquement une partie quand assez de joueurs arrivent
	Players.PlayerAdded:Connect(function(_player)
		local count = #Players:GetPlayers()
		if state.Phase == "Lobby" and count >= Config.Format.Duel.Min then
			-- Petite fenêtre pour laisser d'autres joueurs rejoindre
			task.delay(Config.PhaseDuration.Lobby, function()
				if state.Phase == "Lobby" then
					MatchService.startMatch()
				end
			end)
		end
	end)

	-- En Studio avec 1 joueur : démarrer tout de suite pour tester
	if game:GetService("RunService"):IsStudio() then
		task.delay(5, function()
			if state.Phase == "Lobby" and #Players:GetPlayers() >= 1 then
				print("[MatchService] Mode Studio : démarrage forcé pour tests")
				MatchService.startMatch()
			end
		end)
	end

	print("[MatchService] Initialisé — en attente dans Lobby")
end

return MatchService
