local Lighting = game:GetService("Lighting")


local dayDuration = 120 
local nightDuration = 60 

local totalCycleDuration = dayDuration + nightDuration

while true do
	for i = 0, dayDuration do
		Lighting.ClockTime = (i / dayDuration) * 12 
		wait(1)
	end

	for i = 0, nightDuration do
		Lighting.ClockTime = 12 + ((i / nightDuration) * 12) 
		wait(1) 
	end
end
