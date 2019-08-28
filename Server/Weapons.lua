local network = require(script.Parent.NetworkServer)
local players = game:GetService("Players")
local storage = game:GetService("ReplicatedStorage")
local maff = require(storage.Shared.Math)
local rd = require(storage.Shared.Ragdoll)

local tdm = storage.Mode.Value == "TDM"

---

local scores = {}
scores.kill = 100
scores.headshot = 150

local weapons = {}
weapons.round = nil

local living = {}

weapons.get = function(name)
	assert(storage.Weapons.Config:FindFirstChild(name) ~= nil, "no weapon by name " .. name)
	local data = require(storage.Weapons.Config[name])
	return data
end

-- LEADERBOARD

weapons.leaderboard = {}

local function updateLeaderboard()
	for i,v in next, weapons.leaderboard do
		local kdr = 0
		if v.deaths ~= 0 then
			kdr = v.kills / v.deaths
		else
			kdr = v.kills
		end
		v.kdr = v.deaths == 0 and v.kills or v.kills / v.deaths
	end
	table.sort(weapons.leaderboard, function(a, b)
		return a.score == b.score and a.deaths < b.deaths or a.score > b.score
	end)
	network.sendEventAll("update leaderboard", weapons.leaderboard)
end

local function getLeaderPlayer(player)
	for i,v in next, weapons.leaderboard do
		if v.player == player then
			return v
		end
	end
	table.insert(weapons.leaderboard, {player = player, username = player.Name, kills = 0, deaths = 0, kdr = 0, score = 0, ping = "?"})
end
weapons.getLeaderPlayer = getLeaderPlayer
weapons.wipeleaderstats = function()
	for i,v in next, weapons.leaderboard do
		v.kills = 0
		v.deaths = 0
		v.kdr = 0
		v.score = 0
	end
	living = {}
	updateLeaderboard()
end
local function userPing(player)
	local num = math.random()
	local received = false
	local starttime = time()
	network.sendEvent(player, "ping", num)
	local conn = network.onEvent("pong " .. player.Name, function(p, n)
		if p == player and n == num then
			received = true
		end
	end)
	repeat wait() until received or time() - starttime > 30
	network.removeEvent("pong " .. player.Name)
	return math.floor((time() - starttime) * 500)
end

local function removeFromLiving(victim)
	for i = #living, 1, -1 do
		if living[i].name == victim.Name then
			return table.remove(living, i)
		end
	end
end
local function addToLiving(victim)
	removeFromLiving(victim)
	table.insert(living, {name = victim.Name, damage = {}, hitters = {}})
end
local function getLivingElement(victim)
	for i,v in next, living do
		if v.name == victim.Name then
			return v
		end
	end
end

local function earnPoints(player, points, reason, victim)
	getLeaderPlayer(player).score = getLeaderPlayer(player).score + points
	network.sendEvent(player, "chat add", string.format("<lightblue>[+%d] <>%s <nc:%s>%s<>!", points, reason, victim.Name, victim.Name))
end

local function playerDied(victim, killer, weapon, headshot, velocity)
	rd.ragdoll(victim)
	local livingElement = removeFromLiving(victim)
	if velocity ~= nil then network.sendEvent(victim, "apply velocity", velocity[1], velocity[2]) end
	
	local hitinfo = {}
	if killer and weapons.round.active and killer ~= victim then
		local kstats = getLeaderPlayer(killer)
		kstats.kills = kstats.kills + 1
		
		hitinfo.weapon = weapon or "?"
		hitinfo.distance = "?"
		if victim.Character ~= nil and killer.Character ~= nil then
			hitinfo.distance = (victim.Character.Torso.Position - killer.Character.Torso.Position).magnitude
		end
		hitinfo.taken_damage = livingElement and livingElement.damage[killer] or 0
		hitinfo.taken_hits = livingElement and livingElement.hitters[killer] or 0
		
		local killerLiving = getLivingElement(killer)
		
		hitinfo.given_damage = killerLiving and killerLiving.damage[victim] or 0
		hitinfo.given_hits = killerLiving and killerLiving.hitters[victim] or 0
		
		earnPoints(killer, headshot and scores.headshot or scores.kill, headshot and "Headshotted" or "Eliminated", victim)
	end
	
	network.sendEventAll("player died", victim, killer, weapon or "KILLED", headshot, hitinfo)
	
	if weapons.round.active and livingElement ~= nil then
		for i,v in next, livingElement.damage do
			if v > 50 and i ~= killer then
				earnPoints(i, math.floor(v), "Assisted in eliminating", victim)
			end
		end
	end
	
	updateLeaderboard()
