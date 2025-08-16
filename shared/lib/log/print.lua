local LOG_LEVELS = {
    info    = { label = 'INFO',    color = '^4' },
    success = { label = 'SUCCESS', color = '^2' },
    error   = { label = 'ERROR',   color = '^1' },
    warning = { label = 'WARN',    color = '^3' },
    debug   = { label = 'DEBUG',   color = '^9' },
}

--- Serialize a value into a string representation for printing.
---@param value any The value to serialize.
---@param level? number The current indentation level (used recursively).
---@param seen? table A table to track already serialized tables.
---@return string The serialized string representation of the value.
local function serialize(value, level, seen)
    level = level or 0
    seen = seen or {}
    local valueType = type(value)
    local spacing = string.rep('  ', level)

    if valueType == 'string' then
        return value
    elseif valueType == 'number' or valueType == 'boolean' then
        return tostring(value)
    elseif valueType == 'table' then
        if seen[value] then
            return '<circular reference>'
        end

        seen[value] = true
        local out = '{\n'

        for k, v in pairs(value) do
            local keyStr = serialize(k, 0, seen)
            local valStr = serialize(v, level + 1, seen)
            out = out .. spacing .. '  [' .. keyStr .. '] = ' .. valStr .. ',\n'
        end

        if out:sub(-2) == ',\n' then
            out = out:sub(1, -3) .. '\n'
        end

        out = out .. spacing .. '}'

        return out
    elseif valueType == 'function' then
        return '<function: ' .. tostring(value) .. '>'
    elseif valueType == 'nil' then
        return 'nil'
    else
        return '<' .. valueType .. ': ' .. tostring(value) .. '>'
    end
end

--- Print a log message to the console at a given level.
---@param level 'info'|'success'|'error'|'warning'|'debug' The log level.
---@vararg any The message(s) or variable(s) to print.
local function print_log(level, ...)
    local args = { ... }
    local out = {}

    for i = 1, #args do
        out[#out+1] = serialize(args[i], 0)
    end

    local lvl = LOG_LEVELS[level] or LOG_LEVELS.info

    print(("%s[%s]^7: %s"):format(lvl.color, lvl.label, table.concat(out, ' ')))
end

local log = {}

--- Print an info log message.
---@vararg any The message(s) or variable(s) to print.
function log.info(...)
    print_log('info', ...)
end

--- Print a success log message.
---@vararg any The message(s) or variable(s) to print.
function log.success(...)
    print_log('success', ...)
end

--- Print an error log message and throw a Lua error with stack trace.
---@vararg any The message(s) or variable(s) to print.
function log.error(...)
    local args = { ... }
    local out = {}

    for i = 1, #args do
        out[#out+1] = serialize(args[i], 0)
    end

    local errorMessage = table.concat(out, ' ')
    local lvl = LOG_LEVELS.error

    print(("%s[%s]^7: %s"):format(lvl.color, lvl.label, errorMessage))

    error(errorMessage, 2)
end

--- Print a warning log message.
---@vararg any The message(s) or variable(s) to print.
function log.warning(...)
    print_log('warning', ...)
end

--- Print a debug log message.
---@vararg any The message(s) or variable(s) to print.
function log.debug(...)
    print_log('debug', ...)
end

return log