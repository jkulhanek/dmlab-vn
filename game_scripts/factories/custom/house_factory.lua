local make_map = require 'common.make_map'
local map_maker = require 'dmlab.system.map_maker'
local random = require 'common.random'
local randomMap = random(map_maker:randomGen())
local texture_sets = require 'themes.texture_sets'

factory = {}
function factory.createLevelApi(kwargs)
    api = {}
    function api:nextMap()
        return self._map
    end
    
    function api:start(episode, seed)
        random:seed(seed)
        randomMap:seed(random:mapGenerationSeed())

        self._map = make_map.makeMap{
            mapName = 'WideOpenLevel',
            textureSet = texture_sets.GO,
            mapEntityLayer =
                '***********\n' ..
                '*        P*\n' ..
                '*         *\n' ..
                '*    **   *\n' ..
                '*    **   *\n' ..
                '*         *\n' ..
                '*         *\n' ..
                '*         *\n' ..
                '*         *\n' ..
                '*         *\n' ..
                '***********\n',
        }
    end

    return api
end

return factory
