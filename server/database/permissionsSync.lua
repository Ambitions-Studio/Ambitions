--- Synchronize permissions from config to database
--- This ensures the database always reflects the current permission configuration

--- Sync roles from config to database
---@return boolean success Whether the sync was successful
local function SyncRoles()
    amb.print.info("Syncing roles to database...")

    for roleName, roleData in pairs(permissionsConfig) do
        local result = MySQL.single.await('SELECT id FROM roles WHERE name = ?', {roleName})

        if not result then
            MySQL.insert.await('INSERT INTO roles (name, label) VALUES (?, ?)', {
                roleName,
                roleData.label or roleName
            })
            amb.print.success(("Role '%s' created in database"):format(roleName))
        else
            MySQL.update.await('UPDATE roles SET label = ? WHERE name = ?', {
                roleData.label or roleName,
                roleName
            })
        end
    end

    return true
end

--- Sync permissions from config to database
---@return boolean success Whether the sync was successful
local function SyncPermissions()
    amb.print.info("Syncing permissions to database...")

    local allPermissions = {}

    for _, roleData in pairs(permissionsConfig) do
        if roleData.permissions then
            for _, permission in ipairs(roleData.permissions) do
                allPermissions[permission] = true
            end
        end
    end

    for permissionName, _ in pairs(allPermissions) do
        local result = MySQL.single.await('SELECT id FROM permissions WHERE name = ?', {permissionName})

        if not result then
            MySQL.insert.await('INSERT INTO permissions (name, description) VALUES (?, ?)', {
                permissionName,
                nil
            })
            amb.print.success(("Permission '%s' created in database"):format(permissionName))
        end
    end

    return true
end

--- Sync role-permission relationships
---@return boolean success Whether the sync was successful
local function SyncRolePermissions()
    amb.print.info("Syncing role-permission relationships...")

    for roleName, roleData in pairs(permissionsConfig) do
        local roleResult = MySQL.single.await('SELECT id FROM roles WHERE name = ?', {roleName})

        if roleResult and roleData.permissions then
            MySQL.query.await('DELETE FROM role_permissions WHERE role_id = ?', {roleResult.id})

            for _, permissionName in ipairs(roleData.permissions) do
                local permResult = MySQL.single.await('SELECT id FROM permissions WHERE name = ?', {permissionName})

                if permResult then
                    MySQL.insert.await('INSERT INTO role_permissions (role_id, permission_id) VALUES (?, ?)', {
                        roleResult.id,
                        permResult.id
                    })
                end
            end
        end
    end

    return true
end

--- Main sync function called after migration
---@return boolean success Whether the sync was successful
function SyncPermissionsToDatabase()
    amb.print.info("===== PERMISSIONS SYNC =====")

    local startTime = GetGameTimer()

    local success = SyncRoles()
    if not success then
        amb.print.error("Failed to sync roles")
        return false
    end

    success = SyncPermissions()
    if not success then
        amb.print.error("Failed to sync permissions")
        return false
    end

    success = SyncRolePermissions()
    if not success then
        amb.print.error("Failed to sync role-permission relationships")
        return false
    end

    local endTime = GetGameTimer()
    local duration = endTime - startTime

    amb.print.success(("Permissions synced successfully in %dms"):format(duration))
    amb.print.info("============================")

    return true
end
