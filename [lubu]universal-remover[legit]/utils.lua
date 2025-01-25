
function zoneProcess(name, v)
    if j[name].zone == nil then return nil end
    for k, z in pairs(j[name].zone) do
        if z.status and getDistanceBetweenCoords2d(v.data.position.x, v.data.position.y, z.position.x, z.position.y) <= z.distanceRemove then
            if getDistanceBetweenCoords2d(z.position.x, z.position.y, getCharCoordinates(PLAYER_PED)) <= z.distanceSpawned then
                return true
            end
            return false
        end 
    end
end 

function onScreenCoordinates(name, v)
    local camX, camY, camZ = getActiveCameraCoordinates()
    local processLine, _ = processLineOfSight(camX, camY, camZ, v.data.position.x, v.data.position.y, v.data.position.z, true, false, false, true, false, false, false, false) 
    local onScreen = (select(4, convert3DCoordsToScreenEx(v.data.position.x, v.data.position.y, v.data.position.z)) > 11)
    if name == 'vehicles' then
        onScreen = onScreen and not processLine
    end
    onScreen = (getDistanceBetweenCoords3d(v.data.position.x, v.data.position.y, v.data.position.z, getCharCoordinates(PLAYER_PED)) <= j[name].minDistance) or onScreen
 
    local zone = zoneProcess(name, v)
    return (zone == nil and onScreen or zone)
end

