local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local camera = workspace.CurrentCamera

local localPlayer = Players.LocalPlayer
local character = workspace:WaitForChild(localPlayer.Name)
local humanoid = character.Humanoid
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local crouchAnim = humanoid:LoadAnimation(script:WaitForChild("crouch"))

local modules = require(ReplicatedStorage.modules)
local network = modules.load("network")
local spring = modules.load("spring")

local animationInterface = require(script.animationInterface)

local previousState = "idling"

local currentPlayingStateAnimation
characterEntityAnimationTracks = animationInterface:registerAnimationsForAnimationController(humanoid, "movementAnimations")

local defaultWalkSpeed = 16
local speedMultiplier = 1

local sprinting = false

local ignoreList 

local states = {}
states.crouching	= false
states.standing		= true

humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

local startSprintTime = 0
local isPlayerSprintingAnimationPlaying = false

local function onEntityStateChanged(state)
	local newState = state
	--if state == "walking" or state == "sprinting" or state == "crouching" then
	--	setCharacterMovementState("standing", false)
	--end

	if newState == "walking" then
		if states.crouching then
			return
		end
		local speed = humanoid.RootPart.Velocity.Magnitude
		if humanoid.MoveDirection.Magnitude > 0 then
			if speed >  0.5 and speed <= 20 then
				newState = "walking"
			elseif speed > 20 then
				newState = "sprinting"
			end
		else
			newState = "idling"
		end
	end

	if humanoid then
		if currentPlayingStateAnimation then
			if typeof(currentPlayingStateAnimation) == "Instance" then
				if currentPlayingStateAnimation.Looped or newState == "jumping" then
					currentPlayingStateAnimation:Stop()
				end
			elseif typeof(currentPlayingStateAnimation) == "table" then
				for ii, obj in pairs(currentPlayingStateAnimation) do
					if obj.Looped or newState == "jumping" then
						obj:Stop()
					end
				end
			end
			currentPlayingStateAnimation = nil
		end
	end

	if newState == "dead" then
		
	else
		if humanoid then

			local animationNameToLookFor = newState

			animationNameToLookFor = animationNameToLookFor

			if characterEntityAnimationTracks.movementAnimations[animationNameToLookFor] then
				currentPlayingStateAnimation = characterEntityAnimationTracks.movementAnimations[animationNameToLookFor]

				if currentPlayingStateAnimation then

					-- probably fix this.. i really hate that animations are two layered
					if typeof(currentPlayingStateAnimation) == "Instance" then
						-- ber edit mess with weights here
						if animationNameToLookFor == "walking" then
							currentPlayingStateAnimation:Play(nil, (currentPlayingStateAnimation.Priority == Enum.AnimationPriority.Movement and 0.85) or 1)
						else
							currentPlayingStateAnimation:Play(nil, 1)
						end

						if animationNameToLookFor == "jumping" then
							currentPlayingStateAnimation:AdjustSpeed(1.5)
						end
					elseif typeof(currentPlayingStateAnimation) == "table" then

						for ii, obj in pairs(currentPlayingStateAnimation) do
							obj:Play()

							if animationNameToLookFor == "jumping" then
								obj:AdjustSpeed(1.5)
							end
						end
					end
				end
			end

			previousState = animationNameToLookFor

			-- end it early
			return
		end
	end

	previousState = newState
end

local function startSprinting_animations(onlyStopAnimation)
	if isPlayerSprintingAnimationPlaying then return end

	--stop reload when sprinting??

	isPlayerSprintingAnimationPlaying = true
	--cxhange fov when sprinting

	startSprintTime = tick()
end

local function stopSprinting_animations()
	isPlayerSprintingAnimationPlaying = false
	--cahnge fov
end


-- this is all crappy bad code but you cant burn it all down because you need it so figure out how to
-- use it in a way that isnt crappy bad code thank you good luck have fun we're praying for your
-- safe return
function setCharacterMovementState(state, value, ...)
	if states[state] ~= nil and states[state] ~= value and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
		states[state] = value
		
		onEntityStateChanged(state)
		network:fire("characterStateChanged", state)

		return true
	end
end

local function standUp()
	if states.crouching then
		--TweenService:Create(
		--	humanoid,
		--	crouchTI,
		--	{CameraOffset = Vector3.new(0, 0, 0)}
		--):Play()
		
		crouchAnim:Stop()
		states.crouching = false
		
		setCharacterMovementState("standing", true)
		setCharacterMovementState("crouching", false)
	end
end


