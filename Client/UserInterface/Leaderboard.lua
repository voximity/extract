local keyboard = require(script.Parent.Parent.Keyboard)

local tdm = game:GetService("ReplicatedStorage").Mode.Value == "TDM"

---

local leaderboard = {}
leaderboard.leaderboard = {}

local ui

leaderboard.init = function()
	ui.leaderboard = Instance.new("Frame")
	ui.leaderboard.Visible = false
	ui.leaderboard.Parent = ui.screen
	
	leaderboard.update(leaderboard.leaderboard)
end

leaderboard.update = function(lb)
	if ui.leaderboard == nil or ui.leaderboard.Parent == nil then return end
	ui.leaderboard:ClearAllChildren()
	
	local valuesizes = {
		{name = "ping", size = 50},
		{name = "username", size = true},
		{name = "kills", size = 65},
		{name = "deaths", size = 65},
		{name = "kdr", size = 75},
		{name = "score", size = 75}
	}
	
	local staticsize = 0
	local autosizers = 0
	for i,v in next, valuesizes do
		if type(v.size) == "number" then
			staticsize = staticsize + v.size
		elseif v.size == true then
			autosizers = autosizers + 1
		end
	end
	local autosize = 1 / autosizers
	
	local gui = ui.leaderboard
	gui.BackgroundTransparency = 0.7
	gui.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	gui.BorderSizePixel = 0
	
	local titlebar = Instance.new("Frame")
	titlebar.Size = UDim2.new(1, 0, 0, 20)
	titlebar.BackgroundTransparency = 0.5
	titlebar.BorderSizePixel = 0
	titlebar.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	
	local padded = Instance.new("Frame")
	padded.Name = "Padding"
	padded.Size = UDim2.new(1, -20, 1, 0)
	padded.Position = UDim2.new(0, 10, 0, 0)
	padded.BackgroundTransparency = 1
	
	padded.Parent = titlebar
	titlebar.Parent = gui
	
	local lastpos = UDim2.new(0, 0, 0, 0)
	for i,v in next, valuesizes do
		local val = Instance.new("TextLabel")
		val.Name = v.name
		val.Text = v.name:upper()
		val.BackgroundTransparency = 1
		val.Font = "SourceSansBold"
		val.TextSize = 18
		val.TextXAlignment = "Left"
		val.TextColor3 = Color3.new(0.9, 0.9, 0.9)
		val.ClipsDescendants = true
		if type(v.size) == "number" then
			val.Size = UDim2.new(0, v.size, 1, 0)
		elseif v.size == true then
			val.Size = UDim2.new(autosize, -staticsize, 1, 0)
		end
		val.Position = lastpos
		lastpos = lastpos + UDim2.new(val.Size.X.Scale, val.Size.X.Offset, 0, 0)
		val.Parent = padded
	end
	
	for i,v in next, lb do
		local bar = titlebar:Clone()
		bar.BackgroundTransparency = 0.7
		if not tdm then
			if i % 2 == 0 then
				bar.BackgroundColor3 = Color3.new(0.35, 0.35, 0.35)
			else
				bar.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
			end
		else
			local player = game:GetService("Players"):FindFirstChild(v.username)
			bar.BackgroundColor3 = player and player.TeamColor and player.TeamColor.Color or Color3.new(0.35, 0.35, 0.35)
		end
		
		for a,b in next, v do
			local element = bar.Padding:FindFirstChild(a)
			if element ~= nil then
				element.Font = "SourceSans"
				element.Text = type(b) == "number" and tostring(math.floor(b * 100) / 100) or b
			end
		end
		
		bar.Position = UDim2.new(0, 0, 0, 20 * i)
		bar.Parent = gui
	end
	
	gui.Size = UDim2.new(0, 600, 0, 20 * (#gui:GetChildren() - 1))
	gui.Position = UDim2.new(0.5, -gui.Size.X.Offset / 2, 0.5, -gui.Size.Y.Offset / 2)
end

keyboard.bind("tab", function()
	if not ui.leaderboard or ui.leaderboard.Parent == nil then return end
	ui.leaderboard.Visible = true
end, function()
	if not ui.leaderboard or ui.leaderboard.Parent == nil then return end
	ui.leaderboard.Visible = false
end)

return function(gui) ui = gui return leaderboard end