function emul_rpc(name,p)
    local function getn(t); local i = 0;    for k,v in pairs(t) do i = i + 1 end return i;  end
    local function reverseTable(tbl) 
        local rev = {}
        for i=#tbl, 1, -1 do;   rev[#rev+1] = tbl[i];  end
        return rev
    end
    for _,INTERFACE in pairs({'OUTCOMING_RPCS','OUTCOMING_PACKETS','INCOMING_RPCS','INCOMING_PACKETS'}) do
        for k,v in pairs(events.INTERFACE[INTERFACE]) do
            if (name == v[1] or name == k) then 
                local values, bs = getn(v)-1, raknetNewBitStream()
                if type(v[2]) == 'function' then
                    v[3](bs,p)
                else
                    local T = ((p[1] ~= nil and type(p[1]) == 'table') or (#p == 0 and getn(p) ~= 0))
                    if not T then
                        p = reverseTable(p)
                    elseif T and (p[1] ~= nil and type(p[1]) == 'table') then
                        local res = {}
                        for k,v in pairs(p) do
                            for kk,vv in pairs(p[k]) do
                                res[kk] = vv
                            end
                        end
                        p = res
                    end
                    for _,vv in pairs(v) do
                        if type(vv) == 'table' then
                            for k,v in pairs(vv) do
                                for kk,vv in pairs(events.INTERFACE.BitStreamIO) do
                                    if kk == v then
                                        events.INTERFACE.BitStreamIO[kk].write(bs, p[(T and k or values)])
                                        values = values - 1
                                    end
                                end
                            end
                        end
                    end
                end
                raknetEmulRpcReceiveBitStream(k, bs)
                raknetDeleteBitStream(bs)
            end
        end
    end
end

function renderBlipRadar(x, y, z, size, color)
    local function TransformRealWorldPointToRadarSpace(x, y)
        local RetVal = ffi.new('struct CVector2D', {0, 0})
        CRadar_TransformRealWorldPointToRadarSpace(RetVal, ffi.new('struct CVector2D', {x, y}))
        return RetVal.x, RetVal.y
    end

    local function TransformRadarPointToScreenSpace(x, y)
        local RetVal = ffi.new('struct CVector2D', {0, 0})
        CRadar_TransformRadarPointToScreenSpace(RetVal, ffi.new('struct CVector2D', {x, y}))
        return RetVal.x, RetVal.y
    end

    local function IsPointInsideRadar(x, y)
        return CRadar_IsPointInsideRadar(ffi.new('struct CVector2D', {x, y}))
    end

    local x, y = TransformRealWorldPointToRadarSpace(x,y,z)
    if IsPointInsideRadar(x, y) then
        local x, y = TransformRadarPointToScreenSpace(x, y)
        local _,_,myZ = getCharCoordinates(PLAYER_PED)

        if (myZ > z+5 or myZ < z-5) then  
            renderDrawPolygon(x,y, size*2,size*2, 3, (myZ > z+5 and 180 or 0), color)
        else
            renderDrawBoxWithBorder(x,y,size,size,color,1,0xff000000)
        end
    
    end
end

function getARGB(color)
    return string.format("0x%02x%02x%02x%02x", color[4]*255, color[1]*255, color[2]*255, color[3]*255 )
end


hotkey = {}
do
    local vkeys = require'vkeys'
    if HOTKEY == nil then
        HOTKEY = {
            wait_for_key = 'press any key..',
            no_key = 'none',
            list = {},
            eventHandlers = false,
        }
    end
local function getKeysNameByBind(keys)
    local t = {}
    for k,v in ipairs(keys) do; table.insert(t,vkeys.id_to_name(v)); end
    return (#t == 0 and HOTKEY.no_key or (#t == 1 and table.concat(t,'') or table.concat(t,' + ')))
end
    function hotkey.register(hk,keys,keyDown,activeOnCursorActive,callback)
        keys = decodeJson(keys or '{}')
        HOTKEY.list[hk] = {
            edit = false,
            tick = os.clock(),
            keys = keys,
            keyDown = keyDown,
            activeOnCursorActive = activeOnCursorActive,
            callback = callback,
        }; 
    end
    function hotkey.unregister(hk)
        if HOTKEY.list[hk] == nil then;   return false;    end
        HOTKEY.list[hk] = nil
        return true
    end
    function hotkey.imgui(name,textInButton,hk,width)
        textInButton = (textInButton == nil and '' or (#textInButton == 0 and '' or (textInButton .. ' ')) )
        local b = false
        local h = HOTKEY.list[hk]
        if name ~= nil then imgui.Text(name) imgui.SameLine() end
        if h == nil then;   imgui.Button(textInButton.."NOT FIND HOTKEY "..hk);   return false; end
        if not h.edit then; h.tick = os.clock();    end
        if os.clock()-h.tick >= 1 then;    h.tick = os.clock();    end
        imgui.PushStyleColor(imgui.Col.Text,(os.clock()-h.tick) <= 0.5 and imgui.GetStyle().Colors[imgui.Col.Text] or imgui.ImVec4(1,1,1,0))
        if imgui.Button(textInButton.. (h.edit and (#h.keys == 0 and HOTKEY.wait_for_key or getKeysNameByBind(h.keys)) or getKeysNameByBind(h.keys) .. '##'..hk),imgui.ImVec2(width or 0,0)) then
            h.edit = true;  h.keys = {}
        end
        imgui.PopStyleColor(1)
        if h.edit then
            for k,v in pairs(vkeys) do
                if isKeyDown(VK_BACK) then   h.keys = {};    h.edit = false; b = true;   end
                if isKeyDown(v) and (v ~= VK_MENU and v ~= VK_CONTROL and v ~= VK_SHIFT) or (v == imgui.GetNameClickedMouse()) then
                    for kk,vv in ipairs(h.keys) do
                        if v == vv then;    goto s; end
                    end
                    table.insert(h.keys,v)
                    h.tick = os.clock()
                    ::s::
                    if #h.keys > 2 then
                        for i = 3,#h.keys do;   table.remove(h.keys,i);    end
                    end
                else
                    for kk,vv in ipairs(h.keys) do
                        if v == vv then;    h.edit = false; b = true;   end
                    end
                end
            end--
            -- if isKeyJustPressed(VK_BACK) then;  h.keys = {};    h.edit = false; b = true;   end
        end
        return b
    end
    function hotkey.getKeys(hk)
        return HOTKEY.list[hk].keys == nil and 'nil_'..hk or encodeJson(HOTKEY.list[hk].keys or '{}')
    end
    if not HOTKEY.eventHandlers then
        addEventHandler("onWindowMessage",
            function (message, wparam, lparam)      
                for k,v in pairs(HOTKEY.list) do
                    if v.edit then
                        if message == 0x0102 then--CHAR
                            consumeWindowMessage(true,true)
                        elseif message == 0x0008 then--KILLFOCUS
                            v.edit = false
                            v.keys = {}
                        end
                    end
                end
            end
        )
        lua_thread.create(function()--
            while true do wait(0)--
            -- addEventHandler('onD3DPresent',function()--
                if HOTKEY~=nil then
                    for k,v in pairs(HOTKEY.list) do
                        if HOTKEY.list[k] ~= nil and v.activeOnCursorActive and true or not (sampIsCursorActive() or sampIsDialogActive() or sampIsChatInputActive()) and not v.edit then
                            
                            if v.keyDown and (#v.keys == 1 and isKeyDown(v.keys[1]) or #v.keys == 2 and (isKeyDown(v.keys[1]) and isKeyDown(v.keys[2])) or false) or (#v.keys == 1 and isKeyJustPressed(v.keys[1]) or #v.keys == 2 and (isKeyDown(v.keys[1]) and isKeyJustPressed(v.keys[2])) or false)  then
                                v.callback()
                            end

                        end

                    end
                end
            end--while true do wait(0)
        end)
        HOTKEY.eventHandlers = true
    end
end
function imgui.GetNameClickedMouse()
    local n = {0x01,0x02,0x04}
    for i = 0,2 do
        if imgui.IsMouseClicked(i) then
            return n[i+1]
        end
    end
    return 'none'
end