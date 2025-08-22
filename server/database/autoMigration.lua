local ambitionsPrint = require('shared.lib.log.print')
local migration = require('server.database.migration')
local CONFIG = require('config.migration')

--- Run the auto-migration process
--- This is the main function that handles the migration
local function RunAutoMigration()
  ambitionsPrint.info('===== AMBITIONS AUTO-MIGRATION =====')

  local startTime = GetGameTimer()
  local success = migration.RunMigration()
  local endTime = GetGameTimer()
  local duration = endTime - startTime

  if success then
    ambitionsPrint.success('Auto-migration completed in ' .. duration .. 'ms')

    local appliedMigrations = migration.GetAppliedMigrations()
    if #appliedMigrations > 0 then
      ambitionsPrint.info('Applied migrations:')
      for _, migrationInfo in ipairs(appliedMigrations) do
        ambitionsPrint.info('  - ' .. migrationInfo.version .. ' (applied: ' .. migrationInfo.applied_at .. ')')
      end
    end
  else
    ambitionsPrint.error('Auto-migration failed after ' .. duration .. 'ms')
    ambitionsPrint.error('Please check your database configuration and try again')
  end

  ambitionsPrint.info('=====================================')
end

--- Initialize auto-migration system
--- This function is called when the resource starts
local function Initialize()
  if not CONFIG.enabled then
    ambitionsPrint.warning('Auto-migration is disabled in configuration')

    return
  end

  if not CONFIG.runOnStart then
    ambitionsPrint.info('Auto-migration on start is disabled')

    return
  end

  ambitionsPrint.info('Initializing auto-migration system...')

  SetTimeout(1000, function()
    RunAutoMigration()
  end)
end

--- Manual migration trigger (for admin commands or debugging)
--- Can be called from other scripts if needed
local function TriggerManualMigration()
  ambitionsPrint.info('Manual migration triggered')
  RunAutoMigration()
end

--- Get migration status information
---@return table status Migration status with details
local function GetMigrationStatus()
  local appliedMigrations = migration.GetAppliedMigrations()
  local schema = require('server.database.schema')

  return {
    enabled = CONFIG.enabled,
    currentVersion = schema.version,
    appliedMigrations = appliedMigrations,
    isUpToDate = migration.IsMigrationApplied(schema.version)
  }
end

--- Enable or disable auto-migration
---@param enabled boolean Whether to enable auto-migration
local function SetEnabled(enabled)
  CONFIG.enabled = enabled
  ambitionsPrint.info('Auto-migration ' .. (enabled and 'enabled' or 'disabled'))
end

--- Check if auto-migration is enabled
---@return boolean enabled Whether auto-migration is enabled
local function IsEnabled()
  return CONFIG.enabled
end

-- Event handlers for resource lifecycle
AddEventHandler('onResourceStart', function(resourceName)
  if GetCurrentResourceName() == resourceName then
    Initialize()
  end
end)

-- Admin command to manually trigger migration (optional)
RegisterCommand('ambitions:migrate', function(source, args, rawCommand)
  if source ~= 0 then -- Only allow from server console
    return
  end

  TriggerManualMigration()
end, true)

-- Admin command to check migration status (optional)
RegisterCommand('ambitions:migration-status', function(source, args, rawCommand)
  if source ~= 0 then -- Only allow from server console
    return
  end

  local status = GetMigrationStatus()

  ambitionsPrint.info('===== MIGRATION STATUS =====')
  ambitionsPrint.info('Enabled: ' .. (status.enabled and 'Yes' or 'No'))
  ambitionsPrint.info('Current Version: ' .. status.currentVersion)
  ambitionsPrint.info('Up to Date: ' .. (status.isUpToDate and 'Yes' or 'No'))
  ambitionsPrint.info('Applied Migrations: ' .. #status.appliedMigrations)

  if #status.appliedMigrations > 0 then
    for _, migrationInfo in ipairs(status.appliedMigrations) do
      ambitionsPrint.info('  - ' .. migrationInfo.version .. ' (' .. migrationInfo.applied_at .. ')')
    end
  end

  ambitionsPrint.info('============================')
end, true)

return {
  Initialize = Initialize,
  RunAutoMigration = RunAutoMigration,
  TriggerManualMigration = TriggerManualMigration,
  GetMigrationStatus = GetMigrationStatus,
  SetEnabled = SetEnabled,
  IsEnabled = IsEnabled
}