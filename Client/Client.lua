local character = require(script.Character)
local weapons = require(script.Weapons)
local keyboard = require(script.Keyboard)
local network = require(script.NetworkClient)
local inventory = require(script.Inventory)
local worldmodel = require(script.Worldmodel)
local ui = require(script.UserInterface)(inventory)

inventory.m.weapons = weapons
inventory.m.character = character

worldmodel.character = character

weapons.character = character
weapons.inventory = inventory
character.weapons = weapons
character.ui = ui
character.inventory = inventory

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

game:GetService("ContentProvider"):PreloadAsync(game:GetService("ReplicatedStorage").Assets.Audio:GetChildren())

network.onEvent("ping", function(num)
	network.sendEvent("pong " .. game:GetService("Players").LocalPlayer.Name, num)
end)

local waitedOnce = false

game:GetService("Players").LocalPlayer.CharacterAdded:connect(function()
	--[[if not waitedOnce then
		waitedOnce = true
		wait(1)
	else
		wait()
	end]]
	wait()
	ui.init()
end)

wait(3)
ui.init()
ui.m.deploy.init(inventory)