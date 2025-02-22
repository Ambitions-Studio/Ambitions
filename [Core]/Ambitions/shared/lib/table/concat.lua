--- Return a new table with all elements concatenated
---@param firstTable table The first table to concatenate
---@param secondTable table The second table to concatenate
---@return table thirdTable The concatenated table
function ABT.Table.Concat(firstTable, secondTable)
    local thirdTable = ABT.Table.Clone(firstTable)

    for i = 1, #secondTable, 1 do
        table.insert(thirdTable, secondTable[i])
    end

    return thirdTable
end

return ABT.Table.Concat