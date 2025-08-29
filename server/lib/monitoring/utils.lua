local monitoringConfig = require("config.monitoring")

--- Encodes a string to base64 for HTTP basic authentication
---@param input string The string to encode
---@return string encoded The base64 encoded string
local function base64Encode(input)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((input:gsub('.', function(x)
        local r, bIndex = '', x:byte()
        for i = 8, 1, -1 do 
            r = r .. (bIndex % 2 ^ i - bIndex % 2 ^ (i - 1) > 0 and '1' or '0') 
        end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c = 0
        for i = 1, 6 do 
            c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) 
        end
        return b:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#input % 3 + 1])
end

--- Sanitize sensitive data from a table
---@param data table The data to sanitize
---@return table sanitized The sanitized data
local function sanitizeData(data)
    if not monitoringConfig.security.sanitizeData then
        return data
    end

    local sanitized = {}

    for k, v in pairs(data) do
        local keyStr = tostring(k):lower()
        local shouldRedact = false

        for _, sensitiveField in ipairs(monitoringConfig.security.sensitiveFields) do
            if keyStr:find(sensitiveField:lower()) then
                shouldRedact = true
                break
            end
        end

        sanitized[k] = shouldRedact and monitoringConfig.security.redactionPlaceholder 
                      or (type(v) == "table" and sanitizeData(v) or v)
    end

    return sanitized
end

--- Get authentication header based on deployment type and config
---@return string auth The authorization header
local function getAuthHeader()
    local currentConfig = monitoringConfig.deploymentType == "grafana_cloud" and monitoringConfig.grafanaCloud or monitoringConfig.grafanaOss

    if monitoringConfig.deploymentType == "grafana_cloud" then
        return "Basic " .. base64Encode(currentConfig.instanceId .. ":" .. currentConfig.apiKey)
    else
        if monitoringConfig.grafanaOss.authMethod == "basic" then
            return "Basic " .. base64Encode(monitoringConfig.grafanaOss.username .. ":" .. monitoringConfig.grafanaOss.password)
        elseif monitoringConfig.grafanaOss.authMethod == "service_account" then
            return "Bearer " .. monitoringConfig.grafanaOss.serviceAccountToken
        else
            return "Bearer " .. (monitoringConfig.grafanaOss.apiKey or "")
        end
    end
end

--- Generate unique trace ID for distributed tracing
---@return string traceId Unique trace identifier
local function generateTraceId()
    return string.format("%016x%016x", math.random(0, 2^32-1), math.random(0, 2^32-1))
end

--- Generate unique span ID for tracing spans
---@return string spanId Unique span identifier
local function generateSpanId()
    return string.format("%016x", math.random(0, 2^32-1))
end

return {
    base64Encode = base64Encode,
    sanitizeData = sanitizeData,
    getAuthHeader = getAuthHeader,
    generateTraceId = generateTraceId,
    generateSpanId = generateSpanId
}