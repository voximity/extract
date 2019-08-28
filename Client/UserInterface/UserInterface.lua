local players = game:GetService("Players")
local player = players.LocalPlayer

local keyboard = require(script.Parent.Keyboard)

local inputservice = game:GetService("UserInputService")

local c = require(script.Parent.Constants)

local network = require(script.Parent.NetworkClient)

---

local ui = {}
local elims = {}
local feed = {}
local leaderboard = require(script.Leaderboard)(ui)
local killfeed = require(script.Killfeed)(ui)
local chat = require(script.ClientChat)(ui)
local deploy = require(script.Deploy)(ui)
local spectate = require(script.Spectate)(ui)

ui.m = {}
ui.m.leaderboard = leaderboard
ui.m.killfeed = killfeed
ui.m.chat = chat
ui.m.deploy = deploy
ui.m.spectate = spectate
ui.m.network = network

ui.init = function()
	--repeat wait() until player.Character ~= nil and player.Character:FindFirstChild("Humanoid") ~= nil
	if ui.screen ~= nil and ui.screen.Parent ~= nil then return end
	elims = {}
	ui.screen = Instance.new("ScreenGui")
	ui.screen.Name = "UI"
	ui.screen.Parent = player:WaitForChild("PlayerGui")
	
	killfeed.init()
	chat.init()
	spectate.init()
	leaderboard.init()
end

ui.hint = function(message)
	local h = Instance.new("TextLabel")
	h.Text = message
	h.Font = "SourceSansItalic"
	h.TextColor3 = Color3.new(1, 1, 1)
	h.TextStrokeColor3 = Color3.new(0, 0, 0)
	h.TextStrokeTransparency = 0.5
	h.TextSize = 32
	h.Position = UDim2.new(0.5, 0, 0.7, 0)
	h.Size = UDim2.new(0, 0, 0, 0)
	h.BackgroundTransparency = 1
	h.Parent = ui.screen
end

network.onEvent("player died", function(victim, killer, weapon, headshot, hitinfo)
	if killer == nil then return end
	killfeed.add(killer.Name, victim.Name, weapon, headshot)
	
	if victim == player then
		spectate.showfor(killer, weapon, hitinfo.distance, hitinfo.given_damage, hitinfo.given_hits, hitinfo.taken_damage, hitinfo.taken_hits)
	end
end)

network.onEvent("update leaderboard", function(lb)
	leaderboard.leaderboard = lb
	leaderboard.update(leaderboard.leaderboard)
end)

return function(inv) ui.inventory = inv return ui end