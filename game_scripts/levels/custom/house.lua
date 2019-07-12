local factory = require 'factories.custom.house_factory'

return factory.createLevelApi{
    mapName = 'house',
    episodeLengthSeconds = 60,
    camera = {500, 250, 600}
}
