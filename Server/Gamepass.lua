local marketplace = game:GetService("MarketplaceService")

---

local gamepass = {}

gamepass.cache = {}

gamepass.i = {}
gamepass.i.chateffects = 4747921
gamepass.i.customname = 4748331

gamepass.prompt = function(player, id)
	marketplace:PromptPurchase(player, id)
end

gamepass.haspass = function(player, id)
	if gamepass.cache[id] ~= nil then
		for i,v in next, gamepass.cache[tostring(id)] do
			if v == player.UserId then
				return true
			end
		end
	else
		gamepass.cache[tostring(id)] = {}
	end
	
	if marketplace:UserOwnsGamePassAsync(player.UserId, id) or player:GetRankInGroup(2603658) >= 250 then
		table.insert(gamepass.cache[tostring(id)], player.UserId)
		return true
	end
end

return gamepass