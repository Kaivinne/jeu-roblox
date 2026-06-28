--!strict
-- Gestion des données joueur avec persistance DataStore minimale.
-- Milestone 1.8 : chargement async à PlayerAdded, sauvegarde à PlayerRemoving,
-- autosave toutes les 60s, BindToClose, fallback mémoire si DataStore indisponible.
-- API publique inchangée pour les autres services.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Types = require(Shared.Types)
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)

local AnalyticsService = require(script.Parent.AnalyticsService)

local PlayerDataService = {}

-- ─── Configuration ────────────────────────────────────────────────────────────

local DATASTORE_NAME = "PlayerProfiles_v1"
local AUTOSAVE_INTERVAL = 60 -- secondes

-- ─── Données internes ─────────────────────────────────────────────────────────

local sessionProfiles: { [number]: Types.SessionProfile } = {}
local gameProfiles: { [number]: Types.ProfileData } = {}
local autosaveThreads: { [number]: thread } = {}

-- DataStore : nil si indisponible (Studio sans API, erreur réseau…)
local playerStore: DataStore? = nil

do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)
	if ok then
		playerStore = result :: DataStore
		print("[PlayerDataService] DataStore connecté :", DATASTORE_NAME)
	else
		warn(
			"[PlayerDataService] DataStore indisponible — fonctionnement en mémoire uniquement.",
			result
		)
	end
end

-- ─── Rangs ────────────────────────────────────────────────────────────────────

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

-- ─── Profil par défaut & reconcile ───────────────────────────────────────────

local PROFILE_DEFAULTS: Types.ProfileData = {
	Jetons = 0,
	PartiesJouees = 0,
	VerdictsCorrects = 0,
	VerdictsIncorrects = 0,
	Credibilite = 50,
	Perspicacite = 50,
	RangActuel = "Novice",
	OwnedCosmetics = {},
	EquippedCosmetics = {},
	HasSeenOnboarding = false,
}

local function newProfile(): Types.ProfileData
	return {
		Jetons = 0,
		PartiesJouees = 0,
		VerdictsCorrects = 0,
		VerdictsIncorrects = 0,
		Credibilite = 50,
		Perspicacite = 50,
		RangActuel = "Novice",
		OwnedCosmetics = {},
		EquippedCosmetics = {},
		HasSeenOnboarding = false,
	}
end

-- Fusionne les données sauvegardées avec les valeurs par défaut.
-- Les champs inconnus sont ignorés ; les nouveaux champs reçoivent leur valeur par défaut.
local function reconcile(saved: { [string]: any }): Types.ProfileData
	local function num(key: string, default: number): number
		local v = saved[key]
		return if type(v) == "number" then v else default
	end
	local function str(key: string, default: string): string
		local v = saved[key]
		return if type(v) == "string" then v else default
	end
	local function bool(key: string, default: boolean): boolean
		local v = saved[key]
		return if type(v) == "boolean" then v else default
	end
	-- Cosmétiques possédés
	local owned: { string } = {}
	if type(saved.OwnedCosmetics) == "table" then
		for _, rawId in ipairs(saved.OwnedCosmetics :: { any }) do
			if type(rawId) == "string" then
				table.insert(owned, rawId)
			end
		end
	end
	-- Cosmétiques équipés (slot → itemId)
	local equipped: { [string]: string? } = {}
	if type(saved.EquippedCosmetics) == "table" then
		for slot, rawId in pairs(saved.EquippedCosmetics :: { [string]: any }) do
			if type(slot) == "string" and type(rawId) == "string" then
				equipped[slot] = rawId
			end
		end
	end
	return {
		Jetons = num("Jetons", PROFILE_DEFAULTS.Jetons),
		PartiesJouees = num("PartiesJouees", PROFILE_DEFAULTS.PartiesJouees),
		VerdictsCorrects = num("VerdictsCorrects", PROFILE_DEFAULTS.VerdictsCorrects),
		VerdictsIncorrects = num("VerdictsIncorrects", PROFILE_DEFAULTS.VerdictsIncorrects),
		Credibilite = num("Credibilite", PROFILE_DEFAULTS.Credibilite),
		Perspicacite = num("Perspicacite", PROFILE_DEFAULTS.Perspicacite),
		RangActuel = str("RangActuel", PROFILE_DEFAULTS.RangActuel),
		OwnedCosmetics = owned,
		EquippedCosmetics = equipped,
		HasSeenOnboarding = bool("HasSeenOnboarding", false),
	}
end

-- ─── Persistance ──────────────────────────────────────────────────────────────

