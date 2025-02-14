local perms = import('config.server.config_permissions')

--- Check if the player has permissions based on their group or ACE permissions.
---@param source number The player's server ID.
---@return table isPlayerAuthorized The player's permissions table or an empty table if no permissions.
function ABT.HasPermissions(source)
    local isPlayerAuthorized = {}

    local player = ABT.GetPlayerFromId(source)
    if not player then
        ABT.Print.Log(3, ('Player with source %s not found in ABT.Players!'):format(source))
        return {}
    end

    local character = player.getCurrentCharacter()
    if not character then
        ABT.Print.Log(3, ('Character not found for player with source %s!'):format(source))
        return {}
    end

    local playerGroup = character.getGroup()

    --- Check permissions by group
    local groupPermissions = perms.Groups[playerGroup]
    if groupPermissions then
        for k, v in pairs(groupPermissions) do
            isPlayerAuthorized[k] = v
        end
    end

    --- Check permissions by ace permissions
    for permissionCategory, permissions in pairs(perms.AcePermissions) do
        for permName, acePermission in pairs(permissions) do
            if IsPlayerAceAllowed(source, acePermission) then
                isPlayerAuthorized[permissionCategory] = isPlayerAuthorized[permissionCategory] or {}
                isPlayerAuthorized[permissionCategory][permName] = true
            end
        end
    end

    isPlayerAuthorized.open = next(isPlayerAuthorized) ~= nil

    return isPlayerAuthorized
end