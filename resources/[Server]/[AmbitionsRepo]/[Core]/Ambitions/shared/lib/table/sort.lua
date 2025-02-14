-- Credit: https://stackoverflow.com/a/15706820
--- Return a new table with all elements sorted by the order function
---@param tab table The table to sort the elements of
---@param order function The order function to sort the elements with
---@return function iterator The iterator function to iterate over the sorted table
function ABT.Table.Sort(tab, order)
    local keys = {}

    for k, _ in pairs(tab) do
        keys[#keys + 1] = k
    end

    if order then
        table.sort(keys, function(a, b)
            return order(tab, a, b)
        end)
    else
        table.sort(keys)
    end

    local i = 0

    return function()
        i = i + 1
        if keys[i] then
            return keys[i], tab[keys[i]]
        end
    end
end

return ABT.Table.Sort