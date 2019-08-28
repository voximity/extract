local players = game:GetService("Players")
local player = players.LocalPlayer

local storage = game:GetService("ReplicatedStorage")

local runservice = game:GetService("RunService")

local c = require(script.Parent.Constants)
local maff = require(storage.Shared.Math)
local keyboard = require(script.Parent.Keyboard)

local network = require(script.Parent.NetworkClient)

---


local character = {}
local canRespawn = false

character.keyboard = keyboard
character.weapons = nil
character.ui = nil
character.inventory = nil

character.crouching = false

character.moving = function()
	return keyboard.keys.w or keyboard.keys.a or
			keyboard.keys.s or keyboard.keys.d or
			keyboard.keys.leftshift
end

character.setCrouch = function(value)
	if value ~= character.crouching then
		network.sendEvent("crouch", value)
	end
	character.crouching = value
end

keyboard.bind("leftshift", function()
	if character.crouching then
		character.setCrouch(false)
	end
	character.weapons.mouse.right = false
	character.speed = c.humanoid.sprint
end, function()
	character.speed = character.crouching and c.humanoid.crouch or c.humanoid.walk
end)

local function crouchpress()
	character.setCrouch(not character.crouching)
	if character.crouching then
		character.speed = c.humanoid.crouch
	end
end

keyboard.bind("c", function()
	crouchpress()
end)
keyboard.bind("leftcontrol", function()
	crouchpress()
end)


-- Basic definitions
character.canJump = true

character.get = function()
	return player.Character
end
character.humanoid = function()
	return character.get():WaitForChild("Humanoid")
end
character.fixSpeed = function()
	character.speed = character.crouching and c.humanoid.crouch or (character.keyboard.keys.leftshift and c.humanoid.sprint or c.humanoid.walk)--character.keyboard.keys.leftshift and c.humanoid.sprint or (character.crouching and c.humanoid.crouch or c.humanoid.walk)
end

character.playSoundFromAssets = function(name, parent, volume, dampen)
	local s = storage.Assets.Audio[name]:Clone()
	s.Parent = parent or character.get().Head
	s.Volume = s.Volume * (volume or 1)
	
	if dampen and parent ~= nil then
		
		local pos = workspace.CurrentCamera.CoordinateFrame.p
		local target = parent.Position
		local ray = Ray.new(pos, (target - pos).unit * 1000)
		local chars = {}
		
		for i,v in next, game:GetService("Players"):GetPlayers() do
			if v.Character ~= nil then
				table.insert(chars, v.Character)
			end
		end
		
		local part, hit = workspace:FindPartOnRayWithIgnoreList(ray, {workspace.CurrentCamera, unpack(chars)})
		
		if part ~= nil then
			
			local equ = Instance.new("EqualizerSoundEffect")
			equ.LowGain = 4
			equ.MidGain = -2
			equ.HighGain = -6
			equ.Parent = s
			
		end
		
	end
	
	wait()
	
	s:Play()
	
	delay(s.TimeLength, function() s:Destroy() end)
