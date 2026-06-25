--!strict
-- Point d'entrée client — Milestone 1.3.
-- Initialise tous les modules UI et câble les événements réseau.
-- Le client n'a aucune logique de jeu : il affiche et envoie des intentions.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)
local Types = require(Shared.Types)

local HUD = require(script.ui.HUD)
local Toast = require(script.ui.Toast)
local ReactionBar = require(script.ui.ReactionBar)
local DeclarationBuilder = require(script.ui.DeclarationBuilder)
local VerdictScreen = require(script.ui.VerdictScreen)

-- Rôle local du joueur (assigné par le serveur pendant Matchmaking)
local currentRole: string = ""

-- Initialiser tous les modules UI (crée les ScreenGuis une seule fois)
HUD.setup()
ReactionBar.setup()
DeclarationBuilder.setup()
VerdictScreen.setup()
-- Toast est lazy-initialized à la première notification

-- Détermine quel panneau montrer selon la phase et le rôle local
local function applyPhaseUI(phase: string)
	ReactionBar.hide()
	DeclarationBuilder.hide()
	VerdictScreen.hide()

	if phase == "Testimony" then
		local isWitness = currentRole == "HonestWitness" or currentRole == "Liar"
		local isObserver = currentRole == "Juror"
			or currentRole == "Prosecutor"
			or currentRole == "Defense"
		if isWitness then
			DeclarationBuilder.show()
		elseif isObserver then
			ReactionBar.show()
		end
	elseif phase == "Verdict" then
		-- Seuls les Jurés votent (les autres voient juste le timer)
		if currentRole == "Juror" then
			VerdictScreen.show()
		end
	elseif phase == "Lobby" then
		Toast.info("En attente de joueurs...")
	elseif phase == "Matchmaking" then
		Toast.info("Préparation de la partie...")
	elseif phase == "Intro" then
		Toast.info("La partie commence !")
	elseif phase == "PostVerdict" then
		Toast.success("Partie terminée — résultats en cours...")
	end
end

-- Changement de phase (server → client)
Net.onClient(RemoteNames.GamePhaseChanged, function(payload)
	local typed = payload :: Types.PhaseChangedPayload
	HUD.setPhase(typed.Phase, typed.Duration)
	HUD.setInfo(typed.Format, typed.PlayerCount)
	applyPhaseUI(typed.Phase)
end)

-- Attribution du rôle (FireClient individuel — les autres ne voient pas ce message)
Net.onClient(RemoteNames.RoleAssigned, function(payload)
	local typed = payload :: Types.RoleAssignedPayload
	currentRole = typed.Role
	HUD.setRole(typed.Role)

	local roleLabels: { [string]: string } = {
		HonestWitness = "Vous êtes Témoin Honnête",
		Liar = "Vous êtes le Menteur",
		Prosecutor = "Vous êtes l'Avocat",
		Defense = "Vous êtes l'Avocat de la Défense",
		Juror = "Vous êtes Juré",
	}
	-- ShortDescription est affiché en toast (instruction de jeu)
	local label = roleLabels[typed.Role] or typed.Role
	Toast.info(label)
	if typed.ShortDescription ~= "" then
		task.delay(1.5, function()
			Toast.info(typed.ShortDescription)
		end)
	end
end)

-- Action refusée par le serveur (phase incorrecte ou rôle non autorisé)
Net.onClient(RemoteNames.ActionRejected, function(payload)
	local message = payload.Message
	if type(message) == "string" then
		Toast.error(message)
	end
end)

-- Correction du timer (sync serveur toutes les N secondes)
Net.onClient(RemoteNames.TimerSync, function(payload)
	local timeLeft = payload.TimeLeft
	if type(timeLeft) == "number" then
		HUD.syncTimer(timeLeft)
	end
end)

-- Réaction d'un autre joueur (broadcast)
Net.onClient(RemoteNames.ReactionBroadcast, function(payload)
	local reactionType = payload.ReactionType
	if type(reactionType) == "string" then
		Toast.info("Réaction : " .. reactionType)
	end
end)

-- Verdict révélé par le serveur (déclenché lors du passage en PostVerdict)
Net.onClient(RemoteNames.VerdictRevealed, function(payload)
	local verdict = payload.Verdict
	local guiltyCount = payload.GuiltyCount
	if type(verdict) == "string" and type(guiltyCount) == "number" then
		VerdictScreen.showResult(verdict, guiltyCount)
	end
end)

-- Récompenses attribuées
Net.onClient(RemoteNames.RewardGranted, function(payload)
	local xp = payload.XP
	local jetons = payload.Jetons
	if type(xp) == "number" and type(jetons) == "number" then
		Toast.success(string.format("+%d XP  +%d Jetons", xp, jetons))
	end
end)

print("[Client] The Witness Box v1.3 — UI prête")
