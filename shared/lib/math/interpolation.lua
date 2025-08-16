--- Interpolate between two numeric values using linear interpolation formula
---@param from number The starting numeric value
---@param to number The target numeric value  
---@param alpha number Progress value between 0 and 1
---@return number result The interpolated numeric value
local function interpolateNumber(from, to, alpha)
  return from + (to - from) * alpha
end

--- Interpolate between two vector values based on vector type
---@param from vector2|vector3|vector4 The starting vector value
---@param to vector2|vector3|vector4 The target vector value
---@param alpha number Progress value between 0 and 1
---@return vector2|vector3|vector4|nil result The interpolated vector value or nil if unsupported type
local function interpolateVector(from, to, alpha)
  local vectorType = type(from)

  if vectorType == 'vector2' then
    return vector2(
      interpolateNumber(from.x, to.x, alpha),
      interpolateNumber(from.y, to.y, alpha)
    )
  elseif vectorType == 'vector3' then
    return vector3(
      interpolateNumber(from.x, to.x, alpha),
      interpolateNumber(from.y, to.y, alpha),
      interpolateNumber(from.z, to.z, alpha)
    )
  elseif vectorType == 'vector4' then
    return vector4(
      interpolateNumber(from.x, to.x, alpha),
      interpolateNumber(from.y, to.y, alpha),
      interpolateNumber(from.z, to.z, alpha),
      interpolateNumber(from.w, to.w, alpha)
    )
  end
end

--- Interpolate between two table values recursively
---@param from table The starting table value
---@param to table The target table value
---@param alpha number Progress value between 0 and 1
---@return table result The interpolated table with mixed values
local function interpolateTable(from, to, alpha)
  local result = {}

  for key, fromValue in pairs(from) do
    local toValue = to[key]

    if toValue and type(fromValue) == 'number' and type(toValue) == 'number' then
      result[key] = interpolateNumber(fromValue, toValue, alpha)
    elseif toValue and type(fromValue) == 'table' and type(toValue) == 'table' then
      result[key] = interpolateTable(fromValue, toValue, alpha)
    else
      result[key] = alpha < 0.5 and fromValue or toValue
    end
  end

  return result
end

local ambitionsInterpolation = {}

--- Create an interpolation iterator between two values over time
---@generic T : number | table | vector2 | vector3 | vector4
---@param startValue T The starting value
---@param endValue T The target value  
---@param duration number Duration in milliseconds
---@return function iterator Iterator returning current value and progress
function ambitionsInterpolation.create(startValue, endValue, duration)
  local startTime = nil
  local progress = 0

  local interpolate
  local valueType = type(startValue)

  if valueType == 'number' then
    interpolate = interpolateNumber
  elseif valueType == 'table' then
    interpolate = interpolateTable
  else
    interpolate = interpolateVector
  end

  return function()
    local FRAME_TIME <const> = 0

    if not startTime then
      startTime = GetGameTimer()
      return startValue, 0
    end

    progress = math.min((GetGameTimer() - startTime) / duration, 1)

    if progress >= 1 then
      return endValue, 1
    end

    Wait(FRAME_TIME)

    return interpolate(startValue, endValue, progress), progress
  end
end

--- Get interpolated value at specific progress point
---@generic T : number | table | vector2 | vector3 | vector4
---@param startValue T The starting value
---@param endValue T The target value
---@param progress number Progress value between 0 and 1
---@return T result The interpolated value
function ambitionsInterpolation.valueAt(startValue, endValue, progress)
  progress = math.max(0, math.min(1, progress))

  local valueType = type(startValue)

  if valueType == 'number' then
    return interpolateNumber(startValue, endValue, progress)
  elseif valueType == 'table' then
    return interpolateTable(startValue, endValue, progress)
  else
    return interpolateVector(startValue, endValue, progress)
  end
end

return ambitionsInterpolation