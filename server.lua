local RSGCore = exports['rsg-core']:GetCoreObject()


RSGCore.Functions.CreateUseableItem('bible', function(source)
    TriggerClientEvent('priest:client:useBible', source)
end)


RegisterNetEvent('priest:server:preach', function(message)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    
   
    for _, playerId in ipairs(GetPlayers()) do
        local targetPed = GetPlayerPed(playerId)
        local targetCoords = GetEntityCoords(targetPed)
        local distance = #(playerCoords - targetCoords)
        
        if distance <= 20.0 then
            TriggerClientEvent('ox_lib:notify', tonumber(playerId), {
                title = 'Priest ' .. playerName,
                description = message,
                type = 'info',
                duration = 8000,
                icon = 'church',
                iconColor = '#d4af37'
            })
        end
    end
end)


RegisterNetEvent('priest:server:bless', function(priestCoords)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local blessedCount = 0
    
   
    for _, playerId in ipairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        local targetPed = GetPlayerPed(targetId)
        local targetCoords = GetEntityCoords(targetPed)
        local distance = #(priestCoords - targetCoords)
        
        if distance <= Config.Blessing.radius then
            local targetPlayer = RSGCore.Functions.GetPlayer(targetId)
            
            if targetPlayer then
                
                TriggerClientEvent('rsg-medic:client:adminHeal', targetId)
                
                
                TriggerClientEvent('priest:client:receiveBlessing', targetId, Config.Blessing.healAmount)
                
                blessedCount = blessedCount + 1
            end
        end
    end
    
   
    TriggerClientEvent('priest:client:blessingCount', src, blessedCount)
end)


RSGCore.Functions.CreateCallback('priest:server:getPlayers', function(source, cb)
    local src = source
    local players = {}
    
    for _, playerId in ipairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        local targetPlayer = RSGCore.Functions.GetPlayer(targetId)
        
        if targetPlayer then
            local playerName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
            
           
            if targetId == src then
                playerName = playerName .. " (You)"
            end
            
            table.insert(players, {
                id = targetId,
                name = playerName,
                isSelf = targetId == src
            })
        end
    end
    
    cb(players)
end)


RegisterNetEvent('priest:server:giveBible', function(targetId)
    local src = source
    local Priest = RSGCore.Functions.GetPlayer(src)
    local Target = RSGCore.Functions.GetPlayer(targetId)
    
    if not Priest or not Target then return end
    
   
    Target.Functions.AddItem('bible', 1)
    TriggerClientEvent('inventory:client:ItemBox', targetId, RSGCore.Shared.Items['bible'], 'add', 1)
    
    
    local priestName = Priest.PlayerData.charinfo.firstname .. ' ' .. Priest.PlayerData.charinfo.lastname
    local targetName = Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname
    
    
    if src == targetId then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Bible Added',
            description = 'You took another bible for yourself',
            type = 'success',
            duration = 5000,
            icon = 'book-bible'
        })
    else
        
        TriggerClientEvent('priest:client:bibleGiven', src, targetName)
        TriggerClientEvent('priest:client:receiveBible', targetId, priestName)
    end
    
    
end)


RegisterNetEvent('priest:server:playHymn', function(priestCoords, hymnTitle, hymnUrl)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    
    for _, playerId in ipairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        local targetPed = GetPlayerPed(targetId)
        local targetCoords = GetEntityCoords(targetPed)
        local distance = #(priestCoords - targetCoords)
        
        
        if distance <= Config.Hymns.radius then
            TriggerClientEvent('priest:client:playHymn', targetId, priestCoords, Config.Hymns.radius, hymnTitle, hymnUrl, Config.Hymns.volume)
        end
    end
    
    
end)


RegisterNetEvent('priest:server:stopHymn', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    
    
    for _, playerId in ipairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        local targetPed = GetPlayerPed(targetId)
        local targetCoords = GetEntityCoords(targetPed)
        local distance = #(playerCoords - targetCoords)
        
        if distance <= Config.Hymns.radius then
            TriggerClientEvent('priest:client:stopHymn', targetId)
        end
    end
end)