--- Round a number to a specified number of decimal places
---@param number number The number to round
---@param decimalPlaces number The number of decimal places to round to
---@return number number The rounded number
function ABT.Math.Round(number, decimalPlaces)
    if decimalPlaces then
        local power = 10 ^ decimalPlaces

        return math.floor((number * power) + 0.5) / power
    else
        return math.floor(number + 0.5)
    end
end

return ABT.Math.Round