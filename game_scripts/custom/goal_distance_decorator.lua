local game = require 'dmlab.system.game'

local function copy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
    return res
end

local function decorator(api, kwargs)
    local position = nil
    local distance = 0
    local shortestDistance = 0

    local customObservation = api.customObservation
    function api:customObservation(name)
        if name == 'DISTANCE' then
            return tensor.Tensor{distance}
        elseif name == 'SHORTEST_DISTANCE' then
            return tensor.Tensor{shortestDistance}
        end
        return customObservation and customObservation(self, name) or nil
    end

    local customObservationSpec = api.customObservationSpec
    function api:customObservationSpec()
        local spec = customObservationSpec and copy(customObservationSpec(self)) or {}
        spec[#spec] = {name = 'DISTANCE', type = 'Doubles', shape = {1}}
        spec[#spec] = {name = 'SHORTEST_DISTANCE', type = 'Doubles', shape = {1}}
        return spec
    end

    local modifyControl = api.modifyControl
    function api:modifyControl(actions)
        npos = game:playerInfo().eyePos
        if position ~= nil then
            distance = distance + math.sqrt((position[1] - npos[1]) ^ 2 + (position[2] - npos[2]) ^ 2)
        end
        position = npos
        return modifyControl and modifyControl(self, actions) or actions
    end

    local updateGoals = api.updateGoals
    function api:updateGoals(goals, spawn)
        for i,goal in ipairs(goals) do
            if goal.final then
                shortestDistance = math.sqrt((goal.truePos[1] - spawn[1]) ^ 2 + (goal.truePos[2] - spawn[2]) ^ 2)
                break
            end
        end
        distance = 0
        return updateGoals and updateGoals(self, goals, spawn) or nil
    end
end

return decorator