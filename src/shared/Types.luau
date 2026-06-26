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
	Declarations: { [number]: { [string]: number } }, -- [UserId] = { [FieldKey] = selectedIndex }
	PhaseStartedAt: number,
	PhaseTimer: thread?,
}

-- Payload envoyé à tous les clients lors d'un changement de phase
export type PhaseChangedPayload = {
	Phase: MatchPhase,
	Duration: number,
	MatchId: string,
	Format: string,
	PlayerCount: number,
}

-- Payload envoyé INDIVIDUELLEMENT au client pour son rôle (jamais broadcast)
export type RoleAssignedPayload = {
	Role: PlayerRole,
	MatchId: string,
	DisplayName: string,
	ShortDescription: string,
}

-- Champ d'affaire côté client (sans TruthIndex — server-only)
export type CaseFieldClient = {
	Key: string,
	Label: string,
	Options: { string },
}

-- Payload envoyé individuellement à chaque joueur au début de Intro
export type CaseIntroPayload = {
	CaseId: string,
	Title: string,
	Summary: string,
	Accusation: string,
	Fields: { CaseFieldClient },
	RoleObjective: string,
	TruthGuide: { [string]: number }?, -- FieldKey → index (nil pour les observateurs)
	LiarHint: string?, -- instruction textuelle pour le Menteur
}

return {}
