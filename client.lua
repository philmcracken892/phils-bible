local RSGCore = exports['rsg-core']:GetCoreObject()
local isHoldingBible = false
local currentAction = nil
local onCooldown = false
local activeHymnSound = nil
local hymnPlaying = false
local isMenuOpen = false
local inputPending = false
local inputData = nil

---------------------------------
-- NUI FUNCTIONS
---------------------------------

local function Notify(data)
    SendNUIMessage({
        action = 'showNotification',
        data = data
    })
end

local function ShowMenu(menuData)
    isMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showMenu',
        data = menuData
    })
end

local function HideMenu()
    isMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'hideMenu'
    })
end

local function ShowInput(inputConfig, callback)
    inputPending = true
    inputData = { callback = callback }
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showInput',
        data = inputConfig
    })
end

local function HideInput()
    inputPending = false
    inputData = nil
    if not isMenuOpen then
        SetNuiFocus(false, false)
    end
    SendNUIMessage({
        action = 'hideInput'
    })
end

---------------------------------
-- UTILITY FUNCTIONS
---------------------------------

local function StopBibleAnimation()
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    isHoldingBible = false
    currentAction = nil
end

local function StartBibleScenario()
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    TaskStartScenarioInPlace(ped, GetHashKey(Config.Scenario), 0, true, false, false, false)
end

local function isXsoundAvailable()
    return GetResourceState('xsound') == 'started'
end

---------------------------------
-- BIBLE ACTIONS
---------------------------------

local function ReadBible()
    if isHoldingBible then
        StopBibleAnimation()
    end
    
    StartBibleScenario()
    
    isHoldingBible = true
    currentAction = 'reading'
    
    Notify({
        title = 'Holy Bible',
        description = Config.Messages.reading,
        type = 'info',
        icon = 'book-bible',
        duration = 5000
    })
end

local function HoldBible()
    if isHoldingBible then
        StopBibleAnimation()
    end
    
    StartBibleScenario()
    
    isHoldingBible = true
    currentAction = 'holding'
    
    Notify({
        title = 'Holy Bible',
        description = Config.Messages.holding,
        type = 'info',
        icon = 'book',
        duration = 5000
    })
end

---------------------------------
-- BLESSING FUNCTIONS
---------------------------------

local function Bless()
    if onCooldown then
        Notify({
            title = 'Blessing',
            description = Config.Messages.cooldown,
            type = 'error',
            icon = 'clock',
            duration = 3000
        })
        return
    end
    
    if isHoldingBible then
        StopBibleAnimation()
    end
    
    StartBibleScenario()
    
    isHoldingBible = true
    currentAction = 'blessing'
    
    Notify({
        title = 'Blessing',
        description = Config.Messages.blessing,
        type = 'success',
        icon = 'hands-praying',
        duration = 5000
    })
    
    TriggerServerEvent('priest:server:bless', GetEntityCoords(PlayerPedId()))
    
    onCooldown = true
    SetTimeout(Config.Blessing.cooldown, function()
        onCooldown = false
    end)
end

RegisterNetEvent('priest:client:receiveBlessing', function(healAmount)
    Notify({
        title = 'Divine Blessing',
        description = Config.Messages.blessed,
        type = 'success',
        icon = 'cross',
        duration = 5000
    })
end)

RegisterNetEvent('priest:client:blessingCount', function(count)
    if count > 0 then
        Notify({
            title = 'Blessing Complete',
            description = string.format(Config.Messages.blessedSelf, count),
            type = 'success',
            icon = 'hands-praying',
            duration = 5000
        })
    else
        Notify({
            title = 'Blessing',
            description = Config.Messages.noNearby,
            type = 'warning',
            icon = 'triangle-exclamation',
            duration = 3000
        })
    end
end)

---------------------------------
-- NOTIFICATION & SERMON EVENTS
---------------------------------

RegisterNetEvent('priest:client:notify', function(data)
    Notify(data)
end)

-- Sermon display (NO MOUSE LOCK - display only!)
RegisterNetEvent('priest:client:showSermon', function(data)
    SendNUIMessage({
        action = 'showSermon',
        data = data
    })
    -- NO SetNuiFocus here! Player keeps full control
end)

