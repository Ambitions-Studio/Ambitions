function ABT.Overrides.SetPlayerFunctionOverride(index)
    if not index or not ABT.PlayerFunctionOverrides[index] then
        return ABT.Print.Log(4, 'No player function overrides found for index: ' .. index)
    end
end