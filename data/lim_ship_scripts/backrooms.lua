local lwl = mods.lightweight_lua
local lwui = mods.lightweight_user_interface

local SPOOKY_AUGMENT_NAME = "LS_LIMINAL_HORROR"
local STABILITY_THRESHOLD = 700
local EFFECT_DARKNESS = {noteThreshold=3}
local SPOOKY_EFFECTS = {EFFECT_DARKNESS}

local mInstalled = false
local mFavor = 0 --your reputation with the backrooms
local mNotesCompleted = 0

local mIgnorePause



--You found this in your hangar one day; it exerts the faintest tug on the fringes of your perception.  Ghost aren't real, but this thing might be actually haunted...

--The other part of this is that the doors map is kind of wrong.  The ship is big and empty, and some of the doors make you get lost in the void.


--Part of a mod to make a ship that drives you insane . This will sometimes make checks fail to appear . It will also sometimes make checks succeed when they should not.
--This chance is based on your reputation with _some_ faction.  General for now.
--A fog that comes over your rooms and makes them unclickable.  --clear UI buttons that nom click events.

--[[
Colored icon snippits you can find, and if you click your system rooms in the right order, it gives you a thing and unlocks a new level of madness, slenderman style.
Center of screen, large expanding vertical container with oob horiz containers rendering icons.
--]]

--todo make this scale with 1+ scaled note completion.
--scales from 0% at full stability to (base 10%) at 0 stability

local function isFavored()
    return (math.random() >= (.5 - mFavor))
end

--Used for preventing things from rendering 
local function forceCrash()
    local emptySet = {}
    local ohNo = emptySet[1]
end

-------------------------------------NOTE SYSTEM-------------------------------------------------
local function createNote(system)
    return {found=false, system=system}
end
local function createOrder(color, numbers)
    local order = {color=color}
    for _,number in numbers do
        table.insert(order, createNote(number))
    end
    return order
end
--local noteOrder = {createNote(1), createNote(1), createNote(1), createNote(1), color=todopurple}

--A button that when you hover it shows the notes you've found

local purpleOrder = createOrder(purple, {lwl.SYS_DOORS(), lwl.SYS_SENSORS(), lwl.SYS_TELEPORTER(), lwl.SYS_OXYGEN()})
local greenOrder = createOrder(purple, {lwl.SYS_ENGINES(), lwl.SYS_BATTERY(), lwl.SYS_PILOT(), lwl.SYS_SENSORS()})
local orangeOrder = createOrder(purple, {lwl.SYS_WEAPONS(), lwl.SYS_ENGINES(), lwl.SYS_SHIELDS(), lwl.SYS_PILOT()})
local goldOrder = createOrder(purple, {lwl.SYS_DOORS(), lwl.SYS_DOORS(), lwl.SYS_DOORS(), lwl.SYS_MEDBAY()})
local orderList = {}

--I guess these are text boxes colored so I can print the icons?  Actually idk if the icons are in text or like where they are.
local function noteVisibilityFunction()
    return getNote(item.order, item.note).found --and showNotesHovered()
end
-------------------------------------END NOTE SYSTEM-------------------------------------------------
-------------------------------------EVENT INSTABILITY-------------------------------------------------

local function shouldActivate()
    --if 700 or above, never activate.
    return math.random() >= (1 - (.1 * ((STABILITY_THRESHOLD - Hyperspace.playerVariables.stability) / STABILITY_THRESHOLD)))
end

--Makes choices appear and disappear at random
local function alterChoices(locationEvent)
    local choices = locationEvent:GetChoices()

    --lwl.dumpObject(choices[1])
    for choice in vter(choices) do
        local activated = shouldActivate()
        print("activated: ", activated)
        --print("printing ", choices[1])
        print("requirement: ", choice.text, choice.requirement.min_level, choice.requirement.max_level, choice.requirement.blue, choice.requirement.max_group)
        
        if (activated) then
            if (isFavored()) then --weal
                choice.requirement.min_level = 0
            else --woe
                choice.requirement.min_level = 9
            end
        end
        print("requirement: ", choice.text, choice.requirement.min_level, choice.requirement.max_level, choice.requirement.blue, choice.requirement.max_group)
    end
end

script.on_internal_event(Defines.InternalEvents.PRE_CREATE_CHOICEBOX, function(locationEvent)
        if not mInstalled then return end
        --this should go in its own file for exensibility
        print("pre event ", locationEvent.eventName)
        alterChoices(locationEvent)
    end)
