--!strict
-- Gestion audio côté client — M4.4 Full Audio Integration.
-- Bibliothèque sonore complète avec IDs validés, SoundGroups par catégorie,
-- ambiances par phase, couche environnement en loop, anti-spam par cooldown.
--
-- Pour déclencher un son depuis n'importe quel module :
--   AudioController.play("nom_du_son")   → one-shot, respecte le cooldown
-- Pour ajouter un son : l'inscrire dans SOUNDS avec son groupe.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local AudioController = {}

-- ─── SoundGroups — volumes de catégorie ───────────────────────────────────────
-- Multiplicateur 0–10 ; 1.0 = neutre. Ajustables en Studio sans toucher au code.

local GROUP_VOLUMES: { [string]: number } = {
	Cinematic = 1.2, -- verdict, transitions — légèrement au-dessus
	Gameplay = 1.0,
	UI = 0.9, -- discret, jamais intrusif
	Environment = 0.6, -- couche de fond très subtile
	Ambience = 0.8, -- musique de fond
}

-- ─── Type des sons ────────────────────────────────────────────────────────────

type SoundCfg = {
	id: string,
	vol: number,
	pitch: number,
	group: string,
	looped: boolean?,
}

-- ─── Registre complet des sons — IDs validés ─────────────────────────────────
-- Les sons marqués looped=true sont gérés par le système d'environnement (PHASE_ENV).
-- Ne pas les appeler via play() manuellement.

