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
local ShopScreen = require(script.ui.ShopScreen)
local VerdictSequence = require(script.ui.VerdictSequence)
local WelcomeScreen = require(script.ui.WelcomeScreen)
local OnboardingScreen = require(script.ui.OnboardingScreen)
local DeliberationScreen = require(script.ui.DeliberationScreen)
local CameraController = require(script.CameraController)
local AudioController = require(script.AudioController)

-- Rôle local du joueur (assigné par le serveur pendant Matchmaking)
local currentRole: string = ""
-- Format de la partie courante (mis à jour par GamePhaseChanged)
local currentFormat: string = ""
-- Jetons courants (mis à jour par ProfileUpdated)
local currentJetons: number = 0
-- Contexte de délibération (accumulé pendant Intro + Testimony)
local storedAccusation: string = ""
local lastDeclarationText: string = ""
local recentReactions: { string } = {}

-- Initialiser tous les modules UI (crée les ScreenGuis une seule fois)
HUD.setup()
IntroScreen.setup()
ReactionBar.setup()
DeclarationBuilder.setup()
VerdictScreen.setup()
SummaryScreen.setup()
ProfilePanel.setup()
ShopScreen.setup()
CameraController.setup()
AudioController.setup()
WelcomeScreen.show()
VerdictScreen.setOnVoteCast(function()
	AudioController.play("Vote")
end)
ProfilePanel.setOnShopClick(function()
	Net.getEvent(RemoteNames.ShopOpen):FireServer({})
	ShopScreen.open()
end)
ProfilePanel.setOnHelpClick(function()
	OnboardingScreen.replay()
end)
-- Toast est lazy-initialized à la première notification

-- Masque tous les panneaux contextuels
local function hideAllPanels()
	IntroScreen.hide()
	ReactionBar.hide()
	DeclarationBuilder.hide()
	VerdictScreen.hide()
	SummaryScreen.hide()
	DeliberationScreen.hide()
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
	elseif phase == "Deliberation" then
		DeliberationScreen.show(
			currentFormat,
			currentRole,
			lastDeclarationText,
			storedAccusation,
			recentReactions
		)
	elseif phase == "Lobby" then
		Toast.info("En attente de joueurs...")
	elseif phase == "Matchmaking" then
		Toast.info("Préparation de la partie...")
		-- Réinitialiser l'état du match en attente du prochain cycle
		currentRole = ""
		lastDeclarationText = ""
		storedAccusation = ""
		recentReactions = {}
	end
end

-- Changement de phase (server → client)
Net.onClient(RemoteNames.GamePhaseChanged, function(payload)
	local typed = payload :: Types.PhaseChangedPayload
	currentFormat = typed.Format
	HUD.setPhase(typed.Phase, typed.Duration)
	HUD.setInfo(typed.Format, typed.PlayerCount)
	applyPhaseUI(typed.Phase)
	CameraController.onPhaseChanged(typed.Phase)
	AudioController.onPhaseChanged(typed.Phase)
	WelcomeScreen.dismiss()
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
	-- Stocker pour la phase de délibération
	storedAccusation = typed.Accusation

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
	AudioController.play("Declaration")
	local fromName = payload.FromName
	local fieldValues = payload.FieldValues
	if type(fromName) == "string" and type(fieldValues) == "table" then
		local values = fieldValues :: { string }
		-- Stocker la déclaration pour la phase de délibération
		lastDeclarationText = table.concat(values, " · ")
		if payload.IsNpc == true then
			Toast.info("Le témoin a déposé sa déclaration.")
			task.delay(1, function()
				Toast.info(fromName .. " a dit : " .. lastDeclarationText)
			end)
		else
			Toast.info(fromName .. " : " .. lastDeclarationText)
		end
	end
end)

