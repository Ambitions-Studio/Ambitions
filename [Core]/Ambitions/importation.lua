local ModuleCache = {} ---@type table<string, table>
local ModuleLoading = {} ---@type table<string, boolean>

--- Resolve the resource name and file path from a module path.
---@param modulePath string The module path (e.g., "@resource.folder.file" or "folder.file").
---@return string resourceName, string moduleFilePath
local function resolveModulePath(modulePath)
    assert(type(modulePath) == "string", "Module path must be a string")

    local resourceName, moduleFilePath

    if modulePath:sub(1, 1) == "@" then
        local splitPath = modulePath:match("^@([^%.]+)%.(.+)$")
        if not splitPath then
            error(("Invalid module path format: '%s'"):format(modulePath))
        end

        resourceName, moduleFilePath = splitPath:match("([^%.]+)"), splitPath:sub(#splitPath + 2)
    else
        resourceName = GetCurrentResourceName()
        moduleFilePath = modulePath
    end

    moduleFilePath = moduleFilePath:gsub("%.", "/")
    return resourceName, moduleFilePath
end

--- Load a Lua file as an executable chunk.
---@param resourceName string The resource name containing the module.
---@param filePath string The file path within the resource.
---@return table<string, any> The module's exports.
local function loadModule(resourceName, filePath)
    local moduleContent = LoadResourceFile(resourceName, filePath .. ".lua")
    if not moduleContent then
        error(("Module '%s.lua' not found in resource '%s'"):format(filePath, resourceName))
    end

    local chunk, err = load(moduleContent, ("@%s/%s.lua"):format(resourceName, filePath), "t")
    if not chunk then
        error(("Failed to compile module '%s.lua' in resource '%s': %s"):format(filePath, resourceName, err))
    end

    local result = chunk()
    if type(result) ~= "table" and type(result) ~= "function" then
        error(("Module '%s.lua' in resource '%s' must return a table or a function"):format(filePath, resourceName))
    end

    return result
end

--- Import an entire module with dynamic access.
---@param modulePath string The path to the module file.
---@return table The module's exports, accessible dynamically.
function import(modulePath)
    assert(type(modulePath) == "string", "Module path must be a string")

    if ModuleLoading[modulePath] then
        error(("Circular dependency detected for module '%s'"):format(modulePath))
    end

    local moduleExports = ModuleCache[modulePath]
    if not moduleExports then
        local resourceName, filePath = resolveModulePath(modulePath)

        ModuleLoading[modulePath] = true
        moduleExports = loadModule(resourceName, filePath)
        ModuleCache[modulePath] = moduleExports
        ModuleLoading[modulePath] = nil
    end

    return setmetatable({}, {
        __index = function(_, key)
            local value = moduleExports[key]
            if value == nil then
                error(("Key '%s' not found in module '%s'"):format(key, modulePath))
            end
            return value
        end,
        __call = function(_, ...)
            if type(moduleExports) == "function" then
                return moduleExports(...)
            else
                error(("Module '%s' is not callable"):format(modulePath))
            end
        end
    })
end

--- Import a specific part (function or table) from a module.
---@param partName string The name of the function or table to import.
---@param modulePath string The path to the module file.
---@return any The imported part (function or table).
function importPart(partName, modulePath)
    assert(type(partName) == "string", "Part name must be a string")
    assert(type(modulePath) == "string", "Module path must be a string")

    -- Charge le module complet
    local moduleExports = import(modulePath)

    -- Récupère la partie demandée (fonction ou sous-table)
    local part = moduleExports[partName]
    if not part then
        error(("Part '%s' not found in module '%s'"):format(partName, modulePath))
    end

    return part
end