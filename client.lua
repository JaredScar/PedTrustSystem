local identifiers = {}
function ShowInfo(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentSubstringPlayerName(text)
    DrawNotification(false, false)
end
Citizen.CreateThread(function()
    local myIdss = getIdentifiers()
    print(myIdss)
    while true do
        Citizen.Wait(5000)
        TriggerServerEvent('PedTrustSystem:reloadwl') 
        TriggerServerEvent('PedTrustSystem:Server:Check')
    end
end)
function getConfig()
    return LoadResourceFile(GetCurrentResourceName(), "whitelist.json")
end
AddEventHandler("playerSpawned", function()
    TriggerServerEvent("PedTrustSystem:reloadwl")
end)

function getIdentifiers()
    return identifiers
end
allowedPed = 'a_m_y_skater_01'
RegisterNetEvent('PedTrustSystem:RunCode:Client')
AddEventHandler('PedTrustSystem:RunCode:Client', function(cfg)
    --
    local ped = GetPlayerPed(-1)
    local hashAllowedSkin = GetHashKey(allowedPed)
    local currentModel = GetEntityModel(PlayerPedId())
    local exists = false 
    local allowed = false 
    RequestModel(hashAllowedSkin)
    while not HasModelLoaded(hashAllowedSkin) do 
        RequestModel(hashAllowedSkin)
        Citizen.Wait(0)
    end
    local myIds = {}
    myIds = getIdentifiers()
    for pair,_ in pairs(cfg) do
        -- Pair
        for _,vehic in ipairs(cfg[pair]) do
            --print("Checking if exists with vehic.spawncode == " .. string.upper(vehic.spawncode) .. " and spawncode == "
                --.. string.upper(spawncode))
            if (GetHashKey(vehic.spawncode) == currentModel) then
                exists = true
            end
        end
        if (pair == myIds[1]) then
            for _,v in ipairs(cfg[pair]) do
                --print(v.allowed)
                --print("The vehicle is " .. v.spawncode .. " and allowed = " .. tostring(v.allowed) .. " with ID as " .. tostring(pair))
                if (currentModel == GetHashKey(v.spawncode)) and (v.allowed) then
                    allowed = true
                    print("Allowed was set to true with ped == " .. v.spawncode)
                end
            end
        end
    end
    --print("Value of exists == " .. tostring(exists) .. " and value of allowed == " .. tostring(allowed))
    if (exists and not allowed) then
        --print("It should delete the vehicle for " .. GetPlayerName(source))
        SetPlayerModel(PlayerId(), hashAllowedSkin)
        SetModelAsNoLongerNeeded(hashAllowedSkin)
        TriggerEvent('PedTrustSystem:RunCode:Success', source)
    end
end)

RegisterNetEvent('PedTrustSystem:RunCode:Success')
AddEventHandler('PedTrustSystem:RunCode:Success', function()
    ShowInfo('~r~ERROR: You do not have access to this personal ped')
end)

RegisterNetEvent("PedTrustSystem:loadIdentifiers")
AddEventHandler("PedTrustSystem:loadIdentifiers", function(id)
    identifiers = id
end)

RegisterCommand("reloadPedWL", function(source)
    TriggerServerEvent("PedTrustSystem:reloadwl")
end)

--[[
    Commands:
        /setOwner <id> <spawncode>
        /trust <id> <spawncode>
        /untrust <id> <spawncode>
        /vehicle list
--]]--