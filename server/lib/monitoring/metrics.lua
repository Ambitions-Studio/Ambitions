local log = require("shared.lib.log.print")
local monitoringConfig = require("config.monitoring")
local utils = require("server.lib.monitoring.utils")

local metricQueue = {}

local BATCH_SIZE = 50

--- Flush metric queue to Grafana Prometheus
local function flushMetricQueue()
    if #metricQueue == 0 or not monitoringConfig.metricsEnabled then return end

    local currentConfig = monitoringConfig.deploymentType == "grafana_cloud" and monitoringConfig.grafanaCloud or monitoringConfig.grafanaOss
    local auth = utils.getAuthHeader()
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

--- Send a counter metric to Grafana Prometheus
---@param name string Metric name (must follow Prometheus naming conventions)
---@param value number The counter value to add
---@param labels table? Optional labels as key-value pairs
---@param help string? Optional help text describing the metric
local function sendCounter(name, value, labels, help)
    if not monitoringConfig.metricsEnabled then return end

    local allLabels = {}
    for k, v in pairs(monitoringConfig.globalLabels) do
        allLabels[k] = v
    end

    if labels then
        local sanitizedLabels = utils.sanitizeData(labels)
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
local function sendGauge(name, value, labels, help)
    if not monitoringConfig.metricsEnabled then return end

    local allLabels = {}
    for k, v in pairs(monitoringConfig.globalLabels) do
        allLabels[k] = v
    end

    if labels then
        local sanitizedLabels = utils.sanitizeData(labels)
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
local function sendHistogram(name, value, buckets, labels, help)
    if not monitoringConfig.metricsEnabled then return end

    local allLabels = {}
    for k, v in pairs(monitoringConfig.globalLabels) do
        allLabels[k] = v
    end

    if labels then
        local sanitizedLabels = utils.sanitizeData(labels)
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

--- Get current metric queue size for monitoring
---@return number size The current metric queue size
local function getQueueSize()
    return #metricQueue
end

return {
    Counter = sendCounter,
    Gauge = sendGauge,
    Histogram = sendHistogram,
    Flush = flushMetricQueue,
    GetQueueSize = getQueueSize
}