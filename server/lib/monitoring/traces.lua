local log = require("shared.lib.log.print")
local monitoringConfig = require("config.monitoring")
local utils = require("server.lib.monitoring.utils")

local traceQueue = {}
local activeTraces = {}

local BATCH_SIZE = 50

--- Flush trace queue to Grafana Tempo/Jaeger
local function flushTraceQueue()
    if #traceQueue == 0 or not monitoringConfig.tracingEnabled then return end

    local currentConfig = monitoringConfig.deploymentType == "grafana_cloud" and monitoringConfig.grafanaCloud or monitoringConfig.grafanaOss
    local auth = utils.getAuthHeader()
    local payload = json.encode({spans = traceQueue})

    if monitoringConfig.debug.enabled then
        log.debug(("[Ambitions:Monitoring] Sending %d traces to %s"):format(#traceQueue, currentConfig.endpoints.tempo))
    end

    PerformHttpRequest(currentConfig.endpoints.tempo, function(code, _, _)
        if code ~= 200 and code ~= 202 then
            log.warning(("[Ambitions:Monitoring] Failed to send %d traces: HTTP %s"):format(#traceQueue, code))
        elseif monitoringConfig.debug.enabled then
            log.debug(("[Ambitions:Monitoring] Successfully sent %d traces"):format(#traceQueue))
        end
    end, "POST", payload, {
        ["Authorization"] = auth,
        ["Content-Type"] = "application/json"
    })

    traceQueue = {}
end

--- Start a new trace span for distributed tracing
---@param operationName string Name of the operation being traced
---@param parentSpanId string? Parent span ID for nested traces
---@param traceId string? Existing trace ID to continue a trace
---@param tags table? Optional tags for the span
---@return string traceId The trace ID
---@return string spanId The span ID
local function startSpan(operationName, parentSpanId, traceId, tags)
    if not monitoringConfig.tracingEnabled then 
        return "", ""
    end

    traceId = traceId or utils.generateTraceId()
    local spanId = utils.generateSpanId()
    local startTime = GetGameTimer() * 1000 -- Convert to microseconds

    local spanTags = {
        {key = "server", value = monitoringConfig.serverName},
        {key = "resource", value = GetInvokingResource() or GetCurrentResourceName()}
    }

    for k, v in pairs(monitoringConfig.globalLabels) do
        table.insert(spanTags, {key = tostring(k), value = tostring(v)})
    end

    if tags then
        local sanitizedTags = utils.sanitizeData(tags)
        for k, v in pairs(sanitizedTags) do
            table.insert(spanTags, {key = tostring(k), value = tostring(v)})
        end
    end

    local span = {
        traceID = traceId,
        spanID = spanId,
        parentSpanID = parentSpanId,
        operationName = operationName,
        startTime = startTime,
        tags = spanTags,
        logs = {},
        process = {
            serviceName = "fivem-ambitions",
            tags = {
                {key = "server", value = monitoringConfig.serverName},
                {key = "resource", value = GetInvokingResource() or GetCurrentResourceName()}
            }
        }
    }

    activeTraces[spanId] = span
    return traceId, spanId
end

--- Finish a trace span and send it to Grafana Jaeger
---@param spanId string The span ID to finish
---@param tags table? Additional tags to add before finishing
local function finishSpan(spanId, tags)
    if not monitoringConfig.tracingEnabled then return end

    local span = activeTraces[spanId]

    if not span then
        if monitoringConfig.debug.enabled then
            log.warning(("[Ambitions:Monitoring] Attempted to finish unknown span: %s"):format(spanId))
        end

        return
    end

    span.duration = (GetGameTimer() * 1000) - span.startTime

    if tags then
        local sanitizedTags = utils.sanitizeData(tags)
        for k, v in pairs(sanitizedTags) do
            table.insert(span.tags, {key = tostring(k), value = tostring(v)})
        end
    end

    table.insert(traceQueue, span)
    activeTraces[spanId] = nil

    if #traceQueue >= BATCH_SIZE then
        flushTraceQueue()
    end
end

--- Add a log entry to an active span
---@param spanId string The span ID to add log to
---@param fields table Key-value pairs for the log entry
local function logToSpan(spanId, fields)
    if not monitoringConfig.tracingEnabled then return end

    local span = activeTraces[spanId]

    if not span then
        return
    end

    local logEntry = {
        timestamp = GetGameTimer() * 1000,
        fields = {}
    }

    local sanitizedFields = utils.sanitizeData(fields)
    for k, v in pairs(sanitizedFields) do
        table.insert(logEntry.fields, {key = tostring(k), value = tostring(v)})
    end

    table.insert(span.logs, logEntry)
end

--- Add tags to an active span
---@param spanId string The span ID to add tags to
---@param tags table Key-value pairs for the tags
local function setSpanTags(spanId, tags)
    if not monitoringConfig.tracingEnabled then return end

    local span = activeTraces[spanId]

    if not span then
        return
    end

    local sanitizedTags = sanitizeData(tags)
    for k, v in pairs(sanitizedTags) do
        table.insert(span.tags, {key = tostring(k), value = tostring(v)})
    end
end

--- Get current trace queue size and active traces count for monitoring
---@return table queueSizes Table with current trace queue size and active traces count
local function getQueueSizes()
    local activeCount = 0
    for _ in pairs(activeTraces) do
        activeCount = activeCount + 1
    end

    return {
        traces = #traceQueue,
        activeTraces = activeCount
    }
end

return {
    StartSpan = startSpan,
    FinishSpan = finishSpan,
    LogToSpan = logToSpan,
    SetSpanTags = setSpanTags,
    Flush = flushTraceQueue,
    GetQueueSizes = getQueueSizes
}