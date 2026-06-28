--!strict
-- Construit la salle d'audience Roblox par code au démarrage du serveur.
-- Toute la géométrie est créée programmatiquement pour la compatibilité Rojo.
-- M2.3 : sièges nommés par rôle, signalétique, détails blockout.
-- M3.3 : ambiance dramatique — matériaux, éclairage ciblé, vitraux, faisceaux,
--        particules de poussière, ColorCorrectionEffect, BloomEffect, Atmosphere.
-- M3.6 : zone lobby — pupitre d'accueil, signalétique étendue, éclairage d'entrée.

local WorldBuilder = {}

-- ─── Palette ──────────────────────────────────────────────────────────────────

local C = {
	Floor = Color3.fromRGB(38, 26, 16),
	Wall = Color3.fromRGB(20, 24, 40),
	Ceiling = Color3.fromRGB(12, 12, 20),
	Furniture = Color3.fromRGB(56, 38, 22),
	JudgePlatform = Color3.fromRGB(26, 17, 10),
	JuryPlatform = Color3.fromRGB(28, 32, 46),
	Gold = Color3.fromRGB(200, 158, 48),
	Witness = Color3.fromRGB(34, 40, 58),
	Gallery = Color3.fromRGB(44, 30, 18),
	LightWarm = Color3.fromRGB(255, 230, 180),
	Paper = Color3.fromRGB(228, 218, 192),
	Carpet = Color3.fromRGB(58, 16, 16),
	WinAmber = Color3.fromRGB(220, 162, 52), -- vitraux dorés
}

-- ─── Positions par rôle ───────────────────────────────────────────────────────

type SpawnMap = {
	Lobby: CFrame,
	JurorSeats: { CFrame },
	WitnessStand: CFrame,
	AccusedStand: CFrame,
	ProsecutorSeat: CFrame,
	DefenseSeat: CFrame,
}

local SPAWNS: SpawnMap = {
	Lobby = CFrame.new(0, 3, 17),
	JurorSeats = {
		CFrame.new(20, 4, -21),
		CFrame.new(20, 4, -17),
		CFrame.new(20, 4, -13),
		CFrame.new(20, 4, -9),
	},
	WitnessStand = CFrame.new(-16, 3, -20),
	AccusedStand = CFrame.new(-15, 3, -23),
	ProsecutorSeat = CFrame.new(10, 3, -6),
	DefenseSeat = CFrame.new(-10, 3, -6),
}

-- ─── Helpers structurels ──────────────────────────────────────────────────────

local function mk(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function addLight(p: Part, brightness: number, range: number)
	local light = Instance.new("PointLight")
	light.Brightness = brightness
	light.Range = range
	light.Color = C.LightWarm
	light.Parent = p
end

local function trim(parent: Instance, name: string, w: number, cf: CFrame)
	mk(parent, name, Vector3.new(w, 0.3, 0.3), cf, C.Gold)
end

local function papers(parent: Instance, name: string, cf: CFrame)
	local p = mk(parent, name, Vector3.new(3.5, 0.05, 4), cf, C.Paper)
	p.CanCollide = false
end

local function signage(parent: Instance, name: string, label: string, pos: Vector3)
	local anchor = mk(parent, name .. "Sign", Vector3.new(0.3, 0.3, 0.3), CFrame.new(pos), C.Gold)
	anchor.CanCollide = false

	local bgui = Instance.new("BillboardGui")
	bgui.Name = "SignBillboard"
	bgui.Size = UDim2.new(0, 130, 0, 40)
	bgui.StudsOffset = Vector3.new(0, 1, 0)
	bgui.AlwaysOnTop = false
	bgui.LightInfluence = 0
	bgui.Parent = anchor

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
	bg.BackgroundTransparency = 0.1
	bg.BorderSizePixel = 0
	bg.Parent = bgui

	local stroke = Instance.new("UIStroke")
	stroke.Color = C.Gold
	stroke.Thickness = 1.5
	stroke.Parent = bg

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -8, 1, 0)
	txt.Position = UDim2.new(0, 4, 0, 0)
	txt.BackgroundTransparency = 1
	txt.Text = label
	txt.TextColor3 = C.Gold
	txt.Font = Enum.Font.GothamBold
	txt.TextSize = 14
	txt.TextXAlignment = Enum.TextXAlignment.Center
	txt.Parent = bg
