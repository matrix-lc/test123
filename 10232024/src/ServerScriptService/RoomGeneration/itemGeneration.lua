local itemModule = {}

-- list of possible items to spawn
local items = {
	"Key"
}

function itemModule:spawnItemInFurniture(furniture)
	local availableSlots = {}
	
	for _, drawer in ipairs(furniture:GetDescendants()) do
		if drawer.Name == "box" then
			table.insert(availableSlots, drawer)
		end
	end

	if #availableSlots > 0 then
		local selectedSlot = availableSlots[math.random(1, #availableSlots)]
		local randomItem = items[math.random(1, #items)]

		local item = script:FindFirstChild(randomItem).Handle:Clone()

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = item
		weld.Part1 = selectedSlot.PrimaryPart
	
		item.Name = randomItem
		item.Anchored = true
		item.CanCollide = false
		item.CFrame = selectedSlot.PrimaryPart.CFrame
		item.Parent = selectedSlot

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Take"
		prompt.ObjectText = randomItem
		prompt.RequiresLineOfSight = false
		prompt.Parent = item

		prompt.Triggered:Connect(function(player)
			-- make a more genralized item interaction 
			-- like module.itemInteract and depending on item 
			
			local key = script[item.Name]:Clone()
			
			key.Parent = player.Backpack
			prompt.Enabled = false
			item:Destroy()
		end)	
		
		return true
	else
		return false 
	end
end

return itemModule