local SOUNDS: { [string]: SoundCfg } = {

	-- ── Verdict ──────────────────────────────────────────────────────────────
	gavel_hit = { id = "rbxassetid://9125573844", vol = 0.55, pitch = 1.00, group = "Cinematic" },
	verdict_boom = { id = "rbxassetid://9044820101", vol = 0.60, pitch = 0.95, group = "Cinematic" },
	innocent_reveal = { id = "rbxassetid://1840544226", vol = 0.50, pitch = 1.00, group = "Cinematic" },
	guilty_reveal = { id = "rbxassetid://1845391028", vol = 0.50, pitch = 1.00, group = "Cinematic" },

	-- ── Documents ────────────────────────────────────────────────────────────
	paper_slide = { id = "rbxassetid://104817397163339", vol = 0.30, pitch = 1.10, group = "Gameplay" },
	page_turn = { id = "rbxassetid://95995953662374", vol = 0.25, pitch = 1.00, group = "Gameplay" },
	pen_write = { id = "rbxassetid://9117286829", vol = 0.20, pitch = 1.05, group = "Gameplay" },
	paper_drop = { id = "rbxassetid://9125721539", vol = 0.25, pitch = 0.95, group = "Gameplay" },

	-- ── Gameplay ─────────────────────────────────────────────────────────────
	vote = { id = "rbxassetid://6340682595", vol = 0.30, pitch = 1.00, group = "Gameplay" },
	contradiction = { id = "rbxassetid://1835537345", vol = 0.50, pitch = 0.80, group = "Gameplay" },
	countdown = { id = "rbxassetid://6238869231", vol = 0.28, pitch = 1.00, group = "Gameplay" },
	timer_end = { id = "rbxassetid://99851942666647", vol = 0.40, pitch = 1.00, group = "Gameplay" },
	reaction = { id = "rbxassetid://9125479599", vol = 0.20, pitch = 1.00, group = "Gameplay" },

	-- ── UI ───────────────────────────────────────────────────────────────────
	ui_click = { id = "rbxassetid://139719503904449", vol = 0.30, pitch = 1.00, group = "UI" },
	ui_hover = { id = "rbxassetid://139800881181209", vol = 0.15, pitch = 1.00, group = "UI" },
	ui_confirm = { id = "rbxassetid://85240253037283", vol = 0.35, pitch = 1.00, group = "UI" },
	ui_cancel = { id = "rbxassetid://122125495508907", vol = 0.28, pitch = 1.00, group = "UI" },
	ui_notification = { id = "rbxassetid://8486683243", vol = 0.32, pitch = 1.00, group = "UI" },

	-- ── Récompenses ──────────────────────────────────────────────────────────
	coin_collect = { id = "rbxassetid://80977935658780", vol = 0.42, pitch = 1.00, group = "Gameplay" },
	level_up = { id = "rbxassetid://127199850989931", vol = 0.50, pitch = 1.00, group = "Gameplay" },
	achievement_unlock = {
		id = "rbxassetid://93360393539898",
		vol = 0.45,
		pitch = 1.00,
		group = "Gameplay",
	},
	cash_register = {
		id = "rbxassetid://134810204798705",
		vol = 0.38,
		pitch = 1.00,
		group = "Gameplay",
	},

	-- ── Boutique ─────────────────────────────────────────────────────────────
	purchase_success = { id = "rbxassetid://122766504688172", vol = 0.45, pitch = 1.00, group = "UI" },
	purchase_failed = { id = "rbxassetid://106796270505945", vol = 0.38, pitch = 1.00, group = "UI" },
	equip_item = { id = "rbxassetid://125373488678088", vol = 0.38, pitch = 1.05, group = "UI" },
	unlock_item = { id = "rbxassetid://873617644", vol = 0.42, pitch = 1.00, group = "UI" },

	-- ── Cinématique ──────────────────────────────────────────────────────────
	whoosh = { id = "rbxassetid://138890894929151", vol = 0.50, pitch = 1.00, group = "Cinematic" },
	cinematic_hit = {
		id = "rbxassetid://140315087663767",
		vol = 0.45,
		pitch = 1.00,
		group = "Cinematic",
	},
	riser = { id = "rbxassetid://1843027982", vol = 0.40, pitch = 1.00, group = "Cinematic" },
	transition_sweep = {
		id = "rbxassetid://131621553321105",
		vol = 0.38,
		pitch = 1.00,
		group = "Cinematic",
	},
	heartbeat = { id = "rbxassetid://135454814111440", vol = 0.25, pitch = 1.00, group = "Cinematic" },

	-- ── Environnement (one-shot) ──────────────────────────────────────────────
	door_open = {
		id = "rbxassetid://138380478466241",
		vol = 0.35,
		pitch = 1.00,
		group = "Environment",
	},
	door_close = {
		id = "rbxassetid://136038446613189",
		vol = 0.32,
		pitch = 1.00,
		group = "Environment",
	},
	footsteps_wood = {
		id = "rbxassetid://137526436035209",
		vol = 0.28,
		pitch = 1.00,
		group = "Environment",
	},
	chair_move = { id = "rbxassetid://9125759795", vol = 0.25, pitch = 1.00, group = "Environment" },
	chair_sit = { id = "rbxassetid://9120806410", vol = 0.22, pitch = 1.00, group = "Environment" },
	crowd_gasp = {
		id = "rbxassetid://114951608300912",
		vol = 0.40,
		pitch = 1.00,
		group = "Environment",
	},
	crowd_applause = {
		id = "rbxassetid://17844638663",
		vol = 0.35,
		pitch = 1.00,
		group = "Environment",
	},
	clock_chime = {
		id = "rbxassetid://131294162478945",
		vol = 0.30,
		pitch = 1.00,
		group = "Environment",
	},

	-- ── Environnement (loop — gérés par PHASE_ENV) ────────────────────────────
	crowd_murmur = {
		id = "rbxassetid://9114012248",
		vol = 0.12,
		pitch = 1.00,
		group = "Environment",
		looped = true,
	},
	clock_tick = {
		id = "rbxassetid://128707491647978",
		vol = 0.08,
		pitch = 1.00,
		group = "Environment",
		looped = true,
	},
	wind_ambience = {
		id = "rbxassetid://93035214379043",
		vol = 0.08,
		pitch = 1.00,
		group = "Environment",
		looped = true,
	},
	rain_window = {
		id = "rbxassetid://9112857056",
		vol = 0.10,
		pitch = 1.00,
		group = "Environment",
		looped = true,
	},
}

-- ─── Ambiances musicales par phase (crossfade) ────────────────────────────────
-- Une piste de fond par phase. Fondu croisé de 0.8 s entre les phases.

type AmbientCfg = { id: string, vol: number }