end

-- Variante large de signage() pour le lobby : billboard plus large, TextScaled.
local function lobbySignage(parent: Instance, name: string, label: string, pos: Vector3)
	local anchor = mk(parent, name .. "Sign", Vector3.new(0.3, 0.3, 0.3), CFrame.new(pos), C.Gold)
	anchor.CanCollide = false

	local bgui = Instance.new("BillboardGui")
	bgui.Name = "LobbySignBillboard"
	bgui.Size = UDim2.new(0, 200, 0, 44)
	bgui.StudsOffset = Vector3.new(0, 1, 0)
	bgui.AlwaysOnTop = false
	bgui.LightInfluence = 0
	bgui.Parent = anchor

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
	bg.BackgroundTransparency = 0.10
	bg.BorderSizePixel = 0
	bg.Parent = bgui

	local stroke = Instance.new("UIStroke")
	stroke.Color = C.Gold
	stroke.Thickness = 1.5
	stroke.Parent = bg

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -8, 1, 0)
	txt.Position = UDim2.new(0, 4, 0, 0)
	txt.BackgroundTransparency = 1
	txt.Text = label
	txt.TextColor3 = C.Gold
	txt.Font = Enum.Font.GothamBold
	txt.TextScaled = true
	txt.TextXAlignment = Enum.TextXAlignment.Center
	txt.Parent = bg
end

-- ─── Helpers visuels M3.3 ─────────────────────────────────────────────────────

