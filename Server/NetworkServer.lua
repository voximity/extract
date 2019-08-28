local storage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local events = storage:WaitForChild("Events")

local event = events.NetworkEvent
local func = events.NetworkFunction

---

local network = {}

network.bindings = {}

network.onEvent = function(eventName, binding)
	table.insert(network.bindings, {name = eventName, binding = binding})
end
network.removeEvent = function(eventName)
	for i = #network.bindings, 1, -1 do
		if network.bindings[i].name == eventName then
			table.remove(network.bindings, i)
		end
	end
end


-- sending
network.sendEvent = function(player, eventName, ...)
	event:FireClient(player, eventName, ...)
end
network.sendFunc = function(player, eventName, ...)
	return func:InvokeClient(player, eventName, ...)
end

network.sendEventAll = function(eventName, ...)
	for i,v in next, players:GetPlayers() do
		network.sendEvent(v, eventName, ...)
	end
end
network.sendEventAllBut = function(eventName, exclude, ...)
	for i,v in next, players:GetPlayers() do
		local skip = false
		for a,b in next, exclude do
			if v == b then
				skip = true
			end
		end
		if skip then break end
		network.sendEvent(v, eventName, ...)
	end
end


-- receiving
event.OnServerEvent:connect(function(player, eventName, ...)
	for i,v in next, network.bindings do
		if v.name == eventName then
			v.binding(player, ...)
		end
	end
end)
function func.OnServerInvoke(player, eventName, ...)
	for i,v in next, network.bindings do
		if v.name == eventName then
			return v.binding(player, ...)
		end
	end
end


return network