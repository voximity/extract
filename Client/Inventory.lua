local players = game:GetService("Players")
local player = players.LocalPlayer

local keyboard = require(script.Parent.Keyboard)
local network = require(script.Parent.NetworkClient)

local inputservice = game:GetService("UserInputService")

---

local numbernames = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "zero"}

local inventory = {}

inventory.m = {}

inventory.weapons = {}
inventory.getweapon = function(name)
	for i,v in next, inventory.weapons do
		if v.name == name then
			return v, i
		end
	end
end
inventory.getcurrent = function()
	if not inventory.m.weapons.isdeployed() then return end
	local v, i = inventory.getweapon(inventory.m.weapons.deployed.data.name)
	return v, i
end
inventory.addweapon = function(name, attachments)
	local data = inventory.m.weapons.get(name)
	if data == nil then return end
	local weapon = {
		name = name,
		ammo = data.shoot and data.shoot.ammo,
		chambered = true,
		attachments = attachments or {}
	}
	table.insert(inventory.weapons, weapon)
	return weapon
end
inventory.equipdeb = false
local previouslyDeployed = nil
inventory.equip = function(weapon, ignoreDeb)
	if weapon == nil then return end
	if inventory.equipdeb and not ignoreDeb then return end
	if inventory.m.character.humanoid().Health <= 0 then return end
	if inventory.m.weapons.isdeployed() and weapon.name == inventory.m.weapons.deployed.data.name then return end
	if inventory.m.weapons.isdeployed() then
		pcall(function()
			inventory.getweapon(inventory.m.weapons.deployed.data.name).ammo = inventory.m.weapons.deployed.ammo
		end)
	end
	if inventory.m.weapons.deployed.cooking then
		inventory.m.weapons.deployed.cooking = false
		inventory.equipdeb = true
		wait(0.3)
		inventory.equipdeb = false
	end
	if weapon.ammo == 0 and inventory.m.weapons.get(weapon.name).type == "grenade" then
		local _, index = inventory.getweapon(weapon.name)
		table.remove(inventory.weapons, index)
		return
	end
	if previouslyDeployed ~= nil and not ignoreDeb then return end
	if inventory.getweapon(weapon.name) == nil then return end
	inventory.equipdeb = true
	inventory.m.weapons.deploy(weapon.name, weapon.ammo, weapon.attachments)
	delay(0.6, function()
		inventory.equipdeb = false
	end)
end

for i,v in next, numbernames do
	keyboard.bind(v, function()
		inventory.equip(inventory.weapons[i])
	end)
end
keyboard.bind("g", function()
	previouslyDeployed = inventory.getcurrent()
	for i,v in next, inventory.weapons do
		local data = inventory.m.weapons.get(v.name)
		if data.type == "grenade" and (v.ammo or data.grenade.count or 1) > 0 then
			inventory.equip(v, true)
			inventory.m.weapons.cookGrenade()
		end
	end
end, function()
	if inventory.m.weapons.deployed.cooking then
		inventory.m.weapons.deployed.cooking = false
		inventory.equipdeb = true
		delay(0.4, function()
			if not inventory.m.weapons.deployed.data.remote then
				inventory.equipdeb = false inventory.equip(previouslyDeployed, true) previouslyDeployed = nil
			end
		end)
	else
		previouslyDeployed = nil
		inventory.equipDeb = false
	end
end)

inputservice.InputChanged:connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
	
	local up = 0 < input.Position.Z
	local w, i = inventory.getcurrent()
	if not w or not i then return end
	local n = i + (up and -1 or 1)
	if n > #inventory.weapons then n = 1
	elseif n < 1 then n = #inventory.weapons
	end
	inventory.equip(inventory.weapons[n])
end)

player.CharacterAdded:connect(function(char)
	char:WaitForChild("Humanoid").Died:connect(function()
		inventory.weapons = {}
	end)
	
	char:WaitForChild("HumanoidRootPart")
	--inventory.equip(inventory.getweapon("FAMAS"))
end)

return inventory