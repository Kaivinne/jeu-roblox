--!strict
-- Point d'entrée unique du serveur.
-- Initialise les services dans l'ordre correct, puis s'efface.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Net)

local Server = script.Parent
local AnalyticsService = require(Server.services.AnalyticsService)
local PlayerDataService = require(Server.services.PlayerDataService)
local MatchService = require(Server.services.MatchService)

-- 1. Créer tous les remotes avant que le client puisse en avoir besoin
Net.init()

-- 2. Instrumentation (en premier pour capter les events des autres services)
AnalyticsService.init()

-- 3. Gérer les profils joueur
PlayerDataService.init()

-- 4. Démarrer la boucle de jeu
MatchService.init()

print("[Bootstrap] The Witness Box — serveur prêt")
