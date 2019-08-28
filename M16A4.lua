local data = {}

data.name = script.Name
data.desc = "The classic M16A4 is a very versatile assault rifle that is usable in almost every situation."

data.type = "primary"

data.attachments = {
	"Reflex Sight",
	"EOTech Holographic",
	"ACOG",
	"Vertical Foregrip",
	"Laser Sight"
}

data.loot = {}
data.loot.level = 3
data.loot.rarity = 0.4

data.preview = {}
data.preview.forward = 4
data.preview.side = 0

data.model = {}
data.model.worldmodel = data.name
data.model.name = data.name
data.model.muzzle = "Muzzle"
data.model.adornee = "Muzzle"
data.model.main = "Main"
data.model.aim1 = "Aim1"
data.model.aim2 = "Aim2"
data.model.ironsight = {"HandleBolts", "Handle", "HandleBack", "FrontIronsight"}

data.shoot = {}
data.shoot.ammo = 30
data.shoot.rate = 700 / 60
data.shoot.dist = 2000
data.shoot.recoil = {}
data.shoot.recoil.x = 1.25
data.shoot.recoil.y = {1.1, 1.6}
data.shoot.firemode = {"auto", "single"}
data.shoot.reloadtime = 2.2
data.shoot.velocity = 860--m/s
data.shoot.spread = {}
data.shoot.spread.moving = 0.75
data.shoot.spread.hipfire = 2

data.shoot.dmg = {}
data.shoot.dmg.base = 26
data.shoot.dmg.head = 1.6
data.shoot.dmg.limb = 0.7

data.char = {}

data.view = {}
data.view.recoil = 2.5
data.view.bob = 1.4
data.view.sway = 1
data.view.fix = CFrame.Angles(0, -math.pi / 2, 0)
data.view.origin = CFrame.new(-2.2, -1, -1)
data.view.sprintorigin = CFrame.new(-1.75, -1.3, 0.5) * CFrame.Angles(0, math.rad(62), 0) * CFrame.Angles(math.rad(5), 0, math.rad(10))
data.view.aimorigin = 1
data.view.aimfov = 1.2

data.view.anim = {}
--[[data.view.anim.inspect = {
	{t = 0.75, p = CFrame.new(-0.5, 0, 0) * CFrame.Angles(0, math.rad(25), 0) * CFrame.Angles(0, 0, math.rad(-25)), o = {
		LeftHand = CFrame.new(0.5, -0.75, -0.1)
	}},
	{d = 2, t = 0.75, p = CFrame.new(-1.5, 0, -0.5) * CFrame.Angles(0, math.rad(-40), 0) * CFrame.Angles(math.rad(-10), 0, math.rad(25)), o = {
		RightHand = CFrame.new(0, -1.5, -2) * CFrame.Angles(math.rad(-15), 0, 0)
	}},
	{d = 4, t = 0.75, p = CFrame.new(), o = {}}
}]]

--[[
	keyframe properties:
	t = total time for keyframe to complete = 1.3
	d = delay from beginning = 0.5
	p = MAIN BODY OFFSET = CFrame.new()
	o = key/value list of INDIVIDUAL PART OFFSETS = {LeftHand = CFrame.new()}
	s = sound to play from muzzle = "Fire"
	sd = sound delay = 0.5
	bezier = 4-number array of a bezier curve from cubic-bezier.com = {.36, 0, .26, 1.12}
	trans = list of 1-string 1-number arrays, sets transparency of any object = {{"Mag", 1}}
	clone = list of 2-string arrays, one is cloned from object and one is new name = {{"Mag", "ClonedMag"}}
	unanchor = list of strings or arrays with string and vector for velocity, MUST BE CLONED OBJECT NAME = "ClonedMag" or {"ClonedMag", Vector3.new(0, 1, 0)}
	destroy = list of strings, MUST BE CLONED OBJECT NAME = {"ClonedMag"}
--]]

--[[data.view.anim.reload = {
	{t = 0.5, p = CFrame.new(0, 0.5, -1) * CFrame.Angles(0, 0, math.rad(38)), clone = {{"Mag", "ClonedMag"}}, trans = {{"Mag", 1}}, o = {
		LeftHand = CFrame.new(1.5, -3, 1),
		WMLeftHand = CFrame.new(1.5, -1, 1)
	}},
	{t = 0.2, p = CFrame.new(0, 0.3, -1.2) * CFrame.Angles(0, math.rad(15), math.rad(-45)), pow = 0.5, unanchor = {{"ClonedMag", Vector3.new(0, 0, 10), Vector3.new(-15, 0, 0), 0.02}}, s = "MagOut", o = {
		LeftHand = CFrame.new(1, -3, -0.5),
		WMLeftHand = CFrame.new(1, -1, -0.5),
		Mag = CFrame.new(1, -2, 0)
	}},
	{t = 0.3, p = CFrame.new(0, 0.1, -1.4) * CFrame.Angles(0, math.rad(20), math.rad(-35)), trans = {{"Mag", 0}}, o = {
		LeftHand = CFrame.new(1, -3, -0.5),
		WMLeftHand = CFrame.new(1, -1, -0.5),
		Mag = CFrame.new(1, -2, 0)
	}},
	{t = 0.6, p = CFrame.new(0, 0.2, -0.8) * CFrame.Angles(0, math.rad(10), math.rad(-30)), o = {
		LeftHand = CFrame.new(0.3, 0, -0.5)
	}},
	{t = 0.4, p = CFrame.new(), s = "MagIn", destroy = {"ClonedMag"}, o = {}}
}]]

