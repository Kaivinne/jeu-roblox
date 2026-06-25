--!strict
-- Attribution des rôles selon le format de partie.
-- Module sans état : toutes les fonctions sont pures ou read-only.
-- Les rôles sont toujours envoyés en FireClient individuel, jamais en broadcast.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Types = require(Shared.Types)
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)

local RoleService = {}

-- Description courte affichée au joueur au début de la partie
local function getRoleDescription(role: Types.PlayerRole): string
	if role == "HonestWitness" then
		return "Dites la vérité. Faites-vous croire."
	elseif role == "Liar" then
		return "Mentez. Ne vous faites pas prendre."
	elseif role == "Prosecutor" then
		return "Posez les bonnes questions."
	elseif role == "Defense" then
		return "Défendez l'accusé. Semez le doute."
	else
		return "Observez. Réagissez. Jugez."
	end
end

-- Fisher-Yates shuffle — retourne une copie mélangée de la liste de joueurs
local function shuffle(players: { Player }): { Player }
	local copy: { Player } = {}
	for _, p in ipairs(players) do
		table.insert(copy, p)
	end
	for i = #copy, 2, -1 do
		local j = math.random(1, i)
		copy[i], copy[j] = copy[j], copy[i]
	end
	return copy
end

-- Retourne la table UserId → PlayerRole pour tous les joueurs selon le format
-- Pour le MVP : l'accusé est toujours Liar (sans système de scénario)
function RoleService.assignForMatch(
	players: { Player },
	format: Types.GameFormat
): { [number]: Types.PlayerRole }
	local roles: { [number]: Types.PlayerRole } = {}
	local s = shuffle(players)

	if format == "Solo" then
		-- 1 joueur : Juré d'un dossier froid (NPC witness en Phase 2)
		if s[1] then
			roles[s[1].UserId] = "Juror"
		end
	elseif format == "Duel" then
		-- 1 Liar, 1 Juré
		if s[1] then
			roles[s[1].UserId] = "Liar"
		end
		if s[2] then
			roles[s[2].UserId] = "Juror"
		end
	elseif format == "Mini" then
		-- 1 Liar, 1 Avocat, reste Jurés
		if s[1] then
			roles[s[1].UserId] = "Liar"
		end
		if s[2] then
			roles[s[2].UserId] = "Prosecutor"
		end
		for i = 3, #s do
			roles[s[i].UserId] = "Juror"
		end
	elseif format == "Full" then
		-- 1 Liar, 1 Avocat, 1 Défense, reste Jurés
		if s[1] then
			roles[s[1].UserId] = "Liar"
		end
		if s[2] then
			roles[s[2].UserId] = "Prosecutor"
		end
		if s[3] then
			roles[s[3].UserId] = "Defense"
		end
		for i = 4, #s do
			roles[s[i].UserId] = "Juror"
		end
	end

	return roles
end

-- Envoie RoleAssigned à chaque joueur en FireClient individuel.
-- Garantit que personne ne voit le rôle des autres.
function RoleService.broadcastRoles(
	players: { Player },
	roles: { [number]: Types.PlayerRole },
	matchId: string
)
	for _, player in ipairs(players) do
		local role = roles[player.UserId]
		if not role then
			continue
		end
		Net.fire(player, RemoteNames.RoleAssigned, {
			Role = role,
			MatchId = matchId,
			DisplayName = player.DisplayName,
			ShortDescription = getRoleDescription(role),
		})
		print(string.format("[RoleService] %s (%d) → %s", player.DisplayName, player.UserId, role))
	end
end

return RoleService
