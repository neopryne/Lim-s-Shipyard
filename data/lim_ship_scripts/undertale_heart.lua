
local Brightness = mods.brightness
local lwl = mods.lightweight_lua
local lwk = mods.lightweight_keybinds
--[[

Ideas:
No shields, 100% evasion, 100% hull resist, but every projectile coming at you (triples).
10 (20?) health.  [General noteriety?] raises this by 1.

I think I do this by creating a fake projectile at the heart location that always tracks it.
The heart's default animation is flashing.
There's a period before it spawns another projectile for invulnerability.

--I should make an on_init block in lwl you can register for, since there's no good way to do that vanilla.
--
Light enough to find your way to where you're needed.

Tenacious enough that no wind can rip you away once you're there.
Would be fun if ion damage stuns you.
Make a blue heart icon and switch to that while stunned.
--todo asteroids have variable hitboxes, so I actually need to make this missile or something.

On create, destroy all other shots from PLACEHOLDER_HEART_GUN

Stuff is too boring in the early game, bombs do nothing, beams do a bit, 
I think I need to reroute all the shots to pass through the bounding box.  Draw a line to the center of it, then go out to a radius and choose
an angle that takes you through that point.

The ship looks way too plain, it's distracting during gameplay.
]]

local BOX_TOP_LEFT_X = 255
local BOX_TOP_LEFT_Y = 145
local BOX_WIDTH = 157
local BOX_HEIGHT = 130
local BOX_CENTER_X = BOX_TOP_LEFT_X + (BOX_WIDTH / 2)
local BOX_CENTER_Y = BOX_TOP_LEFT_Y + (BOX_HEIGHT / 2)
local BOX_BOTTOM_RIGHT_X = BOX_TOP_LEFT_X + BOX_WIDTH
local BOX_BOTTOM_RIGHT_Y = BOX_TOP_LEFT_Y + BOX_HEIGHT
local HEART_SPEED = 2
local HEART_IDENTIFIER = -4
local NUM_IFRAMES = 100
local HEART_SIZE = 24

local HEARTSHIP_BLUEPRINT = "PLAYER_SHIP_LIM_UNDERTALE"
local HEART_STRING = "lim_ship_stuff/heart.png"
local STUN_STRING = "lim_ship_stuff/heart_stun.png"
local HeartTexture = Hyperspace.Resources:GetImageId(HEART_STRING)
local HeartStunnedTexture = Hyperspace.Resources:GetImageId(STUN_STRING)

local mHeartsteroid
local mReUpTimer = 0
local mStunTime = 0
local mScaledLocalTime = 0
--imageId is a GL_Texture.
local mInitialized
local mHeartParticle

local function shouldActivate()
    local ownship = Hyperspace.ships(0)
    if not ownship then return end
    return ownship.myBlueprint.blueprintName == HEARTSHIP_BLUEPRINT
end

local function tearDown()
    if mInitialized then
        if mHeartParticle then
            Brightness.destroy_particle(mHeartParticle)
        end
        mInitialized = false
    end
end

local function createNewLife()
    local spaceManager = Hyperspace.App.world.space
    mHeartsteroid = spaceManager:CreateAsteroid(lwl.pointToPointf(mHeartParticle.position), 0, 0, lwl.pointToPointf(mHeartParticle.position), 0, 0)
    --todo change the animation.
    mHeartsteroid.speed_magnitude = HEART_IDENTIFIER
    mHeartsteroid.imageId = HeartTexture
    --mHeartsteroid.imageId = lwl.getAllMemberCrew(Hyperspace.ships(0))[1].crewAnim.anims:front():front().animationStrip
    mHeartsteroid:SetSpin(0)
    mReUpTimer = 0
    --print("mHeartsteroid speed", mHeartsteroid.speed_magnitude)
end


