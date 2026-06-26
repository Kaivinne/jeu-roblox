--!strict
-- Construit la salle d'audience Roblox par code au démarrage du serveur.
-- Toute la géométrie est créée programmatiquement pour la compatibilité Rojo.
-- Milestone 2.3 : sièges nommés par rôle, signalétique, détails blockout.

local WorldBuilder = {}

-- ─── Palette ──────────────────────────────────────────────────────────────────

local C = {
	Floor = Color3.fromRGB(38, 26, 16),
	Wall = Color3.fromRGB(20, 24, 40),
	Ceiling = Color3.fromRGB(14, 14, 22),
	Furniture = Color3.fromRGB(56, 38, 22),
	JudgePlatform = Color3.fromRGB(26, 17, 10),
	JuryPlatform = Color3.fromRGB(28, 32, 46),
	Gold = Color3.fromRGB(200, 158, 48),
	Witness = Color3.fromRGB(34, 40, 58),
	Gallery = Color3.fromRGB(44, 30, 18),
	LightWarm = Color3.fromRGB(255, 235, 200),
	Paper = Color3.fromRGB(228, 218, 192),
	Carpet = Color3.fromRGB(58, 16, 16),
}

-- ─── Positions par rôle ───────────────────────────────────────────────────────

-- Initialisées avec des valeurs de secours, remplacées dans buildCourthouse().
type SpawnMap = {
	Lobby: CFrame,
	JurorSeats: { CFrame }, -- 4 sièges numérotés (Juror1 → Juror4)
	WitnessStand: CFrame, -- HonestWitness
	AccusedStand: CFrame, -- Liar (accusé)
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

-- ─── Helpers ──────────────────────────────────────────────────────────────────

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

-- Liseré doré horizontal fin posé sur la face avant d'un meuble.
local function trim(parent: Instance, name: string, w: number, cf: CFrame)
	mk(parent, name, Vector3.new(w, 0.3, 0.3), cf, C.Gold)
end

-- Feuilles de papier décoratives (non-collidables, très fines).
local function papers(parent: Instance, name: string, cf: CFrame)
	local p = mk(parent, name, Vector3.new(3.5, 0.05, 4), cf, C.Paper)
	p.CanCollide = false
end

-- Panneau de signalétique 3D (BillboardGui toujours lisible).
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

-- ─── Construction ─────────────────────────────────────────────────────────────

function WorldBuilder.buildCourthouse()
	-- Nettoyer une construction précédente (hot-reload Studio)
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

	-- Salle 52 × 24 × 72 studs — Y=0 = surface du sol
	mk(root, "Floor", Vector3.new(52, 1, 72), CFrame.new(0, -0.5, 0), C.Floor)
	mk(root, "Ceiling", Vector3.new(52, 1, 72), CFrame.new(0, 23, 0), C.Ceiling)
	mk(root, "WallBack", Vector3.new(52, 24, 1), CFrame.new(0, 11.5, -36), C.Wall)
	mk(root, "WallFront", Vector3.new(52, 24, 1), CFrame.new(0, 11.5, 36), C.Wall)
	mk(root, "WallLeft", Vector3.new(1, 24, 72), CFrame.new(-26, 11.5, 0), C.Wall)
	mk(root, "WallRight", Vector3.new(1, 24, 72), CFrame.new(26, 11.5, 0), C.Wall)
	-- Liserés dorés bas de mur
	mk(root, "TrimBack", Vector3.new(52, 1, 0.4), CFrame.new(0, 0.5, -35.6), C.Gold)
	mk(root, "TrimFront", Vector3.new(52, 1, 0.4), CFrame.new(0, 0.5, 35.6), C.Gold)
	mk(root, "TrimLeft", Vector3.new(0.4, 1, 72), CFrame.new(-25.6, 0.5, 0), C.Gold)
	mk(root, "TrimRight", Vector3.new(0.4, 1, 72), CFrame.new(25.6, 0.5, 0), C.Gold)

	-- ── Tapis central ────────────────────────────────────────────────────────

	-- Allée centrale depuis le juge jusqu'à l'entrée de la galerie
	local carpet =
		mk(root, "CentralCarpet", Vector3.new(4, 0.05, 60), CFrame.new(0, 0.05, -4), C.Carpet)
	carpet.CanCollide = false

	-- ── Estrade du Juge ──────────────────────────────────────────────────────

	-- Plateforme (dessus à Y=2)
	mk(root, "JudgePlatform", Vector3.new(22, 2, 12), CFrame.new(0, 1, -30), C.JudgePlatform)
	trim(root, "JudgePlatformFront", 22, CFrame.new(0, 2.15, -24.1))
	-- Bureau (dessus à Y=5)
	mk(root, "JudgeDesk", Vector3.new(18, 3, 5), CFrame.new(0, 3.5, -27.5), C.Furniture)
	trim(root, "JudgeDeskFront", 18, CFrame.new(0, 5.15, -25))
	-- Lampe
	local judgeLamp =
		mk(root, "JudgeLamp", Vector3.new(1.5, 0.5, 1.5), CFrame.new(0, 5.5, -27.5), C.Gold)
	addLight(judgeLamp, 4, 22)
	-- Marteau du juge
	mk(root, "GavelHandle", Vector3.new(3.5, 0.22, 0.22), CFrame.new(4.2, 5.13, -27.5), C.Furniture)
	mk(root, "GavelHead", Vector3.new(0.9, 0.9, 0.45), CFrame.new(6, 5.48, -27.5), C.Furniture)
	mk(root, "GavelBase", Vector3.new(0.9, 0.2, 0.9), CFrame.new(3.5, 5.12, -26.2), C.Gold)
	-- Notes du juge
	papers(root, "JudgeNotes", CFrame.new(-3, 5.05, -27) * CFrame.Angles(0, -0.08, 0))

	-- ── Box du Témoin (côté gauche, X négatif) ───────────────────────────────

	-- Sol surélevé (dessus à Y=0.5)
	mk(root, "WitnessFloor", Vector3.new(7, 0.5, 7), CFrame.new(-16, 0.25, -22), C.Witness)
	-- Trois murs (ouvert côté juge)
	mk(root, "WitnessWallFront", Vector3.new(7, 5, 1), CFrame.new(-16, 3, -18.5), C.Witness)
	mk(root, "WitnessWallLeft", Vector3.new(1, 5, 7), CFrame.new(-19.5, 3, -22), C.Witness)
	mk(root, "WitnessWallRight", Vector3.new(1, 5, 7), CFrame.new(-12.5, 3, -22), C.Witness)
	trim(root, "WitnessTopFront", 7, CFrame.new(-16, 5.65, -18.5))
	-- Feuilles sur le pupitre du témoin
	papers(root, "WitnessNotes", CFrame.new(-15.5, 0.55, -21))

	-- ── Table Accusation (côté droit) ─────────────────────────────────────────

	mk(root, "ProsTable", Vector3.new(12, 2, 5), CFrame.new(10, 1, -9), C.Furniture)
	trim(root, "ProsTableFront", 12, CFrame.new(10, 2.15, -6.5))
	papers(root, "ProsNotes", CFrame.new(10, 2.05, -9) * CFrame.Angles(0, 0.12, 0))

	-- ── Table Défense (côté gauche) ───────────────────────────────────────────

	mk(root, "DefTable", Vector3.new(12, 2, 5), CFrame.new(-10, 1, -9), C.Furniture)
	trim(root, "DefTableFront", 12, CFrame.new(-10, 2.15, -6.5))
	papers(root, "DefNotes", CFrame.new(-10, 2.05, -9) * CFrame.Angles(0, -0.12, 0))

	-- ── Box des Jurés (contre le mur droit) ──────────────────────────────────

	-- Plateforme (dessus à Y=1)
	mk(root, "JuryPlatform", Vector3.new(9, 1, 22), CFrame.new(21, 0.5, -14), C.JuryPlatform)
	-- 3 rangées de bancs (4 sièges répartis dessus : 2 sur banc1, 2 sur banc2)
	mk(root, "JuryBench1", Vector3.new(8, 2, 3), CFrame.new(21, 2, -21), C.Furniture)
	mk(root, "JuryBench2", Vector3.new(8, 2, 3), CFrame.new(21, 2, -15), C.Furniture)
	mk(root, "JuryBench3", Vector3.new(8, 2, 3), CFrame.new(21, 2, -8), C.Furniture)
	-- Séparation jury / audience
	mk(root, "JuryRail", Vector3.new(1, 5, 22), CFrame.new(16.5, 3, -14), C.Furniture)
	mk(root, "JuryRailTop", Vector3.new(1, 0.3, 22), CFrame.new(16.5, 5.65, -14), C.Gold)

	-- ── Barrière basse cour / galerie ─────────────────────────────────────────

	-- Barrière 2.5 studs (mur gauche → entrée jury)
	mk(root, "CourtRail", Vector3.new(42.5, 2.5, 1), CFrame.new(-4.75, 1.25, 3), C.Furniture)
	mk(root, "CourtRailTop", Vector3.new(42.5, 0.3, 1), CFrame.new(-4.75, 2.65, 3), C.Gold)
	-- Posts dorés le long de la barrière (espacés d'environ 10 studs)
	local postX = { -24, -14, -4.75, 5, 14 }
	for i, px in ipairs(postX) do
		mk(root, "CourtPost" .. tostring(i), Vector3.new(0.5, 3.2, 0.5), CFrame.new(px, 1.6, 3), C.Gold)
	end

	-- ── Galerie Spectateurs ───────────────────────────────────────────────────

	mk(root, "GalleryBench1", Vector3.new(48, 2, 5), CFrame.new(0, 1, 13), C.Gallery)
	mk(root, "GalleryBench2", Vector3.new(48, 2, 5), CFrame.new(0, 1, 23), C.Gallery)

	-- ── Éclairage plafond ─────────────────────────────────────────────────────

	local lightPos = {
		Vector3.new(-12, 22.5, -18),
		Vector3.new(10, 22.5, -18),
		Vector3.new(-12, 22.5, 8),
		Vector3.new(10, 22.5, 8),
	}
	for i, pos in ipairs(lightPos) do
		local lamp =
			mk(root, "CeilingLight" .. tostring(i), Vector3.new(2, 0.5, 2), CFrame.new(pos), C.Gold)
		addLight(lamp, 2.5, 32)
	end

	-- ── Signalétique 3D ───────────────────────────────────────────────────────

	signage(root, "Judge", "JUGE", Vector3.new(0, 8, -25))
	signage(root, "Jury", "JURY", Vector3.new(19, 7, -14))
	signage(root, "Witness", "TÉMOIN", Vector3.new(-16, 8.5, -22))
	signage(root, "Prosecutor", "ACCUSATION", Vector3.new(10, 5.5, -9))
	signage(root, "Defense", "DÉFENSE", Vector3.new(-10, 5.5, -9))

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

	-- ── Positions de téléportation ────────────────────────────────────────────

	local judgeDir = Vector3.new(0, 3, -28)
	local courtCenter = Vector3.new(0, 3, -20)

	SPAWNS.Lobby = CFrame.lookAt(Vector3.new(0, 3, 17), judgeDir)

	-- 4 sièges jury répartis sur les bancs 1 et 2 (2 × 2), banc 3 en réserve
	SPAWNS.JurorSeats = {
		CFrame.lookAt(Vector3.new(19, 4, -22), courtCenter), -- banc 1, avant-gauche
		CFrame.lookAt(Vector3.new(23, 4, -22), courtCenter), -- banc 1, avant-droit
		CFrame.lookAt(Vector3.new(19, 4, -16), courtCenter), -- banc 2, avant-gauche
		CFrame.lookAt(Vector3.new(23, 4, -16), courtCenter), -- banc 2, avant-droit
	}
	SPAWNS.WitnessStand = CFrame.lookAt(Vector3.new(-16, 3, -20), Vector3.new(-4, 3, -13))
	SPAWNS.AccusedStand = CFrame.lookAt(Vector3.new(-15, 3, -23), Vector3.new(-4, 3, -13))
	SPAWNS.ProsecutorSeat = CFrame.lookAt(Vector3.new(10, 3, -6), judgeDir)
	SPAWNS.DefenseSeat = CFrame.lookAt(Vector3.new(-10, 3, -6), judgeDir)

	-- ── Éclairage global ──────────────────────────────────────────────────────

	local Lighting = game:GetService("Lighting")
	Lighting.Ambient = Color3.fromRGB(28, 28, 46)
	Lighting.OutdoorAmbient = Color3.fromRGB(18, 18, 32)
	Lighting.Brightness = 0.5
	Lighting.ClockTime = 12

	print(
		string.format("[WorldBuilder] Salle construite (%d éléments + LobbySpawn)", #root:GetChildren())
	)
end

-- ─── API publique ─────────────────────────────────────────────────────────────

-- Retourne la CFrame de téléportation pour un rôle donné.
-- jurorIndex (1–4) détermine quel siège de jury est attribué.
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

-- Retourne la CFrame de la zone d'attente (galerie spectateurs).
function WorldBuilder.getLobbySpawnCFrame(): CFrame
	return SPAWNS.Lobby
end

return WorldBuilder