end

network.onEvent("character died", function(player)
	if weapons.round.active then
		local vstats = getLeaderPlayer(player)
		vstats.deaths = vstats.deaths + 1
	end
	
	playerDied(player, nil, nil, nil, nil)
end)

players.PlayerAdded:connect(function(p)
	getLeaderPlayer(p)
	updateLeaderboard()
end)

players.PlayerRemoving:connect(function(p)
	for i = #weapons.leaderboard, 1, -1 do
		if weapons.leaderboard[i].player == p then
			table.remove(weapons.leaderboard, i)
		end
	end
	removeFromLiving(p)
	updateLeaderboard()
end)

spawn(function()
	local userready = {}
	while true do
		for i,v in next, game:GetService("Players"):GetPlayers() do
			if userready[v] == nil or userready[v] == true then
				spawn(function()
					local stats = getLeaderPlayer(v)
					userready[v] = false
					local ping = userPing(v)
					stats.ping = ping == -1 and "?" or ping
					userready[v] = true
				end)
			end
		end
		updateLeaderboard()
		wait(5)
	end
end)

-- END LEADERBOARD

local playSound = function(sound, parent)
	local s = sound:Clone()
	s.PlayOnRemove = true
	s.Pitch = maff.rand(0.97, 1.03, 2)
	s.Parent = parent or sound.Parent
	s:Destroy()
end

network.onEvent("play animation", function(player, weapon, name, last)
	network.sendEventAll("play animation", player, weapon, name, last)
end)



network.onEvent("deploy weapon", function(player, weapon)
	if player == game:GetService("Players").LocalPlayer then return end
	
	local char = player.Character
	for i,v in next, char:GetChildren() do
		if v.Name:sub(1, 10) == "Worldmodel" then
			v:Destroy()
		end
	end
	
	local data = weapons.get(weapon)
	local worldmodel-- = storage.Weapons.Models[data.model.name]:Clone()
	if data.model.worldmodel then
		worldmodel = storage.Weapons.Worldmodels[data.model.worldmodel]:Clone()
	else
		worldmodel = storage.Weapons.Models[data.model.name]:Clone()
	end
	worldmodel.Name = "Worldmodel" .. weapon
	worldmodel.Parent = char
	
	if data.shoot and not data.model.worldmodel then
		worldmodel[data.model.aim1].Transparency = 1
		worldmodel[data.model.aim2].Transparency = 1
	end
	worldmodel.LeftHand.Transparency = 1
	worldmodel.RightHand.Transparency = 1
	
	local function weld(a, b, c)
		local weld = Instance.new("Weld")
		weld.C0 = a.CFrame:inverse() * b.CFrame * (c or CFrame.new())
		weld.Part0 = a
		weld.Part1 = b
		weld.Name = "ToMain"
		weld.Parent = b
		local value = Instance.new("CFrameValue")
		value.Name = "DefaultPosition"
		value.Value = weld.C0
		value.Parent = weld
		return weld
	end
	local function newweld(a, b, c)
		local weld = Instance.new("Weld")
		weld.C0 = c
		weld.Part0 = a
		weld.Part1 = b
		weld.Name = "NewWeld"
		weld.Parent = b
		return weld
	end
	
	local main = worldmodel[data.model.main]	
	
	for i,v in next, worldmodel:GetChildren() do
		v.Anchored = false
		v.CanCollide = false
		if v:IsA("BasePart") and v ~= main then
			weld(main, v)
		end
	end
	
	newweld(worldmodel.LeftHand, char["Left Arm"], CFrame.new(1, 0, 0) * CFrame.Angles(0, 0, -math.pi / 2))--, CFrame.new(0, 0, -1))
	newweld(worldmodel.RightHand, char["Right Arm"], CFrame.new(1, 0, 0) * CFrame.Angles(0, 0, -math.pi / 2))--, CFrame.new(0, 0, -1))
	
	local weld = Instance.new("Weld")
	weld.C0 = data.view.fix * data.world.origin
	weld.Part0 = char.Torso
	weld.Part1 = main
	weld.Name = "RootWeld"
	weld.Parent = main
	local defvalue = Instance.new("CFrameValue")
	defvalue.Name = "DefaultPosition"
	defvalue.Value = weld.C0
	defvalue.Parent = weld
