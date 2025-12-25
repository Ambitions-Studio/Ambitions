--- Modern Needs Manager Class to handle all character needs
---@param characterId string The unique identifier for the character
---@param initialNeeds table Initial needs data from database
---@return AmbitionsNeedsManager needsManager The needs manager instance
function CreateAmbitionsNeedsManager(characterId, initialNeeds)

  ---@class AmbitionsNeedsManager
  ---@field characterId string The character unique ID
  ---@field needs table All needs with their current values
  ---@field thresholds table Threshold callbacks for each need
  local self = {}
  self.characterId = characterId
  self.needs = {}
  self.thresholds = {}

  if initialNeeds and type(initialNeeds) == "table" then
    for needType, value in pairs(initialNeeds) do
      self.needs[needType] = {
        value = value,
        min = needsConfig.limits.min,
        max = needsConfig.limits.max,
        enabled = true
      }
    end
  else
    for needType, defaultValue in pairs(needsConfig.defaults) do
      self.needs[needType] = {
        value = defaultValue,
        min = needsConfig.limits.min,
        max = needsConfig.limits.max,
        enabled = true
      }
    end
  end

  --- Add a new need type to the manager
  ---@param needType string The type of need (e.g., "alcohol", "stress")
  ---@param config table Configuration for the need {value, min, max}
  ---@return AmbitionsNeedsManager self For method chaining
  function self.addNeed(needType, config)
    if not needType or needType == "" then
      amb.print.warning("Invalid need type provided to addNeed")
      return self
    end

    if self.needs[needType] then
      amb.print.warning("Need type '" .. needType .. "' already exists")
      return self
    end

    self.needs[needType] = {
      value = config.value or 100,
      min = config.min or needsConfig.limits.min,
      max = config.max or needsConfig.limits.max,
      enabled = config.enabled ~= false
    }

    return self
  end

  --- Remove a need type from the manager
  ---@param needType string The type of need to remove
  ---@return AmbitionsNeedsManager self For method chaining
  function self.removeNeed(needType)
    if not needType or needType == "" then
      amb.print.warning("Invalid need type provided to removeNeed")
      return self
    end

    self.needs[needType] = nil
    self.thresholds[needType] = nil

    return self
  end

  --- Get all needs with their current values
  ---@return table needs All needs data
  function self.getAll()
    local needsValues = {}
    for needType, needData in pairs(self.needs) do
      needsValues[needType] = needData.value
    end
    return needsValues
  end

  --- Get specific need value
  ---@param needType string The need type to get
  ---@return number | nil value The need value or nil if not found
  function self.get(needType)
    if not needType or needType == "" then
      return nil
    end

    local needData = self.needs[needType]
    return needData and needData.value or nil
  end

  --- Set specific need value
  ---@param needType string The need type to set
  ---@param value number The value to set
  ---@return AmbitionsNeedsManager self For method chaining
  function self.set(needType, value)
    if not needType or needType == "" then
      amb.print.warning("Invalid need type provided to set")
      return self
    end

    if type(value) ~= "number" then
      amb.print.warning("Invalid value provided to set, must be a number")
      return self
    end

    local needData = self.needs[needType]
    if not needData then
      amb.print.warning("Need type '" .. needType .. "' does not exist")
      return self
    end

    local clampedValue = math.max(needData.min, math.min(needData.max, value))
    needData.value = clampedValue

    self.checkThresholds(needType, clampedValue)

    return self
  end

  --- Update need value by adding or subtracting amount
  ---@param needType string The need type to update
  ---@param amount number The amount to add (positive) or subtract (negative)
  ---@return AmbitionsNeedsManager self For method chaining
  function self.update(needType, amount)
    if not needType or needType == "" then
      amb.print.warning("Invalid need type provided to update")
      return self
    end

    if type(amount) ~= "number" then
      amb.print.warning("Invalid amount provided to update, must be a number")
      return self
    end

    local needData = self.needs[needType]
    if not needData then
      amb.print.warning("Need type '" .. needType .. "' does not exist")
      return self
    end

    local newValue = needData.value + amount
    local clampedValue = math.max(needData.min, math.min(needData.max, newValue))

    needData.value = clampedValue

    self.checkThresholds(needType, clampedValue)

    return self
  end

  --- Natural decay of a need (used by degradation system)
  ---@param needType string The need type to decay
  ---@param amount number The amount to decay (should be positive, will be subtracted)
  ---@return AmbitionsNeedsManager self For method chaining
  function self.decay(needType, amount)
    if not needType or needType == "" then
      return self
    end

    local needData = self.needs[needType]
    if not needData or not needData.enabled then
      return self
    end

    return self.update(needType, -math.abs(amount))
  end

  --- Set threshold callback for a need
  ---@param needType string The need type
  ---@param level number The threshold level (e.g., 20 for critical)
  ---@param operator string Comparison operator ("<", ">", "<=", ">=", "==")
  ---@param callback function The callback to execute when threshold is crossed
  ---@return AmbitionsNeedsManager self For method chaining
  function self.setThreshold(needType, level, operator, callback)
    if not needType or needType == "" then
      amb.print.warning("Invalid need type provided to setThreshold")
      return self
    end

    if type(callback) ~= "function" then
      amb.print.warning("Invalid callback provided to setThreshold, must be a function")
      return self
    end

    if not self.thresholds[needType] then
      self.thresholds[needType] = {}
    end

    table.insert(self.thresholds[needType], {
      level = level,
      operator = operator or "<",
      callback = callback,
      triggered = false
    })

    return self
  end

  --- Check if any thresholds are crossed and execute callbacks
  ---@param needType string The need type to check
  ---@param currentValue number The current value of the need
  function self.checkThresholds(needType, currentValue)
    local thresholds = self.thresholds[needType]
    if not thresholds then
      return
    end

    for _, threshold in ipairs(thresholds) do
      local conditionMet = false

      if threshold.operator == "<" then
        conditionMet = currentValue < threshold.level
      elseif threshold.operator == ">" then
        conditionMet = currentValue > threshold.level
      elseif threshold.operator == "<=" then
        conditionMet = currentValue <= threshold.level
      elseif threshold.operator == ">=" then
        conditionMet = currentValue >= threshold.level
      elseif threshold.operator == "==" then
        conditionMet = currentValue == threshold.level
      end

      if conditionMet and not threshold.triggered then
        threshold.triggered = true
        threshold.callback(self.characterId, needType, currentValue)
      elseif not conditionMet and threshold.triggered then
        threshold.triggered = false
      end
    end
  end

  --- Enable a specific need
  ---@param needType string The need type to enable
  ---@return AmbitionsNeedsManager self For method chaining
  function self.enable(needType)
    if not needType or not self.needs[needType] then
      return self
    end

    self.needs[needType].enabled = true

    return self
  end

  --- Disable a specific need (stops decay/updates)
  ---@param needType string The need type to disable
  ---@return AmbitionsNeedsManager self For method chaining
  function self.disable(needType)
    if not needType or not self.needs[needType] then
      return self
    end

    self.needs[needType].enabled = false

    return self
  end

  --- Check if a need is enabled
  ---@param needType string The need type to check
  ---@return boolean enabled Whether the need is enabled
  function self.isEnabled(needType)
    if not needType or not self.needs[needType] then
      return false
    end

    return self.needs[needType].enabled
  end

  --- Serialize needs data for database storage
  ---@return string json JSON encoded needs data
  function self.serialize()
    local data = {}

    for needType, needData in pairs(self.needs) do
      data[needType] = needData.value
    end

    return json.encode(data)
  end

  --- Deserialize needs data from database
  ---@param jsonData string JSON encoded needs data
  ---@return AmbitionsNeedsManager self For method chaining
  function self.deserialize(jsonData)
    if not jsonData or jsonData == "" then
      return self
    end

    local success, data = pcall(json.decode, jsonData)
    if not success or not data then
      amb.print.error("Failed to deserialize needs data")
      return self
    end

    for needType, value in pairs(data) do
      if self.needs[needType] then
        self.needs[needType].value = value
      else
        self.addNeed(needType, {value = value})
      end
    end

    return self
  end

  --- Get character ID
  ---@return string characterId The character unique ID
  function self.getCharacterId()
    return self.characterId
  end

  --- Reset all needs to default values
  ---@return AmbitionsNeedsManager self For method chaining
  function self.reset()
    for needType, defaultValue in pairs(needsConfig.defaults) do
      if self.needs[needType] then
        self.needs[needType].value = defaultValue
      end
    end

    return self
  end

  return self
end