-- Applique (en détruisant l'ancienne) la liste des instances Lighting existantes du type donné.
local function clearLightingChildren(className: string)
	local Lighting = game:GetService("Lighting")
	for _, child in ipairs(Lighting:GetChildren()) do
		if child.ClassName == className then
			child:Destroy()
		end
	end
end

-- Applique un projecteur SpotLight sur une fixture au plafond.
-- La fixture est une small Part dorée visible depuis la salle.
local function addSpotFixture(
	parent: Instance,
	name: string,
	pos: Vector3,
	brightness: number,
	angle: number,
	range: number
): Part
	local fixture = mk(parent, name .. "Fixture", Vector3.new(1.2, 0.4, 1.2), CFrame.new(pos), C.Gold)
	fixture.CanCollide = false
	local spot = Instance.new("SpotLight")
	spot.Brightness = brightness
	spot.Angle = angle
	spot.Range = range
	spot.Color = C.LightWarm
	spot.Face = Enum.NormalId.Bottom
	spot.Parent = fixture
	return fixture
end

-- Crée un applique murale (bracket doré + PointLight chaud).
local function addSconce(
	parent: Instance,
	name: string,
	pos: Vector3,
	brightness: number,
	range: number
)
	local bracket = mk(parent, name, Vector3.new(0.6, 1.0, 0.4), CFrame.new(pos), C.Gold)
	bracket.CanCollide = false
	addLight(bracket, brightness, range)
end

-- Crée un rectangle Neon semi-transparent simulant un vitrail coloré.
local function addWindow(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	transparency: number
): Part
	local w = mk(parent, name, size, cf, color)
	w.Material = Enum.Material.Neon
	w.Transparency = transparency
	w.CanCollide = false
	return w
end

-- Crée une colonne Neon très transparente simulant un faisceau lumineux.
local function addShaft(
	parent: Instance,
	name: string,
	pos: Vector3,
	szX: number,
	szY: number,
	szZ: number
): Part
	local shaft =
		mk(parent, name, Vector3.new(szX, szY, szZ), CFrame.new(pos), Color3.fromRGB(255, 230, 175))
	shaft.Material = Enum.Material.Neon
	shaft.Transparency = 0.93
	shaft.CanCollide = false
	return shaft
end

-- ─── Construction ─────────────────────────────────────────────────────────────

function WorldBuilder.buildCourthouse()
	local existing = workspace:FindFirstChild("Courthouse")
	if existing then
		existing:Destroy()
	end
	local existingSpawn = workspace:FindFirstChild("LobbySpawn")
	if existingSpawn then
		existingSpawn:Destroy()
	end

	local root = Instance.new("Folder")
	root.Name = "Courthouse"
	root.Parent = workspace

	-- ── Structure ────────────────────────────────────────────────────────────

	local floor = mk(root, "Floor", Vector3.new(52, 1, 72), CFrame.new(0, -0.5, 0), C.Floor)
	floor.Material = Enum.Material.Wood

	local ceiling = mk(root, "Ceiling", Vector3.new(52, 1, 72), CFrame.new(0, 23, 0), C.Ceiling)
	ceiling.Material = Enum.Material.Concrete

	local wallBack = mk(root, "WallBack", Vector3.new(52, 24, 1), CFrame.new(0, 11.5, -36), C.Wall)
	wallBack.Material = Enum.Material.Concrete
	local wallFront = mk(root, "WallFront", Vector3.new(52, 24, 1), CFrame.new(0, 11.5, 36), C.Wall)
	wallFront.Material = Enum.Material.Concrete
	local wallLeft = mk(root, "WallLeft", Vector3.new(1, 24, 72), CFrame.new(-26, 11.5, 0), C.Wall)
	wallLeft.Material = Enum.Material.Concrete
	local wallRight = mk(root, "WallRight", Vector3.new(1, 24, 72), CFrame.new(26, 11.5, 0), C.Wall)
	wallRight.Material = Enum.Material.Concrete

	-- Liserés dorés bas de mur
	mk(root, "TrimBack", Vector3.new(52, 1, 0.4), CFrame.new(0, 0.5, -35.6), C.Gold)
	mk(root, "TrimFront", Vector3.new(52, 1, 0.4), CFrame.new(0, 0.5, 35.6), C.Gold)
	mk(root, "TrimLeft", Vector3.new(0.4, 1, 72), CFrame.new(-25.6, 0.5, 0), C.Gold)
	mk(root, "TrimRight", Vector3.new(0.4, 1, 72), CFrame.new(25.6, 0.5, 0), C.Gold)

	-- Liserés dorés haut de mur (M3.3)
	mk(root, "TrimTopBack", Vector3.new(52, 0.8, 0.4), CFrame.new(0, 22.4, -35.6), C.Gold)
	mk(root, "TrimTopFront", Vector3.new(52, 0.8, 0.4), CFrame.new(0, 22.4, 35.6), C.Gold)
	mk(root, "TrimTopLeft", Vector3.new(0.4, 0.8, 72), CFrame.new(-25.6, 22.4, 0), C.Gold)
	mk(root, "TrimTopRight", Vector3.new(0.4, 0.8, 72), CFrame.new(25.6, 22.4, 0), C.Gold)

	-- ── Tapis central ────────────────────────────────────────────────────────

	local carpet =
		mk(root, "CentralCarpet", Vector3.new(4, 0.05, 60), CFrame.new(0, 0.05, -4), C.Carpet)
	carpet.CanCollide = false

	-- ── Estrade du Juge ──────────────────────────────────────────────────────

	local judgePlat =
		mk(root, "JudgePlatform", Vector3.new(22, 2, 12), CFrame.new(0, 1, -30), C.JudgePlatform)
	judgePlat.Material = Enum.Material.Marble

	trim(root, "JudgePlatformFront", 22, CFrame.new(0, 2.15, -24.1))

	local judgeDesk =
		mk(root, "JudgeDesk", Vector3.new(18, 3, 5), CFrame.new(0, 3.5, -27.5), C.Furniture)
	judgeDesk.Material = Enum.Material.Wood

	trim(root, "JudgeDeskFront", 18, CFrame.new(0, 5.15, -25))

	local judgeLamp =
		mk(root, "JudgeLamp", Vector3.new(1.5, 0.5, 1.5), CFrame.new(0, 5.5, -27.5), C.Gold)
	addLight(judgeLamp, 5, 24)

	mk(root, "GavelHandle", Vector3.new(3.5, 0.22, 0.22), CFrame.new(4.2, 5.13, -27.5), C.Furniture)
	mk(root, "GavelHead", Vector3.new(0.9, 0.9, 0.45), CFrame.new(6, 5.48, -27.5), C.Furniture)
	mk(root, "GavelBase", Vector3.new(0.9, 0.2, 0.9), CFrame.new(3.5, 5.12, -26.2), C.Gold)
	papers(root, "JudgeNotes", CFrame.new(-3, 5.05, -27) * CFrame.Angles(0, -0.08, 0))

	-- ── Box du Témoin ────────────────────────────────────────────────────────

	mk(root, "WitnessFloor", Vector3.new(7, 0.5, 7), CFrame.new(-16, 0.25, -22), C.Witness)
	mk(root, "WitnessWallFront", Vector3.new(7, 5, 1), CFrame.new(-16, 3, -18.5), C.Witness)
	mk(root, "WitnessWallLeft", Vector3.new(1, 5, 7), CFrame.new(-19.5, 3, -22), C.Witness)
	mk(root, "WitnessWallRight", Vector3.new(1, 5, 7), CFrame.new(-12.5, 3, -22), C.Witness)
	trim(root, "WitnessTopFront", 7, CFrame.new(-16, 5.65, -18.5))
	papers(root, "WitnessNotes", CFrame.new(-15.5, 0.55, -21))

	-- ── Tables Accusation et Défense ─────────────────────────────────────────

	local prosTable = mk(root, "ProsTable", Vector3.new(12, 2, 5), CFrame.new(10, 1, -9), C.Furniture)
	prosTable.Material = Enum.Material.Wood
	trim(root, "ProsTableFront", 12, CFrame.new(10, 2.15, -6.5))
	papers(root, "ProsNotes", CFrame.new(10, 2.05, -9) * CFrame.Angles(0, 0.12, 0))

	local defTable = mk(root, "DefTable", Vector3.new(12, 2, 5), CFrame.new(-10, 1, -9), C.Furniture)
	defTable.Material = Enum.Material.Wood
	trim(root, "DefTableFront", 12, CFrame.new(-10, 2.15, -6.5))
	papers(root, "DefNotes", CFrame.new(-10, 2.05, -9) * CFrame.Angles(0, -0.12, 0))

	-- ── Box des Jurés ─────────────────────────────────────────────────────────

	mk(root, "JuryPlatform", Vector3.new(9, 1, 22), CFrame.new(21, 0.5, -14), C.JuryPlatform)

	local juryB1 = mk(root, "JuryBench1", Vector3.new(8, 2, 3), CFrame.new(21, 2, -21), C.Furniture)
	juryB1.Material = Enum.Material.Wood
	local juryB2 = mk(root, "JuryBench2", Vector3.new(8, 2, 3), CFrame.new(21, 2, -15), C.Furniture)
	juryB2.Material = Enum.Material.Wood
	local juryB3 = mk(root, "JuryBench3", Vector3.new(8, 2, 3), CFrame.new(21, 2, -8), C.Furniture)
	juryB3.Material = Enum.Material.Wood

	mk(root, "JuryRail", Vector3.new(1, 5, 22), CFrame.new(16.5, 3, -14), C.Furniture)
	mk(root, "JuryRailTop", Vector3.new(1, 0.3, 22), CFrame.new(16.5, 5.65, -14), C.Gold)

	-- ── Barrière basse cour / galerie ─────────────────────────────────────────

	mk(root, "CourtRail", Vector3.new(42.5, 2.5, 1), CFrame.new(-4.75, 1.25, 3), C.Furniture)
	mk(root, "CourtRailTop", Vector3.new(42.5, 0.3, 1), CFrame.new(-4.75, 2.65, 3), C.Gold)
	local postX = { -24, -14, -4.75, 5, 14 }
	for i, px in ipairs(postX) do
		mk(root, "CourtPost" .. tostring(i), Vector3.new(0.5, 3.2, 0.5), CFrame.new(px, 1.6, 3), C.Gold)
	end

	-- ── Galerie Spectateurs ───────────────────────────────────────────────────

	local galB1 = mk(root, "GalleryBench1", Vector3.new(48, 2, 5), CFrame.new(0, 1, 13), C.Gallery)
	galB1.Material = Enum.Material.Wood
	local galB2 = mk(root, "GalleryBench2", Vector3.new(48, 2, 5), CFrame.new(0, 1, 23), C.Gallery)
	galB2.Material = Enum.Material.Wood

	-- ── Éclairage plafond (réduit — les spots dominent) ──────────────────────

	local lightPos = {
		Vector3.new(-12, 22.5, -18),
		Vector3.new(10, 22.5, -18),
		Vector3.new(-12, 22.5, 8),
		Vector3.new(10, 22.5, 8),
	}
	for i, pos in ipairs(lightPos) do
		local lamp =
			mk(root, "CeilingLight" .. tostring(i), Vector3.new(2, 0.5, 2), CFrame.new(pos), C.Gold)
		addLight(lamp, 1.8, 30)
	end

	-- Plaffonnier galerie : évite que le banc arrière et le lobby soient quasi-noirs
	-- (banc2 à Z=23 et lobby à Z=17 hors portée des lumières de la salle)
	local galLamp = mk(root, "CeilingLight5", Vector3.new(2, 0.5, 2), CFrame.new(0, 22.5, 18), C.Gold)
	addLight(galLamp, 1.5, 32)

	-- ── Signalétique 3D ───────────────────────────────────────────────────────

	signage(root, "Judge", "JUGE", Vector3.new(0, 8, -25))
	signage(root, "Jury", "JURY", Vector3.new(19, 7, -14))
	signage(root, "Witness", "TÉMOIN", Vector3.new(-16, 8.5, -22))
	signage(root, "Prosecutor", "ACCUSATION", Vector3.new(10, 5.5, -9))
	signage(root, "Defense", "DÉFENSE", Vector3.new(-10, 5.5, -9))

	-- ── Détails architecturaux M3.3 ───────────────────────────────────────────

	-- Arche d'honneur encadrant l'estrade du Juge (visible depuis galerie)
	mk(root, "JudgeArchLeft", Vector3.new(0.5, 15, 0.5), CFrame.new(-9, 7.5, -25), C.Gold)
	mk(root, "JudgeArchRight", Vector3.new(0.5, 15, 0.5), CFrame.new(9, 7.5, -25), C.Gold)
	mk(root, "JudgeArchTop", Vector3.new(18.5, 0.5, 0.5), CFrame.new(0, 15, -25), C.Gold)

	-- Pilastres dorés sur le mur arrière (encadrent les vitraux)
	local pilasterXs = { -19, -7, 7, 19 }
	for i, px in ipairs(pilasterXs) do
		mk(
			root,
			"BackPilaster" .. tostring(i),
			Vector3.new(1.0, 20, 0.5),
			CFrame.new(px, 10, -35.7),
			C.Gold
		)
	end

	-- Vitraux dorés sur le mur arrière (entre les pilastres)
	-- Très légèrement opaques : chaleur ambrée sans éblouir
	addWindow(root, "WinLeft", Vector3.new(5, 10, 0.15), CFrame.new(-13, 14, -35.6), C.WinAmber, 0.50)
	addWindow(
		root,
		"WinCenter",
		Vector3.new(7, 13, 0.15),
		CFrame.new(0, 15.5, -35.6),
		C.WinAmber,
		0.44
	)
	addWindow(root, "WinRight", Vector3.new(5, 10, 0.15), CFrame.new(13, 14, -35.6), C.WinAmber, 0.50)

	-- Faisceaux lumineux depuis les vitraux vers l'estrade
	-- Neon quasi-invisible — suggestion de lumière, pas d'effet lourd
	addShaft(root, "ShaftLeft", Vector3.new(-10, 9, -30), 2.0, 16, 2.0)
	addShaft(root, "ShaftCenter", Vector3.new(0, 9.5, -31), 2.5, 19, 2.5)
	addShaft(root, "ShaftRight", Vector3.new(10, 9, -30), 2.0, 16, 2.0)

	-- Appliques murales — mur gauche (X=-25.5)
	addSconce(root, "SconceL1", Vector3.new(-25.5, 9, -28), 2.5, 18)
	addSconce(root, "SconceL2", Vector3.new(-25.5, 9, -16), 2.0, 16)
	addSconce(root, "SconceL3", Vector3.new(-25.5, 9, -4), 2.0, 16)
	-- Appliques murales — mur droit (X=25.5)
	addSconce(root, "SconceR1", Vector3.new(25.5, 9, -28), 2.5, 18)
	addSconce(root, "SconceR2", Vector3.new(25.5, 9, -16), 2.0, 16)
	addSconce(root, "SconceR3", Vector3.new(25.5, 9, -4), 2.0, 16)

	-- Projecteur sur l'estrade du Juge (spot centré haut, éclairage dramatique)
	addSpotFixture(root, "JudgeSpot", Vector3.new(0, 22.5, -27.5), 7, 38, 28)

	-- Projecteur sur le box du Témoin (légèrement plus lumineux que la salle)
	addSpotFixture(root, "WitnessSpot", Vector3.new(-16, 22.5, -22), 4, 46, 22)

	-- ── Poussière flottante (particules légères) ──────────────────────────────

	local dustPart =
		mk(root, "DustSource", Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 16, -15), C.Ceiling)
	dustPart.CanCollide = false
	dustPart.Transparency = 1.0

	local dust = Instance.new("ParticleEmitter")
	dust.Rate = 4
	dust.Lifetime = NumberRange.new(14, 22)
	dust.Speed = NumberRange.new(0.04, 0.14)
	dust.SpreadAngle = Vector2.new(180, 180)
	dust.Rotation = NumberRange.new(0, 360)
	dust.RotSpeed = NumberRange.new(-4, 4)
	dust.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.06),
		NumberSequenceKeypoint.new(0.6, 0.05),
		NumberSequenceKeypoint.new(1, 0.02),
	})
	dust.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.88),
		NumberSequenceKeypoint.new(0.5, 0.82),
		NumberSequenceKeypoint.new(1, 1.0),
	})
	dust.Color = ColorSequence.new(Color3.fromRGB(228, 215, 190))
	dust.LightInfluence = 0.9
	dust.Parent = dustPart

	-- ── SpawnLocation Lobby ───────────────────────────────────────────────────

	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "LobbySpawn"
	spawnLoc.Size = Vector3.new(8, 1, 8)
	spawnLoc.CFrame = CFrame.new(0, 0.5, 18)
	spawnLoc.Color = Color3.fromRGB(30, 36, 54)
	spawnLoc.Material = Enum.Material.SmoothPlastic
	spawnLoc.TopSurface = Enum.SurfaceType.Smooth
	spawnLoc.Neutral = true
	spawnLoc.Duration = 0
	spawnLoc.Parent = workspace

	-- ── Zone Lobby M3.6 ───────────────────────────────────────────────────────

	-- Pupitre d'accueil face au mur d'entrée, visible en se retournant depuis spawn
	local podium = mk(root, "LobbyPodium", Vector3.new(6, 3, 4), CFrame.new(0, 1.5, 31), C.Furniture)
	podium.Material = Enum.Material.Wood
	trim(root, "LobbyPodiumTrim", 6, CFrame.new(0, 3.15, 31))

	-- Panneau d'accueil au-dessus du pupitre (BillboardGui toujours face caméra)
	do
		local anchor =
			mk(root, "LobbyWelcomeAnchor", Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 5.5, 31), C.Gold)
		anchor.CanCollide = false

		local bgui = Instance.new("BillboardGui")
		bgui.Name = "WelcomeBillboard"
		bgui.Size = UDim2.new(0, 260, 0, 88)
		bgui.StudsOffset = Vector3.new(0, 1, 0)
		bgui.AlwaysOnTop = false
		bgui.LightInfluence = 0
		bgui.Parent = anchor

		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3 = Color3.fromRGB(8, 8, 20)
		bg.BackgroundTransparency = 0.05
		bg.BorderSizePixel = 0
		bg.Parent = bgui

		local bStroke = Instance.new("UIStroke")
		bStroke.Color = C.Gold
		bStroke.Thickness = 2
		bStroke.Parent = bg

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(1, -8, 0, 44)
		titleLbl.Position = UDim2.new(0, 4, 0, 6)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = "THE WITNESS BOX"
		titleLbl.TextColor3 = C.Gold
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.TextSize = 20
		titleLbl.TextXAlignment = Enum.TextXAlignment.Center
		titleLbl.Parent = bg

		local subLbl = Instance.new("TextLabel")
		subLbl.Size = UDim2.new(1, -8, 0, 28)
		subLbl.Position = UDim2.new(0, 4, 0, 54)
		subLbl.BackgroundTransparency = 1
		subLbl.Text = "Le procès commence bientôt…"
		subLbl.TextColor3 = Color3.fromRGB(175, 150, 100)
		subLbl.Font = Enum.Font.Gotham
		subLbl.TextSize = 13
		subLbl.TextXAlignment = Enum.TextXAlignment.Center
		subLbl.Parent = bg
	end

	-- Spot d'accueil au plafond au-dessus du pupitre
	addSpotFixture(root, "LobbySpot", Vector3.new(0, 22.5, 31), 3, 40, 22)

	-- Poteaux et cordon encadrant la zone de spawn
	mk(root, "LobbyPostL", Vector3.new(0.4, 3, 0.4), CFrame.new(-5, 1.5, 17), C.Gold)
	mk(root, "LobbyPostR", Vector3.new(0.4, 3, 0.4), CFrame.new(5, 1.5, 17), C.Gold)
	local lobbyRope = mk(root, "LobbyRope", Vector3.new(10, 0.18, 0.18), CFrame.new(0, 3, 17), C.Gold)
	lobbyRope.CanCollide = false

	-- Signalétique directionnelle lobby
	lobbySignage(root, "LobbyAudience", "SALLE D'AUDIENCE", Vector3.new(0, 5.5, 5))
	lobbySignage(root, "LobbyGallery", "GALERIE", Vector3.new(-20, 4.5, 22))
	lobbySignage(root, "LobbyShop", "BOUTIQUE", Vector3.new(20, 4.5, 28))
	lobbySignage(root, "LobbyNextCase", "PROCHAINE AFFAIRE", Vector3.new(-12, 4.5, 28))

	-- ── Positions de téléportation ────────────────────────────────────────────

	local judgeDir = Vector3.new(0, 3, -28)
	local courtCenter = Vector3.new(0, 3, -20)

	SPAWNS.Lobby = CFrame.lookAt(Vector3.new(0, 3, 17), judgeDir)

	SPAWNS.JurorSeats = {
		CFrame.lookAt(Vector3.new(18, 5, -9), courtCenter),
		CFrame.lookAt(Vector3.new(21, 5, -9), courtCenter),
		CFrame.lookAt(Vector3.new(24, 5, -9), courtCenter),
		CFrame.lookAt(Vector3.new(18, 5, -16), courtCenter),
		CFrame.lookAt(Vector3.new(21, 5, -16), courtCenter),
		CFrame.lookAt(Vector3.new(24, 5, -16), courtCenter),
		CFrame.lookAt(Vector3.new(19, 5, -22), courtCenter),
		CFrame.lookAt(Vector3.new(23, 5, -22), courtCenter),
	}
	SPAWNS.WitnessStand = CFrame.lookAt(Vector3.new(-16, 3, -20), Vector3.new(-4, 3, -13))
	SPAWNS.AccusedStand = CFrame.lookAt(Vector3.new(-15, 3, -23), Vector3.new(-4, 3, -13))
	SPAWNS.ProsecutorSeat = CFrame.lookAt(Vector3.new(10, 3, -6), judgeDir)
	SPAWNS.DefenseSeat = CFrame.lookAt(Vector3.new(-10, 3, -6), judgeDir)

	-- ── Éclairage global M3.3 ─────────────────────────────────────────────────

	local Lighting = game:GetService("Lighting")

	-- Ambiance très sombre : les spots et appliques dominent entièrement
	Lighting.Ambient = Color3.fromRGB(14, 14, 28)
	Lighting.OutdoorAmbient = Color3.fromRGB(8, 8, 18)
	Lighting.Brightness = 0.22
	Lighting.ClockTime = 1 -- nuit (pas d'influence du soleil à l'intérieur)
	Lighting.GeographicLatitude = 48 -- Paris (cohérent avec ambiance tribunal FR)

	-- Supprime les effets précédents avant de les recréer (hot-reload Studio)
	clearLightingChildren("Atmosphere")
	clearLightingChildren("ColorCorrectionEffect")
	clearLightingChildren("BloomEffect")

	-- Atmosphère légère : poussière en suspension dans l'air (très discret)
	local atm = Instance.new("Atmosphere")
	atm.Density = 0.12
	atm.Offset = 0.20
	atm.Color = Color3.fromRGB(178, 150, 110)
	atm.Decay = Color3.fromRGB(55, 42, 30)
	atm.Glare = 0
	atm.Haze = 1.2
	atm.Parent = Lighting

	-- Correction colorimétrique : légère désaturation + contraste dramatique
	-- TintColor légèrement chaud pour renforcer l'ambiance tribunal candlelight
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = -0.04
	cc.Contrast = 0.18
	cc.Saturation = -0.12
	cc.TintColor = Color3.fromRGB(255, 246, 232)
	cc.Parent = Lighting

	-- Bloom discret : les éléments Neon (vitraux, lampes) ont un léger halo doré
	-- Threshold élevé : seules les surfaces très brillantes blooment
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.30
	bloom.Size = 18
	bloom.Threshold = 0.92
	bloom.Parent = Lighting

	print(
		string.format(
			"[WorldBuilder] Salle construite — %d éléments + LobbySpawn",
			#root:GetChildren()
		)
	)
end

-- ─── API publique ─────────────────────────────────────────────────────────────

function WorldBuilder.getRoleSpawnCFrame(role: string, jurorIndex: number?): CFrame
	if role == "HonestWitness" then
		return SPAWNS.WitnessStand
	elseif role == "Liar" then
		return SPAWNS.AccusedStand
	elseif role == "Juror" then
		local seats = SPAWNS.JurorSeats
		local idx = math.clamp(jurorIndex or 1, 1, #seats)
		return seats[idx]
	elseif role == "Prosecutor" then
		return SPAWNS.ProsecutorSeat
	elseif role == "Defense" then
		return SPAWNS.DefenseSeat
	end
	return SPAWNS.Lobby
end

function WorldBuilder.getLobbySpawnCFrame(): CFrame
	return SPAWNS.Lobby
end

return WorldBuilder
