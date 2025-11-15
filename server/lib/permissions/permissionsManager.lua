amb.permissions = {}

local permissionCache = {}
local roleCache = {}

--- Check if a permission string matches a wildcard pattern
---@param permission string The permission to check (e.g., "admin.getCoords")
---@param pattern string The pattern to match (e.g., "admin.*", "*.getCoords", "*")
---@return boolean matches Whether the permission matches the pattern
local function MatchesWildcard(permission, pattern)
    if pattern == "*" then
        return true
    end

    if not pattern:find("%.") then
        return false
    end

    local patternNamespace, patternAction = pattern:match("^([^%.]+)%.(.+)$")
    local permNamespace, permAction = permission:match("^([^%.]+)%.(.+)$")

    if not patternNamespace or not permNamespace then
        return false
    end

    local namespaceMatch = (patternNamespace == "*" or patternNamespace == permNamespace)
    local actionMatch = (patternAction == "*" or patternAction == permAction)

    return namespaceMatch and actionMatch
end

--- Get all permissions for a role including inherited roles
---@param roleName string The role name
---@return table permissions List of all permissions for the role
local function GetRolePermissions(roleName)
    if roleCache[roleName] then
        return roleCache[roleName]
    end

    local roleData = permissionsConfig[roleName]
    if not roleData then
        return {}
    end

    local allPermissions = {}

    if roleData.inherits then
        for _, inheritedRole in ipairs(roleData.inherits) do
            local inheritedPerms = GetRolePermissions(inheritedRole)
            for _, perm in ipairs(inheritedPerms) do
                table.insert(allPermissions, perm)
            end
        end
    end

    if roleData.permissions then
        for _, perm in ipairs(roleData.permissions) do
            table.insert(allPermissions, perm)
        end
    end

    roleCache[roleName] = allPermissions
    return allPermissions
end

--- Check if a role has a specific permission
---@param roleName string The role name
---@param permission string The permission to check (e.g., "admin.getCoords")
---@return boolean hasPermission Whether the role has the permission
local function RoleHasPermission(roleName, permission)
    local cacheKey = roleName .. ":" .. permission

    if permissionCache[cacheKey] ~= nil then
        return permissionCache[cacheKey]
    end

    local rolePermissions = GetRolePermissions(roleName)

    for _, rolePerm in ipairs(rolePermissions) do
        if rolePerm == permission or MatchesWildcard(permission, rolePerm) then
            permissionCache[cacheKey] = true
            return true
        end
    end

    permissionCache[cacheKey] = false
    return false
end

--- Get player's role
---@param source number The player source
---@return string | nil role The player's role or nil if not found
function amb.permissions.GetPlayerRole(source)
    if not source or source <= 0 then
        return nil
    end

    local player = amb.player.get(source)
    if not player then
        return nil
    end

    local character = player.getCurrentCharacter()
    if not character then
        return nil
    end

    return character.getGroup()
end

--- Check if a player has a specific permission
---@param source number The player source
---@param permission string The permission to check (e.g., "admin.getCoords")
---@return boolean hasPermission Whether the player has the permission
function amb.permissions.HasPermission(source, permission)
    if not source or source <= 0 then
        return false
    end

    if not permission or permission == "" then
        return false
    end

    local role = amb.permissions.GetPlayerRole(source)
    if not role then
        return false
    end

    return RoleHasPermission(role, permission)
end

--- Get all permissions for a player
---@param source number The player source
---@return table permissions List of all permissions the player has
function amb.permissions.GetPlayerPermissions(source)
    local role = amb.permissions.GetPlayerRole(source)
    if not role then
        return {}
    end

    return GetRolePermissions(role)
end

--- Get all available roles
---@return table roles List of all role names with their labels
function amb.permissions.GetAllRoles()
    local roleList = {}
    for roleName, roleData in pairs(permissionsConfig) do
        table.insert(roleList, {
            name = roleName,
            label = roleData.label or roleName,
            permissionCount = roleData.permissions and #roleData.permissions or 0
        })
    end
    return roleList
end

--- Check if a role exists
---@param roleName string The role name to check
---@return boolean exists Whether the role exists
function amb.permissions.RoleExists(roleName)
    return permissionsConfig[roleName] ~= nil
end

--- Get role data
---@param roleName string The role name
---@return table | nil roleData The role data or nil if not found
function amb.permissions.GetRole(roleName)
    return permissionsConfig[roleName]
end

--- Clear permission cache
---@param roleName string | nil Optional role name to clear specific cache
---@return nil
function amb.permissions.ClearCache(roleName)
    if roleName then
        roleCache[roleName] = nil
        for cacheKey in pairs(permissionCache) do
            if cacheKey:find("^" .. roleName .. ":") then
                permissionCache[cacheKey] = nil
            end
        end
    else
        permissionCache = {}
        roleCache = {}
    end
end

--- Add a permission to a role dynamically (runtime only, not persistent)
---@param roleName string The role name
---@param permission string The permission to add
---@return boolean success Whether the permission was added
function amb.permissions.AddPermission(roleName, permission)
    local roleData = permissionsConfig[roleName]
    if not roleData then
        return false
    end

    if not roleData.permissions then
        roleData.permissions = {}
    end

    for _, perm in ipairs(roleData.permissions) do
        if perm == permission then
            return false
        end
    end

    table.insert(roleData.permissions, permission)
    amb.permissions.ClearCache(roleName)

    amb.print.info(("Permission '%s' added to role '%s'"):format(permission, roleName))
    return true
end

--- Remove a permission from a role dynamically (runtime only, not persistent)
---@param roleName string The role name
---@param permission string The permission to remove
---@return boolean success Whether the permission was removed
function amb.permissions.RemovePermission(roleName, permission)
    local roleData = permissionsConfig[roleName]
    if not roleData or not roleData.permissions then
        return false
    end

    for i, perm in ipairs(roleData.permissions) do
        if perm == permission then
            table.remove(roleData.permissions, i)
            amb.permissions.ClearCache(roleName)
            amb.print.info(("Permission '%s' removed from role '%s'"):format(permission, roleName))
            return true
        end
    end

    return false
end

--- Check if a permission string is valid format
---@param permission string The permission to validate
---@return boolean valid Whether the permission format is valid
function amb.permissions.IsValidPermission(permission)
    if not permission or permission == "" then
        return false
    end

    if permission == "*" then
        return true
    end

    return permission:match("^[%w_]+%.[%w_.*]+$") ~= nil
end