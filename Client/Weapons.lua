local players = game:GetService("Players")
local player = players.LocalPlayer
local mouse = player:GetMouse()

local runservice = game:GetService("RunService")

local inputservice = game:GetService("UserInputService")

local textservice = game:GetService("TextService")

local camera = workspace.CurrentCamera

local storage = game:GetService("ReplicatedStorage")
local weapons = storage.Weapons
local models = weapons.Models
local config = weapons.Config

local attachments = storage.Attachments
local amodels = attachments.Models
local aconfig = attachments.Config

local c = require(script.Parent.Constants)
local maff = require(storage.Shared.Math)
local cb = require(storage.Shared.CubicBezier)
local bullet = require(storage.Shared.Bullet)
local network = require(script.Parent.NetworkClient)
local keyboard = require(script.Parent.Keyboard)

local tdm = storage.Mode.Value == "TDM"

---

local m = {}

m.character = nil

m.deployed = {}

m.remoteset = false
m.remotegrenades = {}

m.resetDeployed = function()
	if m.deployed.laser ~= nil then
		m.deployed.laser:Destroy()
	end
	if m.deployed.model ~= nil then
		m.deployed.model:Destroy()
		if m.deployed.ui then
			m.deployed.ui:Destroy()
		end
	end	
	
	m.deployed = {
		data = nil,
		model = nil,
		ui = nil,
		ammo = 0,
		chambered = false,
		firemode = "",
		burstcount = 0,
		canfire = true,
		cooking = false,
		reloading = false,
		wasReloading = false,
		aimdiff = nil,
		defaultpos = {},
		clickedsince = false,
		attachments = {},
		laser = nil,
		anim = {
			active = false,
			offset = CFrame.new(),
			lastkey = {},
			cloned = {}
		}
	}
end

m.bullets = {}

m.resetDeployed()

local function createArm(left, color)
	--[[local arm = Instance.new("Part")
	arm.Name = (left and "Left" or "Right") .. "Arm"
	arm.Anchored = true
	arm.Material = "SmoothPlastic"
	arm.FormFactor = "Custom"
	arm.TopSurface = "Smooth"
	arm.BottomSurface = "Smooth"
	arm.Size = Vector3.new(1, 1, 2)
	arm.CanCollide = false
	arm.BrickColor = color or BrickColor.new("Pastel brown")]]
	
	local arm = storage.Assets[left and "LeftArm" or "RightArm"]:Clone()
	
	return arm
end



-- Muzzle UI

local function updateMuzzleUi(adornee, bbg, ammo, chambered, max, firemode, reloading)
	bbg.Adornee = adornee
	
	bbg.Ammo.Text = tostring(ammo + (chambered and 1 or 0))
	bbg.Ammo.Size = UDim2.new(0, bbg.Ammo.TextBounds.X, 0, bbg.Ammo.TextBounds.Y)
	
	bbg.MaxAmmo.Text = " / " .. tostring(max)
	bbg.MaxAmmo.Position = bbg.Ammo.Position + UDim2.new(0, bbg.Ammo.TextBounds.X, 0, 0)
	
	bbg.Ammo.Position = UDim2.new(1, -bbg.Ammo.TextBounds.X - bbg.MaxAmmo.TextBounds.X, 0.5, -bbg.Ammo.TextBounds.Y / 2)
	
	bbg.MaxAmmo.Size = UDim2.new(0, bbg.MaxAmmo.TextBounds.X, 0, bbg.MaxAmmo.TextBounds.Y)
	
	if reloading then
		bbg.FireMode.Text = "RELOADING"
		bbg.FireMode.Font = "SourceSansItalic"
	else
		bbg.FireMode.Text = firemode
		bbg.FireMode.Font = "SourceSansLight"
	end
	bbg.FireMode.Position = UDim2.new(0, 0, 0.5, -bbg.Ammo.TextBounds.Y / 2 + c.ui.ammo.size - 6)
end
local function createMuzzleUi()
	local bbg = Instance.new("BillboardGui")
	bbg.StudsOffset = Vector3.new(-1.1, 0, 0)
	bbg.Size = UDim2.new(1.5, 0, 1, 0)
	bbg.AlwaysOnTop = true
	bbg.Name = "MuzzleGui"
	
	local ammocount = Instance.new("TextLabel")
	ammocount.Name = "Ammo"
	ammocount.BackgroundTransparency = 1
	ammocount.Font = "SourceSansBold"
	ammocount.TextColor3 = c.ui.ammo.color
	ammocount.TextSize = c.ui.ammo.size
	ammocount.Size = UDim2.new(1, 0, 1, 0)
	ammocount.TextXAlignment = "Left"
	ammocount.TextStrokeColor3 = Color3.new(0, 0, 0)
	ammocount.TextStrokeTransparency = 0.5
	ammocount.Parent = bbg
	
	local maxammo = Instance.new("TextLabel")
	maxammo.Name = "MaxAmmo"
	maxammo.BackgroundTransparency = 1
	maxammo.Font = "SourceSansLight"
	maxammo.TextColor3 = Color3.new(1, 1, 1)
	maxammo.TextSize = c.ui.ammo.size
	maxammo.Size = UDim2.new(1, 0, 1, 0)
	maxammo.TextXAlignment = "Left"
	maxammo.TextStrokeColor3 = Color3.new(0, 0, 0)
	maxammo.TextStrokeTransparency = 0.5
	maxammo.Parent = bbg
	
	local firemode = Instance.new("TextLabel")
	firemode.Name = "FireMode"
	firemode.BackgroundTransparency = 1
	firemode.Font = "SourceSansLight"
	firemode.TextColor3 = Color3.new(1, 1, 1)
	firemode.TextSize = ammocount.TextSize - 12
	firemode.Size = UDim2.new(1, 0, 0, 24)
	firemode.TextXAlignment = "Right"
	firemode.TextStrokeColor3 = Color3.new(0, 0, 0)
	firemode.TextStrokeTransparency = 0.5
	firemode.Parent = bbg
	
	return bbg
end

local function contains(t, a)
	for i,v in next, t do
		if v == a then
			return true
		end
	end
	return false
end


-- Getting/deploying

m.get = function(name)
	assert(config:FindFirstChild(name) ~= nil, "no weapon found by name " .. name)
	
	return require(config[name])
end
m.getAttachment = function(name)
	assert(aconfig:FindFirstChild(name) ~= nil, "no attachment found by name " .. name)
	
	return require(aconfig[name])
end
m.isdeployed = function()
	return m.deployed.data ~= nil
end
m.deployAttachment = function(name)
	if m.deployed.data == nil  then return end
	
	local wdata = m.deployed.data
	local wmodel = m.deployed.model
	
	local adata = m.getAttachment(name)
	local amodel = amodels:FindFirstChild(adata.model):Clone()
	local attach = amodel[adata.attach]
	amodel.PrimaryPart = attach
	attach.Transparency = 1

	local aimdiff
	
	if adata.type:lower() == "sight" then
		local aim1 = amodel[adata.sight.aim1]
		local aim2 = amodel[adata.sight.aim2]
		aim1.Transparency = 1
		aim2.Transparency = 1
		
		aimdiff = aim1.CFrame:inverse() * CFrame.new(aim1.Position, aim2.Position)
	elseif adata.type:lower() == "underbarrel" then
		if adata.underbarrel.lhand then
			amodel[adata.underbarrel.lhand].Transparency = 1
		end
		if adata.underbarrel.laser then
			local l = Instance.new("Part")
			l.Transparency = 1
			l.Anchored = true
			l.CanCollide = false
			l.Size = Vector3.new(adata.underbarrel.laser.size, adata.underbarrel.laser.size, 0.05)
			
			--[[local decal = Instance.new("Decal")
			decal.Face = Enum.NormalId.Front
			decal.Texture = adata.underbarrel.laser.image
			decal.Parent = l]]
			
			local gui = Instance.new("SurfaceGui")
			gui.Face = "Front"
			gui.CanvasSize = Vector2.new(200, 200)
			gui.Parent = l
			
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.Image = adata.underbarrel.laser.image
			img.Size = UDim2.new(1, 0, 1, 0)
			img.ImageColor3 = adata.underbarrel.laser.color or Color3.new(1, 1, 1)
			img.Parent = gui
			
			m.deployed.laser = l
			l.Parent = camera
		end
	end
	
	amodel.Parent = wmodel
	
	table.insert(m.deployed.attachments, {model = amodel, data = adata, atype = adata.type, aimdiff = aimdiff})
