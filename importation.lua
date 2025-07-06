local SEARCH_PATHS   <const> = { "?.lua", "?/init.lua" }
local CURRENT_RES    <const> = GetCurrentResourceName()
local existingCache  = type(_G.require) == "function" and _G.require.__amb_cache
local LOADED_CACHE   = existingCache or {}   ---@type table<string, any>

local function resolve(name)
    if name:sub(1, 1) == "@" then
        local res, p = name:match("^@([^%.]+)%.(.+)$")
        assert(res and p, ("Bad module '%s'"):format(name))
        return res, p:gsub("%.", "/")
    end
    return CURRENT_RES, name:gsub("%.", "/")
end

local function tryLoad(res, file, name)
    local src = LoadResourceFile(res, file)
    if not src then return nil end

    local env = { require = _G.require }
    setmetatable(env, { __index = _G })

    local chunk, err = load(src, ("@%s/%s"):format(res, file), "t", env)
    assert(chunk, ("Compile error in '%s': %s"):format(name, err))

    local ok, ret = pcall(chunk)
    assert(ok, ("Runtime error in '%s': %s"):format(name, ret))
    return ret == nil and true or ret
end

local function ambitionsRequire(module)
    local res, rel = resolve(module)
    local key      = res .. ":" .. module

    local cached = LOADED_CACHE[key]
    if cached ~= nil then
        if cached == "__LOADING__" then
            error(("Circular dependency detected on '%s'"):format(module), 2)
        end
        return cached
    end
    LOADED_CACHE[key] = "__LOADING__"

    local tried = {}
    for _, pattern in ipairs(SEARCH_PATHS) do
        local file   = pattern:gsub("%?", rel)
        local result = tryLoad(res, file, module)
        if result then
            LOADED_CACHE[key] = result
            return result
        end
        tried[#tried + 1] = ("no file '@%s/%s'"):format(res, file)
    end

    LOADED_CACHE[key] = nil
    error(("Module '%s' not found:\n%s"):format(
        module, table.concat(tried, "\n")), 2)
end

AddEventHandler('onResourceStop', function(res)
    for k in pairs(LOADED_CACHE) do
        if k:sub(1, #res + 1) == res .. ":" then
            LOADED_CACHE[k] = nil
        end
    end
end)

ambitionsRequire.__amb_cache = LOADED_CACHE
_G.require = ambitionsRequire