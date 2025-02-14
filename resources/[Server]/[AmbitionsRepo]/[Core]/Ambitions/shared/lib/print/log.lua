--- Print a log message to the console with support for multiple levels and arguments.
---@alias LogLevel number
---| 1 INFO
---| 2 SUCCESS
---| 3 ERROR
---| 4 WARN
---| 5 DEBUG

local LOG_LEVELS <const> = {
    [1] = { label = 'INFO', color = '^4' },
    [2] = { label = 'SUCCESS', color = '^2' },
    [3] = { label = 'ERROR', color = '^1' },
    [4] = { label = 'WARN', color = '^3' },
    [5] = { label = 'DEBUG', color = '^9' },
}

--- Serialize a value into a string representation for printing.
---@param value any The value to serialize.
---@param level? number The current indentation level (used recursively).
---@param seen? table A table to track already serialized tables.
---@return string The serialized string representation of the value.
local function Serialize(value, level, seen)
    level = level or 0
    seen = seen or {}

    local valueType = type(value)
    local SPACING <const> = string.rep('  ', level)

    if valueType == 'string' then
        return value
    elseif valueType == 'number' or valueType == 'boolean' then
        return tostring(value)
    elseif valueType == 'table' then
        if seen[value] then
            return '<circular reference>'
        end
        seen[value] = true

        local serializedTable = '{\n'

        for k, v in pairs(value) do
            local serializedKey = Serialize(k, 0, seen)
            local serializedValue = Serialize(v, level + 1, seen)

            serializedTable = serializedTable .. SPACING .. '  [' .. serializedKey .. '] = ' .. serializedValue .. ',\n'
        end

        serializedTable = serializedTable:sub(1, -3) .. '\n' .. SPACING .. '}'

        return serializedTable
    elseif valueType == 'function' then
        return ('<function: %s>'):format(tostring(value))
    elseif valueType == 'nil' then
        return 'nil'
    else
        return ('<%s: %s>'):format(valueType, tostring(value))
    end
end

--- Print a log message to the console.
---@param level LogLevel The level of the log (1 = INFO, 2 = WARN, 3 = ERROR, 4 = DEBUG).
---@vararg any The message(s) or variable(s) to print.
function ABT.Print.Log(level, ...)
    local INVOKING_RESOURCE <const> = GetInvokingResource()
    local RESOURCE_NAME <const> = INVOKING_RESOURCE and INVOKING_RESOURCE:upper() or 'UNKNOWN RESOURCE'
    local args = { ... }

    local LEVEL_DETAILS <const> = LOG_LEVELS[level] or LOG_LEVELS[1]

    local serializedArgs = {}

    for _, arg in ipairs(args) do
        table.insert(serializedArgs, Serialize(arg, 0))
    end

    local logMessage = table.concat(serializedArgs, ' ')

    print(('[^6%s] %s[%s] ^5: %s^7'):format(RESOURCE_NAME, LEVEL_DETAILS.color, LEVEL_DETAILS.label, logMessage))
end

return ABT.Print.Log