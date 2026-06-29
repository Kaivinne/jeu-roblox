--!strict
-- Orchestre le cycle de vie d'une partie.
-- Valide toutes les actions client avant traitement.
-- Le client n'a aucun accès direct à l'état du match.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Types = require(Shared.Types)
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)

local Server = script.Parent.Parent
local MatchStateMachine = require(Server.MatchStateMachine)
local RoleService = require(Server.services.RoleService)
local CaseService = require(Server.services.CaseService)
local NPCService = require(Server.services.NPCService)
local RewardService = require(Server.services.RewardService)
local AnalyticsService = require(Server.services.AnalyticsService)
local WorldBuilder = require(Server.services.WorldBuilder)

local MatchService = {}

local state: Types.MatchState = {
	MatchId = "",
	Phase = "Lobby",
	Format = "Duel",
	CaseId = "",
	PlayerRoles = {},
	Votes = {},
	Declarations = {},
	NpcIsLiar = false,
	PhaseStartedAt = 0,
	PhaseTimer = nil,
}

local function newMatchId(): string
	return tostring(math.floor(tick())) .. "_" .. tostring(math.random(1000, 9999))
end

local function selectFormat(count: number): Types.GameFormat
	if count <= 1 then
		return "Solo"
	elseif count == 2 then
		return "Duel"
	elseif count <= 4 then
		return "Mini"
	else
		return "Full"
	end
end

local ROLE_OBJECTIVES: { [string]: string } = {
	HonestWitness = "Déclarez la vérité sur votre alibi. Votre crédibilité doit convaincre les jurés.",
	Liar = "Mentez sans vous trahir. Une seule incohérence peut vous démasquer.",
	Prosecutor = "Questionnez les déclarations. Repérez les contradictions et guidez les jurés.",
	Defense = "Défendez l'accusé. Semez le doute et protégez son alibi.",
	Juror = "Écoutez attentivement la déclaration. Votez COUPABLE si vous pensez que le témoin ment.",
}

local function getRoleObjective(role: Types.PlayerRole?): string
	if role == nil then
		return ""
	end
	return ROLE_OBJECTIVES[role] or ""
end

-- Synchro du timer côté client toutes les N secondes pendant les phases actives
local function startTimerSync(capturedPhase: Types.MatchPhase, duration: number)
	task.spawn(function()
		local interval = Config.TimerSyncIntervalSeconds
		local elapsed = 0
		while elapsed < duration and state.Phase == capturedPhase do
			task.wait(interval)
			elapsed += interval
			if state.Phase == capturedPhase then
				Net.broadcast(RemoteNames.TimerSync, {
					TimeLeft = math.max(0, duration - elapsed),
				})
			end
		end
	end)
end

-- Calcule le verdict et le diffuse avec la révélation de la vérité
local function computeAndBroadcastVerdict()
	local guiltyCount = 0
	local innocentCount = 0
	for userId, vote in pairs(state.Votes) do
		if state.PlayerRoles[userId] == "Juror" then
			if vote == "Guilty" then
				guiltyCount += 1
			else
				innocentCount += 1
			end
		end
	end
	local verdict: Types.VerdictValue = if guiltyCount > innocentCount then "Guilty" else "Innocent"

	local case = CaseService.getCase()
	local truthText = CaseService.getTruthText(case)

	local liarUserId: number = 0
	local liarLied = false
	local liarFieldValues: { string } = {}

	-- Chercher un Menteur humain dans les rôles
	for userId, role in pairs(state.PlayerRoles) do
		if role == "Liar" then
			liarUserId = userId
			local decl = state.Declarations[userId]
			if decl then
				local contradictions = CaseService.findContradictions(case, decl)
				liarLied = #contradictions > 0
				liarFieldValues = CaseService.getDeclarationText(case, decl)
			end
			break
		end
	end

	-- Mode Solo : le NPC joue le rôle de témoin
	if state.Format == "Solo" then
		local npcDecl = state.Declarations[NPCService.NPC_USER_ID]
		if npcDecl then
			local contradictions = CaseService.findContradictions(case, npcDecl)
			liarLied = #contradictions > 0
			liarFieldValues = CaseService.getDeclarationText(case, npcDecl)
		else
			-- Le NPC n'a pas encore déclaré (phase trop courte) — utiliser l'intention
			liarLied = state.NpcIsLiar
		end
	end

	Net.broadcast(RemoteNames.VerdictRevealed, {
		Verdict = verdict,
		GuiltyCount = guiltyCount,
		CaseTitle = case.Title,
		TruthSummary = truthText,
		LiarUserId = liarUserId,
		LiarLied = liarLied,
		LiarDeclaration = liarFieldValues,
		NpcName = NPCService.NPC_NAME,
		Twist = case.Twist,
	})

	print(
		string.format(
			"[MatchService] Verdict: %s (%d coupable / %d innocent) — Témoin a menti: %s",
			verdict,
			guiltyCount,
			innocentCount,
			tostring(liarLied)
		)
	)

	-- Calculer quels Jurés ont voté correctement pour les récompenses
	local correctJurors: { [number]: boolean } = {}
	for userId, vote in pairs(state.Votes) do
		if state.PlayerRoles[userId] == "Juror" then
			local votedGuilty = vote == "Guilty"
			correctJurors[userId] = (votedGuilty and liarLied) or (not votedGuilty and not liarLied)
		end
	end
	RewardService.grantPostVerdict(Players:GetPlayers(), state.PlayerRoles, correctJurors)

	AnalyticsService.track(nil, "VerdictRevealed", {
		matchId = state.MatchId,
		caseId = state.CaseId,
		difficulty = case.Difficulty,
		theme = case.Theme,
		format = state.Format,
		verdict = tostring(verdict),
		guiltyCount = guiltyCount,
		innocentCount = innocentCount,
		liarLied = liarLied,
	})
	AnalyticsService.track(nil, "MatchCompleted", {
		matchId = state.MatchId,
		caseId = state.CaseId,
		difficulty = case.Difficulty,
		theme = case.Theme,
		format = state.Format,
	})
