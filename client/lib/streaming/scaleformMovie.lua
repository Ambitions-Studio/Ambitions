local DEFAULT_SCALEFORM_TIMEOUT <const> = 1000

--- Loads a scaleform movie into memory, yielding until loaded when called from a thread
---@param scaleformName string Scaleform movie name
---@param timeout? number Timeout in milliseconds (default: 1000)
---@return number? scaleformHandle The loaded scaleform handle or nil on error
function amb.streaming.requestScaleformMovie(scaleformName, timeout)
    if type(scaleformName) ~= 'string' then
        amb.print.error(('Invalid scaleformName type: expected string, got %s'):format(type(scaleformName)))
        return nil
    end

    local scaleformHandle = RequestScaleformMovie(scaleformName)

    return WaitUntil(function()
        if HasScaleformMovieLoaded(scaleformHandle) then
            return scaleformHandle
        end
    end, ('Failed to load scaleform: %s'):format(scaleformName), timeout or DEFAULT_SCALEFORM_TIMEOUT)
end