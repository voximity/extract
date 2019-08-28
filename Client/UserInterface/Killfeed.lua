local c = require(script.Parent.Parent.Constants)

---

local killfeed = {}
killfeed.feed = {}
local ui

local chat = {}
chat.defaultcolors = {
 	BrickColor.new("Bright red"),
 	BrickColor.new("Bright blue"),
 	BrickColor.new("Earth green"),
 	BrickColor.new("Bright violet"),
 	BrickColor.new("Bright orange"),
 	BrickColor.new("Bright yellow"),
 	BrickColor.new("Light reddish violet"),
 	BrickColor.new("Brick yellow"),
}
chat.namevalue = function(pName)
 	local value = 0
 	for index = 1, #pName do 
 		local cValue = string.byte(string.sub(pName, index, index))
 		local reverseIndex = #pName - index + 1
 		if #pName%2 == 1 then 
 			reverseIndex = reverseIndex - 1			
 		end
 		if reverseIndex%4 >= 2 then 
 			cValue = -cValue 			
 		end 
 		value = value + cValue 
 	end 
 	return value%8
end
chat.namecolor = function(name)
	local player = game:GetService("Players"):FindFirstChild(name)
	return player and player.Team and player.TeamColor and player.TeamColor.Color or chat.defaultcolors[chat.namevalue(name) + 1].Color
end

killfeed.init = function()
	ui.killfeed = Instance.new("Frame")
	ui.killfeed.Name = "Killfeed"
	ui.killfeed.BackgroundTransparency = 1
	ui.killfeed.Size = UDim2.new(0, 400, 0, (c.ui.feed.size + 8) * 8)
	ui.killfeed.Position = UDim2.new(0, 10, 0, 10)
	ui.killfeed.ClipsDescendants = true
	ui.killfeed.Parent = ui.screen
	
	local oldfeed = {}
	for i,v in next, killfeed.feed do
		oldfeed[i] = v
	end
	killfeed.feed = {}
	for i,v in next, oldfeed do
		if #oldfeed - i < 15 then
			killfeed.add(v.killer, v.victim, v.weapon, v.headshot, true)
		end
	end
end

killfeed.add = function(killer, victim, weapon, headshot, skiptween)
	local stroketrans = 0.7
	
	local f = Instance.new("Frame")
	f.Name = "elim_"..killer.."_"..victim
	f.BorderSizePixel = 0
	f.BackgroundTransparency = 0.75
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.Size = UDim2.new(1, 0, 0, c.ui.feed.size + 8)
	f.Position = UDim2.new(0, 0, 0, -f.Size.Y.Offset)
	f.Parent = ui.killfeed
	
	local kl = Instance.new("TextLabel")
	kl.Text = killer
	kl.TextColor3 = chat.namecolor(killer)
	kl.BackgroundTransparency = 1
	kl.Font = "SourceSans"
	kl.TextStrokeColor3 = Color3.new(0, 0, 0)
	kl.TextStrokeTransparency = stroketrans
	kl.TextSize = c.ui.feed.size
	kl.Size = UDim2.new(1, 0, 0, c.ui.feed.size + 8)
	
	local dl = Instance.new("TextLabel")
	dl.Text = "   " .. weapon:upper() .. "   "
	dl.TextColor3 = Color3.new(0.6, 0.6, 0.6)
	dl.BackgroundTransparency = 1
	dl.Font = "SourceSans"
	dl.TextStrokeColor3 = Color3.new(0, 0, 0)
	dl.TextStrokeTransparency = stroketrans
	dl.TextSize = c.ui.feed.size
	dl.Size = UDim2.new(1, 0, 0, c.ui.feed.size + 8)
	
	local hs
	if headshot then
		hs = Instance.new("ImageLabel")
		hs.Image = "rbxgameasset://Images/headshot"
		hs.Name = "Headshot"
		hs.BackgroundTransparency = 1
		hs.AnchorPoint = Vector2.new(0.5, 0.5)
		hs.Size = UDim2.new(0, c.ui.feed.size, 0, c.ui.feed.size)
		hs.Parent = f
	end
	
	local vl = Instance.new("TextLabel")
	vl.Text = victim
	vl.TextColor3 = chat.namecolor(victim)
	vl.BackgroundTransparency = 1
	vl.Font = "SourceSans"
	vl.TextStrokeColor3 = Color3.new(0, 0, 0)
	vl.TextStrokeTransparency = stroketrans
	vl.TextSize = c.ui.feed.size
	vl.Size = UDim2.new(1, 0, 0, c.ui.feed.size + 8)
	
	kl.Parent, dl.Parent, vl.Parent = f, f, f	
	
	kl.Size = UDim2.new(0, kl.TextBounds.X, 1, 0)
	dl.Size = UDim2.new(0, dl.TextBounds.X, 1, 0)
	vl.Size = UDim2.new(0, vl.TextBounds.X, 1, 0)
	
	kl.Position = UDim2.new(0, 8, 0, 0)
	dl.Position = kl.Position + UDim2.new(0, kl.TextBounds.X, 0, 0)
	if hs then
		hs.Position = dl.Position + UDim2.new(0, dl.TextBounds.X + 12, 0.5, 0)
		vl.Position = UDim2.new(0, hs.Position.X.Offset + hs.Size.X.Offset + 4, 0, 0)
	else
		vl.Position = dl.Position + UDim2.new(0, dl.TextBounds.X, 0, 0)
	end

	f.Size = UDim2.new(0, vl.Position.X.Offset + vl.Size.X.Offset + 8, 0, c.ui.feed.size + 8)
	
	table.insert(killfeed.feed, {obj = f, pos = f.Position, killer = killer, victim = victim, weapon = weapon, headshot = headshot})
	
	for i,v in next, killfeed.feed do
		v.pos = v.pos + UDim2.new(0, 0, 0, c.ui.feed.size + 10)
		if skiptween then
			v.obj.Position = v.pos
		else
			v.obj:TweenPosition(v.pos, "InOut", "Quint", 0.5, true)
		end
	end
end

return function(gui) ui = gui return killfeed end