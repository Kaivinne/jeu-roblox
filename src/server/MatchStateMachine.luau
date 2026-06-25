--!strict
-- Machine à états pure pour les phases de jeu.
-- Aucun effet de bord : pas de RemoteEvents, pas de timers.
-- Valider ici, agir dans MatchService.

local Types = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Types)

-- Séquence linéaire des transitions valides
local NEXT_PHASE: { [Types.MatchPhase]: Types.MatchPhase } = {
	Lobby = "Matchmaking",
	Matchmaking = "Intro",
	Intro = "Testimony",
	Testimony = "Deliberation",
	Deliberation = "Verdict",
	Verdict = "PostVerdict",
	PostVerdict = "Cleanup",
	Cleanup = "Lobby",
}

local MatchStateMachine = {}

-- Retourne la prochaine phase autorisée depuis `current`, ou nil si terminal
function MatchStateMachine.nextPhase(current: Types.MatchPhase): Types.MatchPhase?
	return NEXT_PHASE[current]
end

-- Vérifie qu'une transition est légale
function MatchStateMachine.canTransition(from: Types.MatchPhase, to: Types.MatchPhase): boolean
	return NEXT_PHASE[from] == to
end

-- Cleanup est la seule phase "fin de boucle" — après elle on reboucle sur Lobby
function MatchStateMachine.isEndOfCycle(phase: Types.MatchPhase): boolean
	return phase == "Cleanup"
end

-- Phases où le joueur est actif (interactions attendues)
function MatchStateMachine.isActivePhase(phase: Types.MatchPhase): boolean
	return phase == "Testimony" or phase == "Deliberation" or phase == "Verdict"
end

return MatchStateMachine
