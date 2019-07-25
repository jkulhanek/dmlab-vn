local make_map = require 'common.make_map'
local map_maker = require 'dmlab.system.map_maker'
local maze_generation = require 'dmlab.system.maze_generation'
local pickups = require 'common.pickups'
local hit_goal_decorator = require 'custom.hit_goal_decorator'
local custom_observations = require 'decorators.custom_observations'
local pickups_spawn = require 'dmlab.system.pickups_spawn'
local game = require 'dmlab.system.game'
local timeout = require 'decorators.timeout'
local houseTs = require 'custom.house_theme'
local themes = require 'themes.themes'
local api = {}

local kwargs = {
  negativeGoalReward = -1.0,
  positiveGoalReward = 1.0
}

local CELL_SIZE = 64.0
local CEILING_HEIGHT = 1.8
local MAP_ENTITIES = [[
*******
*PA   *
*     *
*     *
*  A  *
*     *
*******
]]

local OBJECTS = {
    A = {
        name = 'apple_reward',
        width = CELL_SIZE * 0.7 / 32.0,
        depth = CELL_SIZE * 0.6 / 32.0,
    },
    G = {
        name = 'goal',
        width = 100.0 / 32.0,
        depth = 100.0 / 32.0,
    },
}

local PICKUPS = {
    apple_reward = {
        name = 'Apple',
        classname = 'apple_reward',
        model = 'models/apple.md3',
        quantity = 1,
        type = pickups.type.REWARD,
        moveType = pickups.moveType.STATIC
    }
}

function api:_getEntityAlign(i, j, width, height)
  if i == 1 then
    return 3
  elseif i == height - 2 then
    return 1
  elseif j == 1 then
    return 0
  elseif j == width - 2 then
    return 2
  end
end

function getPhysicalPosition(i, j, maze_height)
  x = j + 0.5;
  y = (maze_height - i - 1) + 0.5;
  return { x * CELL_SIZE, y * CELL_SIZE }
end

function api:init(params)
    make_map.seedRng(1)

    local mapName = 'house_room'
    local theme = themes.fromTextureSet{
        textureSet = houseTs,
        decalFrequency = 0,
        floorModelFrequency = 0,
    }

    local maze = maze_generation.mazeGeneration{entity = MAP_ENTITIES}
    local width, height = maze:size()
    local currentEntities = {}
    local goalRewards = {}
    local finalGoals = {}
    
    map_maker:mapFromTextLevel{
        entityLayer = MAP_ENTITIES,
        variationsLayer = nil,
        mapName = mapName,
        allowBots = false,
        skyboxTextureName = nil,
        theme = theme,
        cellSize = CELL_SIZE,
        ceilingScale = CEILING_HEIGHT,
        callback = function(i, j, c, maker)
          local pickup = OBJECTS[c]
          if pickup then
            currentEntities[#currentEntities + 1] = getPhysicalPosition(i, j, height)
            goalRewards[#goalRewards + 1] = kwargs.negativeGoalReward
            finalGoals[#goalRewards] = true
            return maker:makePhysicalEntity{
               i = i,
               j = j,
               width = pickup.width,
               height = CEILING_HEIGHT * 2 * 100.0/32.0,
               depth = pickup.depth,
               align = self:_getEntityAlign(i, j, width, height),
               classname = pickup.name,
            }
          end
        end
    }

    api:updateGoals(currentEntities, finalGoals)
    api._map = mapName
    self._goalRewards = goalRewards
end

function api:calculateBonus(goalId)
  return self._goalRewards[goalId]
end

function api:nextMap()
  return self._map
end

function api:updateSpawnVars(spawnVars)
  if spawnVars.classname == "info_player_start" then
    -- Spawn facing East.
    spawnVars.angle = "0"
    spawnVars.randomAngleRange = "0"
  end

  if PICKUPS[spawnVars.classname] then
    spawnVars.id = "1"
    spawnVars.spawnflags = "1"
  end

  if (PICKUPS[spawnVars.classname] and PICKUPS[spawnVars.classname:sub(0, -6)]) then
    -- is goal
    spawnVars.id = "2"
    spawnVars.spawnflags = "1"
  end
  return spawnVars
end

function api:canPickup(id, playerId)
    if id == 1 then
        return false
    end
    return true
end
  -- Create apple explicitly
  function api:createPickup(classname)
    if (classname:len() > 5 and PICKUPS[classname:sub(0, -6)]) then
        -- is goal
        local goalPickup = {}
        for key, value in pairs(PICKUPS[classname:sub(0, -6)]) do
            goalPickup[key] = value
        end
        
        --update goal pickup
        goalPickup.type = pickups.type.GOAL
        return goalPickup
    end
    return PICKUPS[classname]
  end



timeout.decorate(api, 60 * 60)
custom_observations.decorate(api)
hit_goal_decorator(api, {
  cellSize = CELL_SIZE
})

return api
