luacfg = {
    encode = function(tbl)
        local function w(t);    return (type(t) == 'string' and '"'..t..'"' or t) end
        local function returnTableToText(t,s)
            local text = '{'
            s = s or 1
            for k,v in pairs(t) do
                if type(v) == 'table' then
                    text = ('%s\n%s[%s] = '):format(text,(string.rep('\t',s)),w(k))
                    local t = returnTableToText(v,s+1)
                    text = ('%s\n%s%s\n%s},'):format(text,(string.rep('\t',s)),t,(string.rep('\t',s)))
                else
                    if not tostring(v):find("function") then
                        text = ('%s\n%s[%s] = %s,'):format(text,(string.rep('\t',s)),w(k),w(v))
                    end
                end
            end
            return text
        end
        return returnTableToText(tbl)..'\n}'
    end,
    decode = function(text)
        local fu,e = load('return '..text)
        return (e == nil and fu() or e)
    end,

    save = function(tbl, path)
    	local f = io.open(path, 'w')
    	f:write(luacfg.encode(tbl)):close()
    end,
    load = function(path)
    	local f = io.open(path, 'r')
    	return luacfg.decode(f:read("*a"))
    end
}

return luacfg