end)

math.randomseed(os.time())

weapons.requestSpawn = function(player)
	local livingplayers = {}
	for i,v in next, game:GetService("Players"):GetPlayers() do
		if v.Character ~= nil and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 and (tdm and v.TeamColor ~= player.TeamColor or not tdm) then
			table.insert(livingplayers, v)
		end
	end
	if #livingplayers >= 1 then
		local spawns = {}
		for i,v in next, (weapons.round.currentmap ~= "" and workspace[weapons.round.currentmap] or workspace):GetChildren() do
			if v:IsA("SpawnLocation") and (tdm and (v.TeamColor == player.TeamColor or v.TeamColor == BrickColor.new("Medium stone grey")) or not tdm) then
				local pos = v.Position
				local closestpos = math.huge
				
				for a,b in next, livingplayers do
					local c = b.Character
					local dist = (pos - c.HumanoidRootPart.Position).magnitude
					if dist < closestpos then
						closestpos = dist
					end
				end
				
				table.insert(spawns, {obj = v, closest = closestpos})
			end
		end
		table.sort(spawns, function(a, b) return a.closest > b.closest end)
		player.RespawnLocation = spawns[1].obj
		player:LoadCharacter()
		addToLiving(player)
	else
		local spawns = {}
		for i,v in next, (weapons.round.currentmap ~= "" and workspace[weapons.round.currentmap] or workspace):GetChildren() do
			if v:IsA("SpawnLocation") and (tdm and (v.TeamColor == player.TeamColor or v.TeamColor == BrickColor.new("Medium stone grey")) or not tdm) then
				table.insert(spawns, {obj = v, rand = math.random()})
			end
		end
		table.sort(spawns, function(a, b) return a.rand < b.rand end)
		player.RespawnLocation = spawns[1].obj
		player:LoadCharacter()
		addToLiving(player)
	end
end

function lerp(a, b, c)
	return a + (b - a) * c
end