-- Allow player to dismiss sermon with Backspace
CreateThread(function()
    while true do
        Wait(0)
        -- Backspace key to dismiss sermon
        if IsControlJustPressed(0, 0x156F7119) then -- INPUT_CELLPHONE_CANCEL (Backspace)
            SendNUIMessage({
                action = 'hideSermon'
            })
        end
    end
end)

---------------------------------
-- HYMN FUNCTIONS
---------------------------------

local function StopHymn()
    if activeHymnSound then
        exports.xsound:Destroy(activeHymnSound)
        activeHymnSound = nil
    end
    
    hymnPlaying = false
    
    Notify({
        title = 'Hymn Ended',
        description = Config.Messages.hymnStopped,
        type = 'info',
        icon = 'music',
        duration = 3000
    })
end

local function PlayHymn(hymnTitle, hymnUrl)
    if not isXsoundAvailable() then
        Notify({
            title = 'Error',
            description = Config.Messages.xsoundNotFound,
            type = 'error',
            icon = 'exclamation-triangle',
            duration = 5000
        })
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    if hymnPlaying or activeHymnSound then
        TriggerServerEvent('priest:server:stopHymn')
        Wait(500)
    end
    
    TriggerServerEvent('priest:server:playHymn', playerCoords, hymnTitle, hymnUrl)
end

RegisterNetEvent('priest:client:playHymn', function(coords, radius, hymnTitle, hymnUrl, volume)
    if not isXsoundAvailable() then return end
    
    if activeHymnSound then
        exports.xsound:Destroy(activeHymnSound)
        Wait(100)
    end
    
    hymnPlaying = false
    
    local soundId = 'priest_hymn_' .. math.random(10000, 99999)
    activeHymnSound = soundId
    
    exports.xsound:PlayUrlPos(soundId, hymnUrl, volume, coords, false)
    exports.xsound:Distance(soundId, radius)
    
    Wait(100)
    hymnPlaying = true
    
    Notify({
        title = 'Sacred Hymn',
        description = string.format(Config.Messages.hymnPlaying, hymnTitle),
        type = 'info',
        icon = 'music',
        duration = 5000
    })
end)

RegisterNetEvent('priest:client:stopHymn', function()
    StopHymn()
end)

---------------------------------
-- GIVE BIBLE FUNCTIONS
---------------------------------

RegisterNetEvent('priest:client:receiveBible', function(priestName)
    Notify({
        title = 'Holy Gift',
        description = string.format(Config.Messages.bibleReceived, priestName),
        type = 'success',
        icon = 'book-bible',
        duration = 7000
    })
end)

RegisterNetEvent('priest:client:bibleGiven', function(playerName)
    Notify({
        title = 'Bible Given',
        description = string.format(Config.Messages.bibleGiven, playerName),
        type = 'success',
        icon = 'gift',
        duration = 5000
    })
end)

---------------------------------
-- FORWARD DECLARATIONS
---------------------------------

local OpenBibleMenu
local SelectSermon
local SelectHymn
local GiveBible

---------------------------------
-- PREACHING FUNCTIONS
---------------------------------

SelectSermon = function()
    local sermonOptions = {}
    
    for i, sermon in ipairs(Config.Sermons) do
        table.insert(sermonOptions, {
            title = sermon.title,
            description = sermon.description,
            icon = 'book-bible',
            action = 'sermon',
            data = { sermonIndex = i }
        })
    end
    
    table.insert(sermonOptions, {
        title = '← Back',
        description = 'Return to bible menu',
        icon = 'arrow-left',
        action = 'back',
        isBack = true
    })
    
    ShowMenu({
        title = 'Select Sermon',
        type = 'sermon',
        options = sermonOptions
    })
end

local function Preach()
    if isHoldingBible then
        StopBibleAnimation()
    end
    
    StartBibleScenario()
    
    isHoldingBible = true
    currentAction = 'preaching'
    
    Notify({
        title = 'Holy Bible',
        description = Config.Messages.preaching,
        type = 'info',
        icon = 'church',
        duration = 5000
    })
    
    SelectSermon()
end

---------------------------------
-- HYMN MENU
---------------------------------

