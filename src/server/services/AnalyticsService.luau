--!strict
-- Instrumentation analytics minimale — logs console uniquement.
-- Milestone 1.9 : aucune donnée personnelle sensible, aucun texte libre.
-- Stats de session calculées en mémoire, résumé toutes les 5 minutes en Studio.

local RunService = game:GetService("RunService")

local AnalyticsService = {}

-- ─── Stats internes ────────────────────────────────────────────────────────────

local matchesCompleted = 0
local totalMatchDuration = 0
local verdictsCorrect = 0
local verdictsIncorrect = 0
local midMatchLeaves = 0
local currentMatchStartedAt = 0

-- ─── Formatage ────────────────────────────────────────────────────────────────

local function fmtData(data: { [string]: any }?): string
	if not data then
		return ""
	end
	local parts: { string } = {}
	for k, v in pairs(data) do
		table.insert(parts, string.format("%s=%s", tostring(k), tostring(v)))
	end
	table.sort(parts)
	return if #parts > 0 then "  " .. table.concat(parts, "  ") else ""
end

-- ─── API publique ─────────────────────────────────────────────────────────────

-- Logger un événement analytics. `data` ne doit contenir que des valeurs non sensibles.
-- Données acceptées : UserId, matchId, format, phase, role, isCorrect,
--                     rewardAmount, duration, vote, field, playerCount.
function AnalyticsService.track(player: Player?, eventName: string, data: any?)
	local userId = if player then player.UserId else 0
	local typedData: { [string]: any }? = if type(data) == "table"
		then data :: { [string]: any }
		else nil

	print(
		string.format("[Analytics] %-26s userId=%-12s%s", eventName, tostring(userId), fmtData(typedData))
	)

	-- Mise à jour des stats selon l'événement
	if eventName == "MatchStarted" then
		currentMatchStartedAt = tick()
	elseif eventName == "MatchCompleted" then
		matchesCompleted += 1
		if currentMatchStartedAt > 0 then
			totalMatchDuration += tick() - currentMatchStartedAt
			currentMatchStartedAt = 0
		end
	elseif eventName == "PlayerLeftMidMatch" then
		midMatchLeaves += 1
	elseif eventName == "RewardGranted" and typedData ~= nil then
		local isCorrect = typedData.isCorrect
		if isCorrect == true then
			verdictsCorrect += 1
		elseif isCorrect == false then
			verdictsIncorrect += 1
		end
	end
end

-- Imprime un résumé de la session courante dans la console serveur.
function AnalyticsService.printSummary()
	local avg = if matchesCompleted > 0 then totalMatchDuration / matchesCompleted else 0
	print(
		"──────────────────────────────────────────────────────"
	)
	print(string.format("[Analytics] RÉSUMÉ SESSION  %s", os.date("%H:%M:%S")))
	print(string.format("[Analytics]   Matchs terminés     : %d", matchesCompleted))
	print(string.format("[Analytics]   Durée moy. match    : %.1fs", avg))
	print(string.format("[Analytics]   Verdicts corrects   : %d", verdictsCorrect))
	print(string.format("[Analytics]   Verdicts incorrects : %d", verdictsIncorrect))
	print(string.format("[Analytics]   Sorties mid-match   : %d", midMatchLeaves))
	print(
		"──────────────────────────────────────────────────────"
	)
end

function AnalyticsService.init()
	if RunService:IsStudio() then
		-- Résumé automatique toutes les 5 minutes en Studio uniquement
		task.spawn(function()
			while true do
				task.wait(300)
				AnalyticsService.printSummary()
			end
		end)
		print("[Analytics] Initialisé — résumé toutes les 5 min (Studio)")
	else
		print("[Analytics] Initialisé")
	end
end

return AnalyticsService