-- reeload
data.view.anim.reload = {
	{t = 0.3, p = CFrame.new(0.0362271, 0.4375562, 0.0240881) * CFrame.Angles(0.0679073, 0.0633604, 0.7030226), s = "MagOut", sd = 0.25, clone = {{"Mag", "CM"}}, trans = {{"Mag", 1}}, bezier = {.6, .17, .72, .96}, o = { -- to RIGHT
		LeftHand = CFrame.new(0.9683656, -2.0500002, -0.2058328) * CFrame.Angles(0.0787772, 0.0151276, 0.3792602)
	}},
	{t = 0.15, p = CFrame.new(0.1666034, 0.2490882, -0.0047939) * CFrame.Angles(0.0679073, 0.0633604, -0.6285329), bezier = {.36, .24, .32, .99}, unanchor = {{"CM", Vector3.new(0, 0, 12.5), Vector3.new(-15, 0, 0), 0.04}}, o = { -- to LEFT
		LeftHand = CFrame.new(0.9683656, -2.0500002, -0.2058328) * CFrame.Angles(0.0787772, 0.0151276, 0.3792602)
	}},
	{d = 0.15, t = 0.35, p = CFrame.new(0.2897241, 0.0695543, -0.0133169) * CFrame.Angles(-0.0040002, 0.0676125, -0.2841353), o = { -- recovering
		LeftHand = CFrame.new(0.4025046, -2.9100037, -0.126449) * CFrame.Angles(-0.1076393, -0.2992969, -0.0318496),
		Mag = CFrame.new(0.5694036, -2.1250442, -2e-07) * CFrame.Angles(0, 0, 0)
	}},
	{d = 0.1, t = 0.5, p = CFrame.new(-0.0200869, 0.1438255, -0.0149439) * CFrame.Angles(0.0173551, 0.1221565, -0.1414794), bezier = {.6, .23, .3, 1}, trans = {{"Mag", 0}}, o = { -- recovering
		LeftHand = CFrame.new(0.4025046, -1, -0.126449) * CFrame.Angles(-0.1076393, -0.2992969, -0.0318496),
		Mag = CFrame.new(0.0155292, -0.25, -2e-07) * CFrame.Angles(-1e-07, 0, 0)
	}},
	{d = 0.075, t = 0.12, p = CFrame.new(0.0699131, 0.2307376, 0.0336329) * CFrame.Angles(0.3278983, 0.1221567, -0.1414792), bezier = {.5, .1, .75, 1}, s = "MagIn", o = { -- popping in
		LeftHand = CFrame.new(0.4025046, -0.7099963, -0.126449) * CFrame.Angles(-0.1076393, -0.2992969, -0.0318496)
	}},
	{d = 0.12, t = 0.5, p = CFrame.new(), destroy = {"ClonedMag"}, o = {}}
}

local function angle(x, y, z)
	return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
end

data.view.anim.inspect = {
	{t = 1.1, p = CFrame.new(-0.6, 0.3, -1) * CFrame.Angles(math.rad(28.8), math.rad(61.5), math.rad(-29.3)), bezier = {.36, 0, .26, 1.12}, o = {
		LeftHand = CFrame.new(-0.288, 0.056, -0.585) * CFrame.Angles(math.rad(-14.6), math.rad(-61.6), math.rad(-27)),
		RightHand = CFrame.new(0.857, 0.08, 0.417) * CFrame.Angles(math.rad(37.03), math.rad(-70.86), math.rad(23))
	}},
	{d = 3.5, t = 1.5, p = CFrame.new(-0.651, 0.11, -0.804) * angle(26.838, -56.472, 45.017), bezier = {.36, 0, .53, 1}, o = {
		LeftHand = CFrame.new(-0.058, -0.055, -0.175) * angle(0, -12.8, 0),
		RightHand = CFrame.new(0.897, -0.01, 0.19) * angle(0, 24, 0)
	}},
	{d = 2, t = 0.8, p = CFrame.new(), bezier = {.39, .08, .22, .99}, o = {}}
}

--data.view.anim.chamber = {
--	{t = 2, p = CFrame.new(), o = {
--		LeftHand = CFrame.new(1, 0.5, -0.2) * CFrame.Angles(math.rad(-25), math.rad(-26), math.rad(-17))
--	}},
--	{t = 2, p = CFrame.new(), o = {
--		LeftHand = CFrame.new(1.5, 0.5, -0.3) * CFrame.Angles(math.rad(-25), math.rad(-25), math.rad(-17)),
--		Bolt = CFrame.new(-0.5, 0, 0)
--	}}
--}

data.world = {}
data.world.origin = CFrame.new(-1.5, 0.75, -1.05)

return data