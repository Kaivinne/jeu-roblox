--!strict
-- Calcule et attribue les récompenses en fin de partie.
-- Toutes les décisions de récompense sont server-side.
-- Milestone 1.6 : Jetons participation + bonus verdict correct, Perspicacité, Rang.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Types = require(Shared.Types)
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)

local Server = script.Parent.Parent
local PlayerDataService = require(Server.services.PlayerDataService)

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

		-- Participation : tout le monde reçoit des Jetons de base
		local jetons = JETONS_PARTICIPATION
		local isCorrect: boolean? = nil

		local role = roles[userId]
		if role == "Juror" and correctJurors[userId] ~= nil then
			isCorrect = correctJurors[userId]
			if isCorrect then
				jetons += JETONS_VERDICT_CORRECT
			end
		end

		-- Mettre à jour le profil
		PlayerDataService.addJetons(userId, jetons)
		PlayerDataService.incrementParties(userId)

		if isCorrect == true then
			PlayerDataService.recordVerdictCorrect(userId)
		elseif isCorrect == false then
			PlayerDataService.recordVerdictIncorrect(userId)
		end

		local profile = PlayerDataService.getGameProfile(userId)
		if not profile then
			continue
		end

		print(
			string.format(
				"[RewardService] %s → +%d Jetons (verdict: %s) | Perspicacité: %d | Rang: %s",
				player.DisplayName,
				jetons,
				if isCorrect == nil then "N/A" elseif isCorrect then "correct" else "incorrect",
				profile.Perspicacite,
				profile.RangActuel
			)
		)

		-- Notifier le client
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
		})
	end
end

-- Envoie le profil actuel au client sans modifier les données.
-- Utile pour initialiser le ProfilePanel au chargement.
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
	})
end

-- Pousse le profil initial à tous les joueurs présents (appelé depuis MatchService.init)
function RewardService.pushAllProfiles()
	for _, player in ipairs(Players:GetPlayers()) do
		RewardService.pushProfile(player)
	end
end

return RewardService
