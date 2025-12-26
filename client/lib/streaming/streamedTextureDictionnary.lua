--- Loads a texture dictionary into memory, yielding until loaded when called from a thread
---@param textureDict string Texture dictionary name
---@param timeout? number Timeout in milliseconds (default: 10000)
---@return string textureDict The loaded texture dictionary name
function amb.streaming.requestTextureDict(textureDict, timeout)
    if HasStreamedTextureDictLoaded(textureDict) then
        return textureDict
    end

    if type(textureDict) ~= 'string' then
        amb.print.error(('Invalid textureDict type: expected string, got %s'):format(type(textureDict)))
        return textureDict
    end

    return amb.streaming.request(RequestStreamedTextureDict, HasStreamedTextureDictLoaded, 'textureDict', textureDict, timeout)
end