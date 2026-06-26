--!strict
-- Point d'entrée client — Milestone 1.7.
-- Initialise tous les modules UI et câble les événements réseau.
-- Le client n'a aucune logique de jeu : il affiche et envoie des intentions.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)
local Types = require(Shared.Types)

local HUD = require(script.ui.HUD)
local Toast = require(script.ui.Toast)
local IntroScreen = require(script.ui.IntroScreen)
local ReactionBar = require(script.ui.ReactionBar)
local DeclarationBuilder = require(script.ui.DeclarationBuilder)
local VerdictScreen = require(script.ui.VerdictScreen)
local SummaryScreen = require(script.ui.SummaryScreen)
local ProfilePanel = require(script.ui.ProfilePanel)

-- Rôle local du joueur (assigné par le serveur pendant Matchmaking)
local currentRole: string = ""

-- Initialiser tous les modules UI (crée les ScreenGuis une seule fois)
HUD.setup()
IntroScreen.setup()
ReactionBar.setup()
DeclarationBuilder.setup()
VerdictScreen.setup()
SummaryScreen.setup()
ProfilePanel.setup()
-- Toast est lazy-initialized à la première notification

-- Masque tous les panneaux contextuels
local function hideAllPanels()
	IntroScreen.hide()
	ReactionBar.hide()
	DeclarationBuilder.hide()
	VerdictScreen.hide()
	SummaryScreen.hide()
end

-- Détermine quel panneau montrer selon la phase et le rôle local
local function applyPhaseUI(phase: string)
	hideAllPanels()

	-- Intro : IntroScreen est rempli et ouvert via CaseIntroReceived, pas ici
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
		if currentRole == "Juror" then
			VerdictScreen.show()
		else
			-- Les non-jurés attendent le résultat passivement
			Toast.info("Phase de verdict en cours — attendez le résultat des jurés.")
		end
	elseif phase == "Lobby" then
		Toast.info("En attente de joueurs...")
	elseif phase == "Matchmaking" then
		Toast.info("Préparation de la partie...")
		-- Réinitialiser le rôle en attente du prochain RoleAssigned
		currentRole = ""
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
	local label = roleLabels[typed.Role] or typed.Role
	Toast.info(label)
	if typed.ShortDescription ~= "" then
		task.delay(1.5, function()
			Toast.info(typed.ShortDescription)
		end)
	end
end)

-- Données de l'affaire reçues individuellement au début de Intro
Net.onClient(RemoteNames.CaseIntroReceived, function(payload)
	local typed = payload :: Types.CaseIntroPayload

	local isWitness = currentRole == "HonestWitness" or currentRole == "Liar"
	if isWitness then
		local guide: { [string]: number }? = nil
		if typed.TruthGuide then
			guide = typed.TruthGuide :: { [string]: number }
		end
		local liarHint: string? = nil
		if typed.LiarHint and typed.LiarHint ~= "" then
			liarHint = typed.LiarHint
		end
		DeclarationBuilder.loadCase(typed.Fields, guide, liarHint)
	end

	local difficulty = if type(typed.Difficulty) == "string" then typed.Difficulty else "Medium"
	local theme = if type(typed.Theme) == "string" then typed.Theme else ""
	IntroScreen.show(
		typed.CaseId,
		typed.Title,
		typed.Summary,
		typed.Accusation,
		typed.RoleObjective,
		currentRole,
		difficulty,
		theme
	)
end)

-- Action refusée par le serveur (double vote, hors-phase, etc.)
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

-- Déclaration d'un autre joueur ou du NPC reçue (visible par tous)
Net.onClient(RemoteNames.DeclarationBroadcast, function(payload)
	local fromName = payload.FromName
	local fieldValues = payload.FieldValues
	if type(fromName) == "string" and type(fieldValues) == "table" then
		local values = fieldValues :: { string }
		if payload.IsNpc == true then
			Toast.info("Le témoin a déposé sa déclaration.")
			task.delay(1, function()
				Toast.info(fromName .. " a dit : " .. table.concat(values, " · "))
			end)
		else
			Toast.info(fromName .. " : " .. table.concat(values, " · "))
		end
	end
end)

-- Contradiction détectée par le serveur — alerte subtile
Net.onClient(RemoteNames.ContradictionDetected, function(payload)
	local field = payload.Field
	if type(field) == "string" then
		Toast.error("Une incohérence semble apparaître dans les déclarations…")
	end
end)

-- Réaction d'un autre joueur (broadcast)
Net.onClient(RemoteNames.ReactionBroadcast, function(payload)
	local reactionType = payload.ReactionType
	if type(reactionType) == "string" then
		Toast.info("Réaction : " .. reactionType)
	end
end)

-- Verdict révélé — affiche le SummaryScreen pour tous les rôles
Net.onClient(RemoteNames.VerdictRevealed, function(payload)
	local verdict = payload.Verdict
	local guiltyCount = payload.GuiltyCount
	local caseTitle = payload.CaseTitle
	local truthSummary = payload.TruthSummary
	local liarLied = payload.LiarLied
	local liarDeclaration = payload.LiarDeclaration

	if type(verdict) ~= "string" or type(guiltyCount) ~= "number" then
		return
	end
	if type(caseTitle) ~= "string" or type(truthSummary) ~= "table" then
		return
	end

	local didLie: boolean = if type(liarLied) == "boolean" then liarLied else false
	local liarDecl: { string } = if type(liarDeclaration) == "table"
		then liarDeclaration :: { string }
		else {}
	local truth = truthSummary :: { { Key: string, Value: string } }
	local twist: string = if type(payload.Twist) == "string" then payload.Twist :: string else ""

	-- Calculer correct/incorrect pour le Juré
	local playerVote = VerdictScreen.getLastVote()
	local isCorrect: boolean? = nil
	if currentRole == "Juror" and playerVote ~= "" then
		local votedGuilty = playerVote == "Guilty"
		isCorrect = (votedGuilty and didLie) or (not votedGuilty and not didLie)
	end

	SummaryScreen.show(
		caseTitle,
		truth,
		liarDecl,
		didLie,
		playerVote,
		isCorrect,
		currentRole,
		guiltyCount,
		twist
	)
end)

-- Récompenses attribuées — met à jour SummaryScreen et affiche un toast
Net.onClient(RemoteNames.RewardGranted, function(payload)
	local jetons = payload.Jetons
	if type(jetons) == "number" and jetons > 0 then
		SummaryScreen.setReward(jetons)
		Toast.success(string.format("+%d Jetons", jetons))
	end
end)

-- Profil mis à jour — actualise le panneau et notifie une montée de rang
Net.onClient(RemoteNames.ProfileUpdated, function(payload)
	local jetons = payload.Jetons
	local rang = payload.Rang
	local perspicacite = payload.Perspicacite
	local rangPrec = payload.RangPrecedent
	if type(jetons) == "number" and type(rang) == "string" and type(perspicacite) == "number" then
		ProfilePanel.update(jetons, rang, perspicacite)
		if type(rangPrec) == "string" then
			Toast.success("Nouveau rang atteint : " .. rang .. " !")
		end
	end
end)

print("[Client] The Witness Box v1.7 — UI prête")
