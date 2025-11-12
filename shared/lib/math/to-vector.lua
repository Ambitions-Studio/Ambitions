--- Apply number constraints and rounding
---@param value number The value to process
---@param min? number Minimum allowed value
---@param max? number Maximum allowed value  
---@param round? boolean|number If true, rounds to integers; if number, rounds to that many decimals
---@return number processed The processed value
local function processNumber(value, min, max, round)
  local num = tonumber(value)

  if not num then
    error(("Invalid value '%s' cannot be converted to a number"):format(tostring(value)), 2)
  end

  if min and num < min then num = min end
  if max and num > max then num = max end

  if round then
    if type(round) == "number" then
      local power = 10 ^ round

      num = math.floor(num * power + 0.5) / power
    else
      num = math.floor(num + 0.5)
    end
  end

  return num
end

--- Process array of numbers with constraints
---@param numbers number[] Array of numbers to process
---@param min? number Minimum allowed value
---@param max? number Maximum allowed value
---@param round? boolean|number Rounding option
---@return number[] processed Array of processed numbers
local function processNumberArray(numbers, min, max, round)
  local processed = {}

  for i, value in ipairs(numbers) do
    processed[i] = processNumber(value, min, max, round)
  end

  return processed
end

--- Create vector from component count
---@param components number[] Array of numeric components
---@return vector2|vector3|vector4|number result The appropriate vector type or single number
local function createVector(components)
  local count = #components

  if count == 4 then
    return vector4(components[1], components[2], components[3], components[4])
  elseif count == 3 then
    return vector3(components[1], components[2], components[3])
  elseif count == 2 then
    return vector2(components[1], components[2])
  elseif count == 1 then
    return components[1] + 0.0
  else
    error("Invalid number of components: expected 1-4, got " .. count, 2)
  end
end

--- Convert input to appropriate vector type
---@param input string|table The input to convert (string with delimiters or table/array)
---@param min? number Minimum allowed value for each component
---@param max? number Maximum allowed value for each component
---@param round? boolean|number If true, rounds to integers; if number, rounds to that many decimals
---@return vector2|vector3|vector4|number result The converted vector or single number
function amb.math.convertToVector(input, min, max, round)
  local inputType = type(input)

  if inputType == "string" then
    local scalars = amb.math.parseScalarsAuto(input)

    if #scalars == 0 then
      error("No valid components found in the input string", 2)
    end

    local processed = processNumberArray(scalars, min, max, round)

    return createVector(processed)

  elseif inputType == "table" then
    local components = {}

    if #input > 0 then
      for i = 1, #input do
        components[i] = input[i]
      end
    else
      if input.x then components[1] = input.x end
      if input.y then components[2] = input.y end
      if input.z then components[3] = input.z end
      if input.w then components[4] = input.w end
    end

    if #components == 0 then
      error("No valid components found in the input table", 2)
    end

    local processed = processNumberArray(components, min, max, round)

    return createVector(processed)

  else
    error(("Cannot convert '%s' to a vector value"):format(inputType), 2)
  end
end

--- Convert input to vector2 specifically
---@param input string|table The input to convert
---@param min? number Minimum allowed value for each component
---@param max? number Maximum allowed value for each component
---@param round? boolean|number Rounding option
---@return vector2 result The converted vector2
function amb.math.convertToVector2(input, min, max, round)
  local result = amb.math.convertToVector(input, min, max, round)

  if type(result) == "vector2" then
    return result
  elseif type(result) == "number" then
    return vector2(result, result)
  else
    error("Input does not contain exactly 2 components for vector2", 2)
  end
end

--- Convert input to vector3 specifically
---@param input string|table The input to convert
---@param min? number Minimum allowed value for each component
---@param max? number Maximum allowed value for each component
---@param round? boolean|number Rounding option
---@return vector3 result The converted vector3
function amb.math.convertToVector3(input, min, max, round)
  local result = amb.math.convertToVector(input, min, max, round)

  if type(result) == "vector3" then
    return result
  elseif type(result) == "vector2" then
    return vector3(result.x, result.y, 0)
  elseif type(result) == "number" then
    return vector3(result, result, result)
  else
    error("Input does not contain exactly 3 components for vector3", 2)
  end
end

--- Convert input to vector4 specifically
---@param input string|table The input to convert
---@param min? number Minimum allowed value for each component
---@param max? number Maximum allowed value for each component
---@param round? boolean|number Rounding option
---@return vector4 result The converted vector4
function amb.math.convertToVector4(input, min, max, round)
  local result = amb.math.convertToVector(input, min, max, round)

  if type(result) == "vector4" then
    return result
  elseif type(result) == "vector3" then
    return vector4(result.x, result.y, result.z, 0)
  elseif type(result) == "vector2" then
    return vector4(result.x, result.y, 0, 0)
  elseif type(result) == "number" then
    return vector4(result, result, result, result)
  else
    error("Input does not contain exactly 4 components for vector4", 2)
  end
end