end
network.onEvent("footstep sound", function(sound, plr, volume)
	if plr.Character == nil or plr.Character:FindFirstChild("Head") == nil then return end
	if plr == player then return end
	
	character.playSoundFromAssets(sound, plr.Character.Head, volume, true)
end)
network.onEvent("apply velocity", function(body_part, velocity)
	if character.get() == nil then return end
	local part = character.get():FindFirstChild(body_part)
	if not part then return end
	part.Velocity = velocity
end)
character.playFootstep = function(name, parent, volume)
	local sounds = c.footsteps[name]
	if sounds == nil then return end
	local sound = sounds[math.random(#sounds)]
	character.playSoundFromAssets(sound, parent, volume * 0.35)
	network.sendEvent("footstep sound", sound, volume)
end
character.playFootstepMaterial = function(material, parent, volume)
	local name = c.materials[material.Name]
	character.playFootstep(name, parent, volume)
end

character.speed = c.humanoid.walk
character.jumppower = c.humanoid.jump


character.jumpdeb = false

-- Updating

character.running = false
player.CharacterAdded:connect(function()
	character.weapons.remoteset = false
	
	character.running = false
	character.crouching = false
	canRespawn = false
	for i,v in next, workspace.CurrentCamera:GetChildren() do
		if v.Name == "Trail" then
			v:Destroy()
		end
	end
	character.get().ChildAdded:connect(function(ch)
		wait()
		if ch:IsA("Accessory") then
			ch:Destroy()
		elseif ch.Name == "Health" then
			ch:Destroy()
		end
	end)
	
	delay(.1, function()
		workspace.CurrentCamera.CameraType = "Custom"
		game:GetService("UserInputService").MouseIconEnabled = false
		game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.LockCenter
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	end)
	
	local h = character.humanoid()
	
	-- Audio
	h.StateChanged:connect(function(oldstate, newstate)
		if newstate == Enum.HumanoidStateType.Landed or newstate == Enum.HumanoidStateType.Jumping then
			character.playFootstepMaterial(h.FloorMaterial, nil, 3.5)
		end
	end)
	
	h.JumpPower = character.jumppower
	h.WalkSpeed = character.speed
	
	h.Changed:connect(function(property)
		if property == "Jump" and character.crouching then
			character.setCrouch(false)
			character.jumpdeb = true
			delay(1, function() character.jumpdeb = false end)
			h.Jump = false
			return
		end
		if property == "Jump" and character.jumpdeb then
			h.Jump = false
			return
		end
		if property == "Jump" and h.Jump == true then
			if not character.canJump then
				h.Jump = false
			else
				character.canJump = false
				delay(c.jumpdelay, function() character.canJump = true end)
			end
		end
	end)
	
	h.Died:connect(function()
		character.weapons.remoteset = false
		for i,v in next, character.weapons.remotegrenades do
			v.part:Destroy()
			network.sendEvent("remote grenade detonate", v.id)
		end
		character.weapons.remotegrenades = {}
		network.sendEvent("character died")
		character.weapons.resetDeployed()
		
		wait(5)
		character.ui.m.spectate.reset()
		canRespawn = true
		character.ui.m.deploy.init(character.inventory)
	end)
	
	character.get():WaitForChild("Head"):WaitForChild("Jumping")
	for i,v in next, character.get().Head:GetChildren() do
		if v:IsA("Sound") then
			v:Destroy()
		end
	end
end)

character.footsteptimer = 0
character.crouchingNumber = 0

runservice.Stepped:connect(function(_, delta)
	if character.get() == nil then return end
	
	local h = character.humanoid()
	
	local state = h:GetState().Name
	local staterunning = state == "Running" or state == "RunningNoPhysics"
	local movingrunning = (h.Parent.HumanoidRootPart.Velocity * Vector3.new(1, 0, 1)).magnitude
	
	local running = staterunning and movingrunning > 1
	
	character.footsteptimer = character.footsteptimer + delta * (running and 1 or 0)
	
	h.WalkSpeed = maff.lerp(h.WalkSpeed, character.speed, 0.1)
	h.JumpPower = maff.lerp(h.JumpPower, character.jumppower, 0.1)
	
	character.crouchingNumber = maff.lerp(character.crouchingNumber, character.crouching and 1 or 0, 0.1)
	h.CameraOffset = h.CameraOffset:lerp(character.crouching and Vector3.new(0, -1.5, 0) or Vector3.new(0, 0, 0), 0.1)
	
	if not running then
		--character.footsteptimer = 0
	elseif character.footsteptimer >= c.footsteprate / movingrunning then
		character.footsteptimer = 0
		character.playFootstepMaterial(h.FloorMaterial, nil, movingrunning / c.humanoid.walk)
	end
end)

return character