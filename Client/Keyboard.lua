local inputservice = game:GetService("UserInputService")
local runservice = game:GetService("RunService")

---

local keyboard = {}

keyboard.keys = {}
keyboard.binds = {}

inputservice.InputBegan:connect(function(input)
	if inputservice:GetFocusedTextBox() ~= nil then return end	
	
	local k = input.KeyCode.Name:lower()
	keyboard.keys[k] = true
	
	for i,v in next, keyboard.binds do
		if v.key == k then
			v.ondown()
		end
	end
end)
inputservice.InputEnded:connect(function(input)
	if inputservice:GetFocusedTextBox() ~= nil then return end	
	
	local k = input.KeyCode.Name:lower()
	keyboard.keys[k] = false
	
	for i,v in next, keyboard.binds do
		if v.key == k then
			v.onup()
		end
	end
end)

keyboard.bind = function(key, ondown, onup)
	table.insert(keyboard.binds, {key = key, ondown = ondown, onup = onup or function() end})
end

return keyboard