function weaponFalloff(falloffdata, actualdist)
	if not falloffdata then
		return 1
	else
		
		local closestLow = 1
		for i,v in next, falloffdata do
			if actualdist > v.dist then
				closestLow = i
			end
		end
		local curData = falloffdata[closestLow]
		local nextData = falloffdata[math.min(#falloffdata, closestLow + 1)]
		local diffDist = nextData.dist - curData.dist
		local distOf = diffDist == 0 and 0 or (actualdist - curData.dist) / diffDist
		
		return lerp(curData.dmg, nextData.dmg, distOf)
		
	end
end

function bloodAtPosition(pos, parent, dmg)
	local part = Instance.new("Part")
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.FormFactor = "Custom"
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = CFrame.new(pos)
	part.Parent = parent
	
	local emitter = script.ParticleEmitter:Clone()
	emitter.Size = NumberSequence.new(lerp(2, 6, dmg / 100))
	emitter.Lifetime = NumberRange.new(lerp(2, 5, dmg / 100))
	emitter.Acceleration = Vector3.new(0, lerp(-30, -10, dmg / 100), 0)
	emitter.Parent = part
	
	emitter:Emit(1)
	delay(emitter.Lifetime.Max, function() part:Destroy() end)
end

function prepareTorsoWeld(char)
	local torso = char:WaitForChild("Torso")
	local root = char:WaitForChild("HumanoidRootPart")
	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = torso
	weld.C0 = CFrame.new()
	weld.Name = "ToTorso"
	weld.Parent = root
	local state = Instance.new("NumberValue")
	state.Value = 0
	state.Name = "State"
	state.Parent = weld
	local tstate = Instance.new("NumberValue")
	tstate.Value = 0
	tstate.Name = "TargetState"
	tstate.Parent = weld
	return weld
end

network.onEvent("can spawn", function(player)
	--return weapons.round.active and (tdm and player.Team ~= nil)
	if tdm then
		return weapons.round.active and player.Team ~= nil
	else
		return weapons.round.active
	end
end)
network.onEvent("respawn", function(player)
	if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then return end
	if not weapons.round.active then return end
	weapons.requestSpawn(player)
	repeat wait() until player.Character ~= nil
	prepareTorsoWeld(player.Character)
end)

network.onEvent("footstep sound", function(player, sound, volume)
	network.sendEventAll("footstep sound", sound, player, volume)
end)

network.onEvent("crouch", function(player, crouching)
	if player.Character then
		local char = player.Character
		local root = char.HumanoidRootPart
		local weld = root.ToTorso
		local value = weld.TargetState
		value.Value = crouching and 1 or 0
		print(value.Value, crouching)
	end
end)

network.onEvent("grenade threw", function(player, grenade, position, unit, remain, id)
	network.sendEventAll("grenade threw", player, grenade, position, unit, remain, id)
end)

network.onEvent("remote grenade detonate", function(player, id)
	network.sendEventAll("remote grenade detonate", player, id)
end)
network.onEvent("update grenade position", function(player, id, p, v, a)
	network.sendEventAll("update grenade position", player, id, p, v, a)
end)
network.onEvent("sound play", function(player, sound, parent)
	network.sendEventAll("sound play", player, sound, parent)
end)


network.onEvent("grenade explode", function(player, grenade, tracking)
	local data = weapons.get(grenade)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Position = tracking
	
	local sound = storage.Assets.Audio.Explosion:Clone()
	sound.PlayOnRemove = true
	
	local explosion = Instance.new("Explosion")
	explosion.BlastRadius = data.grenade.explosion.radius
	explosion.BlastPressure = 0
	explosion.DestroyJointRadiusPercent = 0
	explosion.Position = tracking
	
	part.Parent = workspace
	explosion.Parent = part
	sound.Parent = part
	sound:Destroy()
	delay(0.1, function() part:Destroy() end)
	local affected = {}
	
	explosion.Hit:connect(function(part, distance)
		local parent = part.Parent
		if parent:FindFirstChild("Humanoid") and parent.Humanoid.Health > 0 and not affected[parent] then
			if distance <= data.grenade.explosion.radius then
				local damage
				if distance <= data.grenade.explosion.radius * data.grenade.explosion.destroy then
					damage = 100
				else
					damage = (1 - (distance - data.grenade.explosion.radius * data.grenade.explosion.destroy) / (data.grenade.explosion.radius * (1 - data.grenade.explosion.destroy))) * 100
				end
				
				affected[parent] = true
				
				local oldHealth = parent.Humanoid.Health
				
				local victim = game:GetService("Players"):GetPlayerFromCharacter(parent)
				if tdm then
				--if (tdm and victim.Team == player.Team and victim ~= player or not tdm) then return end
					if victim.Team == player.Team and victim ~= player then return end
				end
				
				parent.Humanoid:TakeDamage(math.floor(damage))
				
				if victim then
					local livingElement = getLivingElement(victim)
					livingElement.damage[player] = (livingElement.damage[player] or 0) + math.floor(damage)
					livingElement.hitters[player] = (livingElement.hitters[player] or 0) + 1
				end
				
				if oldHealth - damage <= 0 then
					parent:BreakJoints()
					
					local velocity
					local torso = parent.Torso
					local unit = (torso.Position - tracking).unit
					local distance = (torso.Position - tracking).magnitude
					local percent = 1 - distance / data.grenade.explosion.radius
					velocity = unit * percent * data.grenade.explosion.knockback
					
					if victim ~= nil then
						playerDied(victim, player, data.name, false, {"Torso", velocity})
					end
				end
			end
		end
	end)
end)

game:GetService("RunService").Heartbeat:connect(function()
	for i,v in next, game.Players:GetPlayers() do
		if v.Character ~= nil then
			local char = v.Character
			local root = char:WaitForChild("HumanoidRootPart")
			local weld = root:WaitForChild("ToTorso")
			local torso = char.Torso
			local lh, rh = torso:WaitForChild("Left Hip"), torso:WaitForChild("Right Hip")
			local value = weld:WaitForChild("State")
			local targetvalue = weld:WaitForChild("TargetState")
			value.Value = maff.lerp(value.Value, targetvalue.Value, 0.15)
			
			weld.C0 = CFrame.new(0, maff.lerp(0, -1.5, value.Value), maff.lerp(0, 1, value.Value))
			
			local fix = CFrame.Angles(0, math.pi / 2, 0)
			
			local lhb, lha = CFrame.new(-1, -1, 0) * fix:inverse(), CFrame.new(-1, 0.5, -0.6) * fix:inverse()
			local rhb, rha = CFrame.new( 1, -1, 0) * fix, CFrame.new( 1, 0.5, -0.6) * fix
			
			lh.C0 = lhb:lerp(lha, value.Value)
			rh.C0 = rhb:lerp(rha, value.Value)
		end
	end
end)

network.onEvent("weapon fired", function(player, weapon, bulletdata, from, sound, d)
	
	local weapondata = weapons.get(weapon)
	
	--if weapondata.shoot ~= nil then
		--local sound = storage.Weapons.Models[weapondata.name][weapondata.model.muzzle]:FindFirstChild("Fire")
		--if sound ~= nil then
		--	playSound(sound, player.Character.Head)
		--end
		
	--end
	
	network.sendEventAll("weapon fired", player, weapon, bulletdata, from, sound, d)
	
end)

network.onEvent("weapon swung", function(player, weapon, ray, part, backstab)
	
	local data = weapons.get(weapon)
	print(part and part.Name or nil)
	if part ~= nil then
		local parent = part.Parent
		if parent:FindFirstChild("Humanoid") and parent.Humanoid.Health > 0 and player.Character and player.Character.Humanoid.Health > 0 then
			local humanoid = parent.Humanoid
			local victim = players:GetPlayerFromCharacter(parent)
			local damage = data.melee.damage * (backstab and data.melee.backstab or 1)
			if tdm and victim.Team == player.Team then return end
			
			humanoid:TakeDamage(damage)
			
			local livingElement = getLivingElement(victim)
			livingElement.damage[player] = (livingElement.damage[player] or 0) + math.floor(damage)
			livingElement.hitters[player] = (livingElement.hitters[player] or 0) + 1
			
			if humanoid.Health <= 0 then
				-- they died!
				if victim ~= nil then
					playerDied(victim, player, data.name, false)
				end
				humanoid.Health = 0
				parent:BreakJoints()
				rd.ragdoll(victim)
			end
		end
	end
	
end)
network.onEvent("grenade destroyed", function(player, fromplayer, hitdata)
	network.sendEvent(fromplayer, "grenade destroyed", player, hitdata)
end)

network.onEvent("bullet hit", function(player, data, v)
	
	local part = v.part
	local hit = v.hit
	local ray = v.ray
	if part ~= nil and ray ~= nil and hit ~= nil then
		local parent = part.Parent
		if parent:FindFirstChild("Humanoid") and parent.Humanoid.Health > 0 then
			-- hit a humanoid
			local humanoid = parent.Humanoid
			local partname = part.Name
			local victim = players:GetPlayerFromCharacter(parent)
			if tdm and victim.Team == player.Team then return end
			if victim == player then return end
			
			local damage = 1
			
			if partname == "Torso" then
				damage = 1
			elseif partname == "Head" then
				damage = data.shoot.dmg.head
			else
				damage = data.shoot.dmg.limb
			end
			
			local distance = (v.from - hit).magnitude
			local falloff = weaponFalloff(data.shoot.falloff, distance)
			
			local totaldamage = damage * data.shoot.dmg.base * falloff
			
			local oldhealth = humanoid.Health
			humanoid:TakeDamage(totaldamage)
			local livingElement = getLivingElement(victim)
			livingElement.damage[player] = (livingElement.damage[player] or 0) + math.floor(totaldamage)
			livingElement.hitters[player] = (livingElement.hitters[player] or 0) + 1
			bloodAtPosition(hit, parent, totaldamage)
			
			if humanoid.Health <= 0 or oldhealth - totaldamage <= 0 then
				-- they died!
				humanoid.Health = 0
				parent:BreakJoints()
				if victim ~= nil then
					local unit = (part.Position - ray.Origin).unit
					playerDied(victim, player, data.name, partname == "Head", 
						(partname == "Head" and {"Head", unit * totaldamage}) or
						(partname == "Torso" and {"Torso", unit * totaldamage * 0.7}) or
						({"Torso", unit * totaldamage * 0.4}))
				end
			end
		end
	end
		
end)

return weapons