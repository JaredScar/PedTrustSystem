
prefix = '^0[^6PedTrustSystem^0] '

-- Code --
RegisterServerEvent("PedTrustSystem:reloadwl")
AddEventHandler("PedTrustSystem:reloadwl", function()
    local _source = source
    local identifiers = GetPlayerIdentifiers(_source)
    TriggerClientEvent("PedTrustSystem:loadIdentifiers", _source, identifiers)
end)

AddEventHandler("playerSpawned", function()
    TriggerEvent("PedTrustSystem:getIdentifiers")
end)

RegisterServerEvent("PedTrustSystem:saveFile")
AddEventHandler("PedTrustSystem:saveFile", function(data)
    SaveResourceFile(GetCurrentResourceName(), "whitelist.json", json.encode(data, { indent = true }), -1)
end)
function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end
function get_index (tab, val)
    local counter = 1
    for index, value in ipairs(tab) do
        if value == val then
            return counter
        end
        counter = counter + 1
    end

    return nil
end
RegisterNetEvent('PedTrustSystem:Server:Check')
AddEventHandler('PedTrustSystem:Server:Check', function()
    local config = LoadResourceFile(GetCurrentResourceName(), "whitelist.json")
    local cfg = json.decode(config)
    TriggerClientEvent('PedTrustSystem:RunCode:Client', source, cfg)
end)

--- COMMANDS ---
RegisterCommand("peds", function(source, args, rawCommand)
    -- Get the peds they can drive
    local al = LoadResourceFile(GetCurrentResourceName(), "whitelist.json")
    local cfg = json.decode(al)
    local allowed = {}
    local myIds = GetPlayerIdentifiers(source)
    for pair,_ in pairs(cfg) do
        -- Pair
        if (pair == myIds[1]) then
            for _,v in ipairs(cfg[pair]) do
                --print(v.allowed)
                --print("The ped is " .. v.spawncode .. " and allowed = " .. tostring(v.allowed) .. " with ID as " .. tostring(pair))
                if (v.allowed) then
                    table.insert(allowed, v.spawncode)
                end
            end
        end
    end
    if #allowed > 0 then
        TriggerClientEvent('chatMessage', source, prefix .. "^2You are allowed access to drive the following peds:")
        TriggerClientEvent('chatMessage', source, "^0" .. table.concat(allowed, ', '))
    else
        TriggerClientEvent('chatMessage', source, prefix .. "^1Sadly no one has gave you access to drive a personal ped :(")
    end
end)
RegisterCommand("clearPed", function(source, args, rawCommand)
    -- /clear <spawncode> == Basically reset a ped's data (owners and allowed to drive)
    if IsPlayerAceAllowed(source, "PedTrustSystem.Access") then
        -- Check args
        if #args < 1 then
            TriggerClientEvent('chatMessage', source, prefix .. "^1ERROR: Not enough arguments... ^1Valid: /clearPed <spawncode>")
            return;
        end
        local pedd = string.upper(args[1])
        local al = LoadResourceFile(GetCurrentResourceName(), "whitelist.json")
        local cfg = json.decode(al)
        for pair,_ in pairs(cfg) do
            -- Pair
            local ind = 0
            for _,ped in ipairs(cfg[pair]) do
                ind = ind + 1
                if string.upper(ped.spawncode) == string.upper(pedd) then
                    table.remove(cfg[pair], ind)
                end
            end
        end
        TriggerClientEvent('chatMessage', source, prefix .. "^2Success: Removed all data of ped ^5" .. pedd .. "^2")
        TriggerClientEvent('pedwl:Cache:Update:Clearped', -1, pedd)
        TriggerEvent("PedTrustSystem:saveFile", cfg)
    end
end)
RegisterCommand("setPedOwner", function(source, args, rawCommand)
    -- Needs a staff Ace perm to do this
    if IsPlayerAceAllowed(source, "PedTrustSystem.Access") then
        if #args < 2 then
            -- Too low args
            TriggerClientEvent('chatMessage', source, prefix .. "^1ERROR: Not enough arguments... ^1Valid: /setPedOwner <id> <pedspawncode>")
            return;
        end
        local id = tonumber(args[1])
        --print(GetPlayerIdentifiers(id)[1])
        if GetPlayerIdentifiers(id)[1] == nil then
            TriggerClientEvent('chatMessage', source, prefix .. "^1ERROR: That is not a valid server ID of a player...")
            return;
        end
        -- /setOwner <id> <ped>
        local pedSpawn = string.upper(args[2])
        local identifiers = GetPlayerIdentifiers(id)
        local steam = identifiers[1]
        local al = LoadResourceFile(GetCurrentResourceName(), "whitelist.json")
        local cfg = json.decode(al)
        -- Check that no one owns this ped before setting it:
        local peddOwned = false
        -- Check below:
        for pair,_ in pairs(cfg) do
            -- Pair
            for _,pedd in ipairs(cfg[pair]) do
                if string.upper(pedd.spawncode) == string.upper(pedSpawn) then
                    if pedd.owner == true then
                        peddOwned = true
                    end
                end
            end
        end
        -- Is it owned already?
        if not peddOwned then
            local pedsList = cfg[steam]
            if pedsList == nil then
                cfg[steam] = {}
                pedsList = {}
            end
            local hasValue = false
            local index = nil
            for i = 1, #pedsList do
                if string.upper(pedSpawn) == string.upper(pedsList[i].spawncode) then
                    hasValue = true
                    index = i
                end
            end
            if not hasValue then
                -- Doesn't have it, add it
                table.insert(pedsList, {
                    owner=true,
                    allowed=true,
                    spawncode=pedSpawn,
                })
            else
                -- It does have it, set it
                pedsList[index].owner = true
                pedsList[index].allowed = true
            end
            cfg[steam] = pedsList
            TriggerEvent("PedTrustSystem:saveFile", cfg)      
            TriggerClientEvent('chatMessage', source, prefix .. "^2Success: You have set ^5" 
                .. GetPlayerName(id) .. "^2 as the owner to the ped ^5" .. pedSpawn)
            TriggerClientEvent('chatMessage', id, prefix .. "^2You have been set " 
                .. " to the owner of ped ^5" .. pedSpawn .. "^2 by ^5" .. GetPlayerName(source))
        else
            -- ped is owned, need to /clear it first
            TriggerClientEvent('chatMessage', source, prefix .. 
                "^1ERROR: That ped is owned by someone already... Use /clearPed <spawncode> to clear it's data")
        end
    end -- Can't use it if not allowed
end)

