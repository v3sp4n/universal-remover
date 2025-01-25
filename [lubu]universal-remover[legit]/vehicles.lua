
function events.onVehicleStreamIn(id, data)
    lua_thread.create(function()
        while not select(1, sampGetCarHandleBySampVehicleId(id)) do wait(100) end 
        data.numberPlate = "vespa lx 50"
        cache.vehicles[id] = {
            sync = false,
            data = data,
            objects = {},
            paramsex = {},
            seat = {
                driver = {id=-1,clist=-1},
                passengers = {},
            },
            remove = false,
            blip = nil,
        }
    end)
end

for inData, hook in pairs({['rotation']="onSetVehicleAngle",['numberPlate']="onSetVehicleNumberPlate",['health']="onSetVehicleHealth",['position']="onSetVehiclePosition"}) do 
    events[hook] = function(id, arg)
        if arg == nil then return true end
        lua_thread.create(function()
            while cache.vehicles[id] == nil do wait(0) end 
            cache.vehicles[id].data[inData] = arg
            emul_rpc(hook, {id, arg})
        end)
    end
end
function events.onVehicleStreamOut(id)
    cache.vehicles[id] = nil
end
function events.onSetVehicleParamsEx(id, params, doors, windows)
    if cache.vehicles[id] == nil then return true end
    --params.doors = 1 lock, 0 unlock
    local paramsex = {}
    for k,v in pairs({_G["params"],_G["doors"],_G["windows"]}) do
        table.insert(paramsex,v)
    end
    cache.vehicles[id].paramsex = paramsex
    lockCarDoors(select(2,sampGetCarHandleBySampVehicleId(id)),(params.doors == 1 and 2 or (params.doors == 0 and 1 or 1)))
end
function events.onSendVehicleDamaged(id,panel,door,light,tires)
    if cache.vehicles[id] == nil then return true end
    cache.vehicles[id].data.panelDamageStatus = panel
    cache.vehicles[id].data.doorDamageStatus = door
    cache.vehicles[id].data.lightDamageStatus = light
    cache.vehicles[id].data.tireDamageStatus = tires
end

function events.onPlayerEnterVehicle(playerId, vehicleId, passenger)
    if cache.vehicles[vehicleId] == nil then return true end
    if passenger then
        cache.vehicles[vehicleId].seat.passengers[playerId] = {clist=sampGetPlayerColor(playerId),seat=1}
    else
        cache.vehicles[vehicleId].seat.driver = {clist=sampGetPlayerColor(playerId),id=playerId}
    end
end
function events.onPlayerExitVehicle(playerId, vehicleId)
    if cache.players[playerId] ~= nil then
        cache.players[playerId].intoCar = false
    end
    if cache.vehicles[vehicleId] == nil then return true end
    if cache.vehicles[vehicleId].seat.driver.id == playerId then
        cache.vehicles[vehicleId].seat.driver.id = -1; return true
    end
    cache.vehicles[vehicleId].seat.passengers[playerId] = nil
end

function events.onPassengerSync(playerId, data)
    if cache.vehicles[data.vehicleId] == nil then return true end
    cache.vehicles[data.vehicleId].seat.passengers[playerId] = {clist=sampGetPlayerColor(playerId),seat=data.seatId}
    cache.players[playerId].intoCar = true
end
for _,hook in pairs({ "onSendVehicleSync",  "onVehicleSync" }) do
    events[hook] = function(...)
        local data = ({...})[ (hook == "onSendVehicleSync" and 1 or 3) ]
        local vehicleId = (hook == "onSendVehicleSync" and data.vehicleId or ({...})[2])
        if cache.vehicles[vehicleId] == nil then return true end
        local d = {
            ['position'] = {
                ['x'] = data.position.x,
                ['y'] = data.position.y,
                ['z'] = data.position.z,
            },
            ['health'] = data.vehicleHealth,
            ['addSiren'] = data.siren,
        }
        for k, _ in pairs(cache.vehicles[vehicleId].data) do
            if d[k] ~= nil then
                cache.vehicles[vehicleId].data[k] = d[k] 
            end
        end 
        if hook == "onVehicleSync" and cache.vehicles[vehicleId] ~= nil and cache.players[({...})[1]] ~= nil then
            cache.vehicles[vehicleId].seat.driver = {id=({...})[1],clist=sampGetPlayerColor(({...})[1])}
            cache.players[({...})[1]].intoCar = true
        end
    end
end