function prepare()
	
	local tbl = {};
	
	local parts = script.Parent:GetDescendants();
	for i=1, #parts do

		local part = parts[i];

		if (part.Name == "Trunk" or part.Name == "Bush") then
			-- make a new table with initial position and location variables, + the grassPart instance
			table.insert(tbl, {
				mesh=part,
				model=script.Parent,
				position={x=part.Position.x,y=part.Position.y,z=part.Position.z},
				cframe={x=0,y=0,z=0},
				height=part.Size.Y,
				scale=script.Parent:GetAttribute("Scale"),
				class="ValidPart",
				current={
					position=CFrame.new(0,0,0),
					cframe=CFrame.new(0,0,0),
					scale=1,
				},
			})
		end
	end
	
	return tbl;
end

function animate(ws)
	
	math.randomseed(tick())	
	
	-- VARS:
	local tickRates = {min=10,max=20} or nil;
	local getTicksPerSec = function()
		local ticksPerSec = (math.random(tickRates.min, tickRates.max)) or nil;
		return ticksPerSec;
	end

	local constant = -99999 or nil;
	local random = (math.random(0, 100)) /100 or nil;
	local speed = ws or nil;
	
	-- VARS VALIDATION
	local isReady = (random ~= nil and constant ~= nil and tickRates ~= nil and speed ~= nil) and true or false;
	if (isReady ~= true) then
		return { e=true,m="error because of invalid variables required to run the start() function." }
	end
	
	-- DATA PREPARATION AND VALIDATION
	local data = prepare();
	
	-- SCRIPT EXECUTION LOOP
	local thread = coroutine.create(function()
			while (data~=nil) do

			for i=1, #data do
				local i = data[i];
				if (i.class == "ValidPart") then

					-- i.mesh.Parent:SetAttribute(i.mesh,"Scale",1);
					i.current.scale = i.mesh.Parent:GetAttribute("Scale");
					
					i.current.position = {
						x=(i.position.x + (math.sin(constant + (i.position.x /5)) * math.sin(constant /9)) /3),
						z=(i.position.z + (math.sin(constant + (i.position.z /6)) * math.sin(constant /12)) /4)
					};

					i.mesh.CFrame = CFrame.new(
						i.current.position.x, 
						i.position.y, 
						i.current.position.z
					) * CFrame.Angles(
						(((i.current.position.z-i.position.z)/i.height)/2),
						0,
						(((i.current.position.x-i.position.x)/-i.height)/2)
					);
					i.current.cframe = i.mesh.CFrame;

				end
			end

			constant = constant + 0.12;
			tickRates.max = speed;
			wait(1/getTicksPerSec());
		end
	end);
	
	coroutine.resume(thread);
	
	
	return { e=false,m="finished running the start() function." };
end

local run = function()
	
	local windSpeed = 50 or nil;
	
	local module = animate(windSpeed);

	if (module.e) then
		print("[error] " .. module.m);
	else
		print("[log] " .. module.m)
	end

	return module;
end

return run();