local PHASE_AMBIENT: { [string]: AmbientCfg } = {
	Lobby = { id = "rbxassetid://9112753600", vol = 0.05 },
	Matchmaking = { id = "rbxassetid://9112753600", vol = 0.04 },
	Intro = { id = "rbxassetid://9046799798", vol = 0.06 },
	Testimony = { id = "rbxassetid://1836167172", vol = 0.07 },
	Deliberation = { id = "rbxassetid://1837911337", vol = 0.05 },
	Verdict = { id = "rbxassetid://1846491568", vol = 0.08 },
	PostVerdict = { id = "rbxassetid://9112753600", vol = 0.04 },
	Cleanup = { id = "rbxassetid://9112753600", vol = 0.03 },
}

-- ─── Couche d'environnement par phase ────────────────────────────────────────
-- Sons en loop démarrés/arrêtés lors des changements de phase.
-- Les sons partagés entre deux phases adjacentes ne sont pas interrompus.

local PHASE_ENV: { [string]: { string } } = {
	Lobby = { "crowd_murmur" },
	Matchmaking = { "crowd_murmur" },
	Intro = { "crowd_murmur", "clock_tick" },
	Testimony = { "clock_tick" },
	Deliberation = { "crowd_murmur", "clock_tick" },
	Verdict = { "crowd_murmur" },
	PostVerdict = { "crowd_murmur" },
	Cleanup = {},
}

-- ─── Anti-spam : cooldowns par son (secondes) ─────────────────────────────────

local COOLDOWN: { [string]: number } = {
	ui_hover = 0.08,
	ui_click = 0.05,
	ui_confirm = 0.20,
	reaction = 0.15,
	contradiction = 1.00,
	countdown = 0.90,
	footsteps_wood = 0.25,
}

-- ─── MaxDistance par son spatialisé (studs) ───────────────────────────────────
-- Sons non listés ici → MaxDistance 40 par défaut dans playAtAnchor.

local SPATIAL_MAX_DIST: { [string]: number } = {
	door_open = 38,
	door_close = 38,
	footsteps_wood = 22,
	chair_move = 18,
	chair_sit = 18,
	gavel_hit = 60,
	crowd_murmur = 55,
	clock_tick = 42,
}

-- Sons en loop dont la source 3D est une ancre permanente dans workspace.Courthouse.
-- Listés ici → Sound parenté à l'ancre au lieu de SoundService (spatial réel).
local LOOP_ANCHOR: { [string]: string } = {
	crowd_murmur = "AudioAnchor_Gallery",
	clock_tick = "AudioAnchor_Clock",
}

-- ─── Paramètres de fondu d'ambiance ──────────────────────────────────────────

local FADE_OUT = 0.80
local FADE_IN = 0.80

-- ─── État interne ─────────────────────────────────────────────────────────────

local sounds: { [string]: Sound } = {}
local _groups: { [string]: SoundGroup } = {}
local activeAmbient: Sound? = nil
local flashFrame: Frame? = nil
local _ambientTask: thread? = nil
local _currentTween: Tween? = nil
local _currentPhase: string = ""
local _lastPlayTime: { [string]: number } = {}

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function canPlay(name: string): boolean
	local cd = COOLDOWN[name]
	if not cd or cd == 0 then
		return true
	end
	local now = tick()
	local last = _lastPlayTime[name]
	if last and (now - last) < cd then
		return false
	end
	_lastPlayTime[name] = now
	return true
end

local function findAnchor(anchorName: string): BasePart?
	local courthouse = workspace:FindFirstChild("Courthouse")
	if not courthouse then
		return nil
	end
	return courthouse:FindFirstChild(anchorName) :: BasePart?
end

local function cancelAmbientTransition()
	if _ambientTask then
		task.cancel(_ambientTask)
		_ambientTask = nil
	end
	if _currentTween then
		_currentTween:Cancel()
		_currentTween = nil
	end
end

local function crossfadeTo(cfg: AmbientCfg)
	local s = activeAmbient
	if not s then
		return
	end
	cancelAmbientTransition()
	_ambientTask = task.spawn(function()
		local twOut = TweenService:Create(
			s,
			TweenInfo.new(FADE_OUT, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Volume = 0 }
		)
		_currentTween = twOut
		twOut:Play()
		task.wait(FADE_OUT)
		pcall(function()
			s.SoundId = cfg.id
			s.Volume = 0
			s:Play()
		end)
		local twIn = TweenService:Create(
			s,
			TweenInfo.new(FADE_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Volume = cfg.vol }
		)
		_currentTween = twIn
		twIn:Play()
		task.wait(FADE_IN)
		_currentTween = nil
		_ambientTask = nil
	end)
