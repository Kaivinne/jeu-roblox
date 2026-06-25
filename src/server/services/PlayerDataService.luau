--!strict
-- Gestion des données joueur en mémoire pour la session courante.
-- Milestone 1.1 : stub en mémoire uniquement, pas de DataStore.
-- Le DataStore complet est prévu au Milestone 1.4.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Types = require(Shared.Types)
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)

local PlayerDataService = {}

-- Profiles actifs indexés par UserId
local profiles: { [number]: Types.SessionProfile } = {}

-- Crée un profil en mémoire à la connexion du joueur
local function onPlayerAdded(player: Player)
	profiles[player.UserId] = {
		UserId = player.UserId,
		DisplayName = player.DisplayName,
		JoinedAt = tick(),
	}
	print("[PlayerDataService] Profil créé pour", player.DisplayName, "(", player.UserId, ")")
end

-- Supprime le profil à la déconnexion
local function onPlayerRemoving(player: Player)
	profiles[player.UserId] = nil
	print("[PlayerDataService] Profil supprimé pour", player.DisplayName)
end

-- Retourne le profil d'un joueur (nil si absent)
function PlayerDataService.getProfile(userId: number): Types.SessionProfile?
	return profiles[userId]
end

-- Retourne tous les profils actifs
function PlayerDataService.getAllProfiles(): { Types.SessionProfile }
	local result: { Types.SessionProfile } = {}
	for _, profile in pairs(profiles) do
		table.insert(result, profile)
	end
	return result
end

-- Retourne le nombre de joueurs avec un profil actif
function PlayerDataService.getActiveCount(): number
	local count = 0
	for _ in pairs(profiles) do
		count += 1
	end
	return count
end

function PlayerDataService.init()
	-- Brancher les événements joueur
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Rattraper les joueurs déjà connectés (cas de rechargement en Studio)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	-- RemoteFunction : le client peut demander son propre profil
	local fn = Net.getFunction(RemoteNames.GetPlayerProfile)
	fn.OnServerInvoke = function(player: Player): Types.SessionProfile?
		return PlayerDataService.getProfile(player.UserId)
	end

	print("[PlayerDataService] Initialisé")
end

return PlayerDataService
