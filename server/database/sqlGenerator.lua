local ambitionsPrint = require('shared.lib.log.print')

--- Generate SQL column definition from schema column config
---@param columnName string The name of the column
---@param columnConfig table The column configuration
---@return string sqlDefinition The SQL column definition
local function GenerateColumnDefinition(columnName, columnConfig)
  local definition = "`" .. columnName .. "` " .. columnConfig.type

  if columnConfig.length then
    definition = definition .. "(" .. columnConfig.length .. ")"
  end

  if columnConfig.unsigned then
    definition = definition .. " UNSIGNED"
  end

  if columnConfig.notNull then
    definition = definition .. " NOT NULL"
  end

  -- Add PRIMARY KEY before AUTO_INCREMENT (SQL requirement)
  if columnConfig.primaryKey then
    definition = definition .. " PRIMARY KEY"
  end

  if columnConfig.autoIncrement then
    definition = definition .. " AUTO_INCREMENT"
  end

  if columnConfig.unique then
    definition = definition .. " UNIQUE"
  end

  if columnConfig.default then
    if columnConfig.default == "CURRENT_TIMESTAMP" then
      definition = definition .. " DEFAULT CURRENT_TIMESTAMP"
    else
      definition = definition .. " DEFAULT '" .. columnConfig.default .. "'"
    end
  end

  if columnConfig.onUpdate then
    definition = definition .. " ON UPDATE " .. columnConfig.onUpdate
  end

  if columnConfig.comment then
    definition = definition .. " COMMENT '" .. columnConfig.comment .. "'"
  end

  return definition
end

--- Generate SQL index definition
---@param indexConfig table The index configuration
---@return string sqlDefinition The SQL index definition
local function GenerateIndexDefinition(indexConfig)
  local columns = "`" .. table.concat(indexConfig.columns, "`, `") .. "`"

  return "INDEX `" .. indexConfig.name .. "` (" .. columns .. ")"
end

--- Generate SQL foreign key definition
---@param fkConfig table The foreign key configuration
---@return string sqlDefinition The SQL foreign key definition
local function GenerateForeignKeyDefinition(fkConfig)
  local definition = "CONSTRAINT `" .. fkConfig.name .. "` FOREIGN KEY (`" .. fkConfig.column .. "`)"
  definition = definition .. " REFERENCES `" .. fkConfig.references.table .. "`(`" .. fkConfig.references.column .. "`)"

  if fkConfig.onDelete then
    definition = definition .. " ON DELETE " .. fkConfig.onDelete
  end

  if fkConfig.onUpdate then
    definition = definition .. " ON UPDATE " .. fkConfig.onUpdate
  end

  return definition
end

--- Generate CREATE TABLE SQL from schema table config
---@param tableName string The name of the table
---@param tableConfig table The table configuration
---@param globalConfig table Global schema configuration
---@return string sqlStatement The complete CREATE TABLE SQL statement
local function GenerateCreateTableSQL(tableName, tableConfig, globalConfig)
  local sql = "CREATE TABLE IF NOT EXISTS `" .. tableName .. "` (\n"
  local definitions = {}

  for columnName, columnConfig in pairs(tableConfig.columns) do
    table.insert(definitions, "  " .. GenerateColumnDefinition(columnName, columnConfig))
  end

  if tableConfig.indexes then
    for _, indexConfig in ipairs(tableConfig.indexes) do
      table.insert(definitions, "  " .. GenerateIndexDefinition(indexConfig))
    end
  end

  if tableConfig.foreignKeys then
    for _, fkConfig in ipairs(tableConfig.foreignKeys) do
      -- Skip foreign keys for initial creation, add them later
      -- table.insert(definitions, "  " .. GenerateForeignKeyDefinition(fkConfig))
    end
  end

  sql = sql .. table.concat(definitions, ",\n")
  sql = sql .. "\n) ENGINE = " .. globalConfig.engine
  sql = sql .. " DEFAULT CHARSET = " .. globalConfig.charset
  sql = sql .. " COLLATE = " .. globalConfig.collation .. ";"

  return sql
end

--- Generate ALTER TABLE SQL to add foreign key
---@param tableName string The name of the table
---@param fkConfig table The foreign key configuration
---@return string sqlStatement The ALTER TABLE SQL statement
local function GenerateAddForeignKeySQL(tableName, fkConfig)
  local sql = "ALTER TABLE `" .. tableName .. "` ADD " .. GenerateForeignKeyDefinition(fkConfig) .. ";"

  return sql
end

--- Generate all SQL statements from schema
---@param schema table The complete schema configuration
---@return table sqlStatements Array of SQL statements to execute
local function GenerateAllSQL(schema)
  local statements = {}
  local foreignKeys = {}

  for tableName, tableConfig in pairs(schema.tables) do
    local createSQL = GenerateCreateTableSQL(tableName, tableConfig, schema)
    table.insert(statements, createSQL)

    if tableConfig.foreignKeys then
      for _, fkConfig in ipairs(tableConfig.foreignKeys) do
        table.insert(foreignKeys, {
          table = tableName,
          config = fkConfig
        })
      end
    end
  end

  for _, fkInfo in ipairs(foreignKeys) do
    local fkSQL = GenerateAddForeignKeySQL(fkInfo.table, fkInfo.config)
    table.insert(statements, fkSQL)
  end

  ambitionsPrint.success("Generated " .. #statements .. " SQL statements from schema")

  return statements
end

return {
  GenerateColumnDefinition = GenerateColumnDefinition,
  GenerateIndexDefinition = GenerateIndexDefinition,
  GenerateForeignKeyDefinition = GenerateForeignKeyDefinition,
  GenerateCreateTableSQL = GenerateCreateTableSQL,
  GenerateAddForeignKeySQL = GenerateAddForeignKeySQL,
  GenerateAllSQL = GenerateAllSQL
}