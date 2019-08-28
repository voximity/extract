local storage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local network = require(script.Parent.NetworkServer)

local tdm = storage.Mode.Value == "TDM"

local teamservice, teams, teamnames

if tdm then
	teamservice = game:GetService("Teams")
	teams = {a = teamservice["Team A"], b = teamservice["Team B"]}
	teamnames = require(script.TeamNames) -- Just a table of random team names I came up with
end

---

local round = {}
round.weapons = nil
round.chat = nil
round.maps = {
	"dm_library",
	"dm_transport",
	"dm_isolation",
}

round.defaultlighting = {
	Ambient = Color3.new(0, 0, 0),
	Brightness = 1,
	ColorShift_Bottom = Color3.new(0, 0, 0),
	ColorShift_Top = Color3.new(0, 0, 0),
	GlobalShadows = true,
	OutdoorAmbient = Color3.new(127 / 255, 127 / 255, 127 / 255),
	Outlines = false,
	TimeOfDay = "14:00:00",
	GeographicLatitude = 41.733,
	FogColor = Color3.new(191 / 255, 191 / 255, 191 / 255),
	FogEnd = 100000,
	FogStart = 0
}

round.getmap = function(name)
	return storage.Maps:FindFirstChild(name)
end
round.getmapdata = function(name)
	local map = round.getmap(name)
	return map and require(round.getmap(name).MapData)
end
round.verifymap = function(model)
	local mapdata = model:FindFirstChild("MapData")
	assert(mapdata ~= nil, "No MapData ModuleScript")
	local data = require(mapdata)
	assert(data.name and data.author, "No name or author property in MapData ModuleScript")
	for i = 1, #data.name do
		if data.name:sub(i, i) == " " then
			error("Name has spaces, use underscores instead")
			break
		end
	end
	assert(data.name == model.Name, "MapData name property doesn't equal Model name")
	local spawns = {}
	for i,v in next, model:GetChildren() do
		if v:IsA("SpawnLocation") then
			v.Duration = 0
			table.insert(spawns, v)
		end
	end
	if tdm then
		assert(#spawns >= 12, "Needs at least 12 spawns")
	else
		assert(#spawns >= 8, "Needs at least 8 spawns")
	end
	return true
end
round.active = false
round.currentmap = ""
round.nextmap = ""

function contains(t, e)
	for i,v in next, t do
		if v == e then
			return true
		end
	end
	return false
end
function randomButNot(t, exclude)
	local x
	repeat
		x = t[math.random(#t)]
	until not contains(exclude or {}, x)
	return x
end
function shuffle(t)
	local original = {}
	for i,v in next, t do
		table.insert(original, v)
	end
	local new = {}
	repeat
		local index = math.random(#original)
		table.insert(new, table.remove(original, index))
	until #original == 0
	return new
end

if tdm then
	round.playersonteam = function(team)
		local p = {}
		for i,v in next, players:GetPlayers() do
			if v.Team == team then
				table.insert(p, v)
			end
		end
		return p
	end
	round.addtoteam = function(player)
		local aplayers = round.playersonteam(teams.a)
		local bplayers = round.playersonteam(teams.b)
		
		if #aplayers == #bplayers then
			player.Team = math.random(2) == 1 and teams.a or teams.b
		else
			player.Team = #aplayers > #bplayers and teams.b or teams.a
		end
	end
	round.shuffleteams = function()
		teams.a.Name = randomButNot(teamnames)
		teams.b.Name = randomButNot(teamnames, {teams.a.Name})
		
		for i,v in next, players:GetPlayers() do
			v.Team = nil
		end
		
		for i,v in next, shuffle(players:GetPlayers()) do
			round.addtoteam(v)
		end
	end
	round.teamscore = function(team)
		local p = round.playersonteam(team)
		local score = 0
		for i,v in next, p do
			score = score + round.weapons.getLeaderPlayer(v).score
		end
		return score
	end
end

game:GetService("Players").PlayerAdded:connect(function(p)
	if tdm then round.addtoteam(p) end
	wait(1)
	if round.currentmap and round.currentmap ~= "" then
		network.sendEvent(p, "map change", round.getmapdata(round.currentmap))
	end
end)

round.begin = function(name)
	local data = round.getmapdata(name)
	local map = round.getmap(name):Clone()
	map.Parent = workspace
	local sky = map:FindFirstChildOfClass("Sky")
	if sky then
		sky:Clone().Parent = game:GetService("Lighting")
	end
	if data.lighting then
		for i,v in next, data.lighting do
			pcall(function()
				game:GetService("Lighting")[i] = v
				wait()
			end)
		end
	end
	if map:FindFirstChild("Ambient") and map.Ambient:IsA("Sound") then
		map.Ambient:Play()
	end
	round.currentmap = name
	network.sendEventAll("map change", data)
	wait(5)
	round.weapons.wipeleaderstats()
	if tdm then round.shuffleteams() end
	round.chat.add("The round has begun!")
	round.active = true
	spawn(function()
		local starttime = time()
		repeat
			if not round.active then
				break
			end
			wait()
		until time() - starttime > 15 * 60
		if round.active then
			round.stop()
		end
	end)
end

round.stop = function()
	round.active = false
	for i,v in next, game:GetService("Players"):GetPlayers() do
		if v.Character ~= nil then
			spawn(function()
				v.Character:BreakJoints()
				wait(0.5)
				v.Character:Destroy()
			end)
		end
	end
	if round.currentmap ~= "" then
		local cr = game:GetService("Workspace"):FindFirstChild(round.currentmap)
		if cr:FindFirstChild("Ambient") and cr.Ambient:IsA("Sound") then
			cr.Ambient:Play()
		end
		cr:Destroy()
		game:GetService("Lighting"):ClearAllChildren()
		for i,v in next, round.defaultlighting do
			pcall(function()
				game:GetService("Lighting")[i] = v
			end)
		end
	end
	local nextround = round.currentmap
	if round.nextmap == "" then
		local pmaps = {}
		for i,v in next, round.maps do
			if v ~= round.currentmap then
				table.insert(pmaps, {map = v, r = math.random()})
			end
		end
		table.sort(pmaps, function(a, b) return a.r > b.r end)
		if #pmaps >= 1 then
			nextround = pmaps[1].map
		end
	else
		nextround = round.nextmap
	end
	round.nextmap = ""
	local data = round.getmapdata(nextround)
	
	if tdm then
		local ascore = round.teamscore(teams.a)
		local bscore = round.teamscore(teams.b)
		local winner = ascore > bscore and teams.a or (bscore > ascore and teams.b or nil)
		local format = winner and "<" .. tostring(winner.TeamColor) .. ">" .. winner.Name .. " <white>win!<>" or "<b>Draw!<>"
		
		round.chat.add(format .. " Next map is " .. round.chat.nameformat(data.name) .. " by " .. round.chat.nameformat(data.author) .. ".")
	else
		round.chat.add("Next map is " .. round.chat.nameformat(data.name) .. " by " .. round.chat.nameformat(data.author) .. ".")
	end
	wait(1)
	round.begin(nextround)
end

for i = #round.maps, 1, -1 do
	local s, e = pcall(function()
		round.verifymap(round.getmap(round.maps[i]))
	end)
	if not s then
		table.remove(round.maps, i)
		print("Removing map due to error in verification: " .. e)
	end
end

_G.round = round

return round