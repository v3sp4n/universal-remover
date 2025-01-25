


function events.onMarkersSync(markers)
    for playerId, v in pairs(cache.players) do
        if v.remove and markers[playerId] ~= nil then
            markers[playerId].active = false
        end
    end
    return {markers}
end

function events.onPlayerStreamIn(id, team, model, position, rotation, color, fightingStyle)
    local data = {
        ["id"] = id,
        ["team"] = team,
        ["model"] = model,
        ["position"] = position,
        ["rotation"] = rotation,
        ["color"] = color,
        ["fightingStyle"] = fightingStyle,
    }
    cache.players[id] = {
        data = data,
        ["clist"] = sampGetPlayerColor(id),
        attached = {},
        animation = {},
        remove = false,
        zone = false,
        intoCar = false,
    }
end

function events.onPlayerStreamOut(id)
    cache.players[id] = nil
end

function events.onPlayerSync(id, data)
    if cache.players[id] == nil then return true end
    cache.players[id].data.position = {
        ['x'] = data.position.x,
        ['y'] = data.position.y,
        ['z'] = data.position.z,
    }
end

function events.onSetPlayerColor(id, color)
    if cache.players[id] == nil then return end
    cache.players[id].data.color = color
end

function events.onSetPlayerSkin(id, skin)
    if cache.players[id] == nil then return true end
    cache.players[id].data.model = skin
end

function events.onSetPlayerTeam(id, team)
    if cache.players[id] == nil then return true end
    cache.players[id].data.team = team
end

function events.onClearPlayerAnimation(id)
    if cache.players[id] == nil then return true end
    cache.players[id].animation = {id}
end

function events.onSetPlayerAttachedObject(id, index, create, object)
    if cache.players[id] == nil then return true end
    cache.players[id].attached[index] = {id, index, create, object}
    if cache.attaches[id] == nil then cache.attaches[id] = {} end
    cache.attaches[id][index] = {create,object}
    return false
end

function events.onApplyPlayerAnimation(id, animLib, animName, frameDelta, loop, lockX, lockY, freeze, time)
    if cache.players[id] == nil then return end
    cache.players[id].animation = {id, animLib, animName, frameDelta, loop, lockX, lockY, freeze, time}
end