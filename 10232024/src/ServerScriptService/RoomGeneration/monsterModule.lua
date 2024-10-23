local MonsterModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

MonsterModule.Monsters = {}
MonsterModule.Speed = 36
MonsterModule.KillRadius = 5
MonsterModule.NodesFolder = workspace.Nodes

local function moveTowards(target, monster, speed)
	local direction = (target.Position - monster.Position).unit
	monster.CFrame = CFrame.new(monster.Position, target.Position) * CFrame.new(0, 0, 0)
	monster.Position = monster.Position + direction * speed * RunService.Heartbeat:Wait()
end

local connection
local nodeLimit = math.huge

-- Function to spawn a new monster instance
function MonsterModule:SpawnMonster(startNode, limit)
	local monster = workspace.RushNew:Clone()
	monster.Parent = workspace.asd

	local monsterData = {
		Monster = monster,
		CurrentNode = startNode,
		SubNodesFolder = nil,
		CurrentSubNode = nil,
		NodeLimit = limit or nodeLimit
	}

	monster.Position = startNode.Position
	table.insert(self.Monsters, monsterData) 

	if not connection then
		connection = RunService.Heartbeat:Connect(function()
			self:Update()
		end)
	end
end

function MonsterModule:Update()
	for i, monsterData in ipairs(self.Monsters) do
		if not monsterData.Monster then
			table.remove(self.Monsters, i)
		else
			self:UpdateMonster(monsterData)
		end
	end

	if #self.Monsters == 0 then
		connection:Disconnect()
		connection = nil
	end
end

function MonsterModule:UpdateMonster(monsterData)
	for _, player in pairs(Players:GetPlayers()) do
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local distance = (monsterData.Monster.Position - character.HumanoidRootPart.Position).Magnitude
			if distance <= self.KillRadius then
				character.Humanoid:TakeDamage(character.Humanoid.MaxHealth)
			end
		end
	end

	if monsterData.CurrentSubNode then
		moveTowards(monsterData.CurrentSubNode, monsterData.Monster, self.Speed)
		if (monsterData.Monster.Position - monsterData.CurrentSubNode.Position).Magnitude < 2 then
			self:MoveToNextSubNode(monsterData)
		end
	elseif monsterData.CurrentNode then
		moveTowards(monsterData.CurrentNode, monsterData.Monster, self.Speed)
		if (monsterData.Monster.Position - monsterData.CurrentNode.Position).Magnitude < 2 then
			self:ArriveAtNode(monsterData)
		end
	end

	-- check if the monster has reached its node limit
	if monsterData.CurrentNode and tonumber(monsterData.CurrentNode.Name) > monsterData.NodeLimit then
		self:DestroyMonster(monsterData)
	end
end

function MonsterModule:DestroyMonster(monsterData)
	if not monsterData.Monster then return end

	monsterData.Monster:Destroy()
	monsterData.Monster = nil
end

function MonsterModule:MoveToNextSubNode(monsterData)
	local currentSubNodeIndex = tonumber(monsterData.CurrentSubNode.Name)
	local nextSubNode = monsterData.SubNodesFolder:FindFirstChild(tostring(currentSubNodeIndex + 1))

	if nextSubNode then
		monsterData.CurrentSubNode = nextSubNode
	else
		monsterData.CurrentSubNode = nil
		self:MoveToNextNode(monsterData)
	end
end

function MonsterModule:MoveToNextNode(monsterData)
	local currentNodeIndex = tonumber(monsterData.CurrentNode.Name)
	local nextNode = self.NodesFolder:FindFirstChild(tostring(currentNodeIndex + 1))

	if nextNode then
		monsterData.CurrentNode = nextNode
	else
		monsterData.CurrentNode = nil
	end
end

function MonsterModule:ArriveAtNode(monsterData)
	monsterData.SubNodesFolder = monsterData.CurrentNode
	monsterData.CurrentSubNode = monsterData.SubNodesFolder and monsterData.SubNodesFolder:FindFirstChild("1") or nil

	if not monsterData.CurrentSubNode then
		self:MoveToNextNode(monsterData)
	end
end

return MonsterModule
