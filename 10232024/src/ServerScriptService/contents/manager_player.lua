local module = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local modules = require(ReplicatedStorage.modules)
local network = modules.load("network")

function module.init(Modules)
	network:create("updateMouseLocation", "RemoteEvent", "OnServerEvent", function(player, mousePos)
		network:fireAllClientsExcludingPlayer("updateMouseLocation", player, player, mousePos)
	end)
end


return module
