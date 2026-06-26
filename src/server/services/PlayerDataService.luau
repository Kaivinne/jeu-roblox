--!strict
-- Gestion des données joueur en mémoire pour la session courante.
-- Milestone 1.6 : profil de progression en mémoire (Jetons, Rang, Perspicacité).
-- Le DataStore persistant est prévu en Phase 2.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Types = require(Shared.Types)
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)

local PlayerDataService = {}

-- Profils de session (DisplayName, JoinedAt)
local sessionProfiles: { [number]: Types.SessionProfile } = {}

-- Profils de progression en mémoire
local gameProfiles: { [number]: Types.ProfileData } = {}

-- Seuils de rang basés sur le nombre de verdicts corrects
local RANGS: { { Seuil: number, Nom: string } } = {
	{ Seuil = 60, Nom = "Détective" },
	{ Seuil = 30, Nom = "Inspecteur" },
	{ Seuil = 15, Nom = "Enquêteur" },
	{ Seuil = 5, Nom = "Observateur" },
	{ Seuil = 0, Nom = "Novice" },
}

local function computeRang(verdictsCorrects: number): string
	for _, entry in ipairs(RANGS) do
		if verdictsCorrects >= entry.Seuil then
			return entry.Nom
		end
	end
	return "Novice"
end

local function defaultGameProfile(): Types.ProfileData
	return {
		Jetons = 0,
		PartiesJouees = 0,
		VerdictsCorrects = 0,
		VerdictsIncorrects = 0,
		Credibilite = 50,
		Perspicacite = 50,
		RangActuel = "Novice",
	}
end

-- Retourne ou crée le profil de progression d'un joueur
function PlayerDataService.ensureGameProfile(userId: number): Types.ProfileData
	if not gameProfiles[userId] then
		gameProfiles[userId] = defaultGameProfile()
	end
	return gameProfiles[userId]
end

function PlayerDataService.getGameProfile(userId: number): Types.ProfileData?
	return gameProfiles[userId]
end

function PlayerDataService.addJetons(userId: number, amount: number)
	local profile = PlayerDataService.ensureGameProfile(userId)
	profile.Jetons = math.max(0, profile.Jetons + amount)
end

function PlayerDataService.incrementParties(userId: number)
	local profile = PlayerDataService.ensureGameProfile(userId)
	profile.PartiesJouees += 1
end

-- Verdict correct : Perspicacité +5 (plafond 100), VerdictsCorrects++, rang recalculé
function PlayerDataService.recordVerdictCorrect(userId: number)
	local profile = PlayerDataService.ensureGameProfile(userId)
	profile.VerdictsCorrects += 1
	profile.Perspicacite = math.min(100, profile.Perspicacite + 5)
	profile.RangActuel = computeRang(profile.VerdictsCorrects)
end

-- Verdict incorrect : Perspicacité -3 (plancher 0), VerdictsIncorrects++
function PlayerDataService.recordVerdictIncorrect(userId: number)
	local profile = PlayerDataService.ensureGameProfile(userId)
	profile.VerdictsIncorrects += 1
	profile.Perspicacite = math.max(0, profile.Perspicacite - 3)
end

-- Session profile (DisplayName, JoinedAt) — inchangé depuis 1.1
local function onPlayerAdded(player: Player)
	sessionProfiles[player.UserId] = {
		UserId = player.UserId,
		DisplayName = player.DisplayName,
		JoinedAt = tick(),
	}
	-- Préparer le profil de progression dès la connexion
	PlayerDataService.ensureGameProfile(player.UserId)
	print("[PlayerDataService] Profil créé pour", player.DisplayName, "(", player.UserId, ")")
end

local function onPlayerRemoving(player: Player)
	sessionProfiles[player.UserId] = nil
	gameProfiles[player.UserId] = nil
	print("[PlayerDataService] Profil supprimé pour", player.DisplayName)
end

function PlayerDataService.getProfile(userId: number): Types.SessionProfile?
	return sessionProfiles[userId]
end

function PlayerDataService.getAllProfiles(): { Types.SessionProfile }
	local result: { Types.SessionProfile } = {}
	for _, profile in pairs(sessionProfiles) do
		table.insert(result, profile)
	end
	return result
end

function PlayerDataService.getActiveCount(): number
	local count = 0
	for _ in pairs(sessionProfiles) do
		count += 1
	end
	return count
end

function PlayerDataService.init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	local fn = Net.getFunction(RemoteNames.GetPlayerProfile)
	fn.OnServerInvoke = function(player: Player): Types.SessionProfile?
		return PlayerDataService.getProfile(player.UserId)
	end

	print("[PlayerDataService] Initialisé")
end

return PlayerDataService