SelectHymn = function()
    if not Config.Hymns.enabled then
        Notify({
            title = 'Hymns',
            description = 'Hymns are currently disabled',
            type = 'error',
            icon = 'music',
            duration = 3000
        })
        return
    end
    
    local hymnOptions = {}
    
    if hymnPlaying then
        table.insert(hymnOptions, {
            title = '⏹ Stop Current Hymn',
            description = 'End the hymn that is currently playing',
            icon = 'stop',
            iconColor = 'linear-gradient(135deg, #e74c3c 0%, #c0392b 100%)',
            action = 'stopHymnMenu',
            isStopHymn = true
        })
    end
    
    for i, hymn in ipairs(Config.Hymns.songs) do
        table.insert(hymnOptions, {
            title = hymn.title,
            description = hymn.description,
            icon = 'music',
            iconColor = 'linear-gradient(135deg, #9b59b6 0%, #8e44ad 100%)',
            action = 'playHymn',
            data = { hymnIndex = i }
        })
    end
    
    table.insert(hymnOptions, {
        title = '← Back',
        description = 'Return to bible menu',
        icon = 'arrow-left',
        action = 'back',
        isBack = true
    })
    
    ShowMenu({
        title = 'Select Hymn',
        type = 'hymn',
        options = hymnOptions
    })
end

---------------------------------
-- GIVE BIBLE MENU
---------------------------------

GiveBible = function()
    RSGCore.Functions.TriggerCallback('priest:server:getPlayers', function(players)
        if not players or #players == 0 then
            Notify({
                title = 'Give Bible',
                description = Config.Messages.noPlayers,
                type = 'warning',
                icon = 'users',
                duration = 3000
            })
            return
        end
        
        local playerOptions = {}
        
        for _, player in ipairs(players) do
            local iconColor = player.isSelf and 'linear-gradient(135deg, #3498db 0%, #2980b9 100%)' or 'linear-gradient(135deg, #d4af37 0%, #b8942e 100%)'
            local description = player.isSelf and 'Take another bible for yourself' or ('ID: ' .. player.id .. ' | Give them a holy bible')
            
            table.insert(playerOptions, {
                title = player.name,
                description = description,
                icon = 'user',
                iconColor = iconColor,
                action = 'givePlayer',
                data = { playerId = player.id }
            })
        end
        
        table.insert(playerOptions, {
            title = '← Back',
            description = 'Return to bible menu',
            icon = 'arrow-left',
            action = 'back',
            isBack = true
        })
        
        ShowMenu({
            title = 'Give Bible To...',
            type = 'give',
            options = playerOptions
        })
    end)
end

---------------------------------
-- MAIN MENU
---------------------------------

OpenBibleMenu = function()
    local options = {}
    
    for _, option in ipairs(Config.MenuOptions) do
        table.insert(options, {
            title = option.title,
            description = option.description,
            icon = option.icon,
            action = option.action
        })
    end
    
    if hymnPlaying then
        local insertPosition = #options
        for i, opt in ipairs(options) do
            if Config.MenuOptions[i] and Config.MenuOptions[i].action == 'stop' then
                insertPosition = i
                break
            end
        end
        
        table.insert(options, insertPosition, {
            title = '⏹ Stop Hymn',
            description = 'Stop the currently playing hymn',
            icon = 'stop',
            action = 'stophymn',
            isStopHymn = true
        })
    end
    
    ShowMenu({
        title = 'Sacred Actions',
        type = 'main',
        options = options
    })
end

---------------------------------
-- NUI CALLBACKS
---------------------------------

RegisterNUICallback('closeMenu', function(data, cb)
    HideMenu()
    cb('ok')
end)

