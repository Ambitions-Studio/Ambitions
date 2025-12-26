--- Loads a model into memory, yielding until loaded when called from a thread
---@param model number|string Model hash or name
---@param timeout? number Timeout in milliseconds (default: 10000)
---@return number modelHash The loaded model hash
function amb.streaming.requestModel(model, timeout)
    local modelHash = type(model) == 'number' and model or joaat(model)

    if HasModelLoaded(modelHash) then
        return modelHash
    end

    if not IsModelValid(modelHash) and not IsModelInCdimage(modelHash) then
        amb.print.error(('Invalid model: %s'):format(model))
    end

    return amb.streaming.request(RequestModel, HasModelLoaded, 'model', modelHash, timeout)
end