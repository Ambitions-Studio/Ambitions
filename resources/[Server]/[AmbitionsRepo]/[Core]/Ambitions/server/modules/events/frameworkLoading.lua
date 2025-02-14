
local notAuthorizedResources = {
    ["essentialmode"] = true,
    ["es_admin2"] = true,
    ["fivem-map-hipster"] = true,
    ["fivem-map-skater"] = true,
    ["redm-map-one"] = true,
    ["basic-gamemode"] = true,
    ["mapmanager"] = true,
    ["spawnmanager"] = true,
    ["sessionmanager"] = true,
    ["sessionmanager-rdr3"] = true,
    ["qb-core"] = true,
    ["default_spawnpoint"] = true,
}

AddEventHandler("onResourceStart", function(key)
    if notAuthorizedResources[string.lower(key)] then
        while GetResourceState(key) ~= "started" do
            Wait(0)
        end

        StopResource(key)
        error(("Ambitions STOPPED A RESOURCE THAT WILL BREAK ^1Ambitions Framework^1, PLEASE REMOVE ^5%s^1"):format(key))
    end

    if not SetEntityOrphanMode then
        CreateThread(function()
            while true do
            error("Ambitions Requires a minimum Artifact version of 10188, Please update your server.")
                Wait(60 * 1000)
            end
        end)
    end
end)

for key in pairs(notAuthorizedResources) do
    if GetResourceState(key) == "started" or GetResourceState(key) == "starting" then
        StopResource(key)
        error(("Ambitions STOPPED A RESOURCE THAT WILL BREAK ^Ambitions Framework^1, PLEASE REMOVE ^5%s^1"):format(key))
    end
end
