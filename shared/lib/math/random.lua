local CHARSET_ALPHANUMERIC <const> = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
local CHARSET_ALPHA <const> = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
local CHARSET_NUMERIC <const> = "0123456789"
local CHARSET_HEX <const> = "0123456789ABCDEF"

--- Get default seed value that works on both client and server
---@return number seed Default seed value
local function getDefaultSeed()
  local gameTimer = GetGameTimer()
  return gameTimer + (gameTimer % 1000) * 1000
end

--- Initialize random seed for better randomness
---@param seed? number Custom seed value, uses game timer if not provided
local function initializeSeed(seed)
  math.randomseed(seed or getDefaultSeed())
  for _ = 1, 3 do
    math.random()
  end
end

--- Generate weighted random selection from array of weights
---@param weights number[] Array of weight values
---@return number index The selected index based on weights
local function weightedSelect(weights)
  local totalWeight = 0
  for _, weight in ipairs(weights) do
    totalWeight = totalWeight + weight
  end

  local randomValue = math.random() * totalWeight
  local currentWeight = 0

  for i, weight in ipairs(weights) do
    currentWeight = currentWeight + weight
    if randomValue <= currentWeight then
      return i
    end
  end

  return #weights
end

--- Shuffle array elements in place using Fisher-Yates algorithm
---@param array any[] The array to shuffle
---@return any[] shuffled The same array reference with shuffled elements
local function shuffleArray(array)
  local n = #array
  for i = n, 2, -1 do
    local j = math.random(i)
    array[i], array[j] = array[j], array[i]
  end
  return array
end

--- Generate random string from character set
---@param length number Length of the string to generate
---@param charset? string Character set to use, defaults to alphanumeric
---@return string result The generated random string
local function generateString(length, charset)
  charset = charset or CHARSET_ALPHANUMERIC
  local result = {}
  local charsetLength = #charset

  for i = 1, length do
    local randomIndex = math.random(charsetLength)
    result[i] = charset:sub(randomIndex, randomIndex)
  end

  return table.concat(result)
end

local ambitionsRandom = {}

--- Initialize the random number generator with optional seed
---@param seed? number Custom seed value for reproducible sequences
function ambitionsRandom.setSeed(seed)
  initializeSeed(seed)
end

--- Generate random integer between min and max (inclusive)
---@param min number Minimum value (inclusive)
---@param max number Maximum value (inclusive)
---@return number result Random integer in specified range
function ambitionsRandom.integer(min, max)
  return math.random(min, max)
end

--- Generate random float between min and max
---@param min? number Minimum value (inclusive), defaults to 0
---@param max? number Maximum value (exclusive), defaults to 1
---@return number result Random float in specified range
function ambitionsRandom.float(min, max)
  min = min or 0
  max = max or 1
  return min + (max - min) * math.random()
end

--- Generate random boolean with optional probability
---@param probability? number Chance of returning true (0.0 to 1.0), defaults to 0.5
---@return boolean result Random boolean value
function ambitionsRandom.boolean(probability)
  probability = probability or 0.5
  return math.random() < probability
end

--- Pick random element from array
---@generic T
---@param array T[] Array to pick from
---@return T|nil result Random element from array or nil if empty
function ambitionsRandom.choice(array)
  if #array == 0 then
    return nil
  end
  return array[math.random(#array)]
end

--- Pick multiple random elements from array without repetition
---@generic T
---@param array T[] Array to pick from
---@param count number Number of elements to pick
---@return T[] results Array of randomly selected elements
function ambitionsRandom.sample(array, count)
  if count <= 0 or #array == 0 then
    return {}
  end

  count = math.min(count, #array)
  local shuffled = {}
  for i, v in ipairs(array) do
    shuffled[i] = v
  end

  shuffleArray(shuffled)
  local result = {}
  for i = 1, count do
    result[i] = shuffled[i]
  end

  return result
end

--- Generate weighted random selection from options
---@generic T
---@param options T[] Array of options to choose from
---@param weights number[] Array of weights corresponding to options
---@return T|nil result Randomly selected option based on weights
function ambitionsRandom.weighted(options, weights)
  if #options == 0 or #weights == 0 or #options ~= #weights then
    return nil
  end

  local selectedIndex = weightedSelect(weights)
  return options[selectedIndex]
end

--- Shuffle array elements and return new shuffled array
---@generic T
---@param array T[] Array to shuffle
---@return T[] shuffled New array with shuffled elements
function ambitionsRandom.shuffle(array)
  local shuffled = {}
  for i, v in ipairs(array) do
    shuffled[i] = v
  end
  return shuffleArray(shuffled)
end

--- Generate random point within a circle
---@param centerX number Center X coordinate
---@param centerY number Center Y coordinate
---@param radius number Circle radius
---@return number x, number y Random point coordinates within circle
function ambitionsRandom.pointInCircle(centerX, centerY, radius)
  local angle = ambitionsRandom.float(0, 2 * math.pi)
  local distance = radius * math.sqrt(math.random())

  return centerX + distance * math.cos(angle), centerY + distance * math.sin(angle)
end

--- Generate random UUID version 4
---@return string uuid Generated UUID string
function ambitionsRandom.uuid()
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  return template:gsub('[xy]', function(c)
    local value = (c == 'x') and math.random(0, 15) or math.random(8, 11)
    return string.format('%x', value)
  end)
end

--- Generate random alphanumeric string
---@param length number Length of string to generate
---@return string result Random alphanumeric string
function ambitionsRandom.alphanumeric(length)
  return generateString(length, CHARSET_ALPHANUMERIC)
end

--- Generate random alphabetic string
---@param length number Length of string to generate
---@return string result Random alphabetic string
function ambitionsRandom.alpha(length)
  return generateString(length, CHARSET_ALPHA)
end

--- Generate random numeric string
---@param length number Length of string to generate
---@return string result Random numeric string
function ambitionsRandom.numeric(length)
  return generateString(length, CHARSET_NUMERIC)
end

--- Generate random hexadecimal string
---@param length number Length of string to generate
---@return string result Random hexadecimal string
function ambitionsRandom.hex(length)
  return generateString(length, CHARSET_HEX)
end

--- Generate random RGB color values
---@return number red, number green, number blue RGB values (0-255)
function ambitionsRandom.color()
  return math.random(0, 255), math.random(0, 255), math.random(0, 255)
end

--- Generate random percentage value
---@return number percentage Random percentage (0-100)
function ambitionsRandom.percentage()
  return ambitionsRandom.float(0, 100)
end

--- Generate random angle in degrees
---@return number degrees Random angle (0-359)
function ambitionsRandom.angle()
  return ambitionsRandom.float(0, 360)
end

--- Generate random sign (-1 or 1)
---@return number sign Random sign value
function ambitionsRandom.sign()
  return ambitionsRandom.boolean() and 1 or -1
end

-- Initialize with default seed on module load
initializeSeed()

return ambitionsRandom