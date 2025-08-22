local ambitionsPrint = require('shared.lib.log.print')
local schema = require('server.database.schema')
local sqlGenerator = require('server.database.sqlGenerator')

--- Check if a table exists in the database
---@param tableName string The name of the table to check
---@return boolean exists True if the table exists, false otherwise
local function TableExists(tableName)
  local result = MySQL.scalar.await('SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?', { tableName })

  return result > 0
end

--- Check if a column exists in a table
---@param tableName string The name of the table
---@param columnName string The name of the column
---@return boolean exists True if the column exists, false otherwise
local function ColumnExists(tableName, columnName)
  local result = MySQL.scalar.await('SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?', { tableName, columnName })

  return result > 0
end

--- Check if an index exists on a table
---@param tableName string The name of the table
---@param indexName string The name of the index
---@return boolean exists True if the index exists, false otherwise
local function IndexExists(tableName, indexName)
  local result = MySQL.scalar.await('SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = ? AND index_name = ?', { tableName, indexName })

  return result > 0
end

--- Check if a foreign key constraint exists
---@param tableName string The name of the table
---@param constraintName string The name of the foreign key constraint
---@return boolean exists True if the constraint exists, false otherwise
local function ForeignKeyExists(tableName, constraintName)
  local result = MySQL.scalar.await('SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_schema = DATABASE() AND table_name = ? AND constraint_name = ? AND constraint_type = "FOREIGN KEY"', { tableName, constraintName })

  return result > 0
end

--- Check if migration version has been applied
---@param version string The version to check
---@return boolean applied True if the version has been applied, false otherwise
local function IsMigrationApplied(version)
  if not TableExists('schema_migrations') then
    return false
  end

  local result = MySQL.scalar.await('SELECT COUNT(*) FROM schema_migrations WHERE version = ?', { version })

  return result > 0
end

--- Mark migration version as applied
---@param version string The version to mark as applied
---@return boolean success True if successful, false otherwise
local function MarkMigrationApplied(version)
  if not TableExists('schema_migrations') then
    ambitionsPrint.error('schema_migrations table does not exist')
    return false
  end

  local success = MySQL.insert.await('INSERT INTO schema_migrations (version) VALUES (?)', { version })

  return success ~= nil
end

--- Execute SQL statement safely with error handling
---@param sql string The SQL statement to execute
---@param description string Description of what this SQL does
---@return boolean success True if successful, false otherwise
local function ExecuteSQL(sql, description)
  ambitionsPrint.info('Executing: ' .. description)

  local success, error = pcall(function()
    MySQL.query.await(sql)
  end)

  if success then
    ambitionsPrint.success('✓ ' .. description)

    return true
  else
    ambitionsPrint.error('✗ Failed: ' .. description)
    ambitionsPrint.error('Error: ' .. tostring(error))
    ambitionsPrint.error('SQL: ' .. sql)

    return false
  end
end

--- Create missing tables from schema
---@return boolean success True if all operations successful
local function CreateMissingTables()
  local success = true

  for tableName, tableConfig in pairs(schema.tables) do
    if not TableExists(tableName) then
      local createSQL = sqlGenerator.GenerateCreateTableSQL(tableName, tableConfig, schema)
      local result = ExecuteSQL(createSQL, 'Create table ' .. tableName)

      if not result then
        success = false
      end
    else
      ambitionsPrint.info('Table ' .. tableName .. ' already exists')
    end
  end

  return success
end

--- Add missing foreign keys from schema
---@return boolean success True if all operations successful
local function AddMissingForeignKeys()
  local success = true

  for tableName, tableConfig in pairs(schema.tables) do
    if tableConfig.foreignKeys then
      for _, fkConfig in ipairs(tableConfig.foreignKeys) do
        if not ForeignKeyExists(tableName, fkConfig.name) then
          local fkSQL = sqlGenerator.GenerateAddForeignKeySQL(tableName, fkConfig)
          local result = ExecuteSQL(fkSQL, 'Add foreign key ' .. fkConfig.name .. ' to ' .. tableName)

          if not result then
            success = false
          end
        else
          ambitionsPrint.info('Foreign key ' .. fkConfig.name .. ' already exists on ' .. tableName)
        end
      end
    end
  end

  return success
end

--- Run complete database migration
---@return boolean success True if migration completed successfully
local function RunMigration()
  ambitionsPrint.info('Starting database migration...')
  ambitionsPrint.info('Schema version: ' .. schema.version)

  if IsMigrationApplied(schema.version) then
    ambitionsPrint.success('Migration version ' .. schema.version .. ' already applied')

    return true
  end

  local success = true

  if not CreateMissingTables() then
    success = false
  end

  if success and not AddMissingForeignKeys() then
    success = false
  end

  if success then
    if MarkMigrationApplied(schema.version) then
      ambitionsPrint.success('Database migration completed successfully!')
      ambitionsPrint.success('Schema version ' .. schema.version .. ' applied')
    else
      ambitionsPrint.error('Failed to mark migration as applied')
      success = false
    end
  else
    ambitionsPrint.error('Database migration failed!')
  end

  return success
end

--- Get list of applied migrations
---@return table migrations List of applied migration versions with timestamps
local function GetAppliedMigrations()
  if not TableExists('schema_migrations') then
    return {}
  end

  local result = MySQL.query.await('SELECT version, applied_at FROM schema_migrations ORDER BY applied_at DESC')

  return result or {}
end

return {
  TableExists = TableExists,
  ColumnExists = ColumnExists,
  IndexExists = IndexExists,
  ForeignKeyExists = ForeignKeyExists,
  IsMigrationApplied = IsMigrationApplied,
  MarkMigrationApplied = MarkMigrationApplied,
  ExecuteSQL = ExecuteSQL,
  CreateMissingTables = CreateMissingTables,
  AddMissingForeignKeys = AddMissingForeignKeys,
  RunMigration = RunMigration,
  GetAppliedMigrations = GetAppliedMigrations
}