local function saveProfile(userId: number)
	if not playerStore then
		return
	end
	local profile = gameProfiles[userId]
	if not profile then
		return
	end
	local key = tostring(userId)
	local ok, err = pcall(function()
		(playerStore :: DataStore):SetAsync(key, {
			Jetons = profile.Jetons,
			PartiesJouees = profile.PartiesJouees,
			VerdictsCorrects = profile.VerdictsCorrects,
			VerdictsIncorrects = profile.VerdictsIncorrects,
			Credibilite = profile.Credibilite,
			Perspicacite = profile.Perspicacite,
			RangActuel = profile.RangActuel,
			OwnedCosmetics = profile.OwnedCosmetics,
			EquippedCosmetics = profile.EquippedCosmetics,
			HasSeenOnboarding = profile.HasSeenOnboarding,
		})
	end)
	if ok then
		print(string.format("[PlayerDataService] Sauvegardé : %d (Jetons: %d)", userId, profile.Jetons))
	else
		warn(string.format("[PlayerDataService] Erreur sauvegarde %d : %s", userId, tostring(err)))
	end
end

local function loadProfile(userId: number): Types.ProfileData
	if not playerStore then
		return newProfile()
	end
	local key = tostring(userId)
	local ok, result = pcall(function()
		return (playerStore :: DataStore):GetAsync(key)
	end)
	if not ok then
		warn(string.format("[PlayerDataService] Erreur chargement %d : %s", userId, tostring(result)))
		return newProfile()
	end
	if result == nil then
		return newProfile() -- nouveau joueur
	end
	return reconcile(result :: { [string]: any })
end

-- ─── Autosave ─────────────────────────────────────────────────────────────────

local function startAutosave(userId: number)
	autosaveThreads[userId] = task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			if not gameProfiles[userId] then
				break
			end
			saveProfile(userId)
		end
	end)
end

local function stopAutosave(userId: number)
	local thread = autosaveThreads[userId]
	if thread then
		task.cancel(thread)
		autosaveThreads[userId] = nil
	end
end

-- ─── Gestion des joueurs ──────────────────────────────────────────────────────

local function onPlayerAdded(player: Player)
	sessionProfiles[player.UserId] = {
		UserId = player.UserId,
		DisplayName = player.DisplayName,
		JoinedAt = tick(),
	}

	-- Chargement async pour ne pas bloquer le thread principal
	task.spawn(function()
		local loaded = loadProfile(player.UserId)

		-- Vérifier que le joueur est encore connecté (peut partir pendant le chargement)
		if not player.Parent then
			return
		end

		gameProfiles[player.UserId] = loaded
		startAutosave(player.UserId)

		AnalyticsService.track(player, "PlayerJoined", {
			rang = loaded.RangActuel,
			partiesJouees = loaded.PartiesJouees,
		})

		print(
			string.format(
				"[PlayerDataService] Profil chargé pour %s — Jetons: %d | Rang: %s",
				player.DisplayName,
				loaded.Jetons,
				loaded.RangActuel
			)
		)

		-- Pousser le profil au client maintenant que les données sont prêtes
		Net.fire(player, RemoteNames.ProfileUpdated, {
			Jetons = loaded.Jetons,
			Rang = loaded.RangActuel,
			Perspicacite = loaded.Perspicacite,
			PartiesJouees = loaded.PartiesJouees,
			VerdictsCorrects = loaded.VerdictsCorrects,
			VerdictsIncorrects = loaded.VerdictsIncorrects,
			RangPrecedent = nil,
			EquippedFrame = (loaded.EquippedCosmetics :: { [string]: any })["frame"],
		})
		-- Notifier le client de l'état d'onboarding (séparé pour isoler la responsabilité)
		Net.fire(player, RemoteNames.OnboardingStatus, {
			HasSeen = loaded.HasSeenOnboarding,
		})
	end)
end

local function onPlayerRemoving(player: Player)
	stopAutosave(player.UserId)
	saveProfile(player.UserId)
	sessionProfiles[player.UserId] = nil
	gameProfiles[player.UserId] = nil
	print("[PlayerDataService] Profil supprimé pour", player.DisplayName)
end

-- ─── API publique ──────────────────────────────────────────────────────────────

-- Retourne ou crée un profil par défaut (utilisé par RewardService pendant une partie)
function PlayerDataService.ensureGameProfile(userId: number): Types.ProfileData
	if not gameProfiles[userId] then
		gameProfiles[userId] = newProfile()
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

-- Session profile (DisplayName, JoinedAt)
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

	-- Rattraper les joueurs déjà connectés (rechargement en Studio)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	-- Sauvegarde d'urgence à l'arrêt du serveur
	game:BindToClose(function()
		print("[PlayerDataService] BindToClose — sauvegarde de tous les profils actifs")
		for userId in pairs(gameProfiles) do
			stopAutosave(userId)
			saveProfile(userId)
		end
	end)

	-- Marque l'onboarding comme vu dès que le client envoie la confirmation
	Net.onServer(RemoteNames.OnboardingCompleted, function(player, _payload)
		local profile = PlayerDataService.getGameProfile(player.UserId)
		if profile then
			profile.HasSeenOnboarding = true
		end
	end)

	local fn = Net.getFunction(RemoteNames.GetPlayerProfile)
	fn.OnServerInvoke = function(player: Player): Types.SessionProfile?
		return PlayerDataService.getProfile(player.UserId)
	end

	print(
		"[PlayerDataService] Initialisé (DataStore:",
		if playerStore ~= nil then "actif" else "désactivé",
		")"
	)
end

return PlayerDataService
