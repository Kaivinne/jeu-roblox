--!strict
-- Construit la salle d'audience Roblox par code au démarrage du serveur.
-- Toute la géométrie est créée programmatiquement pour la compatibilité Rojo.
-- Milestone 2.2 : blockout tribunal moderne, positions de rôle, téléportation.

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
}

-- ─── Positions par rôle ───────────────────────────────────────────────────────

-- Toutes les positions sont initialisées avec une valeur de secours
-- et mises à jour lors de buildCourthouse().
type SpawnMap = {
	Lobby: CFrame,
	JurorSeat: CFrame,
	WitnessBox: CFrame,
	ProsecutorDesk: CFrame,
	DefenseDesk: CFrame,
}

local SPAWNS: SpawnMap = {
	Lobby = CFrame.new(0, 3, 22),
	JurorSeat = CFrame.new(20, 4, -14),
	WitnessBox = CFrame.new(-16, 3, -21),
	ProsecutorDesk = CFrame.new(10, 3, -5),
	DefenseDesk = CFrame.new(-10, 3, -5),
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

-- Liseré doré horizontal fin (décoration de façade)
local function trim(parent: Instance, name: string, w: number, cf: CFrame)
	mk(parent, name, Vector3.new(w, 0.3, 0.3), cf, C.Gold)
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

	-- Salle : 52 × 23 × 72 studs (Y=0 = surface du sol)
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

	-- ── Estrade du Juge ──────────────────────────────────────────────────────

	-- Plateforme surélevée : dessus à Y=2
	mk(root, "JudgePlatform", Vector3.new(22, 2, 12), CFrame.new(0, 1, -30), C.JudgePlatform)
	trim(root, "JudgePlatformFront", 22, CFrame.new(0, 2.15, -24.1))

	-- Bureau du juge : dessus à Y=5
	mk(root, "JudgeDesk", Vector3.new(18, 3, 5), CFrame.new(0, 3.5, -27.5), C.Furniture)
	trim(root, "JudgeDeskFront", 18, CFrame.new(0, 5.15, -25))

	-- Lampe du juge avec lumière chaude
	local judgeLamp =
		mk(root, "JudgeLamp", Vector3.new(1.5, 0.5, 1.5), CFrame.new(0, 5.5, -27.5), C.Gold)
	addLight(judgeLamp, 4, 22)

	-- ── Box du Témoin (X négatif, côté gauche) ───────────────────────────────

	-- Sol du box légèrement surélevé
	mk(root, "WitnessFloor", Vector3.new(7, 0.5, 7), CFrame.new(-16, 0.25, -22), C.Witness)
	-- Trois murs (ouvert côté juge — mur arrière à Z=-25.5)
	mk(root, "WitnessWallFront", Vector3.new(7, 5, 1), CFrame.new(-16, 3, -18.5), C.Witness)
	mk(root, "WitnessWallLeft", Vector3.new(1, 5, 7), CFrame.new(-19.5, 3, -22), C.Witness)
	mk(root, "WitnessWallRight", Vector3.new(1, 5, 7), CFrame.new(-12.5, 3, -22), C.Witness)
	trim(root, "WitnessTopFront", 7, CFrame.new(-16, 5.65, -18.5))

	-- ── Tables de l'audience ──────────────────────────────────────────────────

	-- Table Accusation (côté droit, X positif)
	mk(root, "ProsTable", Vector3.new(12, 2, 5), CFrame.new(10, 1, -9), C.Furniture)
	trim(root, "ProsTableFront", 12, CFrame.new(10, 2.15, -6.5))

	-- Table Défense (côté gauche, X négatif)
	mk(root, "DefTable", Vector3.new(12, 2, 5), CFrame.new(-10, 1, -9), C.Furniture)
	trim(root, "DefTableFront", 12, CFrame.new(-10, 2.15, -6.5))

	-- ── Box des Jurés (contre le mur droit) ──────────────────────────────────

	-- Plateforme : dessus à Y=1, de X=17.5 à X=25.5, de Z=-25 à Z=-3
	mk(root, "JuryPlatform", Vector3.new(9, 1, 22), CFrame.new(21, 0.5, -14), C.JuryPlatform)
	mk(root, "JuryBench1", Vector3.new(8, 2, 3), CFrame.new(21, 2, -22), C.Furniture)
	mk(root, "JuryBench2", Vector3.new(8, 2, 3), CFrame.new(21, 2, -15), C.Furniture)
	mk(root, "JuryBench3", Vector3.new(8, 2, 3), CFrame.new(21, 2, -8), C.Furniture)
	-- Séparation jury / audience (mur bas)
	mk(root, "JuryRail", Vector3.new(1, 5, 22), CFrame.new(16.5, 3, -14), C.Furniture)
	mk(root, "JuryRailTop", Vector3.new(1, 0.3, 22), CFrame.new(16.5, 5.65, -14), C.Gold)

	-- ── Rambarde de séparation (cour / galerie) ───────────────────────────────

	-- Va du mur gauche (X=-26) jusqu'à l'entrée du jury (X=16.5) : longueur 42.5
	mk(root, "CourtRail", Vector3.new(42.5, 4, 1), CFrame.new(-4.75, 2, 3), C.Furniture)
	mk(root, "CourtRailTop", Vector3.new(42.5, 0.3, 1), CFrame.new(-4.75, 4.15, 3), C.Gold)

	-- ── Galerie Spectateurs ───────────────────────────────────────────────────

	mk(root, "GalleryBench1", Vector3.new(48, 2, 5), CFrame.new(0, 1, 13), C.Gallery)
	mk(root, "GalleryBench2", Vector3.new(48, 2, 5), CFrame.new(0, 1, 23), C.Gallery)

	-- ── Éclairage plafond (4 spots) ───────────────────────────────────────────

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

	-- ── SpawnLocation lobby ───────────────────────────────────────────────────

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

	-- Y=3 = racine du personnage debout sur le sol (Y=0)
	-- Y=4 = debout sur la plateforme jury (dessus Y=1)
	local judgeDir = Vector3.new(0, 3, -28)

	SPAWNS.Lobby = CFrame.lookAt(Vector3.new(0, 3, 17), judgeDir)
	SPAWNS.JurorSeat = CFrame.lookAt(Vector3.new(20, 4, -14), Vector3.new(0, 3, -22))
	SPAWNS.WitnessBox = CFrame.lookAt(Vector3.new(-16, 3, -21), Vector3.new(-5, 3, -10))
	SPAWNS.ProsecutorDesk = CFrame.lookAt(Vector3.new(10, 3, -6), judgeDir)
	SPAWNS.DefenseDesk = CFrame.lookAt(Vector3.new(-10, 3, -6), judgeDir)

	-- ── Éclairage global ──────────────────────────────────────────────────────

	local Lighting = game:GetService("Lighting")
	Lighting.Ambient = Color3.fromRGB(28, 28, 46)
	Lighting.OutdoorAmbient = Color3.fromRGB(18, 18, 32)
	Lighting.Brightness = 0.5
	Lighting.ClockTime = 12

	print(string.format(
		"[WorldBuilder] Salle d'audience construite (%d éléments)",
		#root:GetChildren() + 1 -- +1 pour LobbySpawn
	))
end

-- ─── API publique ─────────────────────────────────────────────────────────────

-- Retourne la CFrame de téléportation pour un rôle PlayerRole (string).
function WorldBuilder.getRoleSpawnCFrame(role: string): CFrame
	if role == "HonestWitness" or role == "Liar" then
		return SPAWNS.WitnessBox
	elseif role == "Juror" then
		return SPAWNS.JurorSeat
	elseif role == "Prosecutor" then
		return SPAWNS.ProsecutorDesk
	elseif role == "Defense" then
		return SPAWNS.DefenseDesk
	end
	return SPAWNS.Lobby
end

-- Retourne la CFrame de la zone Lobby (galerie spectateurs).
function WorldBuilder.getLobbySpawnCFrame(): CFrame
	return SPAWNS.Lobby
end

return WorldBuilder
