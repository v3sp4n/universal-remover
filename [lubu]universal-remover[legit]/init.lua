
require "players" 
require "vehicles" 
require "utils" 
require "ui" 
require "objects" 
j = require("config")
--[[static]] 
imgui = require('imgui')
ffi = require('ffi')
ffi.cdef('struct CVector2D {float x, y;}')
CRadar_TransformRealWorldPointToRadarSpace = ffi.cast('void (__cdecl*)(struct CVector2D*, struct CVector2D*)', 0x583530)
CRadar_TransformRadarPointToScreenSpace = ffi.cast('void (__cdecl*)(struct CVector2D*, struct CVector2D*)', 0x583480)
CRadar_IsPointInsideRadar = ffi.cast('bool (__cdecl*)(struct CVector2D*)', 0x584D40)
events = require "samp.events"
handler = require 'lib.samp.events.handlers'
imgui = require "imgui" 
inspect = require "inspect"
--[[static]] 
-- luacfg = require "luacfg"

cache = {
    vehicles = {},
    players = {},
    objects = {},
    attaches = {},
    -- file_path = getWorkingDirectory()..'/config/universal-remover__CACHE.lua'
}

function main()
    while not isSampAvailable() do wait(100) end
    -- while not sampIsLocalPlayerSpawned() do wait(0) 
    --     if sampGetGamestate() ~= 3 then
    --         print("SKIP CACHE")
    --         goto chapo_loved_poppies_on_keyboards
    --     end
    -- end
    -- if doesFileExist(cache.file_path) then
    --     print("LOAD CACHE")
    --     cache = luacfg.load(cache.file_path)
    -- end
    -- ::chapo_loved_poppies_on_keyboards::

    sampRegisterChatCommand("ur",function() imguiSettings.v = not imguiSettings.v end)

    for _, name in pairs({ "vehicles", "players" }) do
        hotkey.register( name, j.hotkeys[name], false, false, function() 
            j[name].status = not j[name].status; 
            printStringNow(("togle [%s] = %s"):format(name, tostring(j[name].status)),2500)
            if not j[name].status then
                for id, v in pairs( cache[name] ) do
                    _G["create" .. (name:sub(1,1)):upper() .. name:sub(2,#name-1) ]( id, (v) )
                    v.remove = false
                end
            end
        end)
    end

    while true do wait(0)
        imgui.Process = imguiSettings.v

        if j.vehicles.status then
            --vehicles
            for vehicleId, v in pairs(cache.vehicles) do
                if v == nil then return end
                local onScreen = onScreenCoordinates('vehicles', v, true)
                -- local zone = zoneProcess("vehicles", v)
                -- onScreen = (zone == nil and onScreen or not zone)

                if onScreen and v.remove then
                    v.remove = false
                    
                    createVehicle(vehicleId, v)

                    for playerId, passenger in pairs( v.seat.passengers ) do
                        if cache.players[playerId].remove then
                            cache.players[playerId].remove = false
                            createPlayer(playerId, cache.players[playerId].data)
                        end
                        emul_rpc('onSetPlayerColor',{ playerId, cache.players[playerId].data.color })
                        warpCharIntoCarAsPassenger(select(2, sampGetCharHandleBySampPlayerId(playerId)), select(2,sampGetCarHandleBySampVehicleId(vehicleId)), passenger.seat)
                    end
                    if v.seat.driver.id ~= -1 then
                        if cache.players[v.seat.driver.id].remove then
                            cache.players[v.seat.driver.id].remove = false
                            createPlayer(v.seat.driver.id, cache.players[v.seat.driver.id].data)
                        end
                        warpCharIntoCar(select(2, sampGetCharHandleBySampPlayerId(v.seat.driver.id)), select(2,sampGetCarHandleBySampVehicleId(vehicleId)))
                        emul_rpc('onSetPlayerColor',{ v.seat.driver.id, cache.players[v.seat.driver.id].data.color })
                    end

                elseif not onScreen then

                    local clist, passengerClist = getARGB(j.vehicles.color), -1
                    for playerId, passenger in pairs(v.seat.passengers) do
                        if passenger ~= nil then; passengerClist = passenger.clist end
                    end
                    clist = ( v.seat.driver.id ~= -1 and v.seat.driver.clist or (passengerClist ~= -1 and passengerClist or clist) )
                    local playersIntoCar = (passengerClist ~= -1 or clist ~= getARGB(j.vehicles.color)) and j.players.size or j.vehicles.size
                    renderBlipRadar( v.data.position.x, v.data.position.y, v.data.position.z, (playersIntoCar), clist )

                    if not v.remove then
                        v.remove = true

                        emul_rpc('onVehicleStreamOut',{vehicleId})

                        -- if not j.players.status then
                            for playerId, passenger in pairs( v.seat.passengers ) do
                                emul_rpc('onSetPlayerColor',{ playerId, 0x00000000 })
                            end
                            if v.seat.driver.id ~= -1 then
                                emul_rpc('onSetPlayerColor',{ v.seat.driver.id, 0x00000000 })
                            end
                        -- end
                    end

                end--onScreen
            end--for
        end 

        --players
        if j.players.status then
            for playerId, v in pairs(cache.players) do
                if v == nil or v.data == nil then return end
                local onScreen = onScreenCoordinates('players', v)

                if onScreen and v.remove then
                    v.remove = false

                    createPlayer(playerId, v)

                elseif not onScreen then
                    
                    if not v.intoCar then
                        renderBlipRadar( v.data.position.x, v.data.position.y, v.data.position.z, j.players.size, v.clist )
                    end

                    if not v.remove and (select(1, sampGetCharHandleBySampPlayerId(playerId)) and not isCharInAnyCar(select(2, sampGetCharHandleBySampPlayerId(playerId)))) then
                        v.remove = true

                        emul_rpc("onPlayerStreamOut", {playerId})
                        sampAddChatMessage("r " .. playerId, -1)

                    end
                end--onScreen
            end--for
        end


        --objects
        if j.objects.status then
            for id, v in pairs(cache.objects) do
                if v == nil or v.data == nil then return end
                local onScreen = onScreenCoordinates('objects', v)

                if onScreen and v.remove then
                    v.remove = false

                    createObject(id, v.data)

                elseif not onScreen and not v.remove then
                    v.remove = true

                    emul_rpc("onDestroyObject", { id })

                end--onScreen
            end--for
        end


    end
end

function createAttach(v)
    emul_rpc("onSetPlayerAttachedObject", {unpack(v)})
end

function createObject(id, data)
    local bs = raknetNewBitStream()
    handler.rpc_create_object_writer(bs,{id,data})
    raknetEmulRpcReceiveBitStream(44,bs)
    raknetDeleteBitStream(bs)
end

function createPlayer(playerId, v)
    local data = {
        v.data.team, v.data.model, v.data.position,
        v.data.rotation, v.data.color, v.data.fightingStyle
    }
    emul_rpc("onPlayerStreamIn", {playerId, unpack(data)})
    for index, attach in pairs(v.attached) do
        emul_rpc("onSetPlayerAttachedObject", {unpack(attach)})
    end
end

function createVehicle(vehicleId, v)
    local b,err = pcall(function()
        if v.data == nil or type(v.data) ~= 'table' then return end

        local bs = raknetNewBitStream()
        handler.rpc_vehicle_stream_in_writer(bs,{vehicleId,v.data})
        raknetEmulRpcReceiveBitStream(164,bs)
        raknetDeleteBitStream(bs)

        emul_rpc('onSetVehicleNumberPlate',{vehicleId,v.data.numberPlate})

        for _,obj in ipairs(v.objects) do
            local bs = raknetNewBitStream()
            handler.rpc_create_object_writer(bs,{obj[1],obj[2]})
            raknetEmulRpcReceiveBitStream(44,bs)
            raknetDeleteBitStream(bs)
        end

        if #v.paramsex > 0 then
            local bs = raknetNewBitStream()
            raknetBitStreamWriteInt16(bs,vehicleId)
            for k,v in pairs(v.paramsex) do
                raknetBitStreamWriteInt8(bs,v)
            end
            raknetEmulRpcReceiveBitStream(24,bs)
            raknetDeleteBitStream(bs)
        end

    end)
end


-- function onScriptTerminate(s)
--     if s == thisScript() then
--         print("SAVE CACHE")
--         luacfg.save(cache, cache.file_path)
--     end
-- end