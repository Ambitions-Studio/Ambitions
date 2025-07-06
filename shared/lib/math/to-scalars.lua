local COMMON_SEPARATORS <const> = { ",", " ", ";", "|", ":", "\t" }
local VECTOR_PATTERN <const> = "^%s*(.-)%s*$"

--- Trim whitespace from string
---@param str string The string to trim
---@return string trimmed The trimmed string
local function trimString(str)
  return str:match(VECTOR_PATTERN) or str
end

--- Parse string with specific separator
---@param input string The input string to parse
---@param separator string The separator to use for splitting
---@return number[] scalars Array of parsed scalar values
local function parseWithSeparator(input, separator)
  local scalars = {}
  local trimmedInput = trimString(input)

  if trimmedInput == "" then
    return scalars
  end

  for part in string.gmatch(trimmedInput, "[^" .. separator .. "]+") do
    local trimmedPart = trimString(part)
    local number = tonumber(trimmedPart)

    if number then
      table.insert(scalars, number)
    end
  end

  return scalars
end

--- Detect separator automatically from input string
---@param input string The input string to analyze
---@return string|nil separator The detected separator or nil if none found
local function detectSeparator(input)
  local separatorCounts = {}

  for _, sep in ipairs(COMMON_SEPARATORS) do
    local count = 0
    for _ in string.gmatch(input, sep) do
      count = count + 1
    end
    if count > 0 then
      separatorCounts[sep] = count
    end
  end

  local maxCount = 0
  local bestSeparator = nil

  for separator, count in pairs(separatorCounts) do
    if count > maxCount then
      maxCount = count
      bestSeparator = separator
    end
  end

  return bestSeparator
end

--- Validate scalar array has expected count
---@param scalars number[] Array of scalars to validate
---@param expectedCount number Expected number of scalars
---@return boolean isValid True if count matches expectation
local function validateScalarCount(scalars, expectedCount)
  return #scalars == expectedCount
end

local ambitionsToScalars = {}

--- Parse string to array of scalars with specific separator
---@param input string The input string to parse
---@param separator string The separator character to use
---@return number[] scalars Array of parsed scalar values
function ambitionsToScalars.parse(input, separator)
  if type(input) ~= "string" then
    return {}
  end

  return parseWithSeparator(input, separator)
end

--- Parse comma-delimited string to scalars
---@param input string The input string (e.g., "1,2,3")
---@return number[] scalars Array of parsed scalar values
function ambitionsToScalars.fromComma(input)
  return ambitionsToScalars.parse(input, ",")
end

--- Parse space-delimited string to scalars
---@param input string The input string (e.g., "1 2 3")
---@return number[] scalars Array of parsed scalar values
function ambitionsToScalars.fromSpace(input)
  return ambitionsToScalars.parse(input, " ")
end

--- Parse semicolon-delimited string to scalars
---@param input string The input string (e.g., "1;2;3")
---@return number[] scalars Array of parsed scalar values
function ambitionsToScalars.fromSemicolon(input)
  return ambitionsToScalars.parse(input, ";")
end

--- Parse string to scalars with automatic separator detection
---@param input string The input string to parse
---@return number[] scalars Array of parsed scalar values
function ambitionsToScalars.auto(input)
  if type(input) ~= "string" then
    return {}
  end

  local separator = detectSeparator(input)
  if not separator then
    local number = tonumber(trimString(input))
    return number and {number} or {}
  end

  return parseWithSeparator(input, separator)
end

--- Parse string to RGB color values (0-255)
---@param input string The input string (e.g., "255,128,64")
---@return number|nil red, number|nil green, number|nil blue RGB values or nil if invalid
function ambitionsToScalars.toRGB(input)
  local scalars = ambitionsToScalars.auto(input)

  if validateScalarCount(scalars, 3) then
    local r = math.max(0, math.min(255, math.floor(scalars[1])))
    local g = math.max(0, math.min(255, math.floor(scalars[2])))
    local b = math.max(0, math.min(255, math.floor(scalars[3])))
    return r, g, b
  end

  return nil, nil, nil
end

--- Parse string to RGBA color values (0-255)
---@param input string The input string (e.g., "255,128,64,128")
---@return number|nil red, number|nil green, number|nil blue, number|nil alpha RGBA values or nil if invalid
function ambitionsToScalars.toRGBA(input)
  local scalars = ambitionsToScalars.auto(input)

  if validateScalarCount(scalars, 4) then
    local r = math.max(0, math.min(255, math.floor(scalars[1])))
    local g = math.max(0, math.min(255, math.floor(scalars[2])))
    local b = math.max(0, math.min(255, math.floor(scalars[3])))
    local a = math.max(0, math.min(255, math.floor(scalars[4])))
    return r, g, b, a
  end

  return nil, nil, nil, nil
end

--- Get count of scalars that would be parsed from input
---@param input string The input string to analyze
---@return number count Number of scalars that would be parsed
function ambitionsToScalars.count(input)
  local scalars = ambitionsToScalars.auto(input)
  return #scalars
end

--- Validate that input string can be parsed to expected scalar count
---@param input string The input string to validate
---@param expectedCount number Expected number of scalars
---@return boolean isValid True if input can be parsed to expected count
function ambitionsToScalars.validate(input, expectedCount)
  return ambitionsToScalars.count(input) == expectedCount
end

return ambitionsToScalars