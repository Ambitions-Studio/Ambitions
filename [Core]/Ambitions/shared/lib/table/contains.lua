-- Credits: https://github.com/JonasDev99/qb-garages/blob/b0335d67cb72a6b9ac60f62a87fb3946f5c2f33d/server/main.lua#L5
--- Return true if the table contains the value or false if it doesn't
---@param tab table The table to search in
---@param val any The value to search for in the table
---@return boolean contains True if the table contains the value, false if it doesn't
function ABT.Table.TableContains(tab, val)
    if type(val) == 'table' then
        for _, value in pairs(tab) do
            if ABT.Table.TableContains(val, value) then
                return true
            end
        end
        return false
    else
        for _, value in pairs(tab) do
            if value == val then
                return true
            end
        end
    end
    return false
end

return ABT.Table.TableContains