end

-- Transition entre les couches d'environnement de deux phases.
-- Les sons partagés entre fromPhase et toPhase ne sont pas interrompus.
local function transitionEnvSounds(fromPhase: string, toPhase: string)
	local fromList = PHASE_ENV[fromPhase] or {}
	local toList = PHASE_ENV[toPhase] or {}

	local toSet: { [string]: boolean } = {}
	for _, name in ipairs(toList) do
		toSet[name] = true
	end

	for _, name in ipairs(fromList) do
		if not toSet[name] then
			local s = sounds[name]
			if s then
				pcall(function()
					s:Stop()
				end)
			end
		end
	end

	for _, name in ipairs(toList) do
		local s = sounds[name]
		if s and not s.IsPlaying then
			pcall(function()
				s:Play()
			end)
		end
	end
end

-- ─── API publique ─────────────────────────────────────────────────────────────

-- Initialise les SoundGroups, crée toutes les instances Sound, démarre l'ambiance Lobby.
-- Appelé une seule fois depuis init.client.
function AudioController.setup()
	-- SoundGroups par catégorie
	for name, vol in pairs(GROUP_VOLUMES) do
		local g = Instance.new("SoundGroup")
		g.Name = name
		g.Volume = vol
		g.Parent = SoundService
		_groups[name] = g
	end

	-- Instances Sound pour chaque entrée du registre
	for name, cfg in pairs(SOUNDS) do
		local s = Instance.new("Sound")
		s.SoundId = cfg.id
		s.Volume = cfg.vol
		s.PlaybackSpeed = cfg.pitch
		local grp = _groups[cfg.group]
		if grp then
			-- Assigner le SoundGroup pour le mixage par catégorie
			pcall(function()
				s.SoundGroup = grp
			end)
		end
		if cfg.looped then
			s.Looped = true
		end
		-- Sons en loop avec ancre : source spatiale permanente (crowd, horloge).
		-- Fallback SoundService si l'ancre n'existe pas encore (hot-reload Studio).
		local loopAnchorName = LOOP_ANCHOR[name]
		if cfg.looped and loopAnchorName then
			local anch = findAnchor(loopAnchorName)
			if anch then
				s.RollOffMode = Enum.RollOffMode.InverseTapered
				s.MaxDistance = SPATIAL_MAX_DIST[name] or 50
				s.Parent = anch
			else
				s.Parent = SoundService
			end
		else
			s.Parent = SoundService
		end
		sounds[name] = s
	end

	-- Ambiance initiale (Lobby)
	local initCfg = PHASE_AMBIENT.Lobby
	local amb = Instance.new("Sound")
	amb.SoundId = initCfg.id
	amb.Volume = initCfg.vol
	amb.Looped = true
	local ambGrp = _groups["Ambience"]
	if ambGrp then
		pcall(function()
			amb.SoundGroup = ambGrp
		end)
	end
	amb.Parent = SoundService
	activeAmbient = amb
	pcall(function()
		amb:Play()
	end)
	_currentPhase = "Lobby"

	-- Couche d'environnement initiale
	transitionEnvSounds("", "Lobby")

	-- Overlay de flash rouge (contradiction visuelle)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
	local screen = Instance.new("ScreenGui")
	screen.Name = "AudioFlashGui"
	screen.DisplayOrder = 98
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.Parent = playerGui
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.Parent = screen
	flashFrame = flash
end

-- Joue un son one-shot par nom. Silencieux si l'asset est invalide.
-- Respecte le cooldown anti-spam configuré dans COOLDOWN.
function AudioController.play(name: string)
	if not canPlay(name) then
		return
	end
	pcall(function()
		local s = sounds[name]
		if s then
			s:Play()
		end
	end)
end

