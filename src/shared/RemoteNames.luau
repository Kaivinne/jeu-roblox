--!strict
-- Identifiants centralisés pour tous les RemoteEvents et RemoteFunctions.
-- Ne jamais écrire une string de remote en dur ailleurs dans le code.

local RemoteNames = {}

-- RemoteEvents : Server → Client
RemoteNames.GamePhaseChanged = "GamePhaseChanged" -- payload: PhaseChangedPayload
RemoteNames.RoleAssigned = "RoleAssigned" -- payload: RoleAssignedPayload (FireClient individuel uniquement)
RemoteNames.TimerSync = "TimerSync" -- payload: { TimeLeft: number }
RemoteNames.CaseIntroReceived = "CaseIntroReceived" -- payload: CaseIntroPayload (FireClient individuel)
RemoteNames.ContradictionDetected = "ContradictionDetected" -- payload: { Field: string }
RemoteNames.DeclarationBroadcast = "DeclarationBroadcast" -- payload: { FromName: string, FieldValues: {string} }
RemoteNames.VerdictRevealed = "VerdictRevealed" -- payload: voir MatchService.computeAndBroadcastVerdict
RemoteNames.RewardGranted = "RewardGranted" -- payload: { XP: number, Jetons: number }
RemoteNames.ReactionBroadcast = "ReactionBroadcast" -- payload: { FromUserId: number, ReactionType: string }
RemoteNames.ActionRejected = "ActionRejected" -- payload: { Message: string }

-- RemoteEvents : Client → Server
RemoteNames.DeclarationSubmitted = "DeclarationSubmitted" -- payload: { Fields: { [string]: number } }
RemoteNames.ReactionSent = "ReactionSent" -- payload: { ReactionType: string }
RemoteNames.VoteCast = "VoteCast" -- payload: { Vote: string }
RemoteNames.ObjectionRaised = "ObjectionRaised" -- payload: {}

-- RemoteFunctions : bidirectionnel
RemoteNames.GetPlayerProfile = "GetPlayerProfile"
RemoteNames.GetCurrentMatchState = "GetCurrentMatchState"

RemoteNames._EventNames = {
	RemoteNames.GamePhaseChanged,
	RemoteNames.RoleAssigned,
	RemoteNames.TimerSync,
	RemoteNames.CaseIntroReceived,
	RemoteNames.ContradictionDetected,
	RemoteNames.DeclarationBroadcast,
	RemoteNames.VerdictRevealed,
	RemoteNames.RewardGranted,
	RemoteNames.ReactionBroadcast,
	RemoteNames.ActionRejected,
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
