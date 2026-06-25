--!strict
-- Identifiants centralisés pour tous les RemoteEvents et RemoteFunctions.
-- Ne jamais écrire une string de remote en dur ailleurs dans le code.

local RemoteNames = {}

-- RemoteEvents : Server → Client
RemoteNames.GamePhaseChanged = "GamePhaseChanged" -- payload: PhaseChangedPayload
RemoteNames.RoleAssigned = "RoleAssigned" -- payload: RoleAssignedPayload (FireClient individuel)
RemoteNames.TimerSync = "TimerSync" -- payload: { TimeLeft: number }
RemoteNames.ContradictionDetected = "ContradictionDetected" -- payload: { Field: string }
RemoteNames.VerdictRevealed = "VerdictRevealed" -- payload: { Verdict: VerdictValue, GuiltyCount: number }
RemoteNames.RewardGranted = "RewardGranted" -- payload: { XP: number, Jetons: number }
RemoteNames.ReactionBroadcast = "ReactionBroadcast" -- payload: { FromUserId: number, ReactionType: string }

-- RemoteEvents : Client → Server
RemoteNames.DeclarationSubmitted = "DeclarationSubmitted" -- payload: { Fields: {string} }
RemoteNames.ReactionSent = "ReactionSent" -- payload: { ReactionType: string }
RemoteNames.VoteCast = "VoteCast" -- payload: { Vote: VerdictValue }
RemoteNames.ObjectionRaised = "ObjectionRaised" -- payload: {}

-- RemoteFunctions : bidirectionnel
RemoteNames.GetPlayerProfile = "GetPlayerProfile" -- retourne: SessionProfile
RemoteNames.GetCurrentMatchState = "GetCurrentMatchState" -- retourne: { Phase, Format } (pas les rôles des autres)

-- Séparation events / functions pour Net.init()
RemoteNames._EventNames = {
	RemoteNames.GamePhaseChanged,
	RemoteNames.RoleAssigned,
	RemoteNames.TimerSync,
	RemoteNames.ContradictionDetected,
	RemoteNames.VerdictRevealed,
	RemoteNames.RewardGranted,
	RemoteNames.ReactionBroadcast,
	RemoteNames.DeclarationSubmitted,
	RemoteNames.ReactionSent,
	RemoteNames.VoteCast,
	RemoteNames.ObjectionRaised,
}

RemoteNames._FunctionNames = {
	RemoteNames.GetPlayerProfile,
	RemoteNames.GetCurrentMatchState,
}

return RemoteNames
