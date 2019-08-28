local storage = game:GetService("ReplicatedStorage")

local players = game:GetService("Players")
local player = players.LocalPlayer

local keyboard = require(script.Parent.Parent.Keyboard)
local network = require(script.Parent.Parent.NetworkClient)

local camera = workspace.CurrentCamera

--

local deploy = {}
local ui

deploy.inventory = nil

deploy.primary = "M16A4"
deploy.secondary = "Glock 17"
deploy.melee = "M7 Bayonet"
deploy.grenade = "M67 grenade"

deploy.rotoffset = CFrame.new()

deploy.weaponsoftype = function(t)
	local ws = {}
	for i,v in next, storage.Weapons.Config:GetChildren() do
		local data = require(v)
		if data.type == t then
			table.insert(ws, data)
		end
	end
	return ws
end

deploy.getAttachment = function(name)
	return require(storage.Attachments.Config:FindFirstChild(name)), storage.Attachments.Models:FindFirstChild(name)
end

local function contains(t, a)
	for i,v in next, t do
		if v == a then
			return true
		end
	end
	return false
end

deploy.selectedAttachments = {}--{{name = "M16A4", attachment = "Reflex Sight"}, {name = "Desert Eagle", attachment = "Reflex Sight"}}

deploy.selectAttachment = function(gunname, attachmentname)
	for i,v in next, deploy.selectedAttachments do
		if v.name == gunname and v.attachment == attachmentname then
			return
		end
	end
	table.insert(deploy.selectedAttachments, {name = gunname, attachment = attachmentname})
end
deploy.deselectAttachment = function(gunname, attachmentname)
	for i,v in next, deploy.selectedAttachments do
		if v.name == gunname and v.attachment == attachmentname then
			table.remove(deploy.selectedAttachments, i)
			return
		end
	end
end

local indexof = function(t, a)
	for i,v in next, t do
		if v == a then
			return i
		end
	end
	return -1
end
local indexwhere = function(t, f)
	for i,v in next, t do
		if f(v) then
			return i
		end
	end
	return -1
end

deploy.supportedAttachments = function(gunname, t)
	local data = deploy.inventory.m.weapons.get(gunname)
	local sa = {}
	for i,v in next, data.attachments do
		if deploy.getAttachment(v).type:lower() == t then
			table.insert(sa, v)
		end
	end
	return sa
end

deploy.selectedOf = function(gunname, t)
	for i,v in next, deploy.selectedAttachments do
		local data = deploy.getAttachment(v.attachment)
		if v.name == gunname and data.type:lower() == t then
			return data, indexof(deploy.supportedAttachments(gunname, t), data.name)
		end
	end
end

deploy.active = function()
	return ui.screen:FindFirstChild("DeployUi") ~= nil
end

deploy.finish = function()
	if not network.sendFunc("can spawn") then return end
	deploy.updater:disconnect()
	deploy.rendered.obj:Destroy()
	for i,v in next, deploy.rendered.attachments or {} do
		v.model:Destroy()
	end
	deploy.rendered = nil
	network.sendEvent("respawn")
	ui.screen:Destroy()
	repeat wait() until player.Character ~= nil and player.Character:FindFirstChild("HumanoidRootPart")
	local primaryAttachments = {}
	local secondaryAttachments = {}
	for i,v in next, deploy.selectedAttachments do
		if v.name == deploy.primary then
			table.insert(primaryAttachments, v.attachment)
		elseif v.name == deploy.secondary then
			table.insert(secondaryAttachments, v.attachment)
		end
	end
	deploy.inventory.addweapon(deploy.primary, primaryAttachments)
	deploy.inventory.addweapon(deploy.secondary, secondaryAttachments)
	deploy.inventory.addweapon(deploy.melee)
	deploy.inventory.addweapon(deploy.grenade)
	
	delay(0.6, function()
		deploy.inventory.equip(deploy.inventory.getweapon(deploy.primary))
	end)
end

deploy.updater = nil

keyboard.bind("space", function()
	if deploy.active() then
		deploy.finish()
	end
end)

local lastX, lastY = -1, -1

local m1down = false
game:GetService("UserInputService").InputBegan:connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		m1down = true
	end
end)

game:GetService("UserInputService").InputEnded:connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		m1down = false
	end
end)

deploy.mousemoverupdater = game:GetService("UserInputService").InputChanged:connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and deploy.rotoffset ~= nil then
		local posX, posY = input.Position.X, input.Position.Y
		if lastX == -1 then
			lastX, lastY = posX, posY
		end
		local deltaX, deltaY = posX - lastX, posY - lastY
		if m1down then deploy.rotoffset = CFrame.Angles(0, math.rad(deltaX / 2), 0) * CFrame.Angles(math.rad(deltaY / 2), 0, 0) * deploy.rotoffset end
		lastX, lastY = posX, posY
	end
