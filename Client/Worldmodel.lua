local storage = game:GetService("ReplicatedStorage")
local runservice = game:GetService("RunService")

local cb = require(storage.Shared.CubicBezier)
local maff = require(storage.Shared.Math)
local network = require(script.Parent.NetworkClient)

---

local wm = {}
wm.animators = {}
wm.getAnimator = function(player)
	for i,v in next, wm.animators do
		if v.player == player then
			return v
		end
	end
	local animator = {player = player, active = false, offset = CFrame.new(), lastkey = {}}
	table.insert(wm.animators, animator)
	return animator
end
wm.resetAnimator = function(player)
	local a = wm.getAnimator(player)
	a.player = player
	a.active = false
	a.offset = CFrame.new()
	a.lastkey = {}
end
wm.getWeapon = function(weapon)
	return require(storage.Weapons.Config[weapon]), storage.Weapons.Models[weapon]
end

wm.playSound = function(sound, parent)
	local delaytime = 0
	if wm.character.get() ~= nil and wm.character.get():FindFirstChild("Head") ~= nil and parent ~= nil and parent:IsA("BasePart") then
		local headpos = wm.character.get().Head.Position
		local distance = (parent.Position - headpos).magnitude
		delaytime = distance * 1.75 / 5 / 343
	end
	
	delay(delaytime, function()
		local s = sound:Clone()
		--s.Pitch = maff.rand(0.97, 1.03, 2)
		s.TimePosition = s:FindFirstChild("Delay") and s.Delay.Value or 0
		s.Parent = parent or sound.Parent
		if wm.character.get() == nil or wm.character.get().Humanoid.Health <= 0 then
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

wm.playAnim = function(player, weapon, name, last)
	local char = player.Character
	local animator = wm.getAnimator(player)
	
	local data, omodel = wm.getWeapon(weapon)
	local anim = data.view.anim[name]
	local model = char["Worldmodel" .. data.name]
	local main = model[data.model.main]
	
	animator.active = true
	for ind, keyframe in next, anim do
		if type(ind) == "number" and ((keyframe.lastOnly and last) or not keyframe.lastOnly) then
			local waitbegin = time()
			repeat
				if not animator.active then break end
				runservice.RenderStepped:wait()
			until time() - waitbegin >= (keyframe.d or 0)
			
			local bezier = nil
			if keyframe.bezier ~= nil then
				local b = keyframe.bezier
				bezier = cb.cubicbezier(b[1], b[2], b[3], b[4])
			end
			
			local startTime = time()
			local startOffset = animator.offset
			local startOffsets = {}
			for i,v in next, model:GetChildren() do
				if v ~= main and v:IsA("BasePart") and (v.Name == "LeftHand" or v.Name == "RightHand") then
					startOffsets[v] = animator.lastkey["WM" .. v.Name] or animator.lastkey[v.Name] or CFrame.new()
				end
			end
			
			if keyframe.s or keyframe.sound then
				delay(keyframe.sd or 0, function() wm.playSound(omodel[data.model.muzzle][keyframe.s], char:FindFirstChild("HumanoidRootPart")) end)
			end
			
			repeat
				if not animator.active then break end
				local current = (time() - startTime) / keyframe.t	
				
				if bezier == nil then
					animator.offset = maff.cosineclerp(startOffset, keyframe.p or CFrame.new(), current, keyframe.pow)
				else
					animator.offset = startOffset:lerp(keyframe.p or CFrame.new(), bezier(current))
				end
				
				for i,v in next, model:GetChildren() do
					if (v.Name == "LeftHand" or v.Name == "RightHand") then
						local dpos = v.ToMain.DefaultPosition.Value
						local kfs = keyframe.o or {}
						local kf = kfs["WM" .. v.Name] or kfs[v.Name] or CFrame.new()
						if bezier == nil then
							v.ToMain.C0 = dpos * maff.cosineclerp((startOffsets[v] or CFrame.new()), kf, current, keyframe.pow)
						else
							v.ToMain.C0 = dpos * (startOffsets[v] or CFrame.new()):lerp(kf, bezier(current))
						end
					end
				end
				
				runservice.RenderStepped:wait()
			until time() - startTime >= keyframe.t
			
			if not animator.active then break end
			
			animator.lastkey = {}
			for i,v in next, keyframe.o do
				animator.lastkey[i] = v
			end
		end
	end
	if not last then
		wm.stopAnim(player, true, anim.ignoreReset)
	else
		wm.stopAnim(player, true)
	end
	
	if not anim.ignoreReset or last then
		wm.resetAnimator(animator.player)
		for i,v in next, model:GetChildren() do
			if v ~= main and v:IsA("BasePart") and (v.Name == "LeftHand" or v.Name == "RightHand") then
				v.ToMain.C0 = v.ToMain.DefaultPosition.Value
			end
		end
	end
end
wm.stopAnim = function(player, dontWait, dontReset)
	local animator = wm.getAnimator(player)
	animator.active = false
	if not dontReset then animator.offset = CFrame.new()
	animator.lastkey = {} end
	if not dontWait then wait() end
end

network.onEvent("play animation", function(player, weapon, name, last)
	if player == game:GetService("Players").LocalPlayer then return end
	wm.playAnim(player, weapon, name, last)
end)

runservice.RenderStepped:connect(function()
	for i = #wm.animators, 1, -1 do
		local v = wm.animators[i]
		
		if v.player.Character == nil or v.player.Character:FindFirstChild("Humanoid") == nil or v.player.Character.Humanoid.Health <= 0 then
			v.active = false
			table.remove(wm.animators, i)
		else
			local char = v.player.Character
			local model
			for i,v in next, char:GetChildren() do
				if v.Name:sub(1, 10) == "Worldmodel" then
					model = v
					break
				end
			end
			local name = model.Name:sub(11)
			local data = wm.getWeapon(name)
			local main = model[data.model.main]
			main.RootWeld.C0 = main.RootWeld.DefaultPosition.Value * data.view.fix:inverse() * v.offset * data.view.fix
		end
	end
end)

return wm