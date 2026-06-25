--!strict
-- Point d'entrée client.
-- Milestone 1.1 : écoute les phases et les affiche en console.
-- L'UI complète est prévue au Milestone 1.2.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)
local Types = require(Shared.Types)

-- Écoute les changements de phase pour préparer le terrain à la 1.2
Net.onClient(RemoteNames.GamePhaseChanged, function(payload)
	local typed = payload :: Types.PhaseChangedPayload
	print(
		string.format(
			"[Client] Phase → %s (durée: %ds, partie: %s)",
			typed.Phase,
			typed.Duration,
			typed.MatchId
		)
	)
end)

-- Écoute le rôle assigné individuellement
Net.onClient(RemoteNames.RoleAssigned, function(payload)
	local typed = payload :: Types.RoleAssignedPayload
	print(string.format("[Client] Mon rôle : %s", typed.Role))
end)

print("[Client] The Witness Box — client prêt")
