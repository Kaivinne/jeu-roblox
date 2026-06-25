--!strict
-- Configuration globale. Toutes les constantes numériques du jeu viennent d'ici.
-- Modifier ici suffit — ne pas hard-coder de valeurs dans les services.

local Config = {}

Config.GameName = "The Witness Box"
Config.Version = "0.1.0"

-- Durée de chaque phase en secondes
Config.PhaseDuration = {
	Lobby = 60, -- attente d'autres joueurs
	Matchmaking = 10, -- sélection du format + attribution des rôles
	Intro = 20, -- présentation du scénario
	Testimony = 25, -- déclaration par témoin (pas total)
	Deliberation = 45, -- jurés délibèrent
	Verdict = 8, -- affichage et vote final
	PostVerdict = 60, -- conférence de presse, récompenses
	Cleanup = 3, -- nettoyage état serveur avant la prochaine partie
}

-- Seuils de joueurs pour chaque format
Config.Format = {
	Solo = { Min = 1, Max = 1 },
	Duel = { Min = 2, Max = 2 },
	Mini = { Min = 3, Max = 4 },
	Full = { Min = 5, Max = 8 },
}

-- Limites techniques
Config.MaxPlayersPerServer = 8
Config.TimerSyncIntervalSeconds = 5 -- fréquence d'envoi du TimerSync au client

-- Récompenses de base (calcul complet dans MatchService)
Config.Rewards = {
	BaseXP = 50,
	BaseJetons = 10,
	CorrectVerdictXP = 75,
	CorrectVerdictJetons = 15,
	LiarAcquittedXP = 100,
	LiarAcquittedJetons = 20,
}

return Config
