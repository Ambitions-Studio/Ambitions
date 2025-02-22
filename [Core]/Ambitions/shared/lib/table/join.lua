--- Return a string with all elements joined by a separator
---@param table table The table to join the elements of
---@param separator string The separator to join the elements with
---@return string str The joined string
function ABT.Table.Join(table, separator)
    local str = ''

    for i = 1, #table, 1 do
        if i > 1 then
            str = str .. (separator or ',')
        end

        str = str .. table[i]
    end

    return str
end

return ABT.Table.Join