RegisterCommand("trustPed", function(source, args, rawCommand)
    local al = LoadResourceFile(GetCurrentResourceName(), "whitelist.json")
    local cfg = json.decode(al)
    -- /trust <id> <ped>
    local pedd = string.upper(args[2])
    local id = tonumber(args[1])
    -- Check args
    if #args < 2 then
        TriggerClientEvent('chatMessage', source, prefix .. "^1ERROR: Not enough arguments... ^1Valid: /trustPed <id> <pedspawncode>")
        return;
    end
    -- Check if valid id
    if id == source then
        TriggerClientEvent('chatMessage', source, prefix .. "^1ERROR: You cannot trust yourself...")
        return;
    end
    if GetPlayerIdentifiers(id)[1] == nil then
        -- It's invalid
        TriggerClientEvent('chatMessage', source, prefix .. "^1ERROR: That is not a valid server ID of a player...")
        return;
    end
    local steam = GetPlayerIdentifiers(id)[1]
    -- Check if has ped ownership and can do this command
    local peddOwned = false
    -- Check below:
    for pair,_ in pairs(cfg) do
        -- Pair
        if tostring(GetPlayerIdentifiers(source)[1]) == tostring(pair) then 
            for _,ped in ipairs(cfg[pair]) do
                if string.upper(ped.spawncode) == string.upper(pedd) then
                    if ped.owner == true then
                        peddOwned = true
                    end
                end
            end
        end
    end
    if not peddOwned then
        -- They do not own it, end this
        TriggerClientEvent('chatMessage', source, prefix .. "^1ERROR: You do not own this ped...")
        return;
    end
    local pedsList = cfg[steam]
    if pedsList == nil then
        cfg[steam] = {}
        pedsList = {}
    end
    local hasValue = false
    local index = nil
    for i = 1, #pedsList do
        if string.upper(pedd) == string.upper(pedsList[i].spawncode) then
            hasValue = true
            index = i
        end
    end
    if not hasValue then
        -- Doesn't have it, add it
        table.insert(pedsList, {
            owner=false,
            allowed=true,
            spawncode=pedd,
        })
    else
        -- It does have it, set it
        pedsList[index].owner = false
        pedsList[index].allowed = true
    end
    cfg[steam] = pedsList
    TriggerEvent("PedTrustSystem:saveFile", cfg)
    TriggerClientEvent('chatMessage', source, prefix .. "^2Success: You have given player ^5" 
        .. GetPlayerName(id) .. "^2 permission to utilize your ped ^5"
     .. pedd)
    TriggerClientEvent('chatMessage', id, prefix .. "^2You have been trusted " 
                .. " to use the ped, ^5" .. pedd .. "^2 by owner ^5" .. GetPlayerName(source))
end)

