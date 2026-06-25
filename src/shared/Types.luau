--!strict
-- Source de vérité pour tous les types du projet.
-- Importer depuis ici uniquement — ne pas redéfinir localement.

export type MatchPhase =
	"Lobby"
	| "Matchmaking"
	| "Intro"
	| "Testimony"
	| "Deliberation"
	| "Verdict"
	| "PostVerdict"
	| "Cleanup"

export type GameFormat = "Solo" | "Duel" | "Mini" | "Full"

export type PlayerRole = "HonestWitness" | "Liar" | "Prosecutor" | "Juror"

export type VerdictValue = "Guilty" | "Innocent"

-- Profil en mémoire pour la session courante (pas le DataStore complet)
export type SessionProfile = {
	UserId: number,
	DisplayName: string,
	JoinedAt: number, -- tick() au moment du PlayerAdded
}

-- État complet d'une partie en cours (server-only)
export type MatchState = {
	MatchId: string,
	Phase: MatchPhase,
	Format: GameFormat,
	PlayerRoles: { [number]: PlayerRole }, -- [UserId] = Role
	Votes: { [number]: VerdictValue }, -- [UserId] = Vote (Phase 2)
	PhaseStartedAt: number, -- tick()
	PhaseTimer: thread?, -- task.delay handle, annulable
}

-- Payload envoyé au client lors d'un changement de phase
export type PhaseChangedPayload = {
	Phase: MatchPhase,
	Duration: number, -- durée prévue de cette phase en secondes
	MatchId: string,
}

-- Payload envoyé individuellement au client pour son rôle
export type RoleAssignedPayload = {
	Role: PlayerRole,
	MatchId: string,
}

return {}
