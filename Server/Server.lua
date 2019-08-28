local network = require(script.NetworkServer)
local weapons = require(script.Weapons)
local chat = require(script.ServerChat)
local round = require(script.Round)
local players = game:GetService("Players")

round.chat = chat
chat.round = round
weapons.round = round
round.weapons = weapons

wait(1)
round.stop()