end
m.getAttachmentsOfType = function(t)
	local as = {}
	for i,v in next, m.deployed.attachments do
		if v.atype:lower() == t then
			table.insert(as, v)
		end
	end
	return as
end
m.deploy = function(name, ammo, selectedAttachments, chambered)
	if m.character.get().Humanoid.Health <= 0 then return end
	m.resetDeployed()	
	
	m.deployed.chambered = true
	
	local data = m.get(name)
	local model = models[data.model.name]:Clone()
	
	if data.deployed then
		data.deployed(model)
	end
	
	m.pos.current = CFrame.new()
	m.pos.target = CFrame.new()
	
	m.pos.origincurrent = data.view.origin * CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(-7, 0, 0)
	m.pos.origintarget = CFrame.new()
	
	model.PrimaryPart = model[data.model.main]
	model.LeftHand.Transparency = 1
	model.RightHand.Transparency = 1

	for i,v in next, model:GetChildren() do
		if v:IsA("BasePart") and v.Name:sub(#v.Name - 5):lower() == "attach" then
			v.Transparency = 1
		end
	end
	
	local leftarm = createArm(true)
	local rightarm = createArm(false)
	leftarm.Parent = model
	rightarm.Parent = model
	
	if data.shoot then
		local aim1 = model[data.model.aim1]
		local aim2 = model[data.model.aim2]
		aim1.Transparency = 1
		aim2.Transparency = 1
		m.deployed.aimdiff = aim1.CFrame:inverse() * CFrame.new(aim1.Position, aim2.Position)
	end
	--aim1.CFrame = CFrame.new(aim1.Position, aim2.Position)
	--m.deployed.aimdiff = m.deployed.aim1diff:inverse() * aim1.CFrame
	
	for i,v in next, model:GetChildren() do
		if v:IsA("BasePart") then
			m.deployed.defaultpos[v] = model[data.model.main].CFrame:inverse() * v.CFrame
		end
	end	
	
	model.Parent = camera
	
	m.deployed.model = model
	m.deployed.data = data
	m.deployed.ammo = ammo or (data.shoot and data.shoot.ammo or nil) or (data.grenade and data.grenade.count or nil)
	
	if data.shoot then
		m.deployed.firemode = data.shoot.firemode[1]
		m.deployed.ui = createMuzzleUi()
		updateMuzzleUi(model[data.model.adornee], m.deployed.ui, m.deployed.ammo, m.deployed.chambered, m.deployed.data.shoot.ammo, m.deployed.firemode, false)
		m.deployed.ui.Parent = player.PlayerGui
	end
	
	for i,v in next, selectedAttachments or {} do
		m.deployAttachment(v)
	end
	
	network.sendEvent("deploy weapon", data.name)
end
m.getSpeed = function()
	return (m.character.get().HumanoidRootPart.Velocity * Vector3.new(1, 0, 1)).magnitude
end
m.getStance = function()
	local moving = m.character.moving()
	local speed = (m.character.get().HumanoidRootPart.Velocity * Vector3.new(1, 0, 1)).magnitude
	
	if not moving then
		return "standing"
	elseif (moving and speed >= 0.1 and speed < c.humanoid.walk + 1) or (moving and m.character.crouching) then
		return "walking"
	elseif moving and speed >= c.humanoid.walk + 1 and m.character.keyboard.keys.leftshift and not m.character.crouching then
		return "sprinting"
	end
end
m.calculateAim = function()
	if not m.deployed.data then return end
	
	local data = m.deployed.data
	local model = m.deployed.model
	
	local main = model[data.model.main]
	local attach = m.getAttachmentsOfType("sight")[1]
	local a1 = attach and attach.model[attach.data.sight.aim1] or model[data.model.aim1]
	local a2 = attach and attach.model[attach.data.sight.aim2] or model[data.model.aim2]
	
	local a1pos = CFrame.new(-(attach and attach.data.sight.aimorigin or data.view.aimorigin), 0, 0)
	local a1rel = a1.CFrame:inverse() * main.CFrame
	
	local adx, ady, adz = (attach and attach.aimdiff or m.deployed.aimdiff):toEulerAnglesXYZ()
	local ads = data.view.fix:inverse() * CFrame.Angles(adz, ady, -adx)
	
	return data.view.fix * a1rel * data.view.fix:inverse() * ads * a1pos
end
m.getMuzzle = function()
	if not m.deployed.data or not m.deployed.data.shoot then return end
	
	local muzzle = m.deployed.model[m.deployed.data.model.muzzle]
	local mAttach = m.getAttachmentsOfType("muzzle")[1]
	
	return mAttach and mAttach.model[mAttach.data.muzzle.muzzle] or muzzle
end

network.onEvent("sound play", function(player, sound, parent)
	if player == game:GetService("Players").LocalPlayer then return end
	m.playSoundGlobally(sound, parent, true)
end)

m.playSoundGlobally = function(sound, parent, dontsend)
	if not dontsend then network.sendEvent("sound play", sound, parent) end
	local delaytime = 0
	if m.character.get() ~= nil and m.character.get():FindFirstChild("Head") ~= nil and parent ~= nil and parent:IsA("BasePart") then
		local headpos = m.character.get().Head.Position
		local distance = (parent.Position - headpos).magnitude
		delaytime = distance * 1.75 / 5 / 343
	end
	
	delay(delaytime, function()
		local s = game:GetService("ReplicatedStorage").Assets.Audio:FindFirstChild(sound):Clone()
		--s.Pitch = maff.rand(0.97, 1.03, 2)
		s.TimePosition = s:FindFirstChild("Delay") and s.Delay.Value or 0
		s.Parent = parent or sound.Parent
		if m.character.get() == nil or m.character.get().Humanoid.Health <= 0 then
			local equ = Instance.new("EqualizerSoundEffect")
			equ.LowGain = 8
			equ.MidGain = -10
			equ.HighGain = -20
			equ.Parent = s
		end
		s:Play()
		delay(s.TimeLength / s.PlaybackSpeed, function() s:Destroy() end)
	end)
end

m.playSound = function(sound, parent)
	local delaytime = 0
	if m.character.get() ~= nil and m.character.get():FindFirstChild("Head") ~= nil and parent ~= nil and parent:IsA("BasePart") then
		local headpos = m.character.get().Head.Position
		local distance = (parent.Position - headpos).magnitude
		delaytime = distance * 1.75 / 5 / 343
	end
	
	delay(delaytime, function()
		local s = sound:Clone()
		--s.Pitch = maff.rand(0.97, 1.03, 2)
		s.TimePosition = s:FindFirstChild("Delay") and s.Delay.Value or 0
		s.Parent = parent or sound.Parent
		if m.character.get() == nil or m.character.get().Humanoid.Health <= 0 then
			local equ = Instance.new("EqualizerSoundEffect")
			equ.LowGain = 8
			equ.MidGain = -10
			equ.HighGain = -20
			equ.Parent = s
		end
		s:Play()
		delay(s.TimeLength / s.PlaybackSpeed, function() s:Destroy() end)
	end)
end
m.playSoundId = function(sound, parent, d)
	local delaytime = 0
	if m.character.get() ~= nil and m.character.get():FindFirstChild("Head") ~= nil and parent ~= nil and parent:IsA("BasePart") then
		local headpos = m.character.get().Head.Position
		local distance = (parent.Position - headpos).magnitude
		delaytime = distance * 1.75 / 5 / 343
	end
	
	delay(delaytime, function()
		local s = Instance.new("Sound")
		s.Parent = parent
		s.SoundId = sound
		s.TimePosition = d or 0
		if m.character.get() == nil or m.character.get().Humanoid.Health <= 0 then
			local equ = Instance.new("EqualizerSoundEffect")
			equ.LowGain = 8
			equ.MidGain = -10
			equ.HighGain = -20
			equ.Parent = s
		end
		s:Play()
		delay(s.TimeLength / s.PlaybackSpeed, function() s:Destroy() end)
	end)
end

network.onEvent("grenade threw", function(player, name, position, unit, remaining, id)
	if player == game:GetService("Players").LocalPlayer then return end
	m.throwGrenade(player, name, position, unit, remaining, id)
end)

network.onEvent("update grenade position", function(player, id, cf, velocity, anchored)
	if player == game:GetService("Players").LocalPlayer then return end
	for i,v in next, workspace:GetChildren() do
		if v.Name == id then
			if v:IsA("Model") then
				v:SetPrimaryPartCFrame(cf)
				v.PrimaryPart.Velocity = velocity
				v.PrimaryPart.Anchored = anchored
			else
				v.CFrame = cf
				v.Velocity = velocity
				v.Anchored = anchored
			end
		end
	end
end)

network.onEvent("remote grenade detonate", function(player, id)
	if player == game:GetService("Players").LocalPlayer then return end
	for i,v in next, workspace:GetChildren() do
		if v.Name == id then
			v:Destroy()
		end
	end
end)

network.onEvent("grenade destroyed", function(player, bullet)
	m.remoteset = true
end)

m.throwGrenade = function(from, name, position, unit, remaining, id)
	local data = m.get(name)
	
	local grenade = storage.Assets.Grenades:FindFirstChild(data.name):Clone()
	local main
	if grenade:IsA("BasePart") then
		grenade.Anchored = false
		grenade.CanCollide = true
		main = grenade
	elseif grenade:IsA("Model") then
		main = grenade.PrimaryPart
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
		
		for i,v in next, grenade:GetChildren() do
			for i,v in next, grenade:GetChildren() do
				v.Anchored = false
				if v:IsA("BasePart") and v ~= main then
					v.CanCollide = false
					weld(main, v)
				end
			end
		end
	end
	if id then grenade.Name = id end
	local force = unit * data.grenade.throwforce
	if grenade:IsA("Model") then grenade:SetPrimaryPartCFrame(position) else grenade.CFrame = position end
	for i,v in next, main:GetChildren() do
		if v:IsA("Sound") then
			v.Playing = true
		end
	end
	main.Velocity = force
	
	local typename = Instance.new("StringValue", main)
	typename.Name = "Grenade"
	typename.Value = data.name
	local fromvalue = Instance.new("ObjectValue", main)
	fromvalue.Name = "FromPlayer"
	fromvalue.Value = from or player
	
	grenade.Parent = workspace
	
	local t = tick()
	if data.grenade.stick then
		local stuck = false
		while not stuck do
			local delta = tick() - t
			t = tick()
			local this_position = main.Position
			local next_position = main.Position + main.Velocity * delta
			
			local ray = Ray.new(this_position, (next_position - this_position).unit * ((next_position - this_position).magnitude + 1.4))
			local whitelist = {}
			for i,v in next, workspace:GetChildren() do
				if v:FindFirstChild("MapData") then
					table.insert(whitelist, v)
				end
			end
			local part, position, normal = workspace:FindPartOnRayWithWhitelist(ray, whitelist)
			
			if part--[[ and part.Anchored == true]] then
				
				main.Anchored = true
				local cf = CFrame.new(position, position + normal) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(data.grenade.stick.offset, 0, 0) * CFrame.Angles(math.rad(math.random(-data.grenade.stick.tilt, data.grenade.stick.tilt)), 0, 0)
				
				if grenade:IsA("Model") then
					grenade:SetPrimaryPartCFrame(cf)
				else
					grenade.CFrame = cf
				end
				stuck = true
				
			end
			runservice.RenderStepped:wait()
		end
	end
	
	if remaining and remaining > 0 then delay(remaining, function() grenade:Destroy() end) end
	return main, grenade
end

m.cookGrenade = function()
	if m.deployed.data == nil then return end
	if not m.deployed.data.grenade then return end
	if not m.deployed.canfire then return end
	if m.deployed.reloading then return end
	if m.deployed.cooking then return end
	if m.deployed.ammo == 0 then return end
	
	local data = m.deployed.data
	m.deployed.cooking = true
	
	local tracking = m.deployed.model[data.model.main]
	local startTime = time()
	local wasCooking = true
	local threwGrenade = false
	local id = tostring(math.random())
	m.deployed.ammo = m.deployed.ammo - 1
	spawn(function() m.playAnim("cook") end)
	local loopend = false
	spawn(function()
		-- grenade arc
		local part_size = 2.4
		local part_count = 40
		local velocity = camera.CoordinateFrame.lookVector * data.grenade.throwforce
		local acceleration = Vector3.new(0, -workspace.Gravity, 0)
		local positions = {tracking.Position}
		local parts = {}
		
		for i = 1, part_count do
			local last_position = positions[i]
			velocity = velocity + acceleration / velocity.magnitude * part_size
			table.insert(positions, last_position + velocity.unit * part_size)
		end
		
		for i = 2, #positions do
			local last_position = positions[i - 1]
			local this_position = positions[i]
			local magnitude = (this_position - last_position).magnitude
			local cframe = CFrame.new(this_position:Lerp(last_position, 0.5), last_position) * CFrame.Angles(math.pi / 2, 0, 0)
			
			local preview_part = Instance.new("Part", camera)
			preview_part.Anchored = true
			preview_part.Transparency = i % 2 == 0 and maff.lerp(0.25, 1, (this_position - tracking.Position).magnitude / 60) or 1
			preview_part.Material = "Neon"
			preview_part.BrickColor = BrickColor.new("Bright red")
			preview_part.CanCollide = false
			preview_part.Size = Vector3.new(0.2, magnitude, 0.2)
			preview_part.CFrame = cframe
			
			Instance.new("CylinderMesh", preview_part)
			
			table.insert(parts, preview_part)
		end
		
		runservice:BindToRenderStep("arcupdate", 2000, function(delta)
			local velocity = camera.CoordinateFrame.lookVector * data.grenade.throwforce
			local acceleration = Vector3.new(0, -workspace.Gravity, 0)
			local positions = {tracking.CFrame.p + tracking.Velocity * delta}
			for i = 1, part_count do
				local last_position = positions[i]
				velocity = velocity + acceleration / velocity.magnitude * part_size
				table.insert(positions, last_position + velocity.unit * part_size)
			end
			
			for i = 2, #positions do
				local last_position = positions[i - 1]
				local this_position = positions[i]
				local magnitude = (this_position - last_position).magnitude
				local cframe = CFrame.new(this_position:Lerp(last_position, 0.5), last_position) * CFrame.Angles(math.pi / 2, 0, 0)
				
				local preview_part = parts[i - 1]
				preview_part.Size = Vector3.new(0.2, magnitude, 0.2)
				preview_part.CFrame = cframe
			end
		end)
		
		repeat
			
			runservice.RenderStepped:wait()
			
		until threwGrenade or loopend
		runservice:UnbindFromRenderStep("arcupdate")
		
		for i,v in next, parts do
			v:Destroy()
		end
	end)
	repeat
		if not m.deployed.cooking and wasCooking and not threwGrenade then
			tracking = m.throwGrenade(player, m.deployed.data.name, tracking.CFrame, camera.CoordinateFrame.lookVector, nil, id)
			network.sendEvent("grenade threw", data.name, tracking.CFrame, camera.CoordinateFrame.lookVector, data.grenade.cook and data.grenade.cook - (time() - startTime) or -1, id)
			threwGrenade = true
			m.stopAnim(true, true)
			spawn(function()
				m.playAnim("release")
			end)
			if data.grenade.cook then
				if m.deployed.ammo == 0 then
					wait(0.3)
					m.inventory.equip(m.inventory.weapons[1], true)
				end
			elseif data.grenade.remote then
				m.inventory.addweapon(data.grenade.remote)
				local _, index = m.inventory.getweapon(data.grenade.remote)
				m.inventory.equip(m.inventory.weapons[index], true)
				table.insert(m.remotegrenades, {part = tracking, id = id})
				spawn(function()
					repeat
						network.sendEvent("update grenade position", id, tracking.CFrame, tracking.Velocity, tracking.Anchored)
						wait(.3)
					until loopend
				end)
			end
		end
		wasCooking = m.deployed.cooking
		runservice.RenderStepped:wait()
	until (data.grenade.cook and data.grenade.cook < time() - startTime) or (data.grenade.remote and m.remoteset) or (data.grenade.remote and m.character.humanoid().Health <= 0)
	loopend = true
	if tracking ~= nil and data.grenade.cook then
		network.sendEvent("grenade explode", data.name, tracking.Position)
		if tracking.Parent:IsA("Model") and tracking.Parent.PrimaryPart == tracking then
			tracking.Parent:Destroy()
		elseif tracking:IsA("BasePart") then
			tracking:Destroy()
		end
	elseif tracking ~= nil and data.grenade.remote and m.remoteset then
		network.sendEvent("grenade explode", data.name, tracking.Position)
		network.sendEvent("remote grenade detonate", id)
		local _, index = m.inventory.getweapon(data.grenade.remote)
		table.remove(m.inventory.weapons, index)
		for i = #m.remotegrenades, 1, -1 do
			if m.remotegrenades[i].part == tracking then
				table.remove(m.remotegrenades, i)
			end
		end
		m.inventory.equip(m.inventory.weapons[1], true)
		if tracking.Parent:IsA("Model") and tracking.Parent.PrimaryPart == tracking then
			tracking.Parent:Destroy()
		end
	end
	m.remoteset = false
end

m.swing = function()
	if m.deployed.data == nil then return end
	if m.deployed.data.melee == nil then return end
	if not m.deployed.canfire then return end
	if m.deployed.reloading then return end
	
	m.deployed.clickedsince = false
	m.deployed.canfire = false
	
	local data = m.deployed.data
	local stats = data.melee
	
	if data.view.anim.swing then
		spawn(function() m.playAnim("swing") end)
	end
	
	wait(data.melee.delay or 0)
	local from = camera.CoordinateFrame.p
	local unit = camera.CoordinateFrame.lookVector * stats.range
	local ray = Ray.new(from, unit)
	local part, hit = workspace:FindPartOnRayWithIgnoreList(ray, {camera, m.character.get()})
	
	if part ~= nil then
		local parent = part.Parent
		if parent:FindFirstChild("Humanoid") then
			
			local victimUnit = parent:FindFirstChild("HumanoidRootPart").CFrame.lookVector
			local angle = math.acos(victimUnit:Dot(unit) / (victimUnit.magnitude * unit.magnitude))
			local backstab = angle < math.rad(60)
			
			network.sendEvent("weapon swung", data.name, ray, part, backstab)
			
		end
		--network.sendEvent("weapon swung", ray, part, backstab)
	end
	
	wait(stats.cooldown)
	m.deployed.canfire = true
end
local aimtime = 0
local aimtimebez = 0

m.shoot = function()
	if m.deployed.data == nil then return end
	if m.deployed.data.shoot == nil then return end
	if m.deployed.data.shoot.reloadper and m.deployed.wasReloading then
		m.deployed.wasReloading = false
		m.deployed.reloading = false
		m.stopAnim(true)
	end
	if not m.deployed.canfire then return end
	if m.deployed.reloading then return end
	if m.getStance() == "sprinting" and not m.mouse.right then return end
	if m.deployed.anim.active then m.stopAnim(true) end
	
	m.deployed.clickedsince = false
	
	if m.deployed.bursting and m.deployed.firemode ~= "burst" then m.deployed.bursting = false m.deployed.burstcount = 0 end
	if not m.deployed.chambered then m.deployed.ammo = 0 m.deployed.chambered = false m.playSound(m.deployed.model[m.deployed.data.model.muzzle].NoAmmo) return end
	
	local data = m.deployed.data
	local model = m.deployed.model
	
	m.deployed.chambered = false
	
	local bcount = data.shoot.count or 1
	local spread = 0
	if data.shoot.spread then
		local base = data.shoot.spread.base or 0
		local moving = data.shoot.spread.moving or 0
		local hipfire = data.shoot.spread.hipfire or 0
		
		spread = m.getSpeed() / c.humanoid.walk * moving + hipfire * (1 - aimtimebez) + base
	end
	
	local underAttachs = m.getAttachmentsOfType("underbarrel")
	local recoilmult = 1
	
	if underAttachs[1] then
		if underAttachs[1].data.underbarrel.spreadmult then
			spread = spread * underAttachs[1].data.underbarrel.spreadmult
		end
	end 
	
	local muzzle = model[data.model.muzzle]
	local bulletdata = {}
	for i = 1, bcount do
		--[[local unitvector = camera.CoordinateFrame.lookVector * 10 + Vector3.new(math.random(-spread,spread),math.random(-spread,spread),math.random(-spread,spread)) / 10
		local ray = Ray.new(camera.CoordinateFrame.p, unitvector * data.shoot.dist)
		local hrplist = {}
		for i,v in next, game.Players:GetPlayers() do
			if v.Character then
				table.insert(hrplist, v.Character:WaitForChild("HumanoidRootPart"))
			end
		end
		local part, hit = workspace:FindPartOnRayWithIgnoreList(ray, {m.character.get(), model, unpack(hrplist)})
		
		table.insert(hitdata, {hit = hit, part = part, ray = ray})]]
		local unitvector = camera.CoordinateFrame.lookVector * 10 + Vector3.new(math.random(-spread,spread),math.random(-spread,spread),math.random(-spread,spread)) / 10
		
		local b = m.shootBullet(m.getMuzzle().Position, unitvector, data, true)
		table.insert(bulletdata, b)
	end
	
	if underAttachs[1] then
		if underAttachs[1].data.underbarrel.recoilmult then
			recoilmult = recoilmult * underAttachs[1].data.underbarrel.recoilmult
		end
	end
	
	local rx, ry = maff.rand(-data.shoot.recoil.x * recoilmult, data.shoot.recoil.x * recoilmult, 2), maff.rand(data.shoot.recoil.y[1], data.shoot.recoil.y[2] * recoilmult, 2)
	spawn(function()
		local ramount = data.view.recoil * recoilmult
		
		m.pos.recoilcurrent = ramount
		m.pos.recoilhcurrent = maff.rand(-ramount, ramount, 2)
		for i = 1, data.shoot.recoil.rate or c.recoilrate do
			camera.CoordinateFrame = camera.CoordinateFrame * CFrame.Angles(0, math.rad(rx/c.recoilrate), 0) * CFrame.Angles(math.rad(ry/c.recoilrate), 0, 0)
			runservice.RenderStepped:wait()
		end
	end)
	
	m.deployed.canfire = false
	
	m.playSound(m.getMuzzle().Fire)
	network.sendEvent("weapon fired", data.name, bulletdata, m.getMuzzle().Position, m.getMuzzle().Fire.SoundId, m.getMuzzle().Fire:FindFirstChild("Delay") and m.getMuzzle().Fire.Delay.Value or nil)
	--for i,v in next, hitdata do
	--	m.bulletTrail(m.getMuzzle().Position, v.hit, true)
	--end
	
	if m.deployed.ammo > 0 then m.deployed.chambered = true end
	if m.deployed.ammo > 0 then m.deployed.ammo = m.deployed.ammo - 1 end
	
	if data.view.anim.shot then
		repeat wait() until not m.mouse.right
		spawn(function() m.playAnim("shot") end)
	end
	
	if m.deployed.firemode == "burst" then
		m.deployed.bursting = true
	end
	if m.deployed.bursting then
		m.deployed.burstcount = m.deployed.burstcount + 1
	end
	
	wait(1 / data.shoot.rate)
	m.deployed.canfire = true
	
	if (m.mouse.left and m.deployed.firemode == "auto") or
		(m.mouse.left and m.deployed.firemode == "single" and m.deployed.clickedsince) or
		(m.deployed.firemode == "burst" and m.deployed.bursting and m.deployed.burstcount < data.shoot.burstcount) then
		m.shoot()
	elseif m.deployed.firemode == "burst" and m.deployed.bursting and m.deployed.burstcount >= data.shoot.burstcount then
		m.deployed.bursting = false
		m.deployed.burstcount = 0
	end
end
m.chamber = function()
	if m.deployed.ammo <= 0 and not m.deployed.chambered then
		m.playAnim("chamber")
		m.deployed.ammo = m.deployed.ammo - 1
		m.deployed.chambered = true
	end
end	
m.reload = function(fromPress)
	if m.deployed.data == nil then return end
	if m.deployed.data.shoot == nil then return end
	if m.deployed.ammo == m.deployed.data.shoot.ammo and m.deployed.data.shoot.reloadper and m.deployed.wasReloading and not fromPress then
		m.deployed.reloading = true
		if m.deployed.data.view.anim.afterReload then
			m.playAnim("afterReload")
		end
		m.deployed.reloading = false
		m.deployed.wasReloading = false
	end
	if m.deployed.ammo == m.deployed.data.shoot.ammo then m.deployed.reloading = false return end
	if m.deployed.anim.active and not m.deployed.data.shoot.reloadper and m.deployed.ammo ~= m.deployed.shoot.ammo then m.stopAnim() end
	if m.deployed.reloading then return end
	if m.deployed.bursting and m.deployed.firemode == "burst" then m.deployed.bursting = false m.deployed.burstcount = 0 end
	if m.deployed.data.shoot.reloadper and not m.deployed.wasReloading then
		if m.deployed.data.view.anim.beforeReload then
			m.deployed.reloading = true
			m.deployed.wasReloading = true
			m.playAnim("beforeReload")
		end
	end
	
	local data = m.deployed.data	
	
	m.deployed.reloading = true
	m.deployed.wasReloading = true
	if data.view.anim.reload ~= nil then
		local overridereset = m.deployed.data.shoot.reloadper and m.deployed.ammo + 1 == m.deployed.data.shoot.ammo
		m.playAnim("reload", overridereset)
	else
		local st = time()
		repeat
			if m.deployed.data ~= data then break end
			runservice.Stepped:wait()
		until st + data.shoot.reloadtime < time()
	end
	if not m.deployed.chambered then
		m.chamber()
	end
	if not m.deployed.wasReloading then
		m.deployed.reloading = false
		return
	end
	m.deployed.reloading = false
	
	if not data.shoot.reloadper then m.stopAnim() end
	if m.deployed.data == data then -- tryna be sneaky and switch weapons while reloading . . . . . . . . . . . . . . . . clever.
		if data.shoot.reloadper then
			m.reload()
		else
			m.deployed.ammo = data.shoot.ammo
		end
	end
end


-- Animation

m.playAnim = function(name, last)
	if m.deployed.data == nil then return end
	if m.deployed.data.view.anim == nil then return end
	if m.deployed.anim.active then
		m.deployed.anim.active = false
		wait()
	end
	
	local model = m.deployed.model
	local data = m.deployed.data
	local anim = data.view.anim[name]
	local main = model[data.model.main]
	
	if anim == nil then return end
	network.sendEvent("play animation", m.deployed.data.name, name, last)
	
	m.deployed.anim.active = true
	for ind, keyframe in next, anim do
		if type(ind) == "number" and ((keyframe.lastOnly and last) or not keyframe.lastOnly) then
			local waitbegin = time()
			repeat
				if not m.deployed.anim.active then break end
				runservice.RenderStepped:wait()
			until time() - waitbegin >= (keyframe.d or 0)
			
			if keyframe.roundAdd then
				m.deployed.ammo = math.min(m.deployed.ammo + 1, m.deployed.data.shoot.ammo)
			end
			
			local bezier = nil
			if keyframe.bezier ~= nil then
				local b = keyframe.bezier
				bezier = cb.cubicbezier(b[1], b[2], b[3], b[4])
			end
			
			local startTime = time()
			local startOffset = m.deployed.anim.offset
			local startOffsets = {}
			for i,v in next, model:GetChildren() do
				if v ~= main and v:IsA("BasePart") and v.Name ~= "LeftArm" and v.Name ~= "RightArm" then
					startOffsets[v] = m.deployed.anim.lastkey[v.Name] or CFrame.new()
				end
			end
			
			if keyframe.clone then
				for _,prt in next, keyframe.clone do
					local partName, newPartName = prt[1], prt[2]
					local part = model:FindFirstChild(partName)
					local cloned = part:Clone()
					cloned.Name = newPartName
					cloned.Parent = model
					local defaultPosValue = Instance.new("CFrameValue")
					defaultPosValue.Value = m.deployed.defaultpos[part]
					defaultPosValue.Name = "DefaultPosition"
					defaultPosValue.Parent = cloned
					m.deployed.anim.cloned[newPartName] = cloned
				end
			end
			
			if keyframe.trans then
				for _,prt in next, keyframe.trans do
					local partName, transparency = prt[1], prt[2]
					local part = model:FindFirstChild(partName)
					part.Transparency = transparency
				end
			end
			
			if keyframe.unanchor then
				for _,prt in next, keyframe.unanchor do
					spawn(function()
						local part = m.deployed.anim.cloned[type(prt) == "table" and prt[1] or prt]
						if part then
							if prt[4] then
								wait(prt[4])
							end
							part.Anchored = false
							if type(prt) == "table" then
								part.Velocity = part.CFrame:vectorToWorldSpace(prt[2])
								if prt[3] then
									part.RotVelocity = part.CFrame:vectorToWorldSpace(prt[3])
								end
							end
						end
					end)
				end
			end
		
			if keyframe.destroy then
				for _,prt in next, keyframe.destroy do
					local part = m.deployed.anim.cloned[prt]
					if part then
						part:Destroy()
					end
					m.deployed.anim.cloned[prt] = nil
				end
			end
			
			if keyframe.s or keyframe.sound then
				delay(keyframe.sd or 0, function() m.playSound(model[data.model.muzzle][keyframe.s]) end)
			end
			
			repeat
				if not m.deployed.anim.active then break end
				local current = (time() - startTime) / keyframe.t	
				
				if bezier == nil then
					m.deployed.anim.offset = maff.cosineclerp(startOffset, keyframe.p or CFrame.new(), current, keyframe.pow)
				else
					m.deployed.anim.offset = startOffset:lerp(keyframe.p or CFrame.new(), bezier(current))
				end
				
				for i,v in next, model:GetChildren() do
					if v ~= main and v:IsA("BasePart") and v.Anchored and v.Name ~= "LeftArm" and v.Name ~= "RightArm" then
						local dpos = v:FindFirstChild("DefaultPosition") and v.DefaultPosition.Value or m.deployed.defaultpos[v]
						if bezier == nil then
							v.CFrame = main.CFrame * dpos * maff.cosineclerp((startOffsets[v] or CFrame.new()), (keyframe.o or {})[v.Name] or CFrame.new(), current, keyframe.pow)
						else
							v.CFrame = main.CFrame * dpos * (startOffsets[v] or CFrame.new()):lerp((keyframe.o or {})[v.Name] or CFrame.new(), bezier(current))
						end
					end
				end
				
				runservice.RenderStepped:wait()
			until time() - startTime >= keyframe.t
			
			if not m.deployed.anim.active then break end
			
			m.deployed.anim.lastkey = {}
			for i,v in next, keyframe.o do
				m.deployed.anim.lastkey[i] = v
			end
		end
	end
	if not last then
		m.stopAnim(true, anim.ignoreReset)
	else
		m.stopAnim(true)
	end
	
	if not anim.ignoreReset or last then
		m.deployed.anim.offset = CFrame.new()
		for i,v in next, model:GetChildren() do
			if v ~= main and v:IsA("BasePart") and v.Name ~= "LeftArm" and v.Name ~= "RightArm" then
				v.CFrame = main.CFrame * m.deployed.defaultpos[v]
			end
		end
	end
end
m.stopAnim = function(dontWait, dontReset)
	for i,v in next, m.deployed.anim.cloned do
		v:Destroy()
	end
	m.deployed.anim.cloned = {}
	m.deployed.anim.active = false
	if not dontReset then m.deployed.anim.offset = CFrame.new()
	m.deployed.anim.lastkey = {} end
	if not dontWait then wait() end
end

-- from is Vector3 of start location, unit is where the bullet is coming from directionally, mine is if it should deal damage to other players
m.shootBullet = function(from, unit, data, mine)
	local part = storage.Assets.Bullet:Clone()
	part.Parent = camera
	part.CFrame = CFrame.new(from, from + unit)
	
	local b = bullet:new(from, unit.unit * bullet.to_studs(data.shoot.velocity), {camera, m.character.get()}, function(me, ray, hit, pos)
		
		delay(1.5, function() part:Destroy() end)
		
		for i = #m.bullets, 1, -1 do
			if m.bullets[i] == me then
				table.remove(m.bullets, i)
			end
		end
		
		if mine then
			local hitdata = {ray = ray, part = hit, hit = pos, from = from}
			
			local parent = hit.Parent
			
			if parent:IsA("Model") and parent.PrimaryPart and parent.PrimaryPart:FindFirstChild("Grenade") then
				part = parent.PrimaryPart
				local name = part.Grenade.Value
				local g = m.get(name)
				if g.grenade.remote then
					local p = part.FromPlayer.Value
					m.playSound(storage.Assets.Audio.Bodyshot)
					network.sendEvent("grenade destroyed", p, hitdata)
				end
			end
			
			if parent:FindFirstChild("Humanoid") then
				local head = parent:FindFirstChild("Head")
				local chest = parent:FindFirstChild("Torso")
				local p = players:GetPlayerFromCharacter(parent)
				
				if p and (tdm and p.Team == player.Team) then return end
				if parent.Humanoid.Health <= 0 then return end
				
				if hit ~= head and hit ~= chest then
					
					local p, h = workspace:FindPartOnRayWithWhitelist(ray, {head, chest})
					if p ~= nil then
						hitdata.part = p
						hitdata.hit = h
					end
					
				end
				
				m.playSound(storage.Assets.Audio.Bodyshot)
				if hitdata.part.Name == "Head" then
					m.playSound(storage.Assets.Audio.Headshot)
				end
			end
			
			network.sendEvent("bullet hit", data, hitdata)
		end
	end)
	
	local bdata = {bullet = b, part = part, from = from, unit = unit.unit}
	table.insert(m.bullets, bdata)
	return bdata
	
end

--[[m.bulletTrail = function(from, to, ignoreAudio)
	local ray = Ray.new(from, (to - from).unit)
	
	if not ignoreAudio and m.character.get() ~= nil and m.character.get():FindFirstChild("Head") ~= nil then
		local headpos = m.character.get().Head.Position
		local fromDist = (headpos - from).magnitude
		local closest = ray:ClosestPoint(headpos)
		local dist = (headpos - closest).magnitude
		local fromToClosest = (from - closest).magnitude
		local totalDist = (to - from).magnitude
		if dist < c.whizmaxdistance and fromDist > 3.5 then
			
			print'shouldplay'
			local parentPart = Instance.new("Part")
			parentPart.Anchored = true
			parentPart.CanCollide = false
			parentPart.Size = Vector3.new(.2, .2, .2)
			parentPart.Position = closest
			parentPart.Transparency = 1
			parentPart.Parent = camera
			
			local sounds = storage.Assets.Audio
			local sound = sounds:FindFirstChild(c.whiz[math.random(#c.whiz)]):Clone()
			print(sound.Name)
			sound.Parent = parentPart
			sound:Play()
			
			delay(sound.TimeLength, function() parentPart:Destroy() end)
			
		end
	end
	
	local t = Instance.new("Part")
	t.Name = "Trail"
	t.FormFactor = "Custom"
	t.Anchored = true
	t.CanCollide = false
	t.BrickColor = c.trail.color
	t.Transparency = 0.8
	t.Size = Vector3.new(0.2, 0.2, (from - to).magnitude)
	t.CFrame = CFrame.new(from:Lerp(to, 0.5), to)
	t.Parent = camera
	
	local mesh = Instance.new("BlockMesh")
	mesh.Scale = Vector3.new(0.4, 0.4, 1)
	mesh.Parent = t
	
	spawn(function()
		local starttime = time()
		repeat
			local current = (time() - starttime) / c.trail.duration
			t.Transparency = maff.lerp(0.8, 1, current)
			runservice.RenderStepped:wait()
		until time() - starttime >= c.trail.duration
		
		t:Destroy()
	end)
end]]


-- Input

m.mouse = {}
m.mouse.left = false
m.mouse.right = false

inputservice.InputBegan:connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		m.mouse.left = true
		m.deployed.clickedsince = true
		if not m.deployed.data then
			return
		end
		if m.deployed.data.shoot then
			m.shoot()
		elseif m.deployed.data.melee then
			m.swing()
		elseif m.deployed.data.grenade then
			m.cookGrenade()
		elseif m.deployed.data.remote then
			local main = m.deployed.model[m.deployed.data.model.main]
			if m.deployed.data.flash_white then
				m.deployed.data.flash_white(main.Parent)
			end
			if m.deployed.data.remote.sound then
				m.playSoundGlobally(m.deployed.data.remote.sound, m.character.get().Head)
			end
			spawn(function()
				wait(m.deployed.data.remote.delay / 2)
				if m.deployed.data.flash_normal then
					m.deployed.data.flash_normal(main.Parent)
				end
			end)
			wait(m.deployed.data.remote.delay)
			m.remoteset = true
		end
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		m.mouse.right = true
	end
end)
inputservice.InputEnded:connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		m.mouse.left = false
		if m.deployed.data and m.deployed.data.grenade and m.deployed.cooking then
			m.deployed.cooking = false
		end
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		m.mouse.right = false
	end
end)

keyboard.bind("v", function()
	if m.deployed.data == nil or m.deployed.data.shoot == nil then return end
	
	local ind = -1
	for i,v in next, m.deployed.data.shoot.firemode do
		if v == m.deployed.firemode then
			ind = i
		end
	end
	m.deployed.firemode = m.deployed.data.shoot.firemode[ind % #m.deployed.data.shoot.firemode + 1]
end)
keyboard.bind("r", function()
	if not m.deployed.canfire then return end
	m.reload(true)
end)
keyboard.bind("f", function()
	if m.deployed.data == nil or m.deployed.data.view.anim.inspect == nil then return end
	if m.deployed.anim.active then return end
	m.playAnim("inspect")
end)

network.onEvent("weapon fired", function(shooter, weapon, bulletdata, from, sound, d)
	if shooter == player then return end
	
	local data = m.get(weapon)
	
	if data.shoot ~= nil then
		for i,v in next, bulletdata do
			--[[if m.character.get() ~= nil then
				local dontplay = false
				for a,b in next, m.character.get():GetChildren() do
					if b == v.part then
						dontplay = true
					end
				end
				m.bulletTrail(from, v.hit, dontplay)
			end]]
			m.shootBullet(v.from, v.unit, data, false)
		end
		if sound then m.playSoundId(sound, shooter.Character.Head, d) end
	end
end)

m.delta = {}
m.delta.x = 0
m.delta.y = 0
m.delta.sway = CFrame.new()
m.delta.rotsway = CFrame.new()

m.pos = {}
m.pos.current = CFrame.new()
m.pos.target = CFrame.new()
m.pos.origincurrent = CFrame.new()
m.pos.origintarget = CFrame.new()
m.pos.recoilcurrent = 0
m.pos.recoiltarget = 0
m.pos.recoilhcurrent = 0
m.pos.recoilhtarget = 0

m.fov = {}
m.fov.current = c.fov.default
m.fov.target = c.fov.default

m.lhandt = 1
m.lhandtt = 1

inputservice.InputChanged:connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		m.delta.x = input.Delta.x
		m.delta.y = input.Delta.y
	end
end)

local wasaiming = false
local timer = 0

local aimBezier = cb.cubicbezier(.41, .94, .01, 1)
local aimOutBezier = cb.cubicbezier(.94, .02, .71, .94)

-- Rendering

runservice.RenderStepped:connect(function(delta)
	
	local ot = timer
	timer = timer + delta
	
	for i = #m.bullets, 1, -1 do
		local v = m.bullets[i]
		
		if v.part ~= nil and v.part.Parent ~= nil then
			--v.part.Trail.Lifetime = 1
			v.part.CFrame = CFrame.new(v.bullet.lastposition, v.bullet.position)
		end
		v.bullet.life = v.bullet.life + delta
		
		if not v.bullet.hashit then
			v.bullet:next(delta)
		end
		if v.bullet.life > 5 then
			v.part:Destroy()
			v.part = nil
			table.remove(m.bullets, i)
		end
		
	end
	
	if m.deployed.model ~= nil then
		local model = m.deployed.model
		local data = m.deployed.data
		
		local aimFunc = maff.easing.linear
		
		local speed = m.getSpeed()
		local muzzleAttachs = m.getAttachmentsOfType("muzzle")
		local mAttachPart = muzzleAttachs[1] and muzzleAttachs[1].model[muzzleAttachs[1].data.muzzle.muzzle]
		
		if data.shoot then
			updateMuzzleUi(mAttachPart or model[data.model.adornee], m.deployed.ui, m.deployed.ammo, m.deployed.chambered, data.shoot.ammo, m.deployed.firemode:upper(), m.deployed.reloading)
		end
		
		local function setArmPos(arm, hand, hand2, c)
			if hand2 then
				local h1pos = hand.CFrame * CFrame.Angles(0, 0, -math.pi / 2) * CFrame.new(0, 1, 0)
				local h2pos = hand2.CFrame * CFrame.Angles(0, 0, -math.pi / 2) * CFrame.new(0, 1, 0)
				arm:SetPrimaryPartCFrame(h2pos:lerp(h1pos, c))
				return
			end
			arm:SetPrimaryPartCFrame(hand.CFrame * CFrame.Angles(0, 0, -math.pi / 2) * CFrame.new(0, 1, 0))
		end
		
		--model.LeftArm.CFrame = model.LeftHand.CFrame * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(0, 0, 1)
		--model.RightArm.CFrame = model.RightHand.CFrame * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(0, 0, 1)
		
		setArmPos(model.LeftArm, model.LeftHand)
		setArmPos(model.RightArm, model.RightHand)
		
		m.lhandt = maff.lerp(m.lhandt, m.lhandtt, 0.1)
		
		local aiming = data.shoot and m.mouse.right
		local stance = m.getStance()
		local sights = data.shoot and m.getAttachmentsOfType("sight") or {}
		if aiming and not m.deployed.anim.active then
			--stance = "standing"
			aiming = true
			m.character.speed = c.humanoid.aim
		else
			aiming = false
			m.character.fixSpeed()
		end
		
		if data.shoot then
			if aiming then
				if not wasaiming and aimtime > 0 then
					aimtime = cb.bruteforce(aimBezier, aimtimebez)
				end
				aimtime = aimtime + delta / (data.shoot.adstime or 0.7)
				if aimtime > 1 then
					aimtime = 1
				end
				aimtimebez = aimBezier(aimtime)
			else
				if wasaiming and aimtime < 1 then
					aimtime = cb.bruteforce(aimOutBezier, aimtimebez)
				end
				aimtime = aimtime - delta / ((data.shoot.adstime or 0.7) * 0.8)
				if aimtime < 0 then
					aimtime = 0
				end
				aimtimebez = aimOutBezier(aimtime)
			end
		end
		wasaiming = aiming
		
		if stance == "walking" then
			timer = ot + delta * (speed / c.humanoid.walk)
		end
			
		local bob = CFrame.new()
		local bobangle = CFrame.new()
		
		local interpc = aiming and 0.175 or 0.1
		
		m.fov.current = maff.easing.f(aimFunc, c.fov.default, c.fov.default / (sights[1] and sights[1].data.sight.fov or data.view.aimfov or 1), aimtimebez)
		camera.FieldOfView = m.fov.current
		
		inputservice.MouseDeltaSensitivity = maff.lerp(0, 1, m.fov.current / 70)
		
		local bobs = {}
		local function newbob(upperSpeed, pos, angle, useSprint)
			table.insert(bobs, {upper = upperSpeed, pos = pos, ang = angle, sprint = useSprint or false})
		end
		
		-- standing
		newbob(2,
			CFrame.new(math.sin(time() * 0.7) * data.view.bob / 50, math.cos(time() * 0.9) * data.view.bob / 50, 0),
			CFrame.Angles(math.sin(time() * 0.8) * math.rad(0.8 * data.view.bob), 0, math.sin(time() * 0.65) * math.rad(0.8 * data.view.bob))
		)
		
		-- walking
		newbob(c.humanoid.walk, 
			CFrame.new(math.sin(timer * 5) * data.view.bob / 10, -math.cos(timer * 10) * data.view.bob / 15, 0),
			--CFrame.Angles(math.sin(timer * 6.5) * math.rad(1.5 * data.view.bob), 0, math.sin(timer * 5 - 1) * math.rad(2 * data.view.bob))
			CFrame.Angles(math.sin(timer * 5 - .9) * math.rad(6), 0, math.sin(timer * 6.3) * math.rad(2 * data.view.bob))
		)
		
		-- sprinting
		newbob(c.humanoid.sprint,
			CFrame.new(math.sin(time() * 9) * data.view.bob / 3, -math.cos(time() * 18) * data.view.bob / 7, 0),
			--CFrame.Angles(math.sin(time() * 9.35) * math.rad(5.2 * data.view.bob), math.sin(time() * 10 - .8) * math.rad(3.7 * data.view.bob), math.sin(time() * 19) * math.rad(4.3 * data.view.bob))
			CFrame.Angles(math.sin(time() * 9 - 1.2) * math.rad(8 * data.view.bob), math.sin(time() * 9 - 1.2) * math.rad(5 * data.view.bob), math.sin(time() * 12.6) * math.rad(5 * data.view.bob))
		, true)
		
		local abob
		local bbob
		if speed < bobs[1].upper then
			abob = bobs[1]
			bbob = bobs[1]
		elseif speed >= bobs[#bobs].upper then
			abob = bobs[#bobs]
			bbob = bobs[#bobs]
		else
			local highest = #bobs
			for i = #bobs, 1, -1 do
				if bobs[i].upper > speed then
					highest = i
				else
					abob = bobs[i]
					bbob = bobs[highest]
					break
				end
			end
		end
		
		local bobint = abob == bbob and 0 or (speed - abob.upper) / (bbob.upper - abob.upper)
		local sprintint = maff.lerp(abob.sprint and 1 or 0, bbob.sprint and 1 or 0, bobint)
		bob = abob.pos:lerp(bbob.pos, bobint)
		bobangle = abob.ang:lerp(bbob.ang, bobint)
		
		--if stance == "standing" then
		--	bob = CFrame.new(math.sin(time() * 0.7) * data.view.bob / 50, math.cos(time() * 0.9) * data.view.bob / 50, 0)
		--	bobangle = CFrame.Angles(math.sin(time() * 0.8) * math.rad(0.8 * data.view.bob), 0, math.sin(time() * 0.65) * math.rad(0.8 * data.view.bob))
		--elseif stance == "walking" and aiming then
		--	local boba = data.view.bob / 3
		--	bob = CFrame.new(math.sin(timer * 5) * boba / 10, -math.cos(timer * 10) * boba / 15, 0)
		--	bobangle = CFrame.Angles(math.sin(timer * 6.5) * math.rad(1.5 * boba), 0, math.sin(timer * 7.7) * math.rad(1.3 * boba))
		--elseif stance == "walking" then
		--	bob = CFrame.new(math.sin(timer * 5) * data.view.bob / 10, -math.cos(timer * 10) * data.view.bob / 15, 0)
		--	bobangle = CFrame.Angles(math.sin(timer * 6.5) * math.rad(1.5 * data.view.bob), 0, math.sin(timer * 7.7) * math.rad(1.3 * data.view.bob))
		--elseif stance == "sprinting" then
		--	bob = CFrame.new(math.sin(time() * 10) * data.view.bob / 2, -math.cos(time() * 20) * data.view.bob / 4, 0)
		--	bobangle = CFrame.Angles(math.sin(time() * 9.35) * math.rad(5.2 * data.view.bob), math.sin(time() * 10 - .8) * math.rad(3.7 * data.view.bob), math.sin(time() * 19) * math.rad(4.3 * data.view.bob)) --4.3
		--end		
		
		m.delta.sway = m.delta.sway:lerp(CFrame.Angles(math.rad(m.delta.y / 2 * data.view.sway), math.rad(m.delta.x / 2 * data.view.sway), 0), 0.15)		
		m.delta.rotsway = m.delta.rotsway:lerp(CFrame.Angles(math.rad(m.delta.y / 2 * data.view.sway * 0.75), math.rad(m.delta.x / 2 * data.view.sway * 0.75), 0), 0.15)
		
		m.pos.origintarget = data.view.origin:lerp(data.view.sprintorigin, sprintint)
		m.pos.target = data.view.fix:inverse() * bob * data.view.fix * bobangle
		if m.deployed.anim.active then
			m.pos.origintarget = data.view.origin
		end
		--[[if aiming then
			if stance == "walking" then
				m.pos.target = data.view.fix:inverse() * bob * data.view.fix * bobangle
			else
				m.pos.target = CFrame.new()
			end--CFrame.new()--data.view.fix
			m.pos.origintarget = m.calculateAim()
		end]]
		
		--m.pos.origincurrent = (m.pos.origincurrent:lerp(m.pos.origintarget, interpc)):lerp(m.calculate)
		
		m.delta.x = 0
		m.delta.y = 0
		
		m.pos.origincurrent = m.pos.origincurrent:lerp(m.pos.origintarget, interpc)
		if aiming then
			m.pos.target = CFrame.new()
		end
		m.pos.current = m.pos.current:lerp(m.pos.target, 0.1)
		
		m.pos.recoilcurrent = maff.lerp(m.pos.recoilcurrent, 0, 0.2)
		m.pos.recoilhcurrent = maff.lerp(m.pos.recoilhcurrent, 0, 0.2)
		local recoilangle = data.view.fix:inverse() * CFrame.new(0, 0, data.view.recoiloffset) * CFrame.Angles(0, math.rad(m.pos.recoilhcurrent), 0) * CFrame.Angles(math.rad(m.pos.recoilcurrent), 0, 0) * CFrame.new(0, 0, -(data.view.recoiloffset or 0) + math.abs(m.pos.recoilhcurrent) / 10) * data.view.fix
		
		local sightAttachs = m.getAttachmentsOfType("sight")
		local underAttachs = m.getAttachmentsOfType("underbarrel")
		
		local isTransThisFrame = false
		local function setIronsightTransparency(trans)
			if isTransThisFrame then return end
			for i,v in next, data.model.ironsight or {} do
				if model:FindFirstChild(v) ~= nil then
					if trans == 1 then isTransThisFrame = true end
					model[v].Transparency = trans
				end
			end
		end
		
		if model:FindFirstChild("SightAttach") then
			setIronsightTransparency(0)
			for i,v in next, sightAttachs do
				setIronsightTransparency(1)
				v.model:SetPrimaryPartCFrame(model.SightAttach.CFrame * data.view.fix:inverse())
				
				if v.data.sight.real then
					for _,crosshairn in next, v.data.sight.dots do
						local crosshair = v.model[crosshairn]
						local glass = v.model[v.data.sight.glass]
						
						local to = crosshair.Position
						local from = camera.CoordinateFrame.p
						
						local aim1, aim2 = v.model[v.data.sight.aim1], v.model[v.data.sight.aim2]
						
						local ray = Ray.new(from, (to - from).unit * (to - from).magnitude)
						local part = workspace:FindPartOnRayWithWhitelist(ray, {glass})
						--print(part.Name)
						if part ~= glass then
							crosshair.Transparency = 1
						else
							crosshair.Transparency = v.data.sight.dottrans and v.data.sight.dottrans[_] or 0
						end
					end
				end
			end
		end
		if model:FindFirstChild("MuzzleAttach") then
			for i,v in next, muzzleAttachs do
				v.model:SetPrimaryPartCFrame(model.MuzzleAttach.CFrame * data.view.fix:inverse())
			end
		end
		if model:FindFirstChild("UnderbarrelAttach") then
			for i,v in next, underAttachs do
				v.model:SetPrimaryPartCFrame(model.UnderbarrelAttach.CFrame * data.view.fix:inverse())
				
				if v.data.underbarrel.lhand then
					setArmPos(model.LeftArm, model.LeftHand, v.model[v.data.underbarrel.lhand], m.lhandt)
					if m.deployed.anim.active then
						m.lhandtt = 1
					else
						m.lhandtt = 0
					end
				end
				if v.data.underbarrel.laser then
					local laser = m.deployed.laser
					local emitter = v.model[v.data.underbarrel.laser.part]
					
					local ray = Ray.new(emitter.Position, (emitter.CFrame * CFrame.Angles(0, math.pi / 2, 0)).lookVector * 2000)
					local part, hit, surface = workspace:FindPartOnRayWithIgnoreList(ray, {laser, camera, player.Character})
					
					if part then
						laser.SurfaceGui.Enabled = true
						laser.CFrame = CFrame.new(hit, hit + surface)
					else
						laser.SurfaceGui.Enabled = false
					end
				end
			end
		end
		
		local oc = maff.easing.fc(aimFunc, m.pos.origincurrent, data.shoot and m.calculateAim() or m.pos.origincurrent, aimtimebez)
		if not m.deployed.anim.active then
			model:SetPrimaryPartCFrame(camera.CoordinateFrame * m.delta.sway * data.view.fix * oc * recoilangle--[[ * m.pos.current]] * data.view.fix:inverse() * m.delta.rotsway * data.view.fix * m.pos.current)
		else
			model:SetPrimaryPartCFrame(camera.CoordinateFrame * m.delta.sway * data.view.fix * oc * data.view.fix:inverse() * m.deployed.anim.offset * data.view.fix * recoilangle--[[ * m.pos.current]] * data.view.fix:inverse() * m.delta.rotsway * data.view.fix * m.pos.current)
		end
	end
end)

return m