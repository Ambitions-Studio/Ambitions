--- Run the auto-migration process
--- This is the main function that handles the migration
local function runAutoMigration()
  amb.print.info('===== AMBITIONS AUTO-MIGRATION =====')

  local startTime = GetGameTimer()
  local success = runMigration()
  local endTime = GetGameTimer()
  local duration = endTime - startTime

  if success then
    amb.print.success('Auto-migration completed in ' .. duration .. 'ms')

    local appliedMigrations = getAppliedMigrations()
    if #appliedMigrations > 0 then
      amb.print.info('Applied migrations:')
      for _, migrationInfo in ipairs(appliedMigrations) do
        amb.print.info('  - ' .. migrationInfo.version .. ' (applied: ' .. migrationInfo.applied_at .. ')')
      end
    end

    SyncPermissionsToDatabase()
  else
    amb.print.error('Auto-migration failed after ' .. duration .. 'ms')
    amb.print.error('Please check your database configuration and try again')
  end

  amb.print.info('=====================================')
end

--- Initialize auto-migration system
--- This function is called when the resource starts
local function initialize()
  if not migrationConfig.enabled then
    amb.print.warning('Auto-migration is disabled in configuration')

    return
  end

  if not migrationConfig.runOnStart then
    amb.print.info('Auto-migration on start is disabled')

    return
  end

  amb.print.info('Initializing auto-migration system...')

  SetTimeout(1000, function()
    runAutoMigration()
  end)
end

--- Manual migration trigger (for admin commands or debugging)
--- Can be called from other scripts if needed
local function triggerManualMigration()
  amb.print.info('Manual migration triggered')
  runAutoMigration()
end

--- Get migration status information
---@return table status Migration status with details
local function getMigrationStatus()
  local appliedMigrations = getAppliedMigrations()

  return {
    enabled = migrationConfig.enabled,
    currentVersion = schemaConfig.version,
    appliedMigrations = appliedMigrations,
    isUpToDate = isMigrationApplied(schemaConfig.version)
  }
end

--- Enable or disable auto-migration
---@param enabled boolean Whether to enable auto-migration
local function setEnabled(enabled)
  migrationConfig.enabled = enabled
  amb.print.info('Auto-migration ' .. (enabled and 'enabled' or 'disabled'))
end

--- Check if auto-migration is enabled
---@return boolean enabled Whether auto-migration is enabled
local function isEnabled()
  return migrationConfig.enabled
end

-- Event handlers for resource lifecycle
AddEventHandler('onResourceStart', function(resourceName)
  if GetCurrentResourceName() == resourceName then
    initialize()
  end
end)

-- Admin command to manually trigger migration (optional)
RegisterCommand('ambitions:migrate', function(source, args, rawCommand)
  if source ~= 0 then -- Only allow from server console
    return
  end

  triggerManualMigration()
end, true)

-- Admin command to check migration status (optional)
RegisterCommand('ambitions:migration-status', function(source, args, rawCommand)
  if source ~= 0 then -- Only allow from server console
    return
  end

  local status = getMigrationStatus()

  amb.print.info('===== MIGRATION STATUS =====')
  amb.print.info('Enabled: ' .. (status.enabled and 'Yes' or 'No'))
  amb.print.info('Current Version: ' .. status.currentVersion)
  amb.print.info('Up to Date: ' .. (status.isUpToDate and 'Yes' or 'No'))
  amb.print.info('Applied Migrations: ' .. #status.appliedMigrations)

  if #status.appliedMigrations > 0 then
    for _, migrationInfo in ipairs(status.appliedMigrations) do
      amb.print.info('  - ' .. migrationInfo.version .. ' (' .. migrationInfo.applied_at .. ')')
    end
  end

  amb.print.info('============================')
end, true)