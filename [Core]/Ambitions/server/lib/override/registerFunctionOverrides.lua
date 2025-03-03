--- Function to register player function overrides
--- @param index string The index of the player function
--- @param overrides table The overrides of the player function
function ABT.Overrides.RegisterPlayerFunctionOverrides(index, overrides)
    ABT.PlayerFunctionOverrides[index] = overrides
end