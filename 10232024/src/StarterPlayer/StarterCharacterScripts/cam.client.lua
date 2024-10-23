local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local modules = require(ReplicatedStorage.modules)
local network = modules.load("network")
local spring = modules.load("spring")

local crouchOffset = Vector3.new(0, -1.5, 0) 
local defaultOffset = Vector3.new(0, 0, -1.5) 

local camSpring = spring.spring.new(Vector3.new())
camSpring.s = 8
camSpring.d = 0.5

local targetOffset = defaultOffset

for _, v in pairs(char:GetChildren()) do
	if v:IsA("BasePart") and v.Name ~= "Head" then
		v:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
			v.LocalTransparencyModifier = v.Transparency
		end)
		v.LocalTransparencyModifier = v.Transparency
	end
end

RunService.RenderStepped:Connect(function()
	local ray = Ray.new(
		char.Head.Position, 
		(char.Head.CFrame.LookVector * 2).Unit
	)
	local ignoreList = char:GetChildren()
	local hit, pos = game.Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)

	local distanceOffset
	if hit then
		distanceOffset = Vector3.new(0, 0, -(char.Head.Position - pos).Magnitude)
	else
		distanceOffset = defaultOffset
	end

	local isCrouching = network:invoke("isCrouching")
	targetOffset = isCrouching and (crouchOffset + distanceOffset) or distanceOffset

	camSpring.t = targetOffset
	char.Humanoid.CameraOffset = camSpring.p
end)
