--!strict
-- Point d'entrée unique du serveur.
-- Initialise les services dans l'ordre correct, puis s'efface.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Net)

local Server = script.Parent
local AnalyticsService = require(Server.services.AnalyticsService)
local PlayerDataService = require(Server.services.PlayerDataService)
local MatchService = require(Server.services.MatchService)
local WorldBuilder = require(Server.services.WorldBuilder)
local CosmeticService = require(Server.services.CosmeticService)

-- 1. Créer tous les remotes avant que le client puisse en avoir besoin
Net.init()

-- 2. Construire la salle d'audience (Workspace, avant tout le reste)
WorldBuilder.buildCourthouse()

-- 3. Instrumentation (en premier pour capter les events des autres services)
AnalyticsService.init()

-- 4. Gérer les profils joueur
PlayerDataService.init()

-- 5. Démarrer la boucle de jeu
MatchService.init()

-- 6. Boutique de cosmétiques
CosmeticService.init()

print("[Bootstrap] The Witness Box — serveur prêt")