end

local function scheduleNextPhase(phase: Types.MatchPhase, duration: number)
	state.PhaseTimer = task.delay(duration, function()
		local next = MatchStateMachine.nextPhase(phase)
		if next then
			MatchService.transitionTo(next)
		end
	end)
end

function MatchService.transitionTo(newPhase: Types.MatchPhase)
	if not MatchStateMachine.canTransition(state.Phase, newPhase) then
		warn("[MatchService] Transition invalide:", state.Phase, "→", newPhase)
		return
	end

	local oldPhase = state.Phase

	if state.PhaseTimer then
		task.cancel(state.PhaseTimer)
		state.PhaseTimer = nil
	end

	-- Préparer le nouvel état avant le broadcast
	if newPhase == "Matchmaking" then
		state.MatchId = newMatchId()
		state.Format = selectFormat(#Players:GetPlayers())
		state.CaseId = CaseService.selectForMatch()
		state.Votes = {}
		state.Declarations = {}
		state.NpcIsLiar = false
	elseif newPhase == "Lobby" then
		-- Ramener tous les joueurs à la galerie avant de réinitialiser l'état
		local lobbyTarget = WorldBuilder.getLobbySpawnCFrame()
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				char:PivotTo(lobbyTarget)
			end
		end
		state.PlayerRoles = {}
		state.Votes = {}
		state.Declarations = {}
		state.NpcIsLiar = false
		state.MatchId = ""
		state.CaseId = ""
	end

	-- Avertir les Jurés qui n'ont pas voté avant de passer en PostVerdict
	if newPhase == "PostVerdict" then
		for _, player in ipairs(Players:GetPlayers()) do
			if state.PlayerRoles[player.UserId] == "Juror" and not state.Votes[player.UserId] then
				Net.fire(player, RemoteNames.ActionRejected, {
					Message = "Temps écoulé — vous n'avez pas voté. Votre voix n'est pas comptabilisée.",
				})
			end
		end
	end

	state.Phase = newPhase
	state.PhaseStartedAt = tick()

	local duration = Config.PhaseDuration[newPhase] or 30
	-- Durée de délibération adaptée au format pour éviter l'attente passive
	if newPhase == "Deliberation" then
		if state.Format == "Solo" then
			duration = 20
		elseif state.Format == "Duel" then
			duration = 25
			-- Mini et Full conservent la durée Config (45s)
		end
	end
	local playerCount = #Players:GetPlayers()

	Net.broadcast(RemoteNames.GamePhaseChanged, {
		Phase = newPhase,
		Duration = duration,
		MatchId = state.MatchId,
		Format = state.Format,
		PlayerCount = playerCount,
	})

	print(
		string.format(
			"[MatchService] %s → %s (%ds | %s | %d joueur(s))",
			oldPhase,
			newPhase,
			duration,
			state.Format,
			playerCount
		)
	)

	AnalyticsService.track(nil, "PhaseChanged", {
		matchId = state.MatchId,
		from = oldPhase,
		to = newPhase,
		format = state.Format,
		playerCount = playerCount,
	})

	-- Actions spécifiques post-broadcast
	if newPhase == "Matchmaking" then
		local players = Players:GetPlayers()
		state.PlayerRoles = RoleService.assignForMatch(players, state.Format)
		-- Mode Solo : décider si le NPC mentira avant le début du témoignage
		if state.Format == "Solo" then
			state.NpcIsLiar = NPCService.decideLie()
			print(
				string.format(
					"[MatchService] Solo — NPC %s : %s",
					NPCService.NPC_NAME,
					if state.NpcIsLiar then "Menteur" else "Honnête"
				)
			)
		end
		print(string.format("[MatchService] Match %s | %d joueur(s)", state.MatchId, #players))
		RoleService.broadcastRoles(players, state.PlayerRoles, state.MatchId)
		local activeCase = CaseService.getCase()
		AnalyticsService.track(nil, "MatchStarted", {
			matchId = state.MatchId,
			format = state.Format,
			caseId = state.CaseId,
			difficulty = activeCase.Difficulty,
			theme = activeCase.Theme,
			playerCount = #players,
		})
	elseif newPhase == "Intro" then
		-- Téléporter chaque joueur à son siège de rôle (jurorIndex pour les Jurés)
		local jurorCount = 0
		for _, player in ipairs(Players:GetPlayers()) do
			local role = state.PlayerRoles[player.UserId]
			if role then
				local char = player.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					local idx: number? = nil
					if role == "Juror" then
						jurorCount += 1
						idx = jurorCount
					end
					char:PivotTo(WorldBuilder.getRoleSpawnCFrame(tostring(role), idx))
				end
			end
		end
		-- Envoyer les données de l'affaire à chaque joueur selon son rôle
		local case = CaseService.getCase()
		local clientFields = CaseService.getClientFields(case)
		local truthGuide = CaseService.getTruthGuide(case)
		local players = Players:GetPlayers()
		print("[MatchService] Affaire :", case.Title)
		for _, player in ipairs(players) do
			local role = state.PlayerRoles[player.UserId]
			local guide: { [string]: number }? = nil
			local liarHint: string? = nil
			if role == "HonestWitness" then
				guide = truthGuide
			elseif role == "Liar" then
				guide = truthGuide
				liarHint = case.LiarHint
			end
			Net.fire(player, RemoteNames.CaseIntroReceived, {
				CaseId = case.Id,
				Title = case.Title,
				Summary = case.Summary,
				Accusation = case.Accusation,
				Fields = clientFields,
				RoleObjective = getRoleObjective(role),
				TruthGuide = guide,
				LiarHint = liarHint,
				Difficulty = case.Difficulty,
				Theme = case.Theme,
			})
			AnalyticsService.track(player, "CaseIntroShown", {
				matchId = state.MatchId,
				caseId = case.Id,
				difficulty = case.Difficulty,
				theme = case.Theme,
				role = tostring(role),
			})
		end
	elseif newPhase == "Testimony" then
		startTimerSync(newPhase, duration)
		-- Mode Solo : déclaration automatique du NPC après un délai aléatoire
		if state.Format == "Solo" then
			local capturedPhase = newPhase
			local npcDelay = math.random(5, 12)
			task.delay(npcDelay, function()
				if state.Phase ~= capturedPhase then
					return
				end
				local npcDecl = CaseService.buildNpcDeclaration(state.NpcIsLiar)
				state.Declarations[NPCService.NPC_USER_ID] = npcDecl
				local currentCase = CaseService.getCase()
				local fieldValues = CaseService.getDeclarationText(currentCase, npcDecl)
				print(
					string.format(
						"[MatchService] NPC déclare (%s) : %s",
						if state.NpcIsLiar then "Menteur" else "Honnête",
						table.concat(fieldValues, " · ")
					)
				)
				Net.broadcast(RemoteNames.DeclarationBroadcast, {
					FromName = NPCService.NPC_NAME,
					FieldValues = fieldValues,
					IsNpc = true,
				})
				local contradictions = CaseService.findContradictions(currentCase, npcDecl)
				if #contradictions > 0 then
					print("[MatchService] NPC contradiction : " .. table.concat(contradictions, ", "))
					AnalyticsService.track(nil, "ContradictionDetected", {
						matchId = state.MatchId,
						caseId = state.CaseId,
						difficulty = currentCase.Difficulty,
						theme = currentCase.Theme,
						field = contradictions[1],
						isNpc = true,
					})
					local contraKey = contradictions[1]
					local contraLabel = contraKey
					local contraDeclared = "?"
					for _, f in ipairs(CaseService.getClientFields(currentCase)) do
						if f.Key == contraKey then
							contraLabel = f.Label
							local idx = npcDecl[contraKey]
							if idx ~= nil then
								local opt = f.Options[idx]
								if opt ~= nil then
									contraDeclared = opt
								end
							end
							break
						end
					end
					Net.broadcast(RemoteNames.ContradictionDetected, {
						Field = contraKey,
						FieldLabel = contraLabel,
						DeclaredValue = contraDeclared,
						Explanation = "Ce champ contredit les faits établis.",
					})
				end
			end)
		end
	elseif newPhase == "Deliberation" or newPhase == "Verdict" then
		startTimerSync(newPhase, duration)
	elseif newPhase == "PostVerdict" then
		computeAndBroadcastVerdict()
	end

	-- Programmer la prochaine transition automatique
	if newPhase == "Cleanup" then
		state.PhaseTimer = task.delay(duration, function()
			MatchService.transitionTo("Lobby")
		end)
	elseif newPhase ~= "Lobby" then
		scheduleNextPhase(newPhase, duration)
	end
end

function MatchService.startMatch()
	if state.Phase ~= "Lobby" then
		warn("[MatchService] startMatch() ignoré — phase:", state.Phase)
		return
	end
	MatchService.transitionTo("Matchmaking")
end

function MatchService.getPublicState(): {
	Phase: Types.MatchPhase,
	Format: Types.GameFormat,
	MatchId: string,
}
	return { Phase = state.Phase, Format = state.Format, MatchId = state.MatchId }
end

local function rejectAction(player: Player, reason: string)
	Net.fire(player, RemoteNames.ActionRejected, { Message = reason })
	warn(string.format("[MatchService] Action refusée [%s] : %s", player.DisplayName, reason))
end

function MatchService.init()
	Net.getFunction(RemoteNames.GetCurrentMatchState).OnServerInvoke = function(_player: Player)
		return MatchService.getPublicState()
	end

	-- Déclaration : acceptée uniquement en Testimony pour les témoins humains
	Net.onServer(RemoteNames.DeclarationSubmitted, function(player, payload)
		if state.Phase ~= "Testimony" then
			rejectAction(player, "Déclaration hors phase de témoignage")
			return
		end
		local role = state.PlayerRoles[player.UserId]
		if role ~= "HonestWitness" and role ~= "Liar" then
			rejectAction(player, "Seuls les témoins soumettent des déclarations")
			return
		end
		if state.Declarations[player.UserId] then
			rejectAction(player, "Vous avez déjà déclaré")
			return
		end
		local fields = payload.Fields
		if type(fields) ~= "table" then
			rejectAction(player, "Déclaration invalide")
			return
		end
		local fieldSelections = fields :: { [string]: number }

		state.Declarations[player.UserId] = fieldSelections

		local case = CaseService.getCase()
		local fieldValues = CaseService.getDeclarationText(case, fieldSelections)

		print(
			string.format(
				"[MatchService] Déclaration de %s (%s) : %s",
				player.DisplayName,
				tostring(role),
				table.concat(fieldValues, " · ")
			)
		)

		AnalyticsService.track(player, "DeclarationSubmitted", {
			matchId = state.MatchId,
			caseId = state.CaseId,
			difficulty = case.Difficulty,
			theme = case.Theme,
			role = tostring(role),
		})

		Net.broadcast(RemoteNames.DeclarationBroadcast, {
			FromName = player.DisplayName,
			FieldValues = fieldValues,
		})

		local contradictions = CaseService.findContradictions(case, fieldSelections)
		if #contradictions > 0 then
			print(
				string.format(
					"[MatchService] Contradiction chez %s : champ(s) %s",
					player.DisplayName,
					table.concat(contradictions, ", ")
				)
			)
			AnalyticsService.track(player, "ContradictionDetected", {
				matchId = state.MatchId,
				caseId = state.CaseId,
				difficulty = case.Difficulty,
				theme = case.Theme,
				field = contradictions[1],
			})
			local contraKey = contradictions[1]
			local contraLabel = contraKey
			local contraDeclared = "?"
			for _, f in ipairs(CaseService.getClientFields(case)) do
				if f.Key == contraKey then
					contraLabel = f.Label
					local idx = fieldSelections[contraKey]
					if idx ~= nil then
						local opt = f.Options[idx]
						if opt ~= nil then
							contraDeclared = opt
						end
					end
					break
				end
			end
			Net.broadcast(RemoteNames.ContradictionDetected, {
				Field = contraKey,
				FieldLabel = contraLabel,
				DeclaredValue = contraDeclared,
				Explanation = "Ce champ contredit les faits établis.",
			})
		end
	end)

	-- Réaction : acceptée uniquement en Testimony pour les observateurs
	Net.onServer(RemoteNames.ReactionSent, function(player, payload)
		if state.Phase ~= "Testimony" then
			rejectAction(player, "Réaction hors phase de témoignage")
			return
		end
		local role = state.PlayerRoles[player.UserId]
		if role ~= "Juror" and role ~= "Prosecutor" and role ~= "Defense" then
			rejectAction(player, "Rôle non autorisé à réagir")
			return
		end
		local reactionType = tostring(payload.ReactionType or "")
		print(
			string.format(
				"[MatchService] Réaction de %s (%s) : %s",
				player.DisplayName,
				tostring(role),
				reactionType
			)
		)
		Net.broadcast(RemoteNames.ReactionBroadcast, {
			FromUserId = player.UserId,
			ReactionType = reactionType,
		})
	end)

	-- Vote : accepté uniquement en Verdict pour les Jurés
	Net.onServer(RemoteNames.VoteCast, function(player, payload)
		if state.Phase ~= "Verdict" then
			rejectAction(player, "Vote hors phase de verdict")
			return
		end
		local role = state.PlayerRoles[player.UserId]
		if role ~= "Juror" then
			rejectAction(player, "Seuls les jurés votent")
			return
		end
		if state.Votes[player.UserId] then
			rejectAction(player, "Vous avez déjà voté")
			return
		end
		local vote = payload.Vote
		if vote ~= "Guilty" and vote ~= "Innocent" then
			rejectAction(player, "Valeur de vote invalide")
			return
		end
		state.Votes[player.UserId] = vote :: Types.VerdictValue
		print(string.format("[MatchService] Vote de %s : %s", player.DisplayName, tostring(vote)))
		AnalyticsService.track(player, "VerdictSubmitted", {
			matchId = state.MatchId,
			vote = tostring(vote),
		})
	end)

	-- Objection : fonctionnalité Phase 2
	Net.onServer(RemoteNames.ObjectionRaised, function(player, _payload)
		rejectAction(player, "Les objections arrivent en Phase 2")
	end)

	-- Auto-démarrage quand le seuil Duel est atteint
	Players.PlayerAdded:Connect(function(_player)
		-- Le profil initial est poussé par PlayerDataService après chargement DataStore
		if state.Phase == "Lobby" and #Players:GetPlayers() >= Config.Format.Duel.Min then
			task.delay(Config.PhaseDuration.Lobby, function()
				if state.Phase == "Lobby" then
					MatchService.startMatch()
				end
			end)
		end
	end)

	-- Déconnexion pendant une partie : nettoyage et arrêt si plus de joueurs réels
	Players.PlayerRemoving:Connect(function(player)
		if not MatchStateMachine.isActivePhase(state.Phase) then
			return
		end
		state.PlayerRoles[player.UserId] = nil
		state.Votes[player.UserId] = nil
		state.Declarations[player.UserId] = nil
		print(string.format("[MatchService] %s a quitté en phase %s", player.DisplayName, state.Phase))
		AnalyticsService.track(player, "PlayerLeftMidMatch", {
			matchId = state.MatchId,
			phase = state.Phase,
			format = state.Format,
		})
		-- Compter les joueurs humains restants (UserId > 0)
		local realPlayers = 0
		for userId in pairs(state.PlayerRoles) do
			if userId > 0 then
				realPlayers += 1
			end
		end
		if realPlayers == 0 then
			print("[MatchService] Plus de joueurs — abandon de la partie, retour au Lobby")
			if state.PhaseTimer then
				task.cancel(state.PhaseTimer)
				state.PhaseTimer = nil
			end
			-- Réinitialisation directe (contournement volontaire de la state machine)
			state.Phase = "Lobby"
			state.PlayerRoles = {}
			state.Votes = {}
			state.Declarations = {}
			state.NpcIsLiar = false
			state.MatchId = ""
			state.CaseId = ""
			state.PhaseStartedAt = tick()
		end
	end)

	-- Mode Studio : démarrage forcé pour tests rapides
	if RunService:IsStudio() then
		task.delay(5, function()
			if state.Phase == "Lobby" and #Players:GetPlayers() >= 1 then
				print("[MatchService] Studio : démarrage forcé")
				MatchService.startMatch()
			end
		end)
	end

	print("[MatchService] Initialisé")
end

return MatchService
