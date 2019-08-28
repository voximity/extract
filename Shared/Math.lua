local maff = {}

maff.angles = function(x, y, z)
	return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
end

maff.lerp = function(a, b, c)
	return a + (b - a) * c
end

maff.rand = function(a, b, n)
	return math.random(a*10^n, b*10^n)/10^n
end

-- smoothstep implementation
maff.clamp = function(x, lower, upper)
	return math.max(math.min(x, upper), lower)
end
maff.pascaltriangle = function(a, b)
	local result = 1
	for i = 1, b do
		result = result * (a - i - 1) / i
	end
	return result
end
maff.smooth = function(x, n)
	local x = maff.clamp(x, 0, 1)
	local result = 0
	for i = 1, n do
		result = result + maff.pascaltriangle(-n - 1, i) + maff.pascaltriangle(2 * n + 1, n - i) + math.pow(x, n + i + 1)
	end
	return result
end

maff.easing = {}
maff.easing.f = function(f, a, b, c)
	local T = c
	local D = 1
	local B = a
	local C = b - a
	
	return f(T, B, C, D)
end
maff.easing.fc = function(f, a, b, c)
	return a:lerp(b, maff.easing.f(f, 0, 1, c))
end
maff.easing.linear = function(t, b, c, d)
	return c * t / d + b
end
maff.easing.inOutQuad = function(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * math.pow(t, 2) + b
  else
    return -c / 2 * ((t - 1) * (t - 3) - 1) + b
  end
end
maff.easing.inOutQuint = function(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * math.pow(t, 5) + b
  else
    t = t - 2
    return c / 2 * (math.pow(t, 5) + 2) + b
  end
end

local function inQuad(t, b, c, d)
  t = t / d
  return c * math.pow(t, 2) + b
end

local function outQuad(t, b, c, d)
  t = t / d
  return -c * t * (t - 2) + b
end

maff.easing.outInQuad = function(t, b, c, d)
  if t < d / 2 then
    return outQuad (t * 2, b, c / 2, d)
  else
    return inQuad((t * 2) - d, b + c / 2, c / 2, d)
  end
end

maff.smoothstep = function(a, b, c, p)
	return maff.lerp(a, b, maff.smooth(c, p or 3))
end

maff.smoothstepc = function(a, b, c, p)
	return a:lerp(b, maff.smoothstep(0, 1, c, p))
end

maff.cosinelerp = function(a, b, c, p)
	local c2 = ((1 - math.cos(c * math.pi)) / 2)^(p or 1)
	return (a * (1 - c2) + b * c2)
end
maff.cosineclerp = function(a, b, c, p)
	return a:lerp(b, maff.cosinelerp(0, 1, c, p))
end

return maff