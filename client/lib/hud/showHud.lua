--- Show the HUD on screen
---@return void
function amb.ShowHud()
    if GetResourceState('Ambitions-Hud') ~= 'missing' then
        exports['Ambitions-Hud']:ShowHUD()
    end
end