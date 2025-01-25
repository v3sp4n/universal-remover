
function events.onCreateObject(id, data)
	--//vehicles
    if data.attachToVehicleId ~= 0xFFFF and cache.vehicles[data.attachToVehicleId] ~= nil then
        table.insert(cache.vehicles[data.attachToVehicleId].objects, {id, data})
    end
    --//
    cache.objects[id] = {
    	data = data,
    	remove = false,
    }
end

function events.onDestroyObject(id)
	--//vehicles
    for vehicleId, v in pairs(cache.vehicles) do
        for k,v in pairs(v.objects) do
            if v[1] == id then
                table.remove(cache.vehicles[vehicleId].objects, k)
            end
        end
    end
    --//
    cache.objects[id] = nil
end