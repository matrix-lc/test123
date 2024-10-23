local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local module = require(ReplicatedStorage.modules)
local network = module.load("network")


local TweenService = game:GetService("TweenService")

local doorModel = script.Door

local function openDoor(newDoor)
	local leftDoor = newDoor:FindFirstChild("Left")
	local rightDoor = newDoor:FindFirstChild("Right")

	if leftDoor and rightDoor then
		network:fire("updateGameConfig", "roomCount")
		newDoor:SetAttribute("opened", true)
		
		network:fireAllClients("playerRequest_openDoor", leftDoor, rightDoor)
	end
end

function module.new(room, locked)
	local newDoor = doorModel:Clone()

	newDoor:PivotTo(room:FindFirstChild("in1").CFrame)
	newDoor:SetAttribute("opened", false)
	
	if locked == false then
		newDoor.sensor.Touched:Connect(function(hit)
			local humanoid = hit.Parent:FindFirstChild("Humanoid")
			if humanoid and newDoor:GetAttribute("opened") == false then
				openDoor(newDoor)
			end
		end)
	end

	if locked == true then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Open"
		prompt.Style = Enum.ProximityPromptStyle.Default	
		prompt.HoldDuration = 2
		prompt.RequiresLineOfSight = false
		prompt.Parent = newDoor.main.toggle
		
		newDoor.Left.Color = Color3.new(0.0196078, 0.623529, 1)
		newDoor.Right.Color = Color3.new(0.0196078, 0.623529, 1)

		prompt.Triggered:Connect(function(player)
			if player.Character:FindFirstChild("Key") then -- make sure to check the key name match, but shudnt be a problem
				player.Character.Key:Destroy()
				openDoor(newDoor)			
			end
		end)
	end

	return newDoor
end

local function main()
	network:create("playerRequest_openDoor", "RemoteEvent", "OnServerEvent", openDoor)
end

main()

return module