RegisterNUICallback('menuSelect', function(data, cb)
    local action = data.action
    
    if action == 'read' then
        HideMenu()
        ReadBible()
    elseif action == 'hold' then
        HideMenu()
        HoldBible()
    elseif action == 'preach' then
        HideMenu()
        Wait(100)
        Preach()
    elseif action == 'hymn' then
        SelectHymn()
    elseif action == 'bless' then
        HideMenu()
        Bless()
    elseif action == 'give' then
        GiveBible()
    elseif action == 'stop' then
        HideMenu()
        StopBibleAnimation()
        Notify({
            title = 'Holy Bible',
            description = Config.Messages.stopped,
            type = 'info',
            icon = 'book',
            duration = 3000
        })
    elseif action == 'stophymn' then
        if hymnPlaying then
            TriggerServerEvent('priest:server:stopHymn')
            Wait(500)
            OpenBibleMenu()
        else
            Notify({
                title = 'Stop Hymn',
                description = 'No hymn is currently playing',
                type = 'warning',
                icon = 'music',
                duration = 3000
            })
        end
    elseif action == 'back' then
        OpenBibleMenu()
    elseif action == 'sermon' then
        local sermonData = data.data
        if sermonData and sermonData.sermonIndex then
            local sermonIndex = sermonData.sermonIndex
            local sermon = Config.Sermons[sermonIndex]
            
            if sermon then
                if sermon.custom then
                    ShowInput({
                        title = 'Custom Sermon',
                        inputs = {
                            {
                                type = 'textarea',
                                label = 'Your Message',
                                description = 'Enter your sermon message',
                                required = true,
                                min = 10,
                                max = 2000,
                                placeholder = 'Enter your sermon here...'
                            }
                        }
                    }, function(values)
                        if values and values[1] and values[1] ~= '' then
                            TriggerServerEvent('priest:server:preach', values[1])
                        end
                        Wait(100)
                        OpenBibleMenu()
                    end)
                else
                    HideMenu()
                    TriggerServerEvent('priest:server:preach', sermon.message)
                end
            end
        end
    elseif action == 'playHymn' then
        local hymnData = data.data
        if hymnData and hymnData.hymnIndex then
            local hymnIndex = hymnData.hymnIndex
            local hymn = Config.Hymns.songs[hymnIndex]
            
            if hymn then
                if hymn.custom then
                    ShowInput({
                        title = 'Custom Hymn',
                        inputs = {
                            {
                                type = 'input',
                                label = 'Hymn Title',
                                description = 'Enter the hymn name',
                                required = true,
                                min = 3,
                                max = 50,
                                placeholder = 'Amazing Grace...'
                            },
                            {
                                type = 'input',
                                label = 'YouTube URL',
                                description = 'Enter YouTube or direct audio URL',
                                required = true,
                                min = 10,
                                max = 200,
                                placeholder = 'https://youtube.com/watch?v=...'
                            }
                        }
                    }, function(values)
                        if values and values[1] and values[2] then
                            PlayHymn(values[1], values[2])
                        end
                        Wait(100)
                        OpenBibleMenu()
                    end)
                else
                    PlayHymn(hymn.title, hymn.url)
                    Wait(100)
                    OpenBibleMenu()
                end
            end
        end
    elseif action == 'stopHymnMenu' then
        TriggerServerEvent('priest:server:stopHymn')
        Wait(500)
        OpenBibleMenu()
    elseif action == 'givePlayer' then
        local playerData = data.data
        if playerData and playerData.playerId then
            TriggerServerEvent('priest:server:giveBible', playerData.playerId)
        end
        Wait(100)
        OpenBibleMenu()
    end
    
    cb('ok')
end)

RegisterNUICallback('inputSubmit', function(data, cb)
    if inputData and inputData.callback then
        inputData.callback(data.values)
    end
    HideInput()
    cb('ok')
end)

RegisterNUICallback('inputCancel', function(data, cb)
    if inputData and inputData.callback then
        inputData.callback(nil)
    end
    HideInput()
    if isMenuOpen then
        SetNuiFocus(true, true)
    else
        OpenBibleMenu()
    end
    cb('ok')
end)

---------------------------------
-- EVENTS
---------------------------------

RegisterNetEvent('priest:client:useBible', function()
    local PlayerData = RSGCore.Functions.GetPlayerData()
    
    if Config.PriestJob and PlayerData.job and PlayerData.job.name ~= Config.PriestJob then
        Notify({
            title = 'Holy Bible',
            description = Config.Messages.notPriest,
            type = 'error',
            icon = 'ban',
            duration = 3000
        })
        return
    end
    
    OpenBibleMenu()
end)

---------------------------------
-- CLEANUP & SAFETY
---------------------------------

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if isHoldingBible then
            StopBibleAnimation()
        end
        if activeHymnSound then
            StopHymn()
        end
        SetNuiFocus(false, false)
    end
end)

AddEventHandler('gameEventTriggered', function(event, data)
    if event == 'CEventNetworkEntityDamage' then
        local victim = data[1]
        if victim == PlayerPedId() and IsEntityDead(victim) then
            if isHoldingBible then
                StopBibleAnimation()
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if isHoldingBible then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) or IsPedRagdoll(ped) or IsEntityDead(ped) then
                StopBibleAnimation()
            end
        end
    end
end)

print('[Priest Bible] Client loaded successfully!')