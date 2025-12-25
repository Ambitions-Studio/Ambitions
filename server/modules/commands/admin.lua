--- Get player coordinates command
amb.RegisterCommand("getcoords", "admin.getCoords", function(player, args, showMessage)
    if not player then
        return showMessage("This command cannot be used from console")
    end

    local character = player.getCurrentCharacter()
    if not character then
        return showMessage("You need to have an active character", "error")
    end

    local coords = character.getPosition(true, true)
    local coordsString = ("vector4(%.2f, %.2f, %.2f, %.2f)"):format(coords.x, coords.y, coords.z, coords.w)

    showMessage(("Coordinates: %s"):format(coordsString), "info")

    amb.print.info(("%s used /getcoords at %s"):format(
        character.getFullName(),
        coordsString
    ))
end, {
    suggestion = {
        help = "Get your current coordinates"
    }
})

amb.RegisterCommand("giveitem", "admin.giveItem", function(player, args, showMessage)
    local targetCharacter = args.target.getCurrentCharacter()
    if not targetCharacter then
        return showMessage("Target player has no active character", "error")
    end

    local inventoryManager = targetCharacter.getInventoryManager()
    if not inventoryManager then
        return showMessage("Target player has no inventory", "error")
    end

    local targetSessionId = args.target.sessionId
    local itemName = args.item
    local count = args.count
    local metadata = args.metadata and json.decode(args.metadata) or nil

    local success, result = inventoryManager.addItem(targetSessionId, itemName, count, nil, metadata)

    if success then
        local itemLabel = exports['Ambitions-Inventory']:GetItemLabel(itemName)
        local targetName = targetCharacter.getFullName()
        showMessage(("Gave %dx %s to %s"):format(count, itemLabel, targetName), "success")

        amb.print.info(("Admin gave %dx %s to %s (ID: %d)"):format(
            count,
            itemLabel,
            targetName,
            targetSessionId
        ))
    else
        showMessage(("Failed to give item: %s"):format(result), "error")
    end
end, {
    allowConsole = true,
    suggestion = {
        help = "Give an item to a player",
        validate = false,
        arguments = {
            { name = "target", type = "player", help = "Player session ID or 'me'" },
            { name = "item", type = "item", help = "Item name (e.g., water, bread)" },
            { name = "count", type = "number", help = "Quantity to give" },
            { name = "metadata", type = "string", help = "Optional JSON metadata" }
        }
    }
})