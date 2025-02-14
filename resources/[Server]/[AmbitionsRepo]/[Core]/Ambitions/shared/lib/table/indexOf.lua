--- Returns all indexes of a value in a table.
---@param table table The table to search in.
---@param value any The value to search for in the table.
---@return table indexes A table containing all indexes of the value in the table.
function ABT.Table.IndexOf(table, value)
    local indexes = {}
    for i = 1, #table, 1 do
        if table[i] == value then
            table.insert(indexes, i)
        end
    end

    return indexes
end

return ABT.Table.IndexOf