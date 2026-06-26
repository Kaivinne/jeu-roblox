--!strict
-- Témoin NPC pour le mode Solo.
-- Constantes et décision aléatoire uniquement — la construction de la déclaration
-- est déléguée à CaseService pour rester découplé des données d'affaire.

local NPCService = {}

NPCService.NPC_USER_ID = 0
NPCService.NPC_NAME = "Le Témoin"

-- Décide aléatoirement si le NPC doit mentir (appel unique au début du match)
function NPCService.decideLie(): boolean
	return math.random() < 0.5
end

return NPCService
