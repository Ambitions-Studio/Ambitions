--- Test needs command
amb.RegisterCommand("testneed", "ambitioneer.testNeed", function(player, args, showMessage)
    if not player then
        return showMessage("This command can only be used by players", "error")
    end

    local character = player.getCurrentCharacter()
    if not character then
        return showMessage("You have no active character", "error")
    end

    local needs = character.getNeeds()
    local needsText = ""

    for needType, value in pairs(needs) do
        needsText = needsText .. ("%s: %d/100 | "):format(needType, value)
    end

    needsText = needsText:sub(1, -4)

    TriggerClientEvent('amb:showNotification', player.sessionId, "Needs Debug", needsText, "debug", 6000, "top-right")
end, {
    allowConsole = false,
    suggestion = {
        help = "Display your current needs levels",
        validate = false
    }
})

amb.RegisterCommand("debuginventory", "ambitioneer.debugInventory", function(player, args, showMessage)
    local targetCharacter = args.target.getCurrentCharacter()
    if not targetCharacter then
        return showMessage("Target player has no active character", "error")
    end

    local inventoryManager = targetCharacter.getInventoryManager()
    if not inventoryManager then
        return showMessage("Target player has no inventory manager", "error")
    end

    local items = inventoryManager.getItems()
    local maxSlots = inventoryManager.getMaxSlots()
    local maxWeight = inventoryManager.getMaxWeight()

    amb.print.info("=== DEBUG INVENTORY ===")
    amb.print.info("Target: " .. targetCharacter.getFullName())
    amb.print.info("Max Slots: " .. tostring(maxSlots))
    amb.print.info("Max Weight: " .. tostring(maxWeight))
    amb.print.info("Items table type: " .. type(items))
    amb.print.info("Items table address: " .. tostring(items))
    amb.print.info("--- SLOTS ---")

    local itemCount = 0
    for slot, itemData in pairs(items) do
        itemCount = itemCount + 1
        amb.print.info(("Slot %d: %s x%d (meta: %s)"):format(
            slot,
            itemData.name,
            itemData.count,
            json.encode(itemData.metadata or {})
        ))
    end

    if itemCount == 0 then
        amb.print.info("(No items in inventory)")
    end

    amb.print.info("Total occupied slots: " .. tostring(itemCount))
    amb.print.info("=== END DEBUG ===")

    showMessage("Debug info printed to server console", "info")
end, {
    allowConsole = true,
    suggestion = {
        help = "Debug a player's inventory cache",
        arguments = {
            { name = "target", type = "player", help = "Player session ID or 'me'" }
        }
    }
})

--- Set player role command
amb.RegisterCommand("setrole", "ambitioneer.setRole", function(player, args, showMessage)
    if not amb.permissions.RoleExists(args.role) then
        return showMessage(("Role '%s' does not exist"):format(args.role), "error")
    end

    local targetCharacter = args.target.getCurrentCharacter()
    if not targetCharacter then
        return showMessage("Target player has no active character", "error")
    end

    local oldRole = targetCharacter.getGroup()
    targetCharacter.setGroup(args.role)

    local targetName = targetCharacter.getFullName()
    local successMessage = ("Role changed: %s (%s -> %s)"):format(targetName, oldRole, args.role)

    showMessage(successMessage, "success")

    if player then
        local executorCharacter = player.getCurrentCharacter()
        amb.print.info(("%s changed %s's role from '%s' to '%s'"):format(
            executorCharacter.getFullName(),
            targetName,
            oldRole,
            args.role
        ))
    else
        amb.print.info(("Console changed %s's role from '%s' to '%s'"):format(
            targetName,
            oldRole,
            args.role
        ))
    end
end, {
    allowConsole = true,
    suggestion = {
        help = "Change a player's role",
        validate = true,
        arguments = {
            { name = "target", type = "player", help = "Player session ID" },
            { name = "role", type = "string", help = "Role name (user, admin, ambitioneer)" }
        }
    }
})