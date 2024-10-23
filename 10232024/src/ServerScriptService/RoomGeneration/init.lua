local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local roomInfo = require(script.RoomsInfo)
local doorModule = require(script.DoorGeneration)
local furnitureSpawn = require(script.FurnitureGeneration)
local itemModule = require(script.itemGeneration)

local monsterModule = require(script.monsterModule)

local module = require(ReplicatedStorage.modules)
local network = module.load("network")

local nodes = workspace.Nodes

--OVERALL GAME STATS
local settings = ReplicatedStorage.gameStats
local roomNumber = settings.roomNumber.Value

--MONSTER SPAWN
local baseSpawnChance = 80
local maxSpawnChance = 100 
local monsterRoomCount = 1 
local roomThreshold = 15 

module.Rooms = {}

local lockedRoomWeights = { 
	{count = 1, weight = 10},
	{count = 5, weight = 40}, 
	{count = 10, weight = 70}
}

local lockedRoomThreshold = 0
local roomsSinceLastLocked = 0 

function calculateLockedRoomChance()
	-- Get the appropriate weight based on the number of rooms passed
	local lockedRoomWeight = 5 -- Default weight
	for _, room in ipairs(lockedRoomWeights) do
		if roomNumber >= room.count then
			lockedRoomWeight = room.weight
		end
	end

	-- If we've passed the threshold, guarantee a locked room
	if roomsSinceLastLocked >= lockedRoomThreshold then
		return true
	end

	-- Otherwise, return a probability based on the weight
	local randomChance = math.random(1, 100)

	return randomChance <= lockedRoomWeight
end

