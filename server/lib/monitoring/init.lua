local log = require("shared.lib.log.print")
local monitoringConfig = require("config.monitoring")

if not monitoringConfig.enabled then
    return {
        Logs = { Send = function() end, Debug = function() end, Info = function() end, Warn = function() end, Error = function() end, Fatal = function() end },
        Metrics = { Counter = function() end, Gauge = function() end, Histogram = function() end },
        Trace = { StartSpan = function() return "", "" end, FinishSpan = function() end, LogToSpan = function() end, SetSpanTags = function() end },
        FlushAll = function() end,
        GetQueueSizes = function() return {logs = 0, metrics = 0, traces = 0, activeTraces = 0} end
    }
end

local logQueue = {}
local metricQueue = {}
local traceQueue = {}
local activeTraces = {}

local currentConfig = monitoringConfig.deploymentType == "grafana_cloud" and monitoringConfig.grafanaCloud or monitoringConfig.grafanaOss

local BATCH_SIZE = 50
local FLUSH_INTERVAL = 5000

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

--- Flush log queue to Grafana Loki
local function flushLogQueue()
    if #logQueue == 0 or not monitoringConfig.logsEnabled then return end

    local auth = getAuthHeader()
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

--- Flush metric queue to Grafana Prometheus
local function flushMetricQueue()
    if #metricQueue == 0 or not monitoringConfig.metricsEnabled then return end

    local auth = getAuthHeader()
    local metricsText = table.concat(metricQueue, "\n") .. "\n"
    
    if monitoringConfig.debug.enabled then
        log.debug(("[Ambitions:Monitoring] Sending %d metrics to %s"):format(#metricQueue, currentConfig.endpoints.prometheus))
        log.debug(("[Ambitions:Monitoring] Metrics payload: %s"):format(metricsText:sub(1, 200)))
    end

    PerformHttpRequest(currentConfig.endpoints.prometheus, function(code, _, _)
        if code ~= 200 and code ~= 204 then
            log.warning(("[Ambitions:Monitoring] Failed to send %d metrics: HTTP %s"):format(#metricQueue, code))
        elseif monitoringConfig.debug.enabled then
            log.debug(("[Ambitions:Monitoring] Successfully sent %d metrics"):format(#metricQueue))
        end
    end, "PUT", metricsText, {
        ["Content-Type"] = "text/plain"
    })

    metricQueue = {}
end

--- Flush trace queue to Grafana Tempo/Jaeger
local function flushTraceQueue()
    if #traceQueue == 0 or not monitoringConfig.tracingEnabled then return end

    local auth = getAuthHeader()
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

--- Batch flush all queues when they reach size limit or on timer
local function flushAllQueues()
    flushLogQueue()
    flushMetricQueue()
    flushTraceQueue()
end

-- Set up periodic flush timer
CreateThread(function()
    while true do
        Wait(FLUSH_INTERVAL)
        flushAllQueues()

        if monitoringConfig.debug.printQueueStats then
            local activeTraceCount = 0
            for _ in pairs(activeTraces) do
                activeTraceCount = activeTraceCount + 1
            end

            log.info(("[Ambitions:Monitoring] Queue Stats - Logs: %d, Metrics: %d, Traces: %d, Active: %d")
                :format(#logQueue, #metricQueue, #traceQueue, activeTraceCount))
        end
    end
end)

local monitoring = {}

monitoring.Logs = {}

--- Send a structured log message to Grafana Loki with batching support
---@param message string The log message content
---@param level string The log level: "debug" | "info" | "warn" | "error" | "fatal"
---@param component string The component/service name generating the log
---@param labels table? Optional additional labels as key-value pairs
---@param metadata table? Optional metadata to include in the log
function monitoring.Logs.Send(message, level, component, labels, metadata)
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
        local sanitizedLabels = sanitizeData(labels)
        for k, v in pairs(sanitizedLabels) do
            stream[tostring(k)] = tostring(v)
        end
    end

    local logData = {
        message = message,
        metadata = metadata and sanitizeData(metadata) or nil
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
function monitoring.Logs.Debug(message, component, labels, metadata)
    monitoring.Logs.Send(message, "debug", component, labels, metadata)
end

--- Send informational log message for general application events
---@param message string The log message
---@param component string The component name
---@param labels table? Optional labels
---@param metadata table? Optional metadata
function monitoring.Logs.Info(message, component, labels, metadata)
    monitoring.Logs.Send(message, "info", component, labels, metadata)
end

--- Send warning level log message for potential issues that need attention
---@param message string The log message
---@param component string The component name
---@param labels table? Optional labels
---@param metadata table? Optional metadata
function monitoring.Logs.Warn(message, component, labels, metadata)
    monitoring.Logs.Send(message, "warn", component, labels, metadata)
end

--- Send error level log message for application errors and failures
---@param message string The log message
---@param component string The component name
---@param labels table? Optional labels
---@param metadata table? Optional metadata
function monitoring.Logs.Error(message, component, labels, metadata)
    monitoring.Logs.Send(message, "error", component, labels, metadata)
end

--- Send fatal level log message for critical errors that may cause system shutdown
---@param message string The log message
---@param component string The component name
---@param labels table? Optional labels
---@param metadata table? Optional metadata
function monitoring.Logs.Fatal(message, component, labels, metadata)
    monitoring.Logs.Send(message, "fatal", component, labels, metadata)
end

monitoring.Metrics = {}

--- Send a counter metric to Grafana Prometheus
---@param name string Metric name (must follow Prometheus naming conventions)
---@param value number The counter value to add
---@param labels table? Optional labels as key-value pairs
---@param help string? Optional help text describing the metric
function monitoring.Metrics.Counter(name, value, labels, help)
    if not monitoringConfig.metricsEnabled then return end

    local allLabels = {}
    for k, v in pairs(monitoringConfig.globalLabels) do
        allLabels[k] = v
    end

    if labels then
        local sanitizedLabels = sanitizeData(labels)
        for k, v in pairs(sanitizedLabels) do
            allLabels[k] = v
        end
    end

    local labelString = ""
    if next(allLabels) then
        local labelPairs = {}
        for k, v in pairs(allLabels) do
            local cleanValue = tostring(v):gsub(' ', '_'):gsub('"', '\\"')
            table.insert(labelPairs, string.format('%s="%s"', k, cleanValue))
        end
        labelString = "{" .. table.concat(labelPairs, ",") .. "}"
    end

    local metricLine = string.format("# HELP %s %s", name, help or "Counter metric")
    local typeLine = string.format("# TYPE %s counter", name)
    local valueLine = string.format("%s%s %s", name, labelString, tostring(value))

    table.insert(metricQueue, metricLine)
    table.insert(metricQueue, typeLine)  
    table.insert(metricQueue, valueLine)

    if #metricQueue >= BATCH_SIZE then
        flushMetricQueue()
    end
end

--- Send a gauge metric to Grafana Prometheus
---@param name string Metric name
---@param value number The gauge value
---@param labels table? Optional labels as key-value pairs
---@param help string? Optional help text describing the metric
function monitoring.Metrics.Gauge(name, value, labels, help)
    if not monitoringConfig.metricsEnabled then return end

    local allLabels = {}
    for k, v in pairs(monitoringConfig.globalLabels) do
        allLabels[k] = v
    end

    if labels then
        local sanitizedLabels = sanitizeData(labels)
        for k, v in pairs(sanitizedLabels) do
            allLabels[k] = v
        end
    end

    local labelString = ""
    if next(allLabels) then
        local labelPairs = {}
        for k, v in pairs(allLabels) do
            local cleanValue = tostring(v):gsub(' ', '_'):gsub('"', '\\"')
            table.insert(labelPairs, string.format('%s="%s"', k, cleanValue))
        end
        labelString = "{" .. table.concat(labelPairs, ",") .. "}"
    end

    local metricLine = string.format("# HELP %s %s", name, help or "Gauge metric")
    local typeLine = string.format("# TYPE %s gauge", name) 
    local valueLine = string.format("%s%s %s", name, labelString, tostring(value))

    table.insert(metricQueue, metricLine)
    table.insert(metricQueue, typeLine)
    table.insert(metricQueue, valueLine)

    if #metricQueue >= BATCH_SIZE then
        flushMetricQueue()
    end
end

--- Send a histogram metric to Grafana Prometheus
---@param name string Metric name
---@param value number The observed value
---@param buckets table Array of bucket boundaries
---@param labels table? Optional labels as key-value pairs
---@param help string? Optional help text describing the metric
function monitoring.Metrics.Histogram(name, value, buckets, labels, help)
    if not monitoringConfig.metricsEnabled then return end

    local allLabels = {}
    for k, v in pairs(monitoringConfig.globalLabels) do
        allLabels[k] = v
    end

    if labels then
        local sanitizedLabels = sanitizeData(labels)
        for k, v in pairs(sanitizedLabels) do
            allLabels[k] = v
        end
    end

    local labelString = ""
    if next(allLabels) then
        local labelPairs = {}
        for k, v in pairs(allLabels) do
            local cleanValue = tostring(v):gsub(' ', '_'):gsub('"', '\\"')
            table.insert(labelPairs, string.format('%s="%s"', k, cleanValue))
        end
        labelString = "{" .. table.concat(labelPairs, ",") .. "}"
    end

    local timestamp = os.time() * 1000
    local metricLine = string.format("# HELP %s %s", name, help or "Histogram metric")
    local typeLine = string.format("# TYPE %s histogram", name)

    table.insert(metricQueue, metricLine)
    table.insert(metricQueue, typeLine)

    local count = 0

    for _, bucket in ipairs(buckets) do
        if value <= bucket then
            count = count + 1
        end

        local bucketLine = string.format('%s_bucket{le="%s"%s} %d', name, tostring(bucket), labelString:gsub("^{", ","):gsub("}$", "}") or "", count)
        table.insert(metricQueue, bucketLine)
    end

    local infLine = string.format('%s_bucket{le="+Inf"%s} %d', name, labelString:gsub("^{", ","):gsub("}$", "}") or "", count)
    table.insert(metricQueue, infLine)

    local countLine = string.format("%s_count%s %d", name, labelString, 1)
    local sumLine = string.format("%s_sum%s %s", name, labelString, tostring(value))

    table.insert(metricQueue, countLine)
    table.insert(metricQueue, sumLine)

    if #metricQueue >= BATCH_SIZE then
        flushMetricQueue()
    end
end

monitoring.Trace = {}

--- Start a new trace span for distributed tracing
---@param operationName string Name of the operation being traced
---@param parentSpanId string? Parent span ID for nested traces
---@param traceId string? Existing trace ID to continue a trace
---@param tags table? Optional tags for the span
---@return string traceId The trace ID
---@return string spanId The span ID
function monitoring.Trace.StartSpan(operationName, parentSpanId, traceId, tags)
    if not monitoringConfig.tracingEnabled then 
        return "", ""
    end

    traceId = traceId or generateTraceId()
    local spanId = generateSpanId()
    local startTime = GetGameTimer() * 1000 -- Convert to microseconds

    local spanTags = {
        {key = "server", value = monitoringConfig.serverName},
        {key = "resource", value = GetInvokingResource() or GetCurrentResourceName()}
    }

    for k, v in pairs(monitoringConfig.globalLabels) do
        table.insert(spanTags, {key = tostring(k), value = tostring(v)})
    end

    if tags then
        local sanitizedTags = sanitizeData(tags)
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
function monitoring.Trace.FinishSpan(spanId, tags)
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
        local sanitizedTags = sanitizeData(tags)
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
function monitoring.Trace.LogToSpan(spanId, fields)
    if not monitoringConfig.tracingEnabled then return end

    local span = activeTraces[spanId]

    if not span then
        return
    end

    local logEntry = {
        timestamp = GetGameTimer() * 1000,
        fields = {}
    }

    local sanitizedFields = sanitizeData(fields)
    for k, v in pairs(sanitizedFields) do
        table.insert(logEntry.fields, {key = tostring(k), value = tostring(v)})
    end

    table.insert(span.logs, logEntry)
end

--- Add tags to an active span
---@param spanId string The span ID to add tags to
---@param tags table Key-value pairs for the tags
function monitoring.Trace.SetSpanTags(spanId, tags)
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

--- Force flush all queues immediately (useful for shutdown)
function monitoring.FlushAll()
    flushAllQueues()
end

--- Get current queue sizes for monitoring
---@return table queueSizes Table with current queue sizes
function monitoring.GetQueueSizes()
    local activeCount = 0
    for _ in pairs(activeTraces) do
        activeCount = activeCount + 1
    end

    return {
        logs = #logQueue,
        metrics = #metricQueue,
        traces = #traceQueue,
        activeTraces = activeCount
    }
end

return monitoring