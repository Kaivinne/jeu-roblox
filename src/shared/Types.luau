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

-- Defense ajouté en 1.3 (Milestone 1.3)
export type PlayerRole = "HonestWitness" | "Liar" | "Prosecutor" | "Defense" | "Juror"

export type VerdictValue = "Guilty" | "Innocent"

-- Profil en mémoire pour la session courante (pas le DataStore complet)
export type SessionProfile = {
	UserId: number,
	DisplayName: string,
	JoinedAt: number,
}

-- État complet d'une partie en cours (server-only)
export type MatchState = {
	MatchId: string,
	Phase: MatchPhase,
	Format: GameFormat,
	PlayerRoles: { [number]: PlayerRole },
	Votes: { [number]: VerdictValue },
	PhaseStartedAt: number,
	PhaseTimer: thread?,
}

-- Payload envoyé à tous les clients lors d'un changement de phase
export type PhaseChangedPayload = {
	Phase: MatchPhase,
	Duration: number,
	MatchId: string,
	Format: string, -- GameFormat transmis comme string dans le payload réseau
	PlayerCount: number,
}

-- Payload envoyé INDIVIDUELLEMENT au client pour son rôle (jamais broadcast)
export type RoleAssignedPayload = {
	Role: PlayerRole,
	MatchId: string,
	DisplayName: string,
	ShortDescription: string,
}

return {}