RegisterCommand("untrustPed", function(source, args, rawCommand)
    local al = LoadResourceFile(GetCurrentResourceName(), "whitelist.json")
    local cfg = json.decode(al)
    -- /untrust <id> <ped>
    local pedd = string.upper(args[2])
    local id = tonumber(args[1])
    -- Check args
    if #args < 2 then
        TriggerClientEvent('chatMessage', source, prefix .. "^1ERROR: Not enough arguments... ^1Valid: /untrustPed <id> <pedspawncode>")
        return;
    end
    -- Check if valid id
    if id == source then
        TriggerClientEvent('chatMessage', source, prefix .. "^1ERROR: You cannot untrust yourself...")
        return;
    end
    if GetPlayerIdentifiers(id)[1] == nil then
        -- It's invalid
        TriggerClientEvent('chatMessage', source, prefix .. "^1ERROR: That is not a valid server ID of a player...")
        return;
    end
    local steam = GetPlayerIdentifiers(id)[1]
    -- Check if has ped ownership and can do this command
    local peddOwned = false
    -- Check below:
    for pair,_ in pairs(cfg) do
        -- Pair
        if tostring(GetPlayerIdentifiers(source)[1]) == tostring(pair) then 
            for _,ped in ipairs(cfg[pair]) do
                if string.upper(ped.spawncode) == string.upper(pedd) then
                    if ped.owner == true then
                        peddOwned = true
                    end
                end
            end
        end
    end
    if not peddOwned then
        -- They do not own it, end this
        TriggerClientEvent('chatMessage', source, prefix .. "^1ERROR: You do not own this ped...")
        return;
    end
    local pedsList = cfg[steam]
    if pedsList == nil then
        cfg[steam] = {}
        pedsList = {}
    end
    local hasValue = false
    local index = nil
    for i = 1, #pedsList do
        if string.upper(pedd) == string.upper(pedsList[i].spawncode) then
            hasValue = true
            index = i
        end
    end
    if not hasValue then
        -- Doesn't have it, add it
        table.insert(pedsList, {
            owner=false,
            allowed=false,
            spawncode=pedd,
        })
    else
        -- It does have it, set it
        pedsList[index].owner = false
        pedsList[index].allowed = false
    end
    cfg[steam] = pedsList
    TriggerEvent("PedTrustSystem:saveFile", cfg)
    TriggerClientEvent('chatMessage', source, prefix .. "^2Success: ^1Player " 
        .. GetPlayerName(id) .. "^1 no longer has permission to utilize your ped ^5"
     .. pedd)
    TriggerClientEvent('chatMessage', id, prefix .. "^1Your " 
                .. " trust to use the ped ^5" .. pedd .. " ^1has been revoked by owner ^5" .. GetPlayerName(source))
end)