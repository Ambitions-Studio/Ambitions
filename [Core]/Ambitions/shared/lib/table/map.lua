--- Return a new table with all elements that has been mapped by the callback function
---@param table table The table to map the elements of
---@param cb function The callback function to map the elements with
---@return table newTable The mapped table
function ABT.Table.Map(table, cb)
    local newTable = {}

    for i = 1, #table, 1 do
        newTable[i] = cb(table[i], i)
    end

    return newTable
end

return ABT.Table.Map