local game = require 'dmlab.system.game'
local map_maker = require 'dmlab.system.map_maker'
local maze_generation = require 'dmlab.system.maze_generation'
local helpers = require 'common.helpers'
local pickups = require 'common.pickups'
local custom_observations = require 'decorators.custom_observations'
local setting_overrides = require 'decorators.setting_overrides'
local random = require 'common.random'
local map_maker = require 'dmlab.system.map_maker'
local randomMap = random(map_maker:randomGen())

local factory = {}

--[[ Creates a Nav Maze Random Goal.
Keyword arguments:

*   `mapName` (string) - Name of map to load.
*   `entityLayer` (string) - Text representation of the maze.
*   `episodeLengthSeconds` (number, default 600) - Episode length in seconds.
*   `scatteredRewardDensity` (number, default 0.1) - Density of rewards.
]]

function factory.createLevelApi(kwargs)
  local api = {}

  function api:createPickup(class)
    appickup = {
        name = 'Chair',
        classname = class,
        model = 'models/custom/meuble_chevet.md3',
        quantity = 1,
        type = pickups.type.REWARD,
        moveType = pickups.moveType.STATIC
    }

    if class == 'apple_reward' then
        return appickup
    end

    return pickups.defaults[class]

  end

  function api:start(episode, seed, params)
  end

  function api:updateSpawnVars(spawnVars)
    return spawnVars
  end

  function api:nextMap()
    -- Fast map restarts.
    local map = kwargs.mapName
    kwargs.mapName = ''
    return map
  end

  function api:canPickup(spawnId, playerId)
    print(spawnId)
    return false
  end

  function api:extraEntities()
    return {
        {
            classname = 'apple_reward',
            model = 'models/apple.md3',
            origin = '64 64 20',
        },
    }
  end

  custom_observations.decorate(api)
  setting_overrides.decorate{
      api = api,
      apiParams = kwargs,
      decorateWithTimeout = true
  }
  return api
end

return factory
