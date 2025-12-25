--- Hide the HUD from screen
---@return void
function amb.HideHud()
    if GetResourceState('Ambitions-Hud') ~= 'missing' then
        exports['Ambitions-Hud']:HideHUD()
    end
end
