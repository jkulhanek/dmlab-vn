local make_map = require 'common.make_map'
local map_maker = require 'dmlab.system.map_maker'
local random = require 'common.random'
local texture_sets = require 'themes.texture_sets'

factory = {}
function factory.createLevelApi(kwargs)
    api = {}

    function api:nextMap()
        local map = kwargs.mapName
        kwargs.mapName = ''
        return map
    end
    
    function api:start(episode, seed)
        random:seed(seed)
    end

    return api
end

return factory
