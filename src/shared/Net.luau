--!strict
-- Couche réseau centralisée.
-- Crée et cache les RemoteEvents/Functions dans ReplicatedStorage.Remotes.
-- Toute communication client↔server passe par ce module.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteNames = require(script.Parent.RemoteNames)

local IS_SERVER = RunService:IsServer()

local Net = {}

local remoteFolder: Folder? = nil
local eventCache: { [string]: RemoteEvent } = {}
local functionCache: { [string]: RemoteFunction } = {}

local function getFolder(): Folder
	if remoteFolder then
		return remoteFolder :: Folder
	end

	if IS_SERVER then
		local existing = ReplicatedStorage:FindFirstChild("Remotes")
		if existing and existing:IsA("Folder") then
			remoteFolder = existing :: Folder
		else
			local folder = Instance.new("Folder")
			folder.Name = "Remotes"
			folder.Parent = ReplicatedStorage
			remoteFolder = folder
		end
	else
		local folder = ReplicatedStorage:WaitForChild("Remotes", 15)
		assert(folder and folder:IsA("Folder"), "[Net] Remotes introuvable après 15s")
		remoteFolder = folder :: Folder
	end

	return remoteFolder :: Folder
end

-- Retourne (ou crée côté serveur) un RemoteEvent par nom
function Net.getEvent(name: string): RemoteEvent
	if eventCache[name] then
		return eventCache[name]
	end

	local folder = getFolder()
	local remote: RemoteEvent

	if IS_SERVER then
		local existing = folder:FindFirstChild(name)
		if existing and existing:IsA("RemoteEvent") then
			remote = existing :: RemoteEvent
		else
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	else
		local found = folder:WaitForChild(name, 15)
		assert(found and found:IsA("RemoteEvent"), "[Net] RemoteEvent '" .. name .. "' introuvable")
		remote = found :: RemoteEvent
	end

	eventCache[name] = remote
	return remote
end

-- Retourne (ou crée côté serveur) un RemoteFunction par nom
function Net.getFunction(name: string): RemoteFunction
	if functionCache[name] then
		return functionCache[name]
	end

	local folder = getFolder()
	local remote: RemoteFunction

	if IS_SERVER then
		local existing = folder:FindFirstChild(name)
		if existing and existing:IsA("RemoteFunction") then
			remote = existing :: RemoteFunction
		else
			remote = Instance.new("RemoteFunction")
			remote.Name = name
			remote.Parent = folder
		end
	else
		local found = folder:WaitForChild(name, 15)
		assert(found and found:IsA("RemoteFunction"), "[Net] RemoteFunction '" .. name .. "' introuvable")
		remote = found :: RemoteFunction
	end

	functionCache[name] = remote
	return remote
end

-- Server → tous les clients
function Net.broadcast(eventName: string, payload: { [string]: any })
	assert(IS_SERVER, "[Net] broadcast() interdit côté client")
	Net.getEvent(eventName):FireAllClients(payload)
end

-- Server → un client spécifique (pour les rôles notamment)
function Net.fire(player: Player, eventName: string, payload: { [string]: any })
	assert(IS_SERVER, "[Net] fire() interdit côté client")
	Net.getEvent(eventName):FireClient(player, payload)
end

-- Server : écoute un event client→server
function Net.onServer(
	eventName: string,
	callback: (player: Player, payload: { [string]: any }) -> ()
)
	assert(IS_SERVER, "[Net] onServer() interdit côté client")
	Net.getEvent(eventName).OnServerEvent:Connect(function(player, payload)
		callback(player, payload or {})
	end)
end

-- Client : écoute un event server→client
function Net.onClient(eventName: string, callback: (payload: { [string]: any }) -> ())
	assert(not IS_SERVER, "[Net] onClient() interdit côté serveur")
	Net.getEvent(eventName).OnClientEvent:Connect(function(payload)
		callback(payload or {})
	end)
end

-- Pré-crée tous les remotes connus (appelé une seule fois dans Bootstrap)
function Net.init()
	assert(IS_SERVER, "[Net] init() doit être appelé depuis le serveur")

	for _, name in ipairs(RemoteNames._EventNames) do
		Net.getEvent(name)
	end

	for _, name in ipairs(RemoteNames._FunctionNames) do
		Net.getFunction(name)
	end

	print(
		"[Net] "
			.. #RemoteNames._EventNames
			.. " events + "
			.. #RemoteNames._FunctionNames
			.. " functions initialisés"
	)
end

return Net
