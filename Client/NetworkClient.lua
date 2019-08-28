local storage = game:GetService("ReplicatedStorage")
local events = storage:WaitForChild("Events")

local event = events.NetworkEvent
local func = events.NetworkFunction

---

local network = {}

network.bindings = {}

network.onEvent = function(eventName, binding)
	table.insert(network.bindings, {name = eventName, binding = binding})
end


-- sending
network.sendEvent = function(eventName, ...)
	event:FireServer(eventName, ...)
end
network.sendFunc = function(eventName, ...)
	return func:InvokeServer(eventName, ...)
end


-- receiving
event.OnClientEvent:connect(function(eventName, ...)
	for i,v in next, network.bindings do
		if v.name == eventName then
			v.binding(...)
		end
	end
end)
function func.OnClientInvoke(eventName, ...)
	for i,v in next, network.bindings do
		if v.name == eventName then
			return v.binding(...)
		end
	end
end


return network