end)

local mapcam
network.onEvent("map change", function(mapdata)
	mapcam = mapdata and mapdata.camera or nil
end)

deploy.init = function(inv)
	deploy.inventory = inv
	
	camera:ClearAllChildren()
	camera.FieldOfView = 70
	
	game:GetService("UserInputService").MouseIconEnabled = true
	game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.Default
	player.CameraMode = Enum.CameraMode.Classic
	--camera.CameraType = "Scriptable"
	
	local height = 60
	
	--ui.m.chat.adjustoffset(UDim2.new(0, 0, 0, -height), "Out", "Quint", 0)
	
	ui.deployframe = storage.Shared.DeployUi:Clone()
	ui.deployframe.Parent = ui.screen
	
	--[[ui.deployframe = Instance.new("Frame")
	ui.deployframe.BackgroundTransparency = 1
	ui.deployframe.Size = UDim2.new(1, 0, 1, 0)
	ui.deployframe.Name = "Deploy"
	ui.deployframe.Parent = ui.screen
	
	deploy.frame = Instance.new("Frame")
	deploy.frame.BorderSizePixel = 0
	deploy.frame.Size = UDim2.new(1, 0, 0, height)
	deploy.frame.Position = UDim2.new(0, 0, 1, -height)
	deploy.frame.BackgroundColor3 = Color3.new(76 / 255, 89 / 255, 109 / 255)
	deploy.frame.ClipsDescendants = true
	deploy.frame.Parent = ui.deployframe
	
	deploy.spacetd = Instance.new("TextLabel")
	deploy.spacetd.Text = "PRESS SPACE TO DEPLOY\nSCROLL OVER GUN NAME TO SWITCH WEAPON"
	deploy.spacetd.BorderSizePixel = 0
	deploy.spacetd.Size = UDim2.new(0, 500, 0, 80)
	deploy.spacetd.Font = "SourceSansItalic"
	deploy.spacetd.TextSize = 28
	deploy.spacetd.BackgroundColor3 = deploy.frame.BackgroundColor3
	deploy.spacetd.TextColor3 = Color3.new(1, 1, 1)
	deploy.spacetd.Position = UDim2.new(0.5, -deploy.spacetd.Size.X.Offset / 2, 1, -height - 10 - deploy.spacetd.Size.Y.Offset)
	deploy.spacetd.Parent = ui.deployframe
	deploy.spacetd.TextWrapped = true
	deploy.spacetd.Changed:connect(function(p)
		if p == "Text" then
			deploy.spacetd.Font = "SourceSans"
			deploy.spacetd.Size = UDim2.new(0, 500, 0, 40)
			if not deploy.spacetd.TextFits then
				repeat
					deploy.spacetd.Size = deploy.spacetd.Size + UDim2.new(0, 0, 0, 40)
				until deploy.spacetd.TextFits
			end
			deploy.spacetd.Position = UDim2.new(0.5, -deploy.spacetd.Size.X.Offset / 2, 1, -height - 10 - deploy.spacetd.Size.Y.Offset)
		end
	end)]]
	
	local primaries = deploy.weaponsoftype("primary")
	local psel = indexwhere(primaries, function(w) return w.name == deploy.primary end)
	local secondaries = deploy.weaponsoftype("secondary")
	local ssel = indexwhere(secondaries, function(w) return w.name == deploy.secondary end)
	local melees = deploy.weaponsoftype("melee")
	local msel = indexwhere(melees, function(w) return w.name == deploy.melee end)
	
	local categorySelected = "primary"
	
	local atypes = {"sight", "underbarrel", "muzzle"}
	
	local function getType(t)
		for i,v in next, atypes do
			if v.t == t then
				return v
			end
		end
	end
	
	deploy.rendered = nil
	deploy.rotoffset = CFrame.new()
	
	local function setIronsightTransparency(trans)
		for i,v in next, deploy.rendered.data.model.ironsight or {} do
			if deploy.rendered.obj:FindFirstChild(v) ~= nil then
				deploy.rendered.obj[v].Transparency = trans
			end
		end
	end
	
	local function supportsAny(t)
		local l = {"NONE"}
		if not rendering then return false end
		for i,v in next, deploy.inventory.m.weapons.get(rendering).attachments or {} do
			local a = deploy.getAttachment(v)
			if a.type:lower() == t then
				table.insert(l, a)
			end
		end
		return l
	end
	
	local function renderAttachments(oldA)
		if oldA then
			for i,v in next, oldA do
				v.model:Destroy()
			end
		end
		local attch = {}
		
		local data = deploy.rendered.data
		local model = deploy.rendered.obj
		
		setIronsightTransparency(0)
		
		for i,v in next, deploy.selectedAttachments do
			local a, m = deploy.getAttachment(v.attachment)
			if data.shoot and contains(data.attachments, a.name) and data.name == v.name then
				local c = m:Clone()
				c.PrimaryPart = c.Attach
				c.Attach.Transparency = 1
				if a.type:lower() == "sight" then
					c[a.sight.aim1].Transparency = 1
					c[a.sight.aim2].Transparency = 1
					setIronsightTransparency(1)
					
					if a.sight.real then
						for _,sightName in next, a.sight.dots do
							c[sightName].Transparency = 1
						end
					end
				elseif a.type:lower() == "underbarrel" then
					if a.underbarrel.lhand then
						c[a.underbarrel.lhand].Transparency = 1
					end
				end
				c.Parent = camera
				
				table.insert(attch, {model = c, data = a})
			end
		end
		return attch
	end
	
	local function render()
		local oldAttachments = deploy.rendered and deploy.rendered.attachments
		if deploy.rendered then
			deploy.rendered.obj:Destroy()
			deploy.rendered = nil
		end
		local rendering = deploy[categorySelected]
		local data = deploy.inventory.m.weapons.get(rendering)
		local model = storage.Weapons.Models[rendering]:Clone()
		model.PrimaryPart = model[data.model.main]
		for i,v in next, model:GetChildren() do
			if v:IsA("BasePart") and v.Name:sub(#v.Name - 5):lower() == "attach" then
				v.Transparency = 1
			end
		end
		
		if data.shoot then
			model[data.model.aim1].Transparency = 1
			model[data.model.aim2].Transparency = 1
		end
		model.LeftHand.Transparency = 1
		model.RightHand.Transparency = 1
		model.Parent = camera
		deploy.rendered = {obj = model, data = data}
		local a = renderAttachments(oldAttachments)
		deploy.rendered.attachments = a
	end
	
	deploy.updater = game:GetService("RunService").RenderStepped:connect(function()
		if not deploy.rendered then return end
		camera.CoordinateFrame = mapcam or CFrame.new(0, 200, 0) * CFrame.Angles(math.rad(-90), 0, 0)
		deploy.rendered.obj:SetPrimaryPartCFrame(camera.CoordinateFrame * deploy.rendered.data.view.fix * CFrame.new(-deploy.rendered.data.preview.forward, 0, 0) * CFrame.Angles(0, math.pi / 2, 0) * deploy.rotoffset * CFrame.new(-deploy.rendered.data.preview.side, 0, 0))
		
		for i,v in next, deploy.rendered.attachments or {} do
			local t = v.data.type:lower()
			if t == "sight" then
				v.model:SetPrimaryPartCFrame(deploy.rendered.obj.SightAttach.CFrame * deploy.rendered.data.view.fix:inverse())
			elseif t == "underbarrel" then
				v.model:SetPrimaryPartCFrame(deploy.rendered.obj.UnderbarrelAttach.CFrame * deploy.rendered.data.view.fix:inverse())
			elseif t == "muzzle" then
				v.model:SetPrimaryPartCFrame(deploy.rendered.obj.MuzzleAttach.CFrame * deploy.rendered.data.view.fix:inverse())
			end
		end
	end)
	
	local attachObjectOriginal = ui.deployframe.WeaponInfo.StatsPage.Stats.Optics
	local attachObject = attachObjectOriginal:Clone()
	attachObjectOriginal:Destroy()
	
	local dividerObjectOriginal = ui.deployframe.WeaponInfo.StatsPage.Stats.Divider
	local dividerObject = dividerObjectOriginal:Clone()
	dividerObjectOriginal:Destroy()
	
	local statObjectOriginal = ui.deployframe.WeaponInfo.StatsPage.Stats.Damage
	local statObject = statObjectOriginal:Clone()
	statObjectOriginal:Destroy()
		
	local weaponObjectOriginal = ui.deployframe.WeaponSelector.Weapon
	local weaponObject = weaponObjectOriginal:Clone()
	weaponObjectOriginal:Destroy()
	
	local function clearoftype(parent, class)
		for i,v in next, parent:GetChildren() do
			if v:IsA(class) then
				v:Destroy()
			end
		end
	end
	
	local function updateUi()
		local weapon = deploy[categorySelected]
		local data = deploy.inventory.m.weapons.get(weapon)
		local gui = ui.deployframe
		
		for i,v in next, gui.SlotSelector:GetChildren() do
			if v:IsA("TextButton") then
				v.Weapon.Text = deploy[v.Name:lower()]
			end
		end
		
		-- STATS AND STUFF
		gui.WeaponInfo.WeaponName.Title.Text = data.name
		gui.WeaponInfo.WeaponName.Description.Text = data.desc
		
		clearoftype(gui.WeaponInfo.StatsPage.Stats, "Frame")
		local stats = {}
		
		if data.shoot then
			stats = {
				{"Damage", function() return data.shoot.dmg.base end},
				{"Firerate", function() return math.floor(data.shoot.rate * 60) .. " RPM" end},
				{"Muzzle Velocity", function() return math.floor(data.shoot.velocity) .. " m/s" end},
				{"Hipfire Spread", function() return (data.shoot.spread.hipfire or 0) + (data.shoot.spread.base or 0) end},
				{"Recoil", function() return math.floor((data.shoot.recoil.y[1] + data.shoot.recoil.y[2]) * 5) / 10 end}
			}
		elseif data.melee then
			stats = {
				{"Damage", function() return data.melee.damage end},
				{"Backstab Damage", function() return math.floor(data.melee.damage * data.melee.backstab) end},
				{"Range", function() return data.melee.range .. " studs" end},
				{"Cooldown", function() return data.melee.cooldown .. "s" end}
			}
		elseif data.grenade then
			stats = {
				{"Cook Time", function() return data.grenade.cook and data.grenade.cook .. "s" or "N/A" end},
				{"Count", function() return data.grenade.count end}
			}
			if data.grenade.explosion then
				local e = data.grenade.explosion
				table.insert(stats, {"Blast Radius", function() return e.radius .. " studs" end})
				table.insert(stats, {"Lethality Radius", function() return math.floor(e.radius * e.destroy * 10) / 10 .. " studs" end})
			end
		end
		
		for _,v in next, stats do
			local stat = statObject:Clone()
			stat.Name = v[1]
			stat.StatName.Text = v[1]
			stat.Statistic.Text = v[2]()
			stat.Parent = gui.WeaponInfo.StatsPage.Stats
		end
		
		if data.shoot then
			dividerObject:Clone().Parent = gui.WeaponInfo.StatsPage.Stats
			
			for i,v in next, atypes do
				local attachments = {"None"}
				for i,v in next, deploy.supportedAttachments(weapon, v) do
					table.insert(attachments, v)
				end
				local selected = deploy.selectedOf(weapon, v)
				local index = selected and indexof(attachments, selected.name) or -1
				if index == -1 then
					index = 1
				end
				
				local at = attachObject:Clone()
				at.Name = v
				at.StatName.Text = v:sub(1, 1):upper() .. v:sub(2)
				at.Statistic.Text = attachments[index]
				at.Parent = gui.WeaponInfo.StatsPage.Stats
				
				at.LeftButton.MouseButton1Down:connect(function()
					if selected ~= nil then
						deploy.deselectAttachment(weapon, selected.name)
					end
					local nextAttachment = attachments[(index - 2) % #attachments + 1]
					if nextAttachment ~= "None" then
						deploy.selectAttachment(weapon, nextAttachment)
					end
					updateUi()
				end)
				at.RightButton.MouseButton1Down:connect(function()
					if selected ~= nil then
						deploy.deselectAttachment(weapon, selected.name)
					end
					local nextAttachment = attachments[index % #attachments + 1]
					if nextAttachment ~= "None" then
						deploy.selectAttachment(weapon, nextAttachment)
					end
					updateUi()
				end)
			end
		end
		-- END STATS AND STUFF
		
		-- WEAPON LIST ON LEFT
		clearoftype(gui.WeaponSelector, "TextButton")
		local weapons = deploy.weaponsoftype(categorySelected)
		
		for i,v in next, weapons do
			local wo = weaponObject:Clone()
			if deploy[categorySelected] == v.name then
				wo.Checked.Check.Visible = true
			else
				wo.Checked.Check.Visible = false
			end
			wo.Name = v.name
			wo.WeaponName.Text = v.name
			wo.Parent = gui.WeaponSelector
			
			wo.MouseButton1Down:connect(function()
				deploy[categorySelected] = v.name
				updateUi()
			end)
		end
		
		render()
		
	end
		
	ui.deployframe.SlotSelector.Primary.MouseButton1Down:connect(function()
		categorySelected = "primary"
		updateUi()
	end)
	ui.deployframe.SlotSelector.Secondary.MouseButton1Down:connect(function()
		categorySelected = "secondary"
		updateUi()
	end)
	ui.deployframe.SlotSelector.Melee.MouseButton1Down:connect(function()
		categorySelected = "melee"
		updateUi()
	end)
	ui.deployframe.SlotSelector.Grenade.MouseButton1Down:connect(function()
		categorySelected = "grenade"
		updateUi()
	end)
	ui.deployframe.DeployButton.MouseButton1Down:connect(function()
		deploy.finish()
	end)
	
	rendering = deploy.primary
	updateUi()
	
end

return function(gui) ui = gui return deploy end