-------------------------------------END EVENT INSTABILITY-------------------------------------------------
-------------------------------------NAME FLICKER-------------------------------------------------
--flickers crew names
--save all crew names
--set names to empty string
local savedCrewNames = {}

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if not mInstalled then return end
        
    end)
-------------------------------------END NAME FLICKER-------------------------------------------------
-------------------------------------INPUT SHENANIGANS-------------------------------------------------
local mKeyboardDistortion = .1
local mKeyboardTimer = 0
local KEYBOARD_CHECK_DURATION = 333 --ticks

---Handles keyboard gaslighting
script.on_internal_event(Defines.InternalEvents.ON_KEY_DOWN, function(Key)
    if not mInstalled then return end
    local shouldIgnore = false

    if mIgnorePause and (Key == 27 or Key == 19 or Key == KEY_SPACE) then
        shouldIgnore = true
    end

    if shouldIgnore then
        return Defines.Chain.PREEMPT
    else
        return Defines.Chain.CONTINUE
    end
end)

--Move one tick in one direction or the other, on .9 or 1, pause will be blocked.
local function tickKeyboardBlockage()
    if isFavored() then
        mKeyboardDistortion = math.max(0, mKeyboardDistortion - .1)
    else
        mKeyboardDistortion = math.min(1, mKeyboardDistortion + .1)
    end

    if mKeyboardDistortion >= .9 then
        mIgnorePause = true
    else
        mIgnorePause = false
    end
end

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if not mInstalled then return end
    mKeyboardTimer = mKeyboardTimer + (Hyperspace.FPS.SpeedFactor * 16 / 10)
    if (mKeyboardTimer > KEYBOARD_CHECK_DURATION) then
        tickKeyboardBlockage()
        mKeyboardTimer = 0
    end
end)
-------------------------------------END INPUT SHENANIGANS-------------------------------------------------

--Preventing rendering of certain layers, chosen at random.  A value counts up, and once it's high enough, has an increasing chance to trigger a semi-random duration effect.
--fairly high on the spooky list

-------------------------------------RENDER INTERRUPTION-------------------------------------------------

-- {index=n, ticksRemaining=n,}
local mRenderAnomalies = {}
local mRenderTimer = 0

local function anomalyDuration()
    return 1 + (math.random() * 90)
end

local mRenderEventList = {
    MAIN_MENU = true,
    LAYER_BACKGROUND = true,
    LAYER_FOREGROUND = true,
    SHIP = true,
    SHIP_MANAGER = true,
    SHIP_JUMP = true,
    SHIP_HULL = true,
    SHIP_ENGINES = true,
    SHIP_FLOOR = true,
    SHIP_BREACHES = true,
    SHIP_SPARKS = true,
    LAYER_ASTEROIDS = true,
    LAYER_PLAYER = true,
    LAYER_FRONT = true,
    SPACE_STATUS = true,
    TABBED_WINDOW = true,
    MOUSE_CONTROL = true,
    GUI_CONTAINER = true
}

local function registerRenderEvents(eventList)
    for name, _ in pairs(eventList) do
        script.on_render_event(Defines.RenderEvents[name], function(maybeShip)
            if not mRenderEventList[name] then
                return Defines.Chain.PREEMPT
            end
        end, function(maybeShip)
        end)
    end
end

local function triggerDistortionEffect()
    --
end

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if not mInstalled then return end
    local minimumRenderGap = Hyperspace.playerVariables.stability * 2

    mRenderTimer = mRenderTimer + (Hyperspace.FPS.SpeedFactor * 16 / 10)
    if (mRenderTimer > KEYBOARD_CHECK_DURATION) then
        triggerDistortionEffect()
        mRenderTimer = 0
    end

    for _,anomaly in ipairs(mRenderAnomalies) do
        --tick down and reset when done.
    end
    lwl.arrayRemove(mRenderAnomalies, nil, nil)

end)
-------------------------------------END RENDER INTERRUPTION-------------------------------------------------


--rearranges door rooms
--remember to save the master list of doors in case of fallback

local DARKNESS = 0 --literal screen darkness
local twilight = 0 --higher is more likely to start darkness

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if not mInstalled then return end
        --render black rect of size SCREEN_SIZE, alpha DARKNESS
        
    end)




--slowly darken the screen over time when no mouse movement occurs.  Stock type function determines if this is can start triggering.










script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(ship)
    if not mInstalled and ship:HasAugmentation(SPOOKY_AUGMENT_NAME) ~= 0 and ship.iShipId == 0 then -- ship has aug, and is player ship
        mInstalled = true
        registerRenderEvents(mRenderEventList)
    end
end)




















