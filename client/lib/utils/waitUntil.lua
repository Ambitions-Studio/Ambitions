local DEFAULT_TIMEOUT <const> = 1000

--- Waits until the callback function returns a non-nil value, with optional timeout
---@generic T
---@param callback fun(): T? Function that returns a value or nil
---@param errorMessage? string Custom error message on timeout
---@param timeoutMs? number|false Timeout in milliseconds (default: 1000, false = no timeout)
---@return T
---@async
function WaitUntil(callback, errorMessage, timeoutMs)
    local result = callback()
    if result ~= nil then
        return result
    end

    local hasTimeout = timeoutMs ~= false
    local maxWait = type(timeoutMs) == 'number' and timeoutMs or DEFAULT_TIMEOUT
    local startTime = hasTimeout and GetGameTimer() or 0

    repeat
        Wait(0)
        result = callback()

        if hasTimeout then
            local elapsed = GetGameTimer() - startTime
            if elapsed > maxWait then
                error(('%s (timeout after %dms)'):format(errorMessage or 'WaitUntil timeout', elapsed), 2)
            end
        end
    until result ~= nil

    return result
end