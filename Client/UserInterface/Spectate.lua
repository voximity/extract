-- This file has no functionality and was never fully finished

local ui

local spectate = {}
spectate.spectating = {}
spectate.reset = function()
	if spectate.spectating.gui ~= nil then
		spectate.spectating.gui:Destroy()
	end
	spectate.spectating = {
		gui = nil
	}
end
spectate.reset()

spectate.init = function()
	
end

spectate.showfor = function(player, weapon, distance, given_damage, given_hits, taken_damage, taken_hits)
	if player.Character == nil then return end
	local c = player.Character
	local gui = game:GetService("ReplicatedStorage").Shared.KillUi:Clone()
	
	gui.Killer.Text.Text = player.Name
	gui.HealthBar.Health.Size = UDim2.new(c.Humanoid.Health / c.Humanoid.MaxHealth, 0, 0, 6)
	gui.Weapon.Text = weapon
	gui.Distance.Text = distance and (type(distance) == "string" and distance or math.floor(distance / 5 * 1.75) .. "m") or "N/A"
	gui.Given.Text = given_damage .. " in " .. given_hits
	gui.Taken.Text = taken_damage .. " in " .. taken_hits
	
	gui.Parent = ui.screen
	
	spectate.spectating.gui = gui
end

return function(gui) ui = gui return spectate end