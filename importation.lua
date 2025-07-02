local CURRENT_RESOURCE = GetCurrentResourceName()
local loaded = {}
local preload = {}
local searchPaths = {
    "?.lua",
    "?/init.lua"
}

--- Loads and returns a Lua module, with caching and circular dependency detection.
--- @param resource string The name of the resource to load the module from.
--- @param moduleName string The module name using dot notation, e.g. "config.server.foo" or "@OtherRes.util.bar".
--- @return any moduleResult The value returned by the module (table, function, etc.).
local function importWithResource(resource, moduleName)
    assert(type(resource) == "string", ("resource must be a string (got '%s')"):format(type(resource)))
    assert(type(moduleName) == "string", ("moduleName must be a string (got '%s')"):format(type(moduleName)))

    loaded[resource] = loaded[resource] or {}

    local cache = loaded[resource]

    if cache[moduleName] then
        if cache[moduleName] == "__LOADING__" then
            error(("Circular dependency detected while loading module '%s'"):format(moduleName))
        end

        return cache[moduleName]
    end

    cache[moduleName] = "__LOADING__"

    if preload[resource] and preload[resource][moduleName] then
        local result = preload[resource][moduleName]()

        cache[moduleName] = result or true

        return cache[moduleName]
    end

    local targetRes, localName = moduleName:match("^@([^%.]+)%.(.+)")

    if not targetRes then
        targetRes = resource
        localName   = moduleName
    end

    local relPath = localName:gsub("%.", "/")
    local code, errors = nil, {}

    for _, tpl in ipairs(searchPaths) do
        local filePath = tpl:gsub("%?", relPath)
        local file = LoadResourceFile(targetRes, filePath)

        if file then
            code = file
            break
        else
            errors[#errors+1] = ("no file '@%s/%s'"):format(targetRes, filePath)
        end
    end

    if not code then
        error(("Module '%s' not found:\n%s"):format(moduleName, table.concat(errors, "\n")))
    end

    local env = {
        Import     = function(n) return importWithResource(targetRes, n) end,
        ImportJson = function(n) return importJsonWithResource(targetRes, n) end,
        ImportPart = function(n,k) return importPartWithResource(targetRes, n, k) end,
    }

    setmetatable(env, { __index = _G })

    if targetRes ~= CURRENT_RESOURCE then
        local ok, obj = pcall(function() return exports[targetRes]:object() end)

        if ok and obj then
            env.ABT = obj
        end
    end

    local chunk, compileErr = load(code, ("@%s/%s"):format(targetRes, relPath), "t", env)

    if not chunk then
        error(("Error compiling module '%s': %s"):format(moduleName, compileErr))
    end

    local success, result = pcall(chunk)

    if not success then
        error(("Error running module '%s': %s"):format(moduleName, result))
    end

    if result == nil then result = true end

    cache[moduleName] = result

    return result
end

--- Loads and decodes a JSON file from a resource.
--- @param resource string The name of the resource to load the JSON from.
--- @param moduleName string The module path without extension, using dot notation.
--- @return table decodedJson The decoded JSON content as a Lua table.
local function importJsonWithResource(resource, moduleName)
    assert(type(resource) == "string", ("resource must be a string (got '%s')"):format(type(resource)))
    assert(type(moduleName) == "string", ("moduleName must be a string (got '%s')"):format(type(moduleName)))

    local targetRes, localName = moduleName:match("^@([^%.]+)%.(.+)") or resource, moduleName:match("^@[^%.]+%.(.+)") or moduleName
    local relPath = localName:gsub("%.", "/")
    local filePath = relPath .. ".json"
    local raw = LoadResourceFile(targetRes, filePath)

    if not raw then
        error(("JSON '%s' not found at '@%s/%s'"):format(moduleName, targetRes, filePath))
    end

    return json.decode(raw)
end

--- Imports a specific part (key) from a module that returns a table.
--- @param resource string The name of the resource to load the module from.
--- @param moduleName string The module name using dot notation.
--- @param key string The key to extract from the module's returned table.
--- @return any partValue The value associated with the given key in the module.
local function importPartWithResource(resource, moduleName, key)
    local mod = importWithResource(resource, moduleName)
    assert(type(mod) == "table", ("Module '%s' did not return a table"):format(moduleName))
    local part = mod[key]

    if part == nil then
        error(("Key '%s' not found in module '%s'"):format(key, moduleName))
    end

    return part
end

--- Imports a module from the current resource.
--- @param moduleName string The module name to import, e.g. "config.server.foo" or "@OtherRes.util.bar".
--- @return any moduleResult The imported module's return value.
function Import(moduleName)
    return importWithResource(CURRENT_RESOURCE, moduleName)
end

--- Imports a JSON file from the current resource.
--- @param moduleName string The JSON module name without .json extension.
--- @return table decodedJson The decoded JSON content.
function ImportJson(moduleName)
    return importJsonWithResource(CURRENT_RESOURCE, moduleName)
end

--- Preloads a module with a custom loader function, bypassing file search.
--- @param moduleName string The module name to preload.
--- @param loader function A loader function that returns the module's value when called.
--- @return nil
function ImportPreload(moduleName, loader)
    assert(type(moduleName) == "string", "moduleName must be a string")
    assert(type(loader) == "function", "loader must be a function")

    preload[CURRENT_RESOURCE] = preload[CURRENT_RESOURCE] or {}
    preload[CURRENT_RESOURCE][moduleName] = loader
end

--- Imports a table key from a module in the current resource.
--- @param moduleName string The module name to import from.
--- @param key string The key to extract from the module's table.
--- @return any partValue The extracted value.
function ImportPart(moduleName, key)
    return importPartWithResource(CURRENT_RESOURCE, moduleName, key)
end