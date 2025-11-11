local logQueue = {}

local BATCH_SIZE = 50

--- Flush log queue to Grafana Loki
function amb.grafana.flushLogQueue()
    if #logQueue == 0 or not monitoringConfig.logsEnabled then return end

    local currentConfig = monitoringConfig.deploymentType == "grafana_cloud" and monitoringConfig.grafanaCloud or monitoringConfig.grafanaOss
    local auth = getGrafanaAuthHeader()
    local streams = {}

    for _, logEntry in ipairs(logQueue) do
        table.insert(streams, {
            stream = logEntry.stream,
            values = {logEntry.values}
        })
    end

    local payload = json.encode({streams = streams})

    if monitoringConfig.debug.enabled then
        amb.print.debug(("[Ambitions:Monitoring] Sending %d logs to %s"):format(#logQueue, currentConfig.endpoints.loki))
    end

    PerformHttpRequest(currentConfig.endpoints.loki, function(code, _, _)
        if code ~= 204 then
            amb.print.warning(("[Ambitions:Monitoring] Failed to send %d logs: HTTP %s"):format(#logQueue, code))
        elseif monitoringConfig.debug.enabled then
            amb.print.debug(("[Ambitions:Monitoring] Successfully sent %d logs"):format(#logQueue))
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
function amb.grafana.sendLog(message, level, component, labels, metadata)
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
        local sanitizedLabels = sanitizeGrafanaData(labels)
        for k, v in pairs(sanitizedLabels) do
            stream[tostring(k)] = tostring(v)
        end
    end

    local logData = {
        message = message,
        metadata = metadata and sanitizeGrafanaData(metadata) or nil
    }

    local logEntry = {
        stream = stream,
        values = {timestamp, json.encode(logData)}
    }

    table.insert(logQueue, logEntry)

    if #logQueue >= BATCH_SIZE then
        amb.grafana.flushLogQueue()
    end
end

--- Send debug level log message for development and troubleshooting
---@param message string The log message
---@param component string The component name  
---@param labels table? Optional labels
---@param metadata table? Optional metadata
function amb.grafana.debugLog(message, component, labels, metadata)
    amb.grafana.sendLog(message, "debug", component, labels, metadata)
end

--- Send informational log message for general application events
---@param message string The log message
---@param component string The component name
---@param labels table? Optional labels
---@param metadata table? Optional metadata
function amb.grafana.infoLog(message, component, labels, metadata)
    amb.grafana.sendLog(message, "info", component, labels, metadata)
end

--- Send warning level log message for potential issues that need attention
---@param message string The log message
---@param component string The component name
---@param labels table? Optional labels
---@param metadata table? Optional metadata
function amb.grafana.warnLog(message, component, labels, metadata)
    amb.grafana.sendLog(message, "warn", component, labels, metadata)
end

--- Send error level log message for application errors and failures
---@param message string The log message
---@param component string The component name
---@param labels table? Optional labels
---@param metadata table? Optional metadata
function amb.grafana.errorLog(message, component, labels, metadata)
    amb.grafana.sendLog(message, "error", component, labels, metadata)
end

--- Send fatal level log message for critical errors that may cause system shutdown
---@param message string The log message
---@param component string The component name
---@param labels table? Optional labels
---@param metadata table? Optional metadata
function amb.grafana.fatalLog(message, component, labels, metadata)
    amb.grafana.sendLog(message, "fatal", component, labels, metadata)
end

--- Get current log queue size for monitoring
---@return number size The current log queue size
function amb.grafana.getLogsQueueSize()
    return #logQueue
end