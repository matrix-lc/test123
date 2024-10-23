local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local modules = require(ReplicatedStorage:WaitForChild("modules"))
local network = modules.load("network")

local Angles = CFrame.Angles
local aSin = math.asin
local aTan = math.atan
local MseGuide = true
local TurnCharacterToMouse = false
local HeadHorFactor = 0.7
local HeadVertFactor = 0.7
local CharacterHorFactor = 0.7
local CharacterVertFactor = 0.7
local UpdateSpeed = 0.1

local updaters = {}

local playersMouseData = {}

local function tweenModel(model, info, CF)
	local CFrameValue = Instance.new("CFrameValue")
	CFrameValue.Value = model:GetPrimaryPartCFrame()

	CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
		model:PivotTo(CFrameValue.Value)
	end)

	local tween = TweenService:Create(CFrameValue, info, {Value = CF})
	tween:Play()

	tween.Completed:Wait()
	tween.Completed:Connect(function()
		CFrameValue:Destroy()
	end)
end

local function lookCursor()
	
end

local function openDrawer(drawer, dir)
	local targetCframe = drawer.PrimaryPart.CFrame * CFrame.new(1.5 * dir, 0, 0)
	local tweenInfo = TweenInfo.new(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)

	tweenModel(drawer, tweenInfo, targetCframe)	
	
	network:fireServer("playerRequest_openDrawer")
end


local function openDoor(leftDoor, rightDoor)
	local leftDoorOpenCFrame = leftDoor.CFrame * CFrame.new(3, 0, 0) 
	local rightDoorOpenCFrame = rightDoor.CFrame * CFrame.new(-3, 0, 0)

	local tweenInfo = TweenInfo.new(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)

	local leftDoorTween = TweenService:Create(leftDoor, tweenInfo, {CFrame = leftDoorOpenCFrame})
	local rightDoorTween = TweenService:Create(rightDoor, tweenInfo, {CFrame = rightDoorOpenCFrame})

	leftDoorTween:Play()
	rightDoorTween:Play()
end

local function loadplayer(player)
	local self = {}
	
	local Character = player.Character
	local Head = Character:WaitForChild("Head")
	local Humanoid = Character:WaitForChild("Humanoid")
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	local IsR6 = (Humanoid.RigType.Value==0)
	local Torso = (IsR6 and Character:WaitForChild("Torso")) or Character:WaitForChild("UpperTorso")
	local Neck = (IsR6 and Torso:WaitForChild("Neck")) or Head:WaitForChild("Neck")
	local Waist = (not IsR6 and Torso:WaitForChild("Waist"))

	local NeckOrgnC0 = Neck.C0
	local WaistOrgnC0 = (not IsR6 and Waist.C0)
	Neck.MaxVelocity = 1/3
	
	local function lookMouse(dt)
		local mouseHitPosition
		if player == localPlayer then
			mouseHitPosition = localPlayer:GetMouse().Hit.Position
		else
			mouseHitPosition = playersMouseData[player] or Vector3.new(0,0,0)
		end
		--local CameraCF = Camera.CoordinateFrame
		if ((IsR6 and Character["Torso"]) or Character["UpperTorso"])~=nil and Character["Head"]~=nil then
			local TorsoLV = Torso.CFrame.lookVector
			local HdPos = Head.CFrame.p
			if IsR6 and Neck or Neck and Waist then
				
				--if Camera.CameraSubject:IsDescendantOf(Character) or Camera.CameraSubject:IsDescendantOf(player) then
					local Dist = nil;
					local Diff = nil;
					if not MseGuide then
						--Dist = (Head.CFrame.p-CameraCF.p).magnitude
						--Diff = Head.CFrame.Y-CameraCF.Y
						--if not IsR6 then
						--	Neck.C0 = Neck.C0:lerp(NeckOrgnC0*Angles((aSin(Diff/Dist)*HeadVertFactor), -(((HdPos-CameraCF.p).Unit):Cross(TorsoLV)).Y*HeadHorFactor, 0), UpdateSpeed/2)
						--	Waist.C0 = Waist.C0:lerp(WaistOrgnC0*Angles((aSin(Diff/Dist)*CharacterVertFactor), -(((HdPos-CameraCF.p).Unit):Cross(TorsoLV)).Y*CharacterHorFactor, 0), UpdateSpeed/2)
						--else
						--	Neck.C0 = Neck.C0:lerp(NeckOrgnC0*Angles(-(aSin(Diff/Dist)*HeadVertFactor), 0, -(((HdPos-CameraCF.p).Unit):Cross(TorsoLV)).Y*HeadHorFactor),UpdateSpeed/2)
						--end
					else
						local Point = mouseHitPosition
						Dist = (Head.CFrame.p-Point).magnitude
						Diff = Head.CFrame.Y-Point.Y
						if not IsR6 then
							Neck.C0 = Neck.C0:lerp(NeckOrgnC0*Angles(-(aTan(Diff/Dist)*HeadVertFactor), (((HdPos-Point).Unit):Cross(TorsoLV)).Y*HeadHorFactor, 0), UpdateSpeed/2)
							Waist.C0 = Waist.C0:lerp(WaistOrgnC0*Angles(-(aTan(Diff/Dist)*CharacterVertFactor), (((HdPos-Point).Unit):Cross(TorsoLV)).Y*CharacterHorFactor, 0), UpdateSpeed/2)
						else
							Neck.C0 = Neck.C0:lerp(NeckOrgnC0*Angles((aTan(Diff/Dist)*HeadVertFactor), 0, (((HdPos-Point).Unit):Cross(TorsoLV)).Y*HeadHorFactor), UpdateSpeed/2)
						end
					end
				--end
			end
		end
		if TurnCharacterToMouse == true then
			Humanoid.AutoRotate = false
			HumanoidRootPart.CFrame = HumanoidRootPart.CFrame:lerp(CFrame.new(HumanoidRootPart.Position, Vector3.new(mouseHitPosition.x, HumanoidRootPart.Position.Y, mouseHitPosition.z)), UpdateSpeed / 2)
		else
			Humanoid.AutoRotate = true
		end
	end


	function self.step(dt)
		lookMouse(dt)
	end
	
	
	return self
end

local function getupdater(player)
	if player == nil then return end
	if updaters[player]==nil then
		updaters[player] = loadplayer(player)
		return updaters[player]	
	elseif updaters[player] ~= nil then
		return updaters[player]
	end
end

local function main()
	network:connect("playerRequest_openDrawer", "OnClientEvent", openDrawer)
	network:connect("playerRequest_openDoor", "OnClientEvent", openDoor)

	network:connect("updateMouseLocation", "OnClientEvent", function(player, mousePosData)
		if player == nil or mousePosData == nil then return end
		playersMouseData[player] = mousePosData
	end)
	
	RunService.RenderStepped:Connect(function()
		local players=game.Players:GetPlayers()
		for i=1,#players do
			local player=players[i]
			--if player~=Player then
			getupdater(player)
			--end
		end

		network:fireServer("updateMouseLocation", localPlayer:GetMouse().Hit.Position)
	end)
	
	RunService.RenderStepped:Connect(function(dt)
		for player,updater in next, updaters do
			if updater then
				updater.step(dt)
			end
		end
	end)
end

main()



return module