-- Joue un son one-shot spatialisé depuis l'ancre nommée dans workspace.Courthouse.
-- Crée une Part temporaire, joue le son, puis détruit les deux après lecture.
-- Silencieux si l'ancre est absente — aucun effet sur le gameplay.
function AudioController.playAtAnchor(name: string, anchorName: string)
	if not canPlay(name) then
		return
	end
	local cfg = SOUNDS[name]
	if not cfg then
		return
	end
	local anchor = findAnchor(anchorName)
	if not anchor then
		return
	end
	local maxDist = SPATIAL_MAX_DIST[name] or 40
	pcall(function()
		local part = Instance.new("Part")
		part.Name = "AudioSpatial_" .. name
		part.Size = Vector3.new(0.1, 0.1, 0.1)
		part.CFrame = anchor.CFrame
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Parent = workspace:FindFirstChild("Courthouse") or workspace
		local s = Instance.new("Sound")
		s.SoundId = cfg.id
		s.Volume = cfg.vol
		s.PlaybackSpeed = cfg.pitch
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.MaxDistance = maxDist
		local grp = _groups[cfg.group]
		if grp then
			pcall(function()
				s.SoundGroup = grp
			end)
		end
		s.Parent = part
		s:Play()
		local cleaned = false
		local function doCleanup()
			if cleaned then
				return
			end
			cleaned = true
			pcall(function()
				part:Destroy()
			end)
		end
		s.Ended:Connect(doCleanup)
		task.delay(30, doCleanup)
	end)
end

-- Adapte l'ambiance musicale et la couche d'environnement à la phase de jeu.
-- Ignoré si la phase est identique à la courante.
function AudioController.onPhaseChanged(phase: string)
	if phase == _currentPhase then
		return
	end
	local prev = _currentPhase
	_currentPhase = phase

	-- SFX de transition pour les phases marquantes
	-- whoosh est géré par applyPhaseUI pour Intro — pas de doublon ici
	if phase == "Testimony" or phase == "Verdict" then
		AudioController.play("transition_sweep")
	end

	-- Sons spatialisés de scène — portes, pas, chaises, depuis les ancres WorldBuilder
	if phase == "Intro" then
		AudioController.playAtAnchor("door_open", "AudioAnchor_Door")
		task.delay(0.6, function()
			AudioController.playAtAnchor("footsteps_wood", "AudioAnchor_Aisle")
		end)
		task.delay(1.2, function()
			AudioController.playAtAnchor("chair_move", "AudioAnchor_Jury")
		end)
	elseif phase == "Testimony" then
		task.delay(0.3, function()
			AudioController.playAtAnchor("chair_sit", "AudioAnchor_Jury")
		end)
	elseif phase == "PostVerdict" then
		task.delay(1.0, function()
			AudioController.playAtAnchor("door_open", "AudioAnchor_Door")
		end)
	end

	-- Fondu croisé de l'ambiance musicale
	local cfg = PHASE_AMBIENT[phase]
	if cfg then
		crossfadeTo(cfg)
	end

	-- Transition de la couche environnement
	transitionEnvSounds(prev, phase)
end

-- Flash rouge bref (feedback visuel contradiction).
function AudioController.flashContradiction()
	local flash = flashFrame
	if not flash then
		return
	end
	TweenService:Create(flash, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
		BackgroundTransparency = 0.50,
	}):Play()
	task.delay(0.08, function()
		TweenService:Create(flash, TweenInfo.new(0.50, Enum.EasingStyle.Quad), {
			BackgroundTransparency = 1,
		}):Play()
	end)
end

-- Active ou suspend l'ambiance sonore avec fondu.
function AudioController.setAmbientEnabled(enabled: boolean)
	local s = activeAmbient
	if not s then
		return
	end
	cancelAmbientTransition()
	if enabled then
		local cfg = PHASE_AMBIENT[_currentPhase]
		local targetVol: number = if cfg then cfg.vol else 0.05
		pcall(function()
			s:Play()
		end)
		local tw =
			TweenService:Create(s, TweenInfo.new(FADE_IN, Enum.EasingStyle.Quad), { Volume = targetVol })
		_currentTween = tw
		tw:Play()
	else
		local tw = TweenService:Create(s, TweenInfo.new(FADE_OUT, Enum.EasingStyle.Quad), { Volume = 0 })
		_currentTween = tw
		tw:Play()
		task.delay(FADE_OUT, function()
			pcall(function()
				s:Pause()
			end)
		end)
	end
end

return AudioController
