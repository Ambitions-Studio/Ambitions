local IsConsuming = false

local FOOD_CONFIG <const> = {
    prop = 'prop_cs_burger_01',
    animDict = 'mp_player_inteat@burger',
    animName = 'mp_player_int_eat_burger_fp',
    animSettings = {8.0, -8, -1, 49, 0, 0, 0, 0},
    propPos = vector3(0.15, 0.03, 0.0),
    propRot = vector3(15.0, 175.0, 5.0),
    duration = 3000
}

local DRINK_CONFIG <const> = {
    prop = 'prop_ld_flow_bottle',
    animDict = 'mp_player_intdrink',
    animName = 'loop_bottle',
    animSettings = {1.0, -1.0, 2000, 0, 1, true, true, true},
    propPos = vector3(0.12, 0.028, 0.001),
    propRot = vector3(10.0, 175.0, 0.0),
    duration = 3000
}

local HAND_BONE <const> = 18905

local function PlayConsumingAnimation(config)
    if IsConsuming then return end

    IsConsuming = true
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    amb.streaming.requestModel(config.prop)
    local prop = CreateObject(joaat(config.prop), coords.x, coords.y, coords.z + 0.2, true, true, true)
    local boneIndex = GetPedBoneIndex(playerPed, HAND_BONE)

    AttachEntityToEntity(
        prop, playerPed, boneIndex,
        config.propPos.x, config.propPos.y, config.propPos.z,
        config.propRot.x, config.propRot.y, config.propRot.z,
        true, true, false, true, 1, true
    )

    amb.streaming.requestAnimDict(config.animDict)
    TaskPlayAnim(playerPed, config.animDict, config.animName, table.unpack(config.animSettings))
    RemoveAnimDict(config.animDict)

    SetTimeout(config.duration, function()
        IsConsuming = false
        ClearPedSecondaryTask(playerPed)
        DeleteObject(prop)
        SetModelAsNoLongerNeeded(joaat(config.prop))
    end)
end

RegisterNetEvent('ambitions:client:consumeFood', function()
    PlayConsumingAnimation(FOOD_CONFIG)
end)

RegisterNetEvent('ambitions:client:consumeDrink', function()
    PlayConsumingAnimation(DRINK_CONFIG)
end)