-- Contradiction détectée par le serveur — alerte subtile
Net.onClient(RemoteNames.ContradictionDetected, function(payload)
	local field = payload.Field
	if type(field) == "string" then
		AudioController.play("Contradiction")
		AudioController.flashContradiction()
		Toast.error("Une incohérence semble apparaître dans les déclarations…")
	end
end)

-- Réaction d'un autre joueur (broadcast)
Net.onClient(RemoteNames.ReactionBroadcast, function(payload)
	local reactionType = payload.ReactionType
	if type(reactionType) == "string" then
		-- Conserver les 3 dernières réactions pour la délibération en Duel
		table.insert(recentReactions, reactionType)
		if #recentReactions > 3 then
			table.remove(recentReactions, 1)
		end
		Toast.info("Réaction : " .. reactionType)
	end
end)

-- Verdict révélé — séquence dramatique M3.4 puis SummaryScreen
Net.onClient(RemoteNames.VerdictRevealed, function(payload)
	AudioController.play("VerdictReveal")
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

	-- Calculer correct/incorrect pour le Juré (avant la séquence — closure)
	local playerVote = VerdictScreen.getLastVote()
	local isCorrect: boolean? = nil
	if currentRole == "Juror" and playerVote ~= "" then
		local votedGuilty = playerVote == "Guilty"
		isCorrect = (votedGuilty and didLie) or (not votedGuilty and not didLie)
	end

	-- Masquer l'UI active (VerdictScreen pour les Jurés, etc.)
	hideAllPanels()

	-- Séquence dramatique (~1.7 s) puis ouverture du SummaryScreen
	VerdictSequence.play(verdict, function()
		SummaryScreen.show(
			caseTitle,
			truth,
			liarDecl,
			didLie,
			playerVote,
			isCorrect,
			currentRole,
			guiltyCount,
			twist,
			verdict
		)
	end)
end)

-- Récompenses attribuées — met à jour SummaryScreen et affiche un toast
Net.onClient(RemoteNames.RewardGranted, function(payload)
	local jetons = payload.Jetons
	if type(jetons) == "number" and jetons > 0 then
		AudioController.play("Reward")
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
		currentJetons = jetons
		ProfilePanel.update(jetons, rang, perspicacite)
		if type(rangPrec) == "string" then
			Toast.success("Nouveau rang atteint : " .. rang .. " !")
		end
	end
	-- Appliquer le cadre équipé (envoyé à la connexion et après chaque achat)
	if type(payload.EquippedFrame) == "string" then
		ProfilePanel.setFrame(payload.EquippedFrame :: string)
	else
		ProfilePanel.setFrame(nil)
	end
end)

-- Données boutique reçues du serveur (à l'ouverture ou après achat/équipement)
Net.onClient(RemoteNames.ShopDataReceived, function(payload)
	local items = payload.Items
	if type(items) == "table" then
		ShopScreen.updateItems(items :: { { [string]: any } }, currentJetons)
	end
end)

-- Résultat d'un achat
Net.onClient(RemoteNames.ShopPurchaseResult, function(payload)
	local message = payload.Message
	if type(message) == "string" then
		if payload.Success == true then
			Toast.success(message)
		else
			Toast.error(message)
		end
	end
end)

-- Résultat d'un équipement
Net.onClient(RemoteNames.ShopEquipResult, function(payload)
	if payload.Success == true then
		local slot = payload.Slot
		local itemId = payload.ItemId
		if type(slot) == "string" and slot == "frame" and type(itemId) == "string" then
			ProfilePanel.setFrame(itemId :: string)
		end
	end
end)

-- Onboarding first-time : affiché si le serveur indique HasSeen = false
Net.onClient(RemoteNames.OnboardingStatus, function(payload)
	local hasSeen = payload.HasSeen
	if type(hasSeen) == "boolean" and not hasSeen then
		OnboardingScreen.show(function()
			Net.getEvent(RemoteNames.OnboardingCompleted):FireServer({})
		end)
	end
end)

print("[Client] The Witness Box v1.7 — UI prête")
