local SPACE_SEPARATOR <const> = " "
local MIN_DIGITS_TO_FORMAT <const> = 5
local DECIMAL_SEPARATOR <const> = "."

--- Format integer part by grouping digits with spaces
---@param integerStr string The integer part as string
---@return string formatted The formatted integer string
local function formatIntegerPart(integerStr)
  if #integerStr < MIN_DIGITS_TO_FORMAT then
    return integerStr
  end

  local result = {}
  local length = #integerStr

  for i = length, 1, -1 do
    local char = integerStr:sub(i, i)

    table.insert(result, 1, char)

    local positionFromRight = length - i + 1

    if positionFromRight % 3 == 0 and i > 1 then
      table.insert(result, 1, SPACE_SEPARATOR)
    end
  end

  return table.concat(result)
end

--- Convert input to number and validate
---@param value any The value to convert
---@return number|nil number The converted number or nil if invalid
local function toValidNumber(value)
  if type(value) == "number" then
    return value
  elseif type(value) == "string" then
    local num = tonumber(value)
    return num
  end

  return nil
end

--- Format a number with space-separated digit groups
---@param number number|string The number to format
---@return string formatted The formatted number string
function amb.math.formatNumber(number)
  local validNumber = toValidNumber(number)

  if not validNumber then
    return tostring(number)
  end

  if validNumber ~= validNumber then
    return "NaN"
  end

  if validNumber == math.huge then
    return "Infinity"
  end

  if validNumber == -math.huge then
    return "-Infinity"
  end

  local numberStr = tostring(math.abs(validNumber))
  local isNegative = validNumber < 0

  local integerPart, decimalPart = numberStr:match("^([^%.]+)%.?(.*)$")

  local formattedInteger = formatIntegerPart(integerPart)

  local result = formattedInteger

  if decimalPart and #decimalPart > 0 then
    result = result .. DECIMAL_SEPARATOR .. decimalPart
  end

  if isNegative then
    result = "-" .. result
  end

  return result
end

--- Format a number as currency with optional currency symbol
---@param number number|string The number to format
---@param currencySymbol? string The currency symbol to append, defaults to "$"
---@return string formatted The formatted currency string
function amb.math.formatCurrency(number, currencySymbol)
  currencySymbol = currencySymbol or "$"
  local formatted = amb.math.formatNumber(number)

  return formatted .. " " .. currencySymbol
end

--- Format a number with custom separator
---@param number number|string The number to format
---@param separator? string The separator to use, defaults to space
---@return string formatted The formatted number string
function amb.math.formatNumberWithSeparator(number, separator)
  separator = separator or SPACE_SEPARATOR
  local validNumber = toValidNumber(number)

  if not validNumber then
    return tostring(number)
  end

  local numberStr = tostring(math.abs(validNumber))
  local isNegative = validNumber < 0

  local integerPart, decimalPart = numberStr:match("^([^%.]+)%.?(.*)$")

  if #integerPart < MIN_DIGITS_TO_FORMAT then
    return isNegative and "-" .. numberStr or numberStr
  end

  local result = {}
  local length = #integerPart

  for i = length, 1, -1 do
    local char = integerPart:sub(i, i)
    table.insert(result, 1, char)

    local positionFromRight = length - i + 1
    if positionFromRight % 3 == 0 and i > 1 then
      table.insert(result, 1, separator)
    end
  end

  local formattedInteger = table.concat(result)
  local finalResult = formattedInteger

  if decimalPart and #decimalPart > 0 then
    finalResult = finalResult .. DECIMAL_SEPARATOR .. decimalPart
  end

  if isNegative then
    finalResult = "-" .. finalResult
  end

  return finalResult
end