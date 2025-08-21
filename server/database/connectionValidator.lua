local ambitionsPrint = require('Ambitions.shared.lib.log.print')

--- Validate URL format: mysql://user:password@host:port/database
---@param connectionString string The connection string to validate
---@return boolean success True if valid, false otherwise
local function ValidateUrlFormat(connectionString)
  ambitionsPrint.info("Validating MySQL URL format...")

  local cleanString = connectionString:sub(9, -1)
  local pattern = "^([^:]+):?([^@]*)@([^:]+):(%d+)/(.+)$"
  local user, password, host, port, database = cleanString:match(pattern)

  if not user or not host or not port or not database then
    ambitionsPrint.error("^1[DATABASE ERROR]^7 Invalid MySQL URL format")
    ambitionsPrint.error("^1Expected format: mysql://user:password@host:port/database^7")
    ambitionsPrint.error("^1Your format: " .. connectionString .. "^7")

    return false
  end

  if user == "" then
    ambitionsPrint.error("^1[DATABASE ERROR]^7 Missing required field: Username")

    return false
  end

  if host == "" then
    ambitionsPrint.error("^1[DATABASE ERROR]^7 Missing required field: Host/Server")

    return false
  end

  local portNum = tonumber(port)
  if not portNum or portNum <= 0 or portNum > 65535 then
    ambitionsPrint.error("^1[DATABASE ERROR]^7 Invalid port: must be a number between 1-65535")

    return false
  end

  if database == "" then
    ambitionsPrint.error("^1[DATABASE ERROR]^7 Missing required field: Database name")
    return false
  end

  if not password or password == "" then
    ambitionsPrint.warning("⚠ Password is empty - connecting without password")
  end

  ambitionsPrint.success("✓ MySQL URL format validation passed")
  ambitionsPrint.info("  - User: " .. user)
  ambitionsPrint.info("  - Host: " .. host)
  ambitionsPrint.info("  - Port: " .. port)
  ambitionsPrint.info("  - Database: " .. database)

  return true
end

--- Validate key-value format: database=mydb;server=localhost;userid=user;password=pass;port=3306
---@param connectionString string The connection string to validate
---@return boolean success True if valid, false otherwise
local function ValidateKeyValueFormat(connectionString)
  ambitionsPrint.info("Validating MySQL key-value format...")

  local config = {}
  local confPairs = { string.strsplit(";", connectionString) }

  for i = 1, #confPairs do
    local confPair = confPairs[i]
    local key, value = confPair:match("^%s*(.-)%s*=%s*(.-)%s*$")

    if key and value then
      config[key:lower()] = value
    end
  end

  local user = config.userid or config.uid or config.username or config.user
  local password = config.password or config.pwd or config.pass
  local host = config.server or config.hostname or config.data_source or config.host
  local port = config.port
  local database = config.database or config.db or config.initial_catalog

  if not user or user == "" then
    ambitionsPrint.error("^1[DATABASE ERROR]^7 Missing required field: User")
    ambitionsPrint.error("^1Valid keys: userid, uid, username, user^7")
    ambitionsPrint.error("^1Your connection string: " .. connectionString .. "^7")

    return false
  end

  if not host or host == "" then
    ambitionsPrint.error("^1[DATABASE ERROR]^7 Missing required field: Host/Server")
    ambitionsPrint.error("^1Valid keys: server, hostname, data_source, host^7")
    ambitionsPrint.error("^1Your connection string: " .. connectionString .. "^7")

    return false
  end

  if not port or port == "" then
    ambitionsPrint.error("^1[DATABASE ERROR]^7 Missing required field: Port")
    ambitionsPrint.error("^1Valid key: port^7")
    ambitionsPrint.error("^1Your connection string: " .. connectionString .. "^7")

    return false
  end

  local portNum = tonumber(port)
  if not portNum or portNum <= 0 or portNum > 65535 then
    ambitionsPrint.error("^1[DATABASE ERROR]^7 Invalid port: must be a number between 1-65535")
    ambitionsPrint.error("^1Your port value: " .. tostring(port) .. "^7")

    return false
  end

  if not database or database == "" then
    ambitionsPrint.error("^1[DATABASE ERROR]^7 Missing required field: Database name")
    ambitionsPrint.error("^1Valid keys: database, db, initial_catalog^7")
    ambitionsPrint.error("^1Your connection string: " .. connectionString .. "^7")

    return false
  end

  if not password or password == "" then
    ambitionsPrint.warning("⚠ Password is empty - connecting without password")
  end

  ambitionsPrint.success("✓ MySQL key-value format validation passed")
  ambitionsPrint.info("  - User: " .. user)
  ambitionsPrint.info("  - Host: " .. host)
  ambitionsPrint.info("  - Port: " .. port)
  ambitionsPrint.info("  - Database: " .. database)

  return true
end

--- Validate MySQL connection string format and required fields
---@param connectionString string The MySQL connection string to validate
---@return boolean success True if valid, false otherwise
local function ValidateConnectionString(connectionString)
  if not connectionString or connectionString == "" then
    ambitionsPrint.error("^1[DATABASE ERROR]^7 mysql_connection_string convar is empty or not set")
    ambitionsPrint.error("^1Please set the mysql_connection_string convar in your server.cfg^7")
    ambitionsPrint.error("^1Example: set mysql_connection_string \"mysql://user:password@localhost:3306/database\"^7")

    return false
  end

  local isUrlFormat = connectionString:find("mysql://")

  if isUrlFormat then
    return ValidateUrlFormat(connectionString)
  else
    return ValidateKeyValueFormat(connectionString)
  end
end

--- Initialize database connection validation
---@return boolean success True if connection string is valid
local function Initialize()
  ambitionsPrint.info("===== DATABASE CONNECTION VALIDATION =====")

  local connectionString = GetConvar("mysql_connection_string", "")
  local success = ValidateConnectionString(connectionString)

  if success then
    ambitionsPrint.success("Database connection string validation passed")
  else
    ambitionsPrint.error("Database connection string validation failed")
    ambitionsPrint.error("^1ABORTING: Cannot continue without valid database configuration^7")
  end

  ambitionsPrint.info("==========================================")

  return success
end

return {
  ValidateConnectionString = ValidateConnectionString,
  Initialize = Initialize
}