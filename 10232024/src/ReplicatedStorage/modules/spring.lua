local physics = {}

do
	local sort = table.sort
	local atan2 = math.atan2
	local inf = math.huge
	local cos = math.cos
	local sin = math.sin
	local setmetatable = setmetatable
	local tick = tick
	local dot = Vector3.new().Dot
	physics.spring = {}
	do
		local spring = {}
		physics.spring = spring
		local tick = tick
		local setmt = setmetatable
		local cos = math.cos
		local sin = math.sin
		local e = 2.718281828459045
		function spring.new(init)
			local null = 0 * (init or 0)
			local d = 1
			local s = 1
			local p0 = init or null
			local v0 = null
			local p1 = init or null
			local t0 = tick()
			local h = 0
			local c1 = null
			local c2 = null
			local self = {}
			local meta = {}
			local function updateconstants()
				if s == 0 then
					h = 0
					c1 = null
					c2 = null
				elseif d < 0.99999999 then
					h = (1 - d * d) ^ 0.5
					c1 = p0 - p1
					c2 = d / h * c1 + v0 / (h * s)
				elseif d < 1.00000001 then
					h = 0
					c1 = p0 - p1
					c2 = c1 + v0 / s
				else
					h = (d * d - 1) ^ 0.5
					local a = -v0 / (2 * s * h)
					local b = -(p1 - p0) / 2
					c1 = (1 - d / h) * b + a
					c2 = (1 + d / h) * b - a
				end
			end
			local function pos(x)
				if x < 0.001 then
					return p0
				end
				if s == 0 then
					return p0
				elseif d < 0.99999999 then
					local co = cos(h * s * x)
					local si = sin(h * s * x)
					local ex = e ^ (d * s * x)
					return co / ex * c1 + si / ex * c2 + p1
				elseif d < 1.00000001 then
					local ex = e ^ (s * x)
					return (c1 + s * x * c2) / ex + p1
				else
					local co = e ^ ((-d - h) * s * x)
					local si = e ^ ((-d + h) * s * x)
					return c1 * co + c2 * si + p1
				end
			end
			local function vel(x)
				if x < 0.001 then
					return v0
				end
				if s == 0 then
					return p0
				elseif d < 0.99999999 then
					local co = cos(h * s * x)
					local si = sin(h * s * x)
					local ex = e ^ (d * s * x)
					return s * (co * h - d * si) / ex * c2 - s * (co * d + h * si) / ex * c1
				elseif d < 1.00000001 then
					local ex = e ^ (s * x)
					return -s / ex * (c1 + (s * x - 1) * c2)
				else
					local co = e ^ ((-d - h) * s * x)
					local si = e ^ ((-d + h) * s * x)
					return si * (h - d) * s * c2 - co * (d + h) * s * c1
				end
			end
			local function posvel(x)
				if s == 0 then
					return p0
				elseif d < 0.99999999 then
					local co = cos(h * s * x)
					local si = sin(h * s * x)
					local ex = e ^ (d * s * x)
					return co / ex * c1 + si / ex * c2 + p1, s * (co * h - d * si) / ex * c2 - s * (co * d + h * si) / ex * c1
				elseif d < 1.00000001 then
					local ex = e ^ (s * x)
					return (c1 + s * x * c2) / ex + p1, -s / ex * (c1 + (s * x - 1) * c2)
				else
					local co = e ^ ((-d - h) * s * x)
					local si = e ^ ((-d + h) * s * x)
					return c1 * co + c2 * si + p1, si * (h - d) * s * c2 - co * (d + h) * s * c1
				end
			end
			updateconstants()
			function self.getpv()
				return posvel(tick() - t0)
			end
			function self.setpv(p, v)
				local time = tick()
				p0, v0 = p, v
				t0 = time
				updateconstants()
			end
			function self:accelerate(a)
				local time = tick()
				local p, v = posvel(time - t0)
				p0, v0 = p, v + a
				t0 = time
				updateconstants()
			end
			function meta:__index(index)
				local time = tick()
				if index == "p" then
					return pos(time - t0)
				elseif index == "v" then
					return vel(time - t0)
				elseif index == "t" then
					return p1
				elseif index == "d" then
					return d
				elseif index == "s" then
					return s
				end
			end
			function meta:__newindex(index, value)
				local time = tick()
				if index == "p" then
					p0, v0 = value, vel(time - t0)
				elseif index == "v" then
					p0, v0 = pos(time - t0), value
				elseif index == "t" then
					p0, v0 = posvel(time - t0)
					p1 = value
				elseif index == "d" then
					if value == nil then
						warn("nil value for d")
						warn(debug.stacktrace())
						value = d
					end
					p0, v0 = posvel(time - t0)
					d = value
				elseif index == "s" then
					if value == nil then
						warn("nil value for s")
						warn(debug.stacktrace())
						value = s
					end
					p0, v0 = posvel(time - t0)
					s = value
				elseif index == "a" then
					local p, v = posvel(time - t0)
					p0, v0 = p, v + value
				end
				t0 = time
				updateconstants()
			end
			return setmt(self, meta)
		end
	end
	local err = 1.0E-10
	local function solve(a, b, c, d, e)
		if not a then
			return
		end

		local function cubic_root(x)
			if x >= 0 then
				return math.pow(x, 1/3)
			else
				return -math.pow(-x, 1/3)
			end
		end

		local err = 1.0E-10
		local k = -b / (3 * a)
		local p = (3 * a * c - b * b) / (9 * a * a)
		local q = (2 * b * b * b - 9 * a * b * c + 27 * a * a * d) / (54 * a * a * a)
		local r = p * p * p + q * q

		if r <= err then
			if r >= -err then
				return k - cubic_root(q), k - cubic_root(q), k - cubic_root(q)
			end
			local theta = math.acos(q / math.sqrt(-p * p * p)) / 3
			local m = 2 * math.sqrt(-p)
			return k - m * math.cos(theta), k - m * math.cos(theta + 2 * math.pi / 3), k - m * math.cos(theta - 2 * math.pi / 3)
		else
			local s = math.sqrt(r)
			local u = cubic_root(-q + s)
			local v = cubic_root(-q - s)
			return k + u + v
		end
	end
	physics.solve = solve
	local minpos = function(a, b, c, d)
		if a and a >= 0 then
			return a
		elseif b and b >= 0 then
			return b
		elseif c and c >= 0 then
			return c
		elseif d and d >= 0 then
			return d
		end
	end
	physics.minpos = minpos
	local function minposroot(a, b, c, d, e)
		return minpos(solve(a, b, c, d, e))
	end
	physics.minposroot = minposroot
	function physics.cpoint_traj_point(v, a, r)
		local a0 = -2 * dot(r, v)
		local a1 = 2 * (dot(v, v) - dot(a, r))
		local a2 = 3 * dot(a, v)
		local a3 = dot(a, a)
		local t = minpos(solve(a3, a2, a1, a0))
		if t then
			return t, t * v + t * t / 2 * a
		end
	end
	function physics.simple_trajectory(s, a, r)
		local a0 = 4 * dot(r, r)
		local a1 = -4 * (dot(a, r) + s * s)
		local a2 = dot(a, a)
		local u = minpos(solve(a2, a1, a0))
		if u then
			local t = u ^ 0.5
			return r / t - t / 2 * a
		end
	end
	function physics.trajectory(pp, pv, pa, tp, tv, ta, s)
		local rp = tp - pp
		local rv = tv - pv
		local ra = ta - pa
		local t0, t1, t2, t3 = solve(dot(ra, ra) / 4, dot(ra, rv), dot(ra, rp) + dot(rv, rv) - s * s, 2 * dot(rp, rv), dot(rp, rp))
		if t0 and t0 > 0 then
			return ra * t0 / 2 + tv + rp / t0, t0
		elseif t1 and t1 > 0 then
			return ra * t1 / 2 + tv + rp / t1, t1
		elseif t2 and t2 > 0 then
			return ra * t2 / 2 + tv + rp / t2, t2
		elseif t3 and t3 > 0 then
			return ra * t3 / 2 + tv + rp / t3, t3
		end
	end
end

return physics