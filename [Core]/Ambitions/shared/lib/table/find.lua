--- Return the first element in the table that satisfies the callback function
---@param table table The table to search in
---@param cb function The callback function to search the table
---@return any element The element that satisfies the callback function
function ABT.Table.Find(table, cb)
    for i = 1, #table, 1 do
        if cb(table[i]) then
            return table[i]
        end
    end

    return nil
end

return ABT.Table.Find