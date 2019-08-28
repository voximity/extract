local c = {}

c.footsteps = {}
c.footsteps.concrete = {"StepConcrete1", "StepConcrete2", "StepConcrete3", "StepConcrete4"}
c.footsteps.grass = {"StepGrass1", "StepGrass2", "StepGrass3", "StepGrass4"}
c.footsteps.metal = {"StepMetal1", "StepMetal2", "StepMetal3", "StepMetal4"}
c.footsteps.wood = {"StepWood1", "StepWood2", "StepWood3", "StepWood4"}
c.footsteps.tile = {"StepTile1", "StepTile2", "StepTile3", "StepTile4"}

c.whiz = {"BulletWhiz1", "BulletWhiz2", "BulletWhiz3", "BulletWhiz4", "BulletWhiz5", "BulletWhiz6", "BulletWhiz7"}
c.whizmaxdistance = 5

c.footsteprate = 6

c.materials = {}
c.materials.Plastic = "tile"
c.materials.Neon = "concrete"
c.materials.WoodPlanks = "wood"
c.materials.Slate = "concrete"
c.materials.Granite = "concrete"
c.materials.Pebble = "concrete"
c.materials.CorrodedMetal = "metal"
c.materials.Foil = "metal"
c.materials.Grass = "grass"
c.materials.Fabric = "grass"
c.materials.SmoothPlastic = "tile"
c.materials.Wood = "wood"
c.materials.Marble = "tile"
c.materials.Concrete = "concrete"
c.materials.Brick = "concrete"
c.materials.Cobblestone = "concrete"
c.materials.DiamondPlate = "metal"
c.materials.Metal = "metal"
c.materials.Sand = "grass"
c.materials.Ice = "tile"

c.jumpdelay = 0.6

c.recoilrate = 3

c.trail = {}
c.trail.duration = 0.1
c.trail.color = BrickColor.new("Bright yellow")

c.ui = {}
c.ui.ammo = {}
c.ui.ammo.color = Color3.new(0.8, 0, 0)
c.ui.ammo.size = 48

c.ui.elim = {}
c.ui.elim.size = 18
c.ui.elim.color = Color3.new(1, 1, 1)
c.ui.elim.duration = 10

c.ui.feed = {}
c.ui.feed.size = 18

c.humanoid = {}
c.humanoid.crouch = 7
c.humanoid.aim = 6
c.humanoid.walk = 10
c.humanoid.sprint = 20
c.humanoid.jump = 15

c.fov = {}
c.fov.default = 80

return c