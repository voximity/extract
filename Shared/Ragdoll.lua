local r = {}

r.create_weld = function(char, name)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "Weld" .. name
	weld.Part0 = char.Torso
	weld.Part1 = char[name]
	weld.Parent = char.Torso
	
	return weld
end
r.create_joint = function(char, name, torsoOff, partOff, upper, twupper, twlower)
	local torsoAttach = Instance.new("Attachment")
	torsoAttach.Position = torsoOff
	torsoAttach.Name = "Ragdoll"..name
	
	local partAttach = torsoAttach:Clone()
	partAttach.Position = partOff
	
	torsoAttach.Parent = char.Torso
	partAttach.Parent = char[name]
	
	local socket = Instance.new("BallSocketConstraint")
	socket.Attachment0 = torsoAttach
	socket.Attachment1 = partAttach
	socket.LimitsEnabled = true
	socket.UpperAngle = upper or 45
	
	if twupper or twlower then
		socket.TwistLimitsEnabled = true
		socket.TwistLowerAngle = twlower
		socket.TwistUpperAngle = twupper
	end
	
	socket.Name = "RagdollSocket"..name
	socket.Parent = char.Torso
end

r.ragdoll = function(player, velocity)
	if player.Character == nil then return end
	local c = player.Character
	if c.Torso:FindFirstChild("RagdollHead") then return end
	
	local neck = r.create_joint(c, "Head", Vector3.new(0, 1, 0), Vector3.new(0, -0.5, 0), 165, 35, 35)
	local larm = r.create_joint(c, "Left Arm", Vector3.new(-1, 0.5, 0), Vector3.new(0.5, 0.5, 0))
	local rarm = r.create_joint(c, "Right Arm", Vector3.new(1, 0.5, 0), Vector3.new(-0.5, 0.5, 0))
	local lleg = r.create_joint(c, "Left Leg", Vector3.new(-1, -1, 0), Vector3.new(-0.5, 1, 0))
	local rleg = r.create_joint(c, "Right Leg", Vector3.new(1, -1, 0), Vector3.new(0.5, 1, 0))
end

return r