local function crouch()
	if states.crouching then
		standUp()
		return
	end
	setCharacterMovementState("crouching", not states.crouching)
	
	local moveDirection = humanoid.MoveDirection
	if 0.1 < moveDirection.magnitude then
		local suffMoment = false
		local hitPart, hitPoint, hitNormal = workspace:FindPartOnRayWithIgnoreList(Ray.new(humanoidRootPart.Position, Vector3.new(0, -12, 0)), ignoreList)

		if hitPart then
			if hitNormal.Y <= 0.99 then -- meaning the ground is slanted allow longer slide
				local dirVector = (hitNormal * Vector3.new(1, 0, 1)).Unit
				local magnitude = dirVector.Magnitude
				if 0 < magnitude then
					
					if -0.1 < dirVector:Dot(moveDirection) then
						suffMoment = true
					end
				end
			end
		end

		if states.sprinting ~= true then
			--if niot sprinting what happens
			
		elseif states.sprinting == true then
			setCharacterMovementState("crouching", false)
			return
		end
	end

	--Sprint(false)
	crouchAnim:Play()

	

	--TweenService:Create(
	--	humanoid,
	--	crouchTI,
	--	{CameraOffset = Vector3.new(0, -1.5, 0)}
	--):Play()

	while true do
		if states.crouching == false then
			break
		end
		
		if humanoid.MoveDirection.magnitude < 0.1 then
			crouchAnim:AdjustSpeed(0)
			--break
		else
			crouchAnim:AdjustSpeed(humanoid.WalkSpeed / 15.5)
		end	
		
		task.wait()
	end
end


local renderStepped_connection
local function onCharacterAdded(character)
	local startTime = tick()

	repeat wait() until character.PrimaryPart or character.Parent == nil or tick() - startTime >= 10

	character = workspace:WaitForChild(localPlayer.Name)
	humanoid = character.Humanoid
	humanoidRootPart = character.HumanoidRootPart
	
	--animationInterface = require(script.animationInterface)

	crouchAnim = humanoid:LoadAnimation(script.crouch)

	ignoreList = {character, camera, workspace.Terrain}
	
	previousState = "idling"

	local characterEntityAnimationTracks = animationInterface:registerAnimationsForAnimationController(humanoid, "movementAnimations")

	
	if not character.PrimaryPart then
		return false
	end
end

local walkspeedSpring = spring.spring.new(defaultWalkSpeed)
walkspeedSpring.s = 8

local backwardsMulti = 0.8
local function monitorWalkSpeed()
	if not states then return end
	if humanoid.Health <= 0 then return end


	local newState
	local speed = humanoid.RootPart.Velocity.Magnitude
	if states.crouching then
		
	elseif humanoid.MoveDirection.Magnitude > 0 then
		if speed >  0.5 and speed <= 20 then
			newState = "walking"
		elseif speed > 20 then
			newState = "sprinting"
		end
	else
		newState = "idling"
	end
	
	if newState ~= previousState then
		onEntityStateChanged(newState)
		previousState = newState
	end

	--speedMultiplier
	if states.crouching then
		walkspeedSpring.t = speedMultiplier * defaultWalkSpeed * 0.5
	else	
		walkspeedSpring.t = speedMultiplier *  defaultWalkSpeed
	end
	
	local relv = CFrame.new().VectorToObjectSpace(humanoidRootPart.CFrame, humanoidRootPart.Velocity)
	humanoid.WalkSpeed = (backwardsMulti + (1 - backwardsMulti)*(1  -relv.unit.z) / 2) * walkspeedSpring.p
end

local function onStateUpdated(state, value)
	if state == "walking" then
		walkspeedSpring.t = speedMultiplier *  defaultWalkSpeed
	elseif state == "crouching" then
		walkspeedSpring.t = speedMultiplier * defaultWalkSpeed * 0.5
	end
end

local function onStateChanged(_, newState)
	if newState == Enum.HumanoidStateType.Jumping then
		if states.crouching then
			standUp()
		end
		setCharacterMovementState("jumping", true)
	elseif newState == Enum.HumanoidStateType.Running then
		setCharacterMovementState("walking", true)
	end
end

local function isCrouching()
	return states.crouching
end

local function main()
	if localPlayer.Character then
		onCharacterAdded(localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(onCharacterAdded)
	
	network:create("characterStateChanged", "BindableEvent")
	
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		
		if input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.Space then
			crouch()	
		end
	end)
	
	humanoid.StateChanged:Connect(onStateChanged)
	local connection = RunService.Stepped:Connect(monitorWalkSpeed)
	
	network:create("isCrouching", "BindableFunction", "OnInvoke", isCrouching)
end

main()