local function onTick()
    if not Hyperspace.ships(0) then return end
    if not mInitialized then
        --shipManager:AddAugmentation("FM_CRUCIBLE_PLATING_PLAYER")
        --You just give ROCK_ARMOR for flat hull resist.  SYSTEM_CASING for system resist, and ION_ARMOR for ion resist.  Fractional amounts.
        mHeartParticle = Brightness.create_particle("particles/ship_soul", 2, .3, Hyperspace.Point(BOX_CENTER_X, BOX_CENTER_Y), 0, 0, "SHIP_MANAGER")
        mHeartParticle.persists = true
        createNewLife()
        mInitialized = true
        --print("mInitialized!")
    end

    --Heart control code.
    local heartVerticalSpeed = 0
    local heartHorizSpeed = 0
    if not (mStunTime < 0) then --todo stun animation
        if lwk.isKeyPressed(Defines.SDL_KEY_LEFT) then heartHorizSpeed = heartHorizSpeed - HEART_SPEED end
        if lwk.isKeyPressed(Defines.SDL_KEY_RIGHT) then heartHorizSpeed = heartHorizSpeed + HEART_SPEED end
        if lwk.isKeyPressed(Defines.SDL_KEY_UP) then heartVerticalSpeed = heartVerticalSpeed - HEART_SPEED end
        if lwk.isKeyPressed(Defines.SDL_KEY_DOWN) then heartVerticalSpeed = heartVerticalSpeed + HEART_SPEED end
        local newX = mHeartParticle.position.x + heartHorizSpeed
        local newY = mHeartParticle.position.y + heartVerticalSpeed
        --print(heartHorizSpeed, heartVerticalSpeed)
        newX = math.max(BOX_TOP_LEFT_X + (HEART_SIZE / 2), math.min(BOX_BOTTOM_RIGHT_X - (HEART_SIZE / 2), newX))
        newY = math.max(BOX_TOP_LEFT_Y + (HEART_SIZE / 2), math.min(BOX_BOTTOM_RIGHT_Y - (HEART_SIZE / 2), newY))
        mHeartParticle.position = Hyperspace.Point(newX, newY)
    else
        mStunTime = mStunTime - 1
        if mStunTime == 0 then
            mHeartsteroid.imageId = HeartTexture
        end
    end
    if mHeartsteroid and not mHeartsteroid:Dead() then
        mHeartsteroid.position = lwl.pointToPointf(mHeartParticle.position)
    else
        mReUpTimer = mReUpTimer + 1
        --print("reup", mReUpTimer)
        if mReUpTimer > NUM_IFRAMES then
            createNewLife()
        end
    end
end




--todo this doesn't actually scale the time properly, more testing needed.
--We want the heart to show up in the hangar.
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if not shouldActivate() or Hyperspace.ships(0).iCustomizeMode == 2 then
        tearDown()
        return
    end
    if not lwl.isPaused() then
        mScaledLocalTime = mScaledLocalTime + (Hyperspace.FPS.SpeedFactor * 16) --todo pull this into a library.
        if (mScaledLocalTime > 1) then
            onTick()
            mScaledLocalTime = 0
        end
    end

    if mHeartParticle and mHeartsteroid then
        mHeartsteroid.position = lwl.pointToPointf(mHeartParticle.position)
        mHeartsteroid.angle = 0
    end
end)


print("undertale_heart loaded.")


script.on_internal_event(Defines.InternalEvents.PROJECTILE_COLLISION, function(this, other, damage, collisionResponse)
    if not shouldActivate() then return end
    --Hacky but works near 100% of the time.  check for doubles.
    print("Collision occured", mHeartsteroid, this.speed_magnitude, other.speed_magnitude)
    if not mHeartsteroid then return end
    if lwl.floatCompare(HEART_IDENTIFIER, this.speed_magnitude) then
        if (damage.iIonDamage > 0) then
            mStunTime = damage.iIonDamage * 30
            mHeartsteroid.imageId = HeartStunnedTexture
        end
        local ownship = Hyperspace.ships(0)
        damage.bFriendlyFire = true
        ownship:DamageHull(damage.iDamage, true)
        ownship:DamageSystem(lwl.getRandomSystem(ownship):GetId(), damage)
        mHeartsteroid = nil
    end
end)

script.on_internal_event(Defines.InternalEvents.GET_DODGE_FACTOR, function(ship, value)
    if ship.iShipId == 0 and shouldActivate() then
        return Defines.Chain.CONTINUE, 100
    end
    return Defines.Chain.CONTINUE, value
end)
 