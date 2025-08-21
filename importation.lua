local SEARCH_PATTERNS = { "?.lua", "?/init.lua" }
local MODULE_CACHE = {}

--- Parse module name to extract resource and path components
---@param name string The module name to parse (e.g., "ResourceName.module.path")
---@return string resource The resource name
---@return string path The module path with dots converted to slashes
local function parseModule(name)
    local dotIndex = name:find("%.")

    if not dotIndex then
        error(("Invalid module format: '%s'. Must use 'ResourceName.module.path' format"):format(name), 3)
    end

    local resource = name:sub(1, dotIndex - 1)
    local path = name:sub(dotIndex + 1)

    local resourceState = GetResourceState(resource)
    if resourceState ~= "starting" and resourceState ~= "started" then
        error(("Resource '%s' is not started or does not exist"):format(resource), 3)
    end

    return resource, path:gsub("%.", "/")
end

--- Load and execute a Lua file from a resource
---@param resource string The resource name to load from
---@param filepath string The file path within the resource
---@param moduleName string The original module name for error messages
---@return boolean success Whether the file was found and loaded successfully
---@return any result The module result or nil if not found
local function loadFile(resource, filepath, moduleName)
    local source = LoadResourceFile(resource, filepath)
    if not source then
        return false
    end

    local env = setmetatable({}, { __index = _G })
    env.require = _G.require

    local chunk, compileError = load(source, ("@%s/%s"):format(resource, filepath), "t", env)
    if not chunk then
        error(("Failed to compile module '%s': %s"):format(moduleName, compileError), 0)
    end

    local success, result = pcall(chunk)
    if not success then
        error(("Runtime error in module '%s': %s"):format(moduleName, result), 0)
    end

    return true, result == nil and true or result
end

--- Search for and load a module using multiple file patterns
---@param resource string The resource name to search in
---@param modulePath string The module path to search for
---@param originalName string The original module name for error messages
---@return any module The loaded module result
local function findAndLoadModule(resource, modulePath, originalName)
    local attempts = {}

    for _, pattern in ipairs(SEARCH_PATTERNS) do
        local filepath = pattern:gsub("%?", modulePath)
        local success, result = loadFile(resource, filepath, originalName)

        if success then
            return result
        end

        table.insert(attempts, ("  - %s/%s"):format(resource, filepath))
    end

    error(("Module '%s' not found. Searched:\n%s"):format(
        originalName, table.concat(attempts, "\n")
    ), 2)
end

--- Main require function that handles module loading with caching and circular dependency detection
---@param name string The module name to require
---@return any module The loaded module result
local function requireModule(name)
    local resource, modulePath = parseModule(name)
    local cacheKey = resource .. ":" .. name

    local cached = MODULE_CACHE[cacheKey]
    if cached ~= nil then
        if cached == "LOADING" then
            error(("Circular dependency detected: '%s'"):format(name), 2)
        end
        return cached
    end

    MODULE_CACHE[cacheKey] = "LOADING"

    local module = findAndLoadModule(resource, modulePath, name)
    MODULE_CACHE[cacheKey] = module

    return module
end

AddEventHandler("onResourceStop", function(resourceName)
    local prefix = resourceName .. ":"
    for key in pairs(MODULE_CACHE) do
        if key:sub(1, #prefix) == prefix then
            MODULE_CACHE[key] = nil
        end
    end
end)

_G.require = requireModule