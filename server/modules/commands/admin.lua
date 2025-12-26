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

    local targetSessionId = args.target.sessionId
    local itemName = args.item
    local count = args.count or 1
    local metadata = args.metadata and json.decode(args.metadata) or nil

    return exports['Ambitions-Inventory']:AddItem(targetSessionId, itemName, count, nil, metadata)
end, {
    allowConsole = true,
    suggestion = {
        help = "Give an item to a player",
        validate = false,
        arguments = {
            { name = "target", type = "player", help = "Player session ID or 'me'" },
            { name = "item", type = "item", help = "Item name (e.g., water, bread)" },
            { name = "count", type = "number", help = "Quantity (default: 1)", optional = true },
            { name = "metadata", type = "string", help = "JSON metadata", optional = true }
        }
    }
})