local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local modules = require(ReplicatedStorage.modules)
local network = modules.load("network")

local TweenService = game:GetService("TweenService")

local function openDrawer(player, drawer)
	drawer:SetAttribute("Moving", true)
	
	local isOpen = drawer:GetAttribute("Open")
	local dir = isOpen and -1 or 1
	
	network:fireAllClients("playerRequest_openDrawer", drawer, dir)
	
	drawer:SetAttribute("Open", not isOpen)
	drawer:SetAttribute("Moving", false)
end

function module.spawnFurniture(room, furnitureModel, spawnAreaPart, fixedX)
	local areaSize = spawnAreaPart.Size
	local areaCFrame = spawnAreaPart.CFrame
	local fixedSpawnX = fixedX or 0
	
	local randomZ = math.random(-areaSize.Z / 2, areaSize.Z / 2)
	local localSpawnPosition = Vector3.new(fixedSpawnX, 0, randomZ)
	local worldSpawnPosition = areaCFrame:PointToWorldSpace(localSpawnPosition)
	local newFurniture = script:FindFirstChild(furnitureModel):Clone()
	local primaryPart = newFurniture.PrimaryPart

	if primaryPart then
		local cent = primaryPart:Clone()
		cent:PivotTo(CFrame.new(worldSpawnPosition) * (areaCFrame - areaCFrame.Position))
		cent.Parent = workspace

		local partsInRegion = workspace:GetPartsInPart(cent)
		for i, part in ipairs(partsInRegion) do
			if part.Name == "center" then
				cent:Destroy()
				newFurniture.center.Transparency = 1
				return
			end
		end

		newFurniture:PivotTo(CFrame.new(worldSpawnPosition) * (areaCFrame - areaCFrame.Position))
		newFurniture.Parent = room.Furnitures
		
		newFurniture.center.Transparency = 1

		for i, drawer in ipairs(newFurniture:GetChildren()) do
			if drawer.Name == "box" then
				drawer:SetAttribute("Open", false)
				drawer:SetAttribute("Moving", false)
				
				local prompt = Instance.new("ProximityPrompt")
				prompt.ActionText = "Open"
				prompt.ObjectText = newFurniture.Name
				prompt.Style = Enum.ProximityPromptStyle.Default	
				prompt.RequiresLineOfSight = false
				prompt.Parent = drawer.main.toggle
				
				prompt.Triggered:Connect(function(player)
					if drawer:GetAttribute("Moving") == false then
						openDrawer(player, drawer)
						prompt.Enabled = false
						task.wait(1)
						
						prompt.Enabled = true
					end
				end)
			end
		end
		
		cent:Destroy()
		
		return true
	end
end

local function main()
	network:create("playerRequest_openDrawer", "RemoteEvent", "OnServerEvent", openDrawer)
end

main()

return module
