local bullet = {}

bullet.gravity = 9.8*4
bullet.slowdown = 0.2
bullet.position = Vector3.new()

bullet.velocity = Vector3.new()
bullet.fullvelocity = Vector3.new()

bullet.gravvelocity = Vector3.new()

bullet.lastposition = Vector3.new()
bullet.ignore = {}
bullet.life = 0
bullet.onhit = nil
bullet.hashit = false

function bullet.to_meters(studs)
	return studs / 5 * 2
end
function bullet.to_studs(meters)
	return meters / 2 * 5
end

function bullet:new(position, velocity, ignore, onhit)
	local this = {}
	setmetatable(this, {__index = bullet})
	this.position = position
	this.lastposition = position
	this.velocity = velocity
	this.fullvelocity = velocity
	this.ignore = ignore or {}
	this.onhit = onhit or function() end
	return this
end
function bullet:next(delta)
	self.lastposition = self.position
	self.velocity = self.fullvelocity + self.gravvelocity
	self.position = self.position + self.velocity * delta
	
	self.fullvelocity = self.fullvelocity * (1 - self.slowdown * delta)
	self.gravvelocity = self.gravvelocity + Vector3.new(0, -196.2 * delta, 0)
	
	local ray = Ray.new(self.lastposition, (self.position - self.lastposition).unit * (self.position - self.lastposition).magnitude)
	
	local worldmodels = {}
	for i,v in next, game:GetService("Players"):GetPlayers() do
		if v.Character ~= nil then
			for a,b in next, v.Character:GetChildren() do
				if b.Name:sub(1, 10) == "Worldmodel" then
					table.insert(worldmodels, b)
				end
			end
		end
	end
	
	local part, hit = workspace:FindPartOnRayWithIgnoreList(ray, {unpack(self.ignore), unpack(worldmodels)})
	if part ~= nil then
		self:hit(ray, part, hit)
	end
end
function bullet:hit(ray, part, position)
	self.hashit = true
	self.onhit(self, ray, part, position)
end



return bullet