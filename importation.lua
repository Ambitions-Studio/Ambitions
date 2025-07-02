local CURRENT_RESOURCE = GetCurrentResourceName()
local loaded = {}
local searchPaths = {
    "?.lua",
    "?/init.lua"
}

--- Import functions via index lookup
--- @param resource string The current resource name
--- @param functionNames string|table Function name(s) to import
--- @param targetResource string The target resource name (without @)
--- @return any The imported function(s)
local function importViaIndex(resource, functionNames, targetResource)
    functionNames = type(functionNames) == "table" and functionNames or {functionNames}

    local context = IsDuplicityVersion() and 'server' or 'client'
    local indices = {}

    local sharedSuccess, sharedIndex = pcall(function()
        return importWithResource(targetResource, 'shared.index')
    end)
    if sharedSuccess then
        for funcName, modulePath in pairs(sharedIndex) do
            indices[funcName] = modulePath
        end
    end

    local contextSuccess, contextIndex = pcall(function()
        return importWithResource(targetResource, context .. '.index')
    end)
    if contextSuccess then
        for funcName, modulePath in pairs(contextIndex) do
            indices[funcName] = modulePath
        end
    end

    local results = {}
    for i, funcName in ipairs(functionNames) do
        local modulePath = indices[funcName]
        if not modulePath then
            error(("Function '%s' not found in %s registry"):format(funcName, targetResource), 2)
        end

        local moduleResult = importWithResource(targetResource, modulePath)

        if type(moduleResult) == "table" and moduleResult[funcName] then
            results[i] = moduleResult[funcName]
        elseif type(moduleResult) == "function" then
            results[i] = moduleResult
        else
            error(("Function '%s' not found in module '%s'"):format(funcName, modulePath), 2)
        end
    end

    return #results == 1 and results[1] or table.unpack(results)
end

--- Extract a specific key from a module
--- @param resource string The resource name
--- @param moduleName string The module path
--- @param keyName string The key to extract
--- @return any The extracted value
local function importWithKey(resource, moduleName, keyName)
    local mod = importWithResource(resource, moduleName)
    assert(type(mod) == "table", ("Module '%s' did not return a table"):format(moduleName))

    local part = mod[keyName]
    if part == nil then
        error(("Key '%s' not found in module '%s'"):format(keyName, moduleName), 2)
    end
    
    return part
end

--- Standard module import with caching
--- @param resource string The resource name
--- @param moduleName string The module path
--- @return any The imported module
local function importModule(resource, moduleName)
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

    local targetRes, localName = moduleName:match("^@([^%.]+)%.(.+)")
    if not targetRes then
        targetRes = resource
        localName = moduleName
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
        Import     = function(n, k) return importWithResource(targetRes, n, k) end,
        ImportJson = function(n, k) return importJsonWithResource(targetRes, n, k) end,
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

--- Loads and returns a Lua module, with caching and circular dependency detection.
--- Supports multiple syntaxes for maximum flexibility:
--- 1. Import('module.path') - Import entire module from current resource
--- 2. Import('@Resource.module.path') - Import entire module from external resource
--- 3. Import('FunctionName', '@Resource') - Import function via index
--- 4. Import({'Func1', 'Func2'}, '@Resource') - Import multiple functions via index
--- 5. Import('module.path', 'keyName') - Extract specific key from module
--- @param moduleNameOrKeys string|table Module path, function name(s), or key to extract
--- @param keyOrResource string|nil Key to extract from module OR resource name for index lookup
--- @return any importedModule The imported module, function(s), or extracted value
local function importWithResource(resource, moduleNameOrKeys, keyOrResource)
    -- Case 1: Index-based import (ImportPart style)
    if type(keyOrResource) == "string" and keyOrResource:match("^@") then
        local targetResource = keyOrResource:sub(2)
        return importViaIndex(resource, moduleNameOrKeys, targetResource)
    end

    -- Case 2: Extract key from module (old syntax)
    if type(keyOrResource) == "string" and not keyOrResource:match("^@") then
        return importWithKey(resource, moduleNameOrKeys, keyOrResource)
    end

    -- Case 3: Standard module import
    return importModule(resource, moduleNameOrKeys)
end

--- Import JSON sections via index lookup
--- @param resource string The current resource name
--- @param jsonKeys string|table JSON key(s) to import
--- @param targetResource string The target resource name (without @)
--- @return table|any The imported JSON section(s)
local function importJsonViaIndex(resource, jsonKeys, targetResource)
    jsonKeys = type(jsonKeys) == "table" and jsonKeys or {jsonKeys}

    local context = IsDuplicityVersion() and 'server' or 'client'
    local jsonIndex = nil

    local sharedSuccess, sharedIndex = pcall(importWithResource, targetResource, 'shared.index')
    if sharedSuccess and sharedIndex.Json then
        jsonIndex = sharedIndex.Json
    end

    local contextSuccess, contextIndex = pcall(importWithResource, targetResource, context .. '.index')
    if contextSuccess and contextIndex.Json then
        jsonIndex = jsonIndex or {}
        for k, v in pairs(contextIndex.Json) do
            jsonIndex[k] = v
        end
    end

    if not jsonIndex then
        error(("No Json section found in indices for resource '%s'"):format(targetResource), 2)
    end

    local results = {}
    for i, jsonKey in ipairs(jsonKeys) do
        local entry = jsonIndex[jsonKey]
        if not entry then
            error(("JSON key '%s' not found in Json index for resource '%s'"):format(jsonKey, targetResource), 2)
        end

        if type(entry) ~= "table" or not entry.file then
            error(("Invalid Json index entry for key '%s': expected table with 'file' field"):format(jsonKey), 2)
        end

        local filePath = entry.file:gsub("%.", "/") .. ".json"
        local raw = LoadResourceFile(targetResource, filePath)

        if not raw then
            error(("JSON file '%s' not found at '@%s/%s'"):format(entry.file, targetResource, filePath), 2)
        end

        local data = json.decode(raw)

        if entry.section then
            local sectionData = data[entry.section]
            if sectionData == nil then
                error(("Section '%s' not found in JSON file '%s'"):format(entry.section, entry.file), 2)
            end
            results[i] = sectionData
        else
            results[i] = data
        end
    end

    return #results == 1 and results[1] or table.unpack(results)
end

--- Import a JSON file directly
--- @param resource string The resource name
--- @param fileName string The JSON file path
--- @return table The decoded JSON content
local function importJsonFile(resource, fileName)
    local targetRes = resource

    local externalRes, localPath = fileName:match("^@([^%.]+)%.(.+)")
    if externalRes then
        targetRes = externalRes
        fileName = localPath
    end

    local filePath = fileName:gsub("%.", "/") .. ".json"
    local raw = LoadResourceFile(targetRes, filePath)

    if not raw then
        error(("JSON file '%s' not found at '@%s/%s'"):format(fileName, targetRes, filePath), 2)
    end

    return json.decode(raw)
end

--- Loads and decodes a JSON file from a resource, with optional index-based destructuring.
--- @param resource string The name of the resource to load the JSON from.
--- @param keyOrKeys string|table The key(s) to extract from the JSON index, or the file name for direct import.
--- @param indexResource string|nil The resource to use for the index (e.g. '@Ambitions').
--- @return table|any The decoded JSON content as a Lua table, or selected keys if destructuring.
local function importJsonWithResource(resource, keyOrKeys, indexResource)
    assert(type(resource) == "string", ("resource must be a string (got '%s')"):format(type(resource)))
    assert(type(keyOrKeys) == "string" or type(keyOrKeys) == "table", ("keyOrKeys must be a string or table (got '%s')"):format(type(keyOrKeys)))

    -- Case 1: Index-based import
    if type(indexResource) == "string" and indexResource:match("^@") then
        local targetResource = indexResource:sub(2)
        return importJsonViaIndex(resource, keyOrKeys, targetResource)
    end

    -- Case 2: Direct file import
    if type(keyOrKeys) == "string" then
        return importJsonFile(resource, keyOrKeys)
    end

    error("Invalid ImportJson syntax", 2)
end

--- Imports a module from the current resource.
--- Supports multiple syntaxes:
--- 1. Import('module.path') - Import entire module
--- 2. Import('@Resource.module.path') - Import from external resource
--- 3. Import('FunctionName', '@Resource') - Import via index
--- 4. Import({'Func1', 'Func2'}, '@Resource') - Import multiple via index
--- 5. Import('module.path', 'keyName') - Extract key from module
--- @param moduleNameOrKeys string|table Module path or function names
--- @param keyOrResource string|nil Key to extract or resource name
--- @return any The imported module, function(s), or value
function Import(moduleNameOrKeys, keyOrResource)
    return importWithResource(CURRENT_RESOURCE, moduleNameOrKeys, keyOrResource)
end

--- Imports a JSON file from the current resource.
--- Supports multiple syntaxes:
--- 1. ImportJson('jsonKey', '@Resource') - Import section via index
--- 2. ImportJson({'key1', 'key2'}, '@Resource') - Import multiple sections
--- 3. ImportJson('path.to.file') - Import entire JSON file (local)
--- 4. ImportJson('@Resource.path.to.file') - Import entire JSON file (external)
--- @param keyOrKeys string|table The key(s) to extract from the JSON index, or the file name for direct import.
--- @param indexResource string|nil The resource to use for the index (e.g. '@Ambitions').
--- @return table decodedJson The decoded JSON content.
function ImportJson(keyOrKeys, indexResource)
    return importJsonWithResource(CURRENT_RESOURCE, keyOrKeys, indexResource)
end