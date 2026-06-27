--!strict
-- Calcule et attribue les récompenses en fin de partie.
-- Toutes les décisions de récompense sont server-side.
-- Milestone 1.7 : détection de montée de rang (RangPrecedent dans ProfileUpdated).

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Types = require(Shared.Types)
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)

local Server = script.Parent.Parent
local PlayerDataService = require(Server.services.PlayerDataService)
local AnalyticsService = require(Server.services.AnalyticsService)

local RewardService = {}

local JETONS_PARTICIPATION = 10
local JETONS_VERDICT_CORRECT = 15

-- Attribue les récompenses post-verdict à tous les joueurs connectés.
-- correctJurors : { [UserId] = true/false } — uniquement les Jurés qui ont voté.
function RewardService.grantPostVerdict(
	players: { Player },
	roles: { [number]: Types.PlayerRole },
	correctJurors: { [number]: boolean }
)
	for _, player in ipairs(players) do
		local userId = player.UserId

		local jetons = JETONS_PARTICIPATION
		local isCorrect: boolean? = nil

		local role = roles[userId]
		if role == "Juror" and correctJurors[userId] ~= nil then
			isCorrect = correctJurors[userId]
			if isCorrect then
				jetons += JETONS_VERDICT_CORRECT
			end
		end

		-- Capturer le rang AVANT les mutations pour détecter un changement
		local profile = PlayerDataService.ensureGameProfile(userId)
		local oldRang = profile.RangActuel

		PlayerDataService.addJetons(userId, jetons)
		PlayerDataService.incrementParties(userId)

		if isCorrect == true then
			PlayerDataService.recordVerdictCorrect(userId)
		elseif isCorrect == false then
			PlayerDataService.recordVerdictIncorrect(userId)
		end

		-- profile est la même référence, maintenant mutée
		local rangMonte = profile.RangActuel ~= oldRang

		print(
			string.format(
				"[RewardService] %s → +%d Jetons (verdict: %s) | Perspicacité: %d | Rang: %s%s",
				player.DisplayName,
				jetons,
				if isCorrect == nil then "N/A" elseif isCorrect then "correct" else "incorrect",
				profile.Perspicacite,
				profile.RangActuel,
				if rangMonte then " ↑ (montée de rang)" else ""
			)
		)

		AnalyticsService.track(player, "RewardGranted", {
			jetons = jetons,
			isCorrect = isCorrect,
			rang = profile.RangActuel,
			rangMonte = rangMonte,
		})

		Net.fire(player, RemoteNames.RewardGranted, {
			XP = 0,
			Jetons = jetons,
		})
		Net.fire(player, RemoteNames.ProfileUpdated, {
			Jetons = profile.Jetons,
			Rang = profile.RangActuel,
			Perspicacite = profile.Perspicacite,
			PartiesJouees = profile.PartiesJouees,
			VerdictsCorrects = profile.VerdictsCorrects,
			VerdictsIncorrects = profile.VerdictsIncorrects,
			RangPrecedent = if rangMonte then oldRang else nil,
			EquippedFrame = (profile.EquippedCosmetics :: { [string]: any })["frame"],
		})
	end
end

-- Envoie le profil actuel au client sans modifier les données.
function RewardService.pushProfile(player: Player)
	local profile = PlayerDataService.getGameProfile(player.UserId)
	if not profile then
		return
	end
	Net.fire(player, RemoteNames.ProfileUpdated, {
		Jetons = profile.Jetons,
		Rang = profile.RangActuel,
		Perspicacite = profile.Perspicacite,
		PartiesJouees = profile.PartiesJouees,
		VerdictsCorrects = profile.VerdictsCorrects,
		VerdictsIncorrects = profile.VerdictsIncorrects,
		RangPrecedent = nil,
		EquippedFrame = (profile.EquippedCosmetics :: { [string]: any })["frame"],
	})
end

function RewardService.pushAllProfiles()
	for _, player in ipairs(Players:GetPlayers()) do
		RewardService.pushProfile(player)
	end
end

return RewardService
