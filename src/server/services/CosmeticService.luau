--!strict
-- Boutique de cosmétiques Milestone 2.7.
-- Catalogue 5 items Jetons uniquement. Validation serveur stricte.
-- Aucune logique de Robux, Game Pass, ou monnaie premium.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Net)
local RemoteNames = require(Shared.RemoteNames)

local PlayerDataService = require(script.Parent.PlayerDataService)

local CosmeticService = {}

-- ─── Catalogue ────────────────────────────────────────────────────────────────

type CosmeticItem = {
	id: string,
	name: string,
	description: string,
	price: number,
	slot: string,
}

local CATALOGUE: { CosmeticItem } = {
	{
		id = "frame_bronze",
		name = "Cadre Bronze",
		description = "Encadrement bronze pour votre profil.",
		price = 10,
		slot = "frame",
	},
	{
		id = "frame_silver",
		name = "Cadre Argent",
		description = "Encadrement argenté élégant.",
		price = 25,
		slot = "frame",
	},
	{
		id = "badge_juror1",
		name = "Juré Débutant",
		description = "Badge pour vos premiers verdicts.",
		price = 5,
		slot = "badge",
	},
	{
		id = "badge_keen_eye",
		name = "Œil Attentif",
		description = "Rien ne vous échappe.",
		price = 15,
		slot = "badge",
	},
	{
		id = "effect_gavel",
		name = "Marteau Doré",
		description = "Effet doré au moment du verdict.",
		price = 30,
		slot = "effect",
	},
}

local CATALOGUE_BY_ID: { [string]: CosmeticItem } = {}
for _, item in ipairs(CATALOGUE) do
	CATALOGUE_BY_ID[item.id] = item
end

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function isOwned(profile: { OwnedCosmetics: { string } }, itemId: string): boolean
	for _, ownedId in ipairs(profile.OwnedCosmetics) do
		if ownedId == itemId then
			return true
		end
	end
	return false
end

local function buildShopPayload(userId: number): { [string]: any }
	local profile = PlayerDataService.getGameProfile(userId)
	local items: { { [string]: any } } = {}
	for _, item in ipairs(CATALOGUE) do
		local owned = if profile ~= nil then isOwned(profile, item.id) else false
		local equippedCosmetics: { [string]: any } = if profile ~= nil
			then profile.EquippedCosmetics :: { [string]: any }
			else {}
		local equipped = owned and (equippedCosmetics[item.slot] == item.id)
		table.insert(items, {
			Id = item.id,
			Name = item.name,
			Description = item.description,
			Price = item.price,
			Slot = item.slot,
			Owned = owned,
			Equipped = equipped,
		})
	end
	return { Items = items }
end

local function fireProfileUpdate(player: Player)
	local profile = PlayerDataService.getGameProfile(player.UserId)
	if not profile then
		return
	end
	Net.fire(player, RemoteNames.ProfileUpdated, {
		Jetons = profile.Jetons,
		Rang = profile.RangActuel,
		Perspicacite = profile.Perspicacite,
		PartiesJouees = profile.PartiesJouees,
		VerdictsCorrects = profile.VerdictsCorrects,
		VerdictsIncorrects = profile.VerdictsIncorrects,
		RangPrecedent = nil,
		EquippedFrame = (profile.EquippedCosmetics :: { [string]: any })["frame"],
	})
end

-- ─── Handlers ─────────────────────────────────────────────────────────────────

function CosmeticService.init()
	-- Demande du catalogue (ouverture boutique)
	Net.onServer(RemoteNames.ShopOpen, function(player: Player, _payload)
		Net.fire(player, RemoteNames.ShopDataReceived, buildShopPayload(player.UserId))
	end)

	-- Achat d'un cosmétique
	Net.onServer(RemoteNames.ShopPurchase, function(player: Player, payload)
		local itemId = payload.ItemId
		if type(itemId) ~= "string" then
			Net.fire(player, RemoteNames.ShopPurchaseResult, { Success = false, Message = "ID invalide." })
			return
		end

		local item = CATALOGUE_BY_ID[itemId]
		if not item then
			Net.fire(
				player,
				RemoteNames.ShopPurchaseResult,
				{ Success = false, Message = "Article introuvable." }
			)
			return
		end

		local profile = PlayerDataService.getGameProfile(player.UserId)
		if not profile then
			Net.fire(
				player,
				RemoteNames.ShopPurchaseResult,
				{ Success = false, Message = "Profil non chargé." }
			)
			return
		end

		if isOwned(profile, itemId) then
			Net.fire(
				player,
				RemoteNames.ShopPurchaseResult,
				{ Success = false, Message = "Article déjà possédé." }
			)
			return
		end

		if profile.Jetons < item.price then
			Net.fire(player, RemoteNames.ShopPurchaseResult, {
				Success = false,
				Message = string.format(
					"Jetons insuffisants (%d requis, %d disponibles).",
					item.price,
					profile.Jetons
				),
			})
			return
		end

		-- Transaction
		PlayerDataService.addJetons(player.UserId, -item.price)
		table.insert(profile.OwnedCosmetics, itemId)

		Net.fire(player, RemoteNames.ShopPurchaseResult, {
			Success = true,
			ItemId = itemId,
			Message = item.name .. " déverrouillé !",
		})
		Net.fire(player, RemoteNames.ShopDataReceived, buildShopPayload(player.UserId))
		fireProfileUpdate(player)

		print(
			string.format(
				"[CosmeticService] %s a acheté '%s' pour %d J",
				player.DisplayName,
				item.name,
				item.price
			)
		)
	end)

	-- Équiper un cosmétique possédé
	Net.onServer(RemoteNames.ShopEquip, function(player: Player, payload)
		local itemId = payload.ItemId
		if type(itemId) ~= "string" then
			return
		end

		local item = CATALOGUE_BY_ID[itemId]
		if not item then
			return
		end

		local profile = PlayerDataService.getGameProfile(player.UserId)
		if not profile then
			return
		end

		if not isOwned(profile, itemId) then
			return
		end

		profile.EquippedCosmetics[item.slot] = itemId

		Net.fire(
			player,
			RemoteNames.ShopEquipResult,
			{ Success = true, ItemId = itemId, Slot = item.slot }
		)
		Net.fire(player, RemoteNames.ShopDataReceived, buildShopPayload(player.UserId))

		print(string.format("[CosmeticService] %s a équipé '%s'", player.DisplayName, item.name))
	end)

	print("[CosmeticService] Initialisé — " .. #CATALOGUE .. " items en catalogue")
end

return CosmeticService