-- for where the weights of rooms change over time (e.g., based on player actions, game progression, etc
--local threshold = 3

--function updateWeights()
--	for roomType, count in pairs(lastEncountered) do
--		if count >= threshold then
--			roomWeights[roomType] = roomWeights[roomType] + 1
--			lastEncountered[roomType] = 0 -- Reset the counter
--		else
--			lastEncountered[roomType] = count + 1 -- Increment the counter
--		end
--	end
--end

local furnitureTypes = {
	"drawer",
	"desk",
	"miniShelf",
}

local roomFurnitureCounts = {}

function spawnRandomFurnitureInRoom(room)
	roomFurnitureCounts[room.Name] = {}
	if room:FindFirstChild("furnSpawn") then
		for _, furnitureArea in pairs(room.furnSpawn:GetChildren()) do
			print(furnitureSpawn)
			local furnitureCountInArea = math.random(2, 5)

			for i = 1, furnitureCountInArea do
				local randomFurniture = furnitureTypes[math.random(1, #furnitureTypes)]
				local success = furnitureSpawn.spawnFurniture(room, randomFurniture, furnitureArea)
				furnitureArea.Transparency = 1

				if success then
					-- Track how many of this type of furniture was placed in this room
					if not roomFurnitureCounts[room.Name][randomFurniture] then
						roomFurnitureCounts[room.Name][randomFurniture] = 0
					end
					roomFurnitureCounts[room.Name][randomFurniture] += 1
				else
					--print("Failed to spawn furniture: " .. randomFurniture)
				end
			end
		end
	end

	-- Return the table tracking the furniture counts in this room
	return roomFurnitureCounts[room.Name]
end

function selectRoomType()
	local totalWeight = 0
	for _, category in pairs(roomInfo) do
		for _, room in pairs(category) do
			totalWeight = totalWeight + room.weight
		end
	end
	
	local rand = math.random(1, totalWeight)

	local cumulativeWeight = 0
	for categoryName, category in pairs(roomInfo) do
		for roomName, room in pairs(category) do
			cumulativeWeight = cumulativeWeight + room.weight
			--print("rand:", rand, "cumulativeWeight:", cumulativeWeight, "roomType:", roomType)
			if rand <= cumulativeWeight then
				return categoryName, roomName -- Return the selected category and room
			end
		end
	end

	return nil
end

local i = 0
 
function module:createRoomByChunk(roomModel, targetCFrame)
	local newRoom	= Instance.new("Model")
	newRoom.Parent = workspace
	newRoom.Name = i
	
	
	local chunks = roomModel:GetChildren()
	local chunkpart	= 0

	for i=1,#chunks do
		chunkpart=chunkpart+1
		if chunkpart%100==0 then
			wait(0.75)
		end
		if chunks[i]:IsA("Model") then
			local pt=chunks[i]:GetChildren()
			for x=1,#pt do
				chunkpart=chunkpart+1
				if chunkpart%50==0 then
					wait(0.95)
				end
			end
		end
		chunks[i]:Clone().Parent = newRoom
	end
	
	newRoom.PrimaryPart = newRoom:FindFirstChild("in1")

	newRoom:PivotTo(targetCFrame)
	newRoom.in1.Transparency = 1
	newRoom.out1.Transparency = 1
	
	if newRoom:FindFirstChild("nodes") then
		local nodes = newRoom.nodes 
		nodes.Name = i
		nodes.Parent = workspace.Nodes
	end
	
	table.insert(self.Rooms, newRoom)
	i+= 1
	
	return newRoom
end

function module:instantCreateRoom(roomModel, targetCFrame)
	local newRoom = roomModel:Clone()
	newRoom.Name = i

	newRoom:PivotTo(targetCFrame)
	newRoom.in1.Transparency = 1
	newRoom.out1.Transparency = 1

	newRoom.Parent = workspace
	
	if newRoom:FindFirstChild("nodes") then		
		local nodes = newRoom.nodes 
		nodes.Name = i
		nodes.Parent = workspace.Nodes
	end
	

	table.insert(self.Rooms, newRoom)
	i+= 1

	return newRoom
end

local function pickRoomName(rooms)
	local roomNames = {}

	for roomName, _ in pairs(rooms) do
		table.insert(roomNames, roomName)
	end

	if #roomNames > 0 then
		local randomRoomName = roomNames[math.random(1, #roomNames)]
		return script[randomRoomName] 
	end
end

local previousRoom = module:instantCreateRoom(script.SpawnRoom, CFrame.new(0,0,0))
local furnitureCount = spawnRandomFurnitureInRoom(previousRoom)	
print(previousRoom.Name, furnitureCount)

local lastDirection = nil

function module:GenerateRooms(bypass)
	--updateWeights()
	local roomType = selectRoomType() 

	local direction = nil
	if roomType == "L" then -- also applies to T or cross shape
		direction = "L"
		if lastDirection == "L" then
			roomType = "R"
			direction = "R"
		end
	elseif roomType == "R" then -- also applies to T or cross shape
		direction = "R"
		if lastDirection == "R" then
			roomType = "L"
			direction = "L"
		end
	else
		direction = "S"
	end
	
	local targetCFrame = previousRoom.out1.CFrame	
	if previousRoom:FindFirstChild("out1") and previousRoom:FindFirstChild("out2") then
		local chance = math.random(1, 2) 
		if chance == 2 then
			--previousRoom.out1.Name = "out2"
			--previousRoom.out2.Name = "out1"
			targetCFrame = previousRoom.out2.CFrame
			direction = "S"
		end
	end

	local roomModel = pickRoomName(roomInfo[direction])
	
	local newRoom 
	if bypass then
		newRoom = self:instantCreateRoom(roomModel, targetCFrame)
	else
		newRoom = self:createRoomByChunk(roomModel, targetCFrame)
	end
	
	local furnitureCount = spawnRandomFurnitureInRoom(newRoom)	
	print(newRoom.Name, furnitureCount)
	
	local locked = calculateLockedRoomChance()
	if locked then 
		local furnitureToPlaceItem = previousRoom:FindFirstChild("Furnitures")
		print(furnitureToPlaceItem)

		if furnitureToPlaceItem then
			local itemPlaced = itemModule:spawnItemInFurniture(furnitureToPlaceItem)
			if itemPlaced then
				print("Item placed inside " .. furnitureToPlaceItem.Name)
			else
				print("No suitable furniture found to place the item.")
			end
		end
		
		roomsSinceLastLocked = 0
	else
		roomsSinceLastLocked += 1
	end
	
	local door = doorModule.new(newRoom, locked)
	door.Parent = newRoom
	
	previousRoom = newRoom
	if direction == "L" or direction == "R" then
		lastDirection = direction
	end
end

function module.getRooms()
	return module.Rooms
end

local monsterLevels = {
	{level = 1, weight = 50}, -- Level 1: Base weight 50%
	{level = 2, weight = 30}, -- Level 2: Base weight 30%
	{level = 3, weight = 15}, -- Level 3: Base weight 15%
	{level = 4, weight = 5}   -- Level 4: Base weight 5%
}


local function calculateSpawnChance()
	local adjustedChance = baseSpawnChance + (monsterRoomCount / roomThreshold) * (maxSpawnChance - baseSpawnChance)
	return math.min(adjustedChance, maxSpawnChance)
end

function adjustMonsterLevelWeights()
	local totalWeight = 0
	
	for _, monster in ipairs(monsterLevels) do
		-- Increase weight for higher levels as player progresses
		if monsterRoomCount > 15 then
			if monster.level == 4 then
				monster.weight = monster.weight + 10 -- higher level appears more often
			elseif monster.level == 3 then
				monster.weight = monster.weight + 5
			end
		elseif monsterRoomCount > 10 then
			if monster.level == 3 then
				monster.weight = monster.weight + 5
			elseif monster.level == 2 then
				monster.weight = monster.weight + 3
			end
		end
		totalWeight = totalWeight + monster.weight
	end
	return totalWeight
end



local function updateGameConfig(configType)
	if configType == "roomCount" then
		roomNumber += 1
		monsterRoomCount += 1
		
		--also make sure there is already a rush, make sure not to spawn another
		
		--everytime a door opens, chance spawning enemy		
		local spawnChance = 100 --calculateSpawnChance()
		local randomChance = 0 --math.random(1, 100)

		if randomChance <= spawnChance then			
			print(roomNumber)
			local nodeNum = math.max(1, roomNumber)--- math.random(1, 2)
						
			monsterModule:SpawnMonster(nodes[nodeNum], roomNumber + 1, workspace.Nodes)
			
			monsterRoomCount = 0
		end
	end 
	print(roomNumber)
end


network:create("updateGameConfig", "BindableEvent", "Event", updateGameConfig)


return module

