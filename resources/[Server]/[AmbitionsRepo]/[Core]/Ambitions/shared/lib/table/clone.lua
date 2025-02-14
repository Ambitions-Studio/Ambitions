--- Return a new table with all elements cloned
---@param table table The table to clone
---@return table target The cloned table
function ABT.Table.Clone(table)
    if type(table) ~= 'table' then
        return table
    end

    local meta = getmetatable(table)
    local target = {}

    for k, v in pairs(table) do
        if type(v) == 'table' then
            target[k] = PL.Table.Clone(v)
        else
            target[k] = v
        end
    end

    setmetatable(target, meta)

    return target
end

return ABT.Table.Clone