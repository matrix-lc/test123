local player = game.Players.LocalPlayer

local function createVelocityUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VelocityUI"
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "VelocityLabel"
	textLabel.Parent = screenGui
	textLabel.Size = UDim2.new(0.3, 0, 0.1, 0) 
	textLabel.Position = UDim2.new(0.35, 0, 0.05, 0) 
	textLabel.AnchorPoint = Vector2.new(0.5, 0) 
	textLabel.BackgroundTransparency = 0.5
	textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0) 
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255) 
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.TextScaled = true
	textLabel.Text = "Velocity: 0"

	return textLabel
end

player.CharacterAdded:Connect(function(character)
	local hrp = character:WaitForChild("HumanoidRootPart")
	local textLabel = createVelocityUI()

	game:GetService("RunService").RenderStepped:Connect(function()
		if hrp then
			local velocity = hrp.Velocity.Magnitude
			textLabel.Text = string.format("Velocity: %.2f", velocity)
		end
	end)
end)
