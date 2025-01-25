json = setmetatable({defPath = getWorkingDirectory()..'/config/',
    save = function(t,path) 
        if not path:find('[\\/]') then;  path = json.defPath..path end
        if not doesDirectoryExist(path:match('(.+)/.+%.%S+$')) then createDirectory(path:match('(.+)/.+%.%S+$')) end
        t = (t == nil and {} or (type(t) == 'table' and t or {}))
        local f = io.open(path,'w');    f:write(encodeJson(t) or {});   f:close()
    end,
    load = function(t,path) 
        if not path:find('[\\/]') then;  path = json.defPath..path end
        if (not doesFileExist(path) or not doesDirectoryExist(path:match('(.+)/.+%.%S+$'))) then;    json.save(t,path);  end
        local f = io.open(path,'r+');   local T = decodeJson(f:read('*a')); f:close()
        return setmetatable(T,{
            __call = function(mytable) json.save(mytable,path) end,
        })
    end
},{
    __call = function(self, n, func, ...)
        if not doesDirectoryExist(getWorkingDirectory()..'/config/') then createDirectory(getWorkingDirectory()..'/config/') end
    end,
})

return json.load({
    vehicles = {
        status = false,
        size = 9,
        color = {0,0,0,1},
        minDistance = 10,
        zone = {},
    },
    players = {
        minDistance = 10,
        status = false,
        size = 9,
        zone = {},
    },
    objects = {
        minDistance = 10,
        status = false,
        zone = {},
    },
    hotkeys = {
        vehicles = "[]",
        players = "[]",
    }
}, "universal-remover.json")