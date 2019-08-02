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
  negativeGoalReward = -1,
  positiveGoalReward = 10,
  finalGoalReward = 10,
  entityPercentage = 0.7
}

local CELL_SIZE = 64.0
local CEILING_HEIGHT = 2.2
local MAP_ENTITIES = [[
*******
*C333P*
*0   2*
*0   2*
*0   2*
*0   2*
*C111C*
*******
]]

local OBJECTS = {
  meuble_chevet = {
    width = CELL_SIZE * 0.7 / 32.0,
    depth = CELL_SIZE * 0.6 / 32.0,
    probabilityFactor = 1.0,
  },
  chair = {
    width = CELL_SIZE * 0.9 / 32.0,
    depth = CELL_SIZE * 0.9 / 32.0,
    probabilityFactor = 1.0,
  },
  chair2 = {
    width = CELL_SIZE * 0.9 / 32.0,
    depth = CELL_SIZE * 0.9 / 32.0,
    probabilityFactor = 1.0,
  },
  shoe_cabinet = {
    width = CELL_SIZE * 0.7 / 32.0,
    depth = CELL_SIZE * 0.6 / 32.0,
    probabilityFactor = 1.0,
  },
  coat_stand = {
    width = CELL_SIZE * 0.4 / 32.0,
    depth = CELL_SIZE * 0.4 / 32.0,
    probabilityFactor = 1.0,
  },
  cartboard_box = {
    width = CELL_SIZE * 0.7 / 32.0,
    depth = CELL_SIZE * 0.6 / 32.0,
    probabilityFactor = 1.0,
  },
  black_bookcase = {
    width = CELL_SIZE * 0.7 / 32.0,
    depth = CELL_SIZE * 0.6 / 32.0,
    probabilityFactor = 1.0,
  },
}

local objectSampleProbabilities = {}
local totalPSum = 0.0
for key, val in pairs(OBJECTS) do
  local pfactor = val.probabilityFactor or 1.0
  totalPSum = totalPSum + pfactor
  objectSampleProbabilities[#objectSampleProbabilities + 1] = {pfactor, key}
end
for i=1,#objectSampleProbabilities do
  objectSampleProbabilities[i][1] = objectSampleProbabilities[i][1] / totalPSum
end

function sampleObject(randomValue)
  local totalValue = 0.0
  for i=1,#objectSampleProbabilities do
    totalValue = totalValue + objectSampleProbabilities[i][1]
    if randomValue <= totalValue then
      return objectSampleProbabilities[i][2]
    end
  end
end

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

  local entityLocations = {}
  local entityOrientations = {}
  local spawnLocations = {}

  for i = 1, (width - 2) do
    for j = 1, (height - 2) do
      local c = maze:getEntityCell(i + 1, j + 1)
      local orientation = tonumber(c)
      local isNearWall = orientation ~= nil
      local isCorner = c == "C" or c == "P"
      if not isCorner then
        if isNearWall then        
          entityLocations[#entityLocations + 1] = {i, j}
          entityOrientations[#entityLocations] = orientation
        elseif c ~= "*" then
          spawnLocations[#spawnLocations + 1] = {i, j}
        end
      end
    end
  end

  local entityCount = random:uniformInt(math.max(1, 
    math.floor(kwargs.entityPercentage * #entityLocations  - 3)),
    math.min(#entityLocations, math.floor(kwargs.entityPercentage * #entityLocations  + 3)))
  local placeGenerator = random:shuffledIndexGenerator(#entityLocations)

  local finalGoalIndex = placeGenerator()
  local finalGoalPos = entityLocations[finalGoalIndex]
  local finalGoal = {
    gridPos = finalGoalPos,
    pos = self:_getPhysicalPosition(finalGoalPos[1], finalGoalPos[2], width),
    reward = kwargs.finalGoalReward,
    type = sampleObject(random:uniformReal(0, 1)),
    orientation = entityOrientations[finalGoalIndex],
    final = true
  }
  finalGoal.orientationVector = getOrientationVector(finalGoal.orientation)

  local entities = { finalGoal }
  local indexedEntities = {}
  indexedEntities[tuple(entities[#entities].gridPos[1], entities[#entities].gridPos[2])] = entities[#entities]  
  for i = 1,(entityCount - 1) do
    local index = placeGenerator()
    local pos = entityLocations[index]

    entities[#entities + 1] = {
      gridPos = pos,
      pos = self:_getPhysicalPosition(pos[1], pos[2], width),
      reward = kwargs.negativeGoalReward,
      type = sampleObject(random:uniformReal(0, 1)),
      orientation = entityOrientations[index],
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

function api:_initializePickups(objects)
  self.pickups = {}
  for key, obj in pairs(objects) do
    self.pickups[key] = {
      name = key,
      classname = key,
      model = 'models/custom/'..key..'.md3',
      quantity = 1,
      type = pickups.type.REWARD,
      moveType = pickups.moveType.STATIC
    }
  end
end

function api:start(episode, seed, params)
    random:seed(seed)
    self:_initializePickups(OBJECTS)

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
  if self._currentEntities[goalId].isCollected then
    return 0.0
  else
    self._currentEntities[goalId].isCollected = true
    return self._currentEntities[goalId].reward
  end
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

  if self.pickups[spawnVars.classname] then
    spawnVars.id = "1"
    spawnVars.spawnflags = "1"
  end

  if (self.pickups[spawnVars.classname] and self.pickups[spawnVars.classname:sub(0, -6)]) then
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
    if (classname:len() > 5 and self.pickups[classname:sub(0, -6)]) then
        -- is goal
        local goalPickup = {}
        for key, value in pairs(self.pickups[classname:sub(0, -6)]) do
            goalPickup[key] = value
        end
        
        --update goal pickup
        goalPickup.type = pickups.type.GOAL
        return goalPickup
    end
    return self.pickups[classname]
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
