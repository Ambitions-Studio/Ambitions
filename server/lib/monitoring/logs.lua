local log = require("shared.lib.log.print")
local monitoringConfig = require("config.monitoring")
local utils = require("server.lib.monitoring.utils")

local logQueue = {}

local BATCH_SIZE = 50

--- Flush log queue to Grafana Loki
local function flushLogQueue()
    if #logQueue == 0 or not monitoringConfig.logsEnabled then return end

    local currentConfig = monitoringConfig.deploymentType == "grafana_cloud" and monitoringConfig.grafanaCloud or monitoringConfig.grafanaOss
    local auth = utils.getAuthHeader()
    local streams = {}

    for _, logEntry in ipairs(logQueue) do
        table.insert(streams, {
            stream = logEntry.stream,
            values = {logEntry.values}
        })
    end

    local payload = json.encode({streams = streams})

    if monitoringConfig.debug.enabled then
        log.debug(("[Ambitions:Monitoring] Sending %d logs to %s"):format(#logQueue, currentConfig.endpoints.loki))
    end

    PerformHttpRequest(currentConfig.endpoints.loki, function(code, _, _)
        if code ~= 204 then
            log.warning(("[Ambitions:Monitoring] Failed to send %d logs: HTTP %s"):format(#logQueue, code))
        elseif monitoringConfig.debug.enabled then
            log.debug(("[Ambitions:Monitoring] Successfully sent %d logs"):format(#logQueue))
        end
    end, "POST", payload, {
        ["Authorization"] = auth,
        ["Content-Type"] = "application/json"
    })

    logQueue = {}
end

--- Send a structured log message to Grafana Loki with batching support
---@param message string The log message content
---@param level string The log level: "debug" | "info" | "warn" | "error" | "fatal"
---@param component string The component/service name generating the log
---@param labels table? Optional additional labels as key-value pairs
---@param metadata table? Optional metadata to include in the log
local function sendLog(message, level, component, labels, metadata)
    if not monitoringConfig.logsEnabled then return end

    local validLevels = {debug=true, info=true, warn=true, error=true, fatal=true}
    level = validLevels[level] and level or "info"

    local timestamp = tostring(os.time() * 1000000000)

    local stream = {
        job = "fivem-ambitions",
        level = level,
        component = tostring(component or "unknown"),
        server = monitoringConfig.serverName,
        resource = GetInvokingResource() or GetCurrentResourceName()
    }

    for k, v in pairs(monitoringConfig.globalLabels) do
        stream[tostring(k)] = tostring(v)
    end

    if labels then
        local sanitizedLabels = utils.sanitizeData(labels)
        for k, v in pairs(sanitizedLabels) do
            stream[tostring(k)] = tostring(v)
        end
    end

    local logData = {
        message = message,
        metadata = metadata and utils.sanitizeData(metadata) or nil
    }

    local logEntry = {
        stream = stream,
        values = {timestamp, json.encode(logData)}
    }

    table.insert(logQueue, logEntry)

    if #logQueue >= BATCH_SIZE then
        flushLogQueue()
    end
end

--- Send debug level log message for development and troubleshooting
---@param message string The log message
---@param component string The component name  
---@param labels table? Optional labels
---@param metadata table? Optional metadata
local function debugLog(message, component, labels, metadata)
    sendLog(message, "debug", component, labels, metadata)
end

--- Send informational log message for general application events
---@param message string The log message
---@param component string The component name
---@param labels table? Optional labels
---@param metadata table? Optional metadata
local function infoLog(message, component, labels, metadata)
    sendLog(message, "info", component, labels, metadata)
end

--- Send warning level log message for potential issues that need attention
---@param message string The log message
---@param component string The component name
---@param labels table? Optional labels
---@param metadata table? Optional metadata
local function warnLog(message, component, labels, metadata)
    sendLog(message, "warn", component, labels, metadata)
end

--- Send error level log message for application errors and failures
---@param message string The log message
---@param component string The component name
---@param labels table? Optional labels
---@param metadata table? Optional metadata
local function errorLog(message, component, labels, metadata)
    sendLog(message, "error", component, labels, metadata)
end

--- Send fatal level log message for critical errors that may cause system shutdown
---@param message string The log message
---@param component string The component name
---@param labels table? Optional labels
---@param metadata table? Optional metadata
local function fatalLog(message, component, labels, metadata)
    sendLog(message, "fatal", component, labels, metadata)
end

--- Get current log queue size for monitoring
---@return number size The current log queue size
local function getQueueSize()
    return #logQueue
end

return {
    Send = sendLog,
    Debug = debugLog,
    Info = infoLog,
    Warn = warnLog,
    Error = errorLog,
    Fatal = fatalLog,
    Flush = flushLogQueue,
    GetQueueSize = getQueueSize
}