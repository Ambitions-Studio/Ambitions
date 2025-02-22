--- Return a new table with all elements that has been filtered by the callback function
---@param tab table The table to filter
---@param cb function The callback function to filter the table
---@return table newTable The filtered table
function ABT.Table.Filter(tab, cb)
    local newTable = {}

    for i = 1, #tab, 1 do
        if cb(tab[i]) then
            table.insert(newTable, tab[i])
        end
    end

    return newTable
end

return ABT.Table.Filter