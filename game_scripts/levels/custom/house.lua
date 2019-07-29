local make_map = require 'common.make_map'
local map_maker = require 'dmlab.system.map_maker'
local maze_generation = require 'dmlab.system.maze_generation'
local pickups = require 'common.pickups'
local hit_goal_decorator = require 'custom.hit_goal_decorator'
local observe_goal_decorator = require 'custom.observe_goal_decorator'
local custom_observations = require 'decorators.custom_observations'
local pickups_spawn = require 'dmlab.system.pickups_spawn'
local game = require 'dmlab.system.game'
local timeout = require 'decorators.timeout'
local random = require 'common.random'
local houseTs = require 'custom.house_theme'
local themes = require 'themes.themes'
local tuple = require 'common.tuple'
local api = {}

local kwargs = {
  negativeGoalReward = -1.0,
  positiveGoalReward = 1.0,
  finalGoalReward = 1.0,
  entityPercentage = 0.7
}

local CELL_SIZE = 64.0
local CEILING_HEIGHT = 1.8
local MAP_ENTITIES = [[
*******
*P    *
*     *
*     *
*     *
*     *
*     *
*******
]]

local OBJECTS = {
  apple_reward = {
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
  elseif i == width - 2 then
    return 1
  elseif j == 1 then
    return 0
  elseif j == height - 2 then
    return 2
  end

  print('Error: invalid align i: '..i..' j:'..j..' width:'..width..' height:'..height)
  return 1
end

function getOrientationVector(orientation)
  if orientation == 3 then
    return {0, -1, 0}
  elseif orientation == 1 then
    return {0, 1, 0}
  elseif orientation == 0 then
    return {1, 0, 0}
  elseif orientation == 2 then
    return {-1, 0, 0}
  end
end

function api:_getPhysicalPosition(i, j, width)
  x = j + 0.5;
  y = ((width or self._maze_width) - i - 1) + 0.5;
  return { x * CELL_SIZE, y * CELL_SIZE }
end

function api:_generateEntitiesAndMaze()
  local maze = maze_generation.mazeGeneration{entity = MAP_ENTITIES}
  local width, height = maze:size()
  local currentEntities = {}

  local entityLocations = {{3,3}}
  local spawnLocations = {{2,2}}
  -- for i = 1, (width - 2) do
  --   for j = 1, (height - 2) do
  --     local isNearWall = i == 1 or i == (width - 2) or j == 1 or j == (height - 2)
  --     local isCorner = (i == 1 and j == 1) or (i == (width - 2) and j == (height - 2)) or
  --                     (i == 1 and j == (height - 2)) or (i == 1 and j == (height - 2))
  --     if not isCorner then
  --       if isNearWall then        
  --         entityLocations[#entityLocations + 1] = {i, j}
  --       elseif maze:getEntityCell(i, j) ~= "*" then
  --         spawnLocations[#spawnLocations + 1] = {i, j}
  --       end
  --     end
  --   end
  -- end
  local entityCount = 1
  -- local entityCount = random:uniformInt(math.max(1, 
  --   math.floor(kwargs.entityPercentage * #entityLocations  - 3)),
  --   math.min(#entityLocations, math.floor(kwargs.entityPercentage * #entityLocations  + 3)))
  local placeGenerator = random:shuffledIndexGenerator(#entityLocations)

  local finalGoalPos = entityLocations[placeGenerator()]
  local finalGoal = {
    gridPos = finalGoalPos,
    pos = self:_getPhysicalPosition(finalGoalPos[1], finalGoalPos[2], width),
    reward = kwargs.finalGoalReward,
    type = "apple_reward",
    orientation = self:_getEntityAlign(finalGoalPos[1], finalGoalPos[2], width, height),
    final = true
  }
  finalGoal.orientationVector = getOrientationVector(finalGoal.orientation)

  local entities = { finalGoal }
  local indexedEntities = {}
  indexedEntities[tuple(entities[#entities].gridPos[1], entities[#entities].gridPos[2])] = entities[#entities]  
  for i = 1,(entityCount - 1) do
    local pos = entityLocations[placeGenerator()]

    entities[#entities + 1] = {
      gridPos = pos,
      pos = self:_getPhysicalPosition(pos[1], pos[2], width),
      reward = kwargs.negativeGoalReward,
      type = "apple_reward",
      orientation = self:_getEntityAlign(pos[1], pos[2], width, height),
      final = false
    }

    indexedEntities[tuple(entities[#entities].gridPos[1], entities[#entities].gridPos[2])] = entities[#entities]
  end

  local i = placeGenerator()
  while i do
    spawnLocations[#spawnLocations + 1] = entityLocations[i]
    i = placeGenerator()
  end

  return {
    entities = entities,
    indexedEntities = indexedEntities,
    maze = maze,
    spawnLocations = spawnLocations,
  }
end

function api:init(params)
    make_map.seedRng(1)
    random:seed(4)
    local mapName = 'house_room'
    local theme = themes.fromTextureSet{
        textureSet = houseTs,
        decalFrequency = 0,
        floorModelFrequency = 0,
    }

    local entitiesResult = self:_generateEntitiesAndMaze()
    local width, height = entitiesResult.maze:size()
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
          local entity = entitiesResult.indexedEntities[tuple(i, j)]
          if entity then
            local object = OBJECTS[entity.type]
            local e= maker:makePhysicalEntity{
               i = i,
               j = j,
               width = object.width,
               height = CEILING_HEIGHT * 2 * 100.0/32.0,
               depth = object.depth,
               align = entity.orientation,
               classname = entity.type,
            }
            return e         
          end
        end
    }

    api:updateGoals(entitiesResult.entities)
    self._currentEntities = entitiesResult.entities
    self._allSpawnLocations = entitiesResult.spawnLocations
    self._maze_width = width
    api._map = mapName
end

function api:calculateBonus(goalId)
  return self._currentEntities[goalId].reward
end

function api:nextMap()
  local spawnLocation = api._allSpawnLocations[
                                 random:uniformInt(1, #api._allSpawnLocations)]
  spawnLocation = self:_getPhysicalPosition(spawnLocation[1], spawnLocation[2])
  self._newSpawnVarsPlayerStart = {
    classname = 'info_player_start',
    origin = '' .. spawnLocation[1] .. ' ' .. spawnLocation[2] .. ' 30',
    angle = '' .. (90 * random:uniformInt(0, 3))
  }

  return self._map
end


function api:updateSpawnVars(spawnVars)
  if spawnVars.classname == "info_player_start" then
    return self._newSpawnVarsPlayerStart
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
--custom_observations.decorate(api)
hit_goal_decorator(api, {
  cellSize = CELL_SIZE,
})
observe_goal_decorator(api, {
  cellSize = CELL_SIZE,
})

return api
