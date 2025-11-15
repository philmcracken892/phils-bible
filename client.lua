local RSGCore = exports['rsg-core']:GetCoreObject()
local isHoldingBible = false
local currentAction = nil
local onCooldown = false
local activeHymnSound = nil
local hymnPlaying = false

---------------------------------
-- UTILITY FUNCTIONS
---------------------------------

-- Function to stop animation
local function StopBibleAnimation()
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    isHoldingBible = false
    currentAction = nil
end

-- Function to start scenario with bible
local function StartBibleScenario()
    local ped = PlayerPedId()
    
    -- Clear any existing tasks
    ClearPedTasksImmediately(ped)
    
    -- Start the scenario (this includes the book prop automatically)
    TaskStartScenarioInPlace(ped, GetHashKey(Config.Scenario), 0, true, false, false, false)
end

-- Function to check if xsound is available
local function isXsoundAvailable()
    return GetResourceState('xsound') == 'started'
end

---------------------------------
-- BIBLE ACTIONS
---------------------------------

-- Function to handle reading
local function ReadBible()
    if isHoldingBible then
        StopBibleAnimation()
    end
    
    StartBibleScenario()
    
    isHoldingBible = true
    currentAction = 'reading'
    
    lib.notify({
        title = 'Holy Bible',
        description = Config.Messages.reading,
        type = 'info',
        duration = 5000,
        icon = 'book-bible'
    })
end

-- Function to hold bible
local function HoldBible()
    if isHoldingBible then
        StopBibleAnimation()
    end
    
    StartBibleScenario()
    
    isHoldingBible = true
    currentAction = 'holding'
    
    lib.notify({
        title = 'Holy Bible',
        description = Config.Messages.holding,
        type = 'info',
        duration = 5000,
        icon = 'book'
    })
end

---------------------------------
-- BLESSING FUNCTIONS
---------------------------------

-- Function to bless
local function Bless()
    if onCooldown then
        lib.notify({
            title = 'Blessing',
            description = Config.Messages.cooldown,
            type = 'error',
            duration = 3000,
            icon = 'clock'
        })
        return
    end
    
    if isHoldingBible then
        StopBibleAnimation()
    end
    
    StartBibleScenario()
    
    isHoldingBible = true
    currentAction = 'blessing'
    
    lib.notify({
        title = 'Blessing',
        description = Config.Messages.blessing,
        type = 'success',
        duration = 5000,
        icon = 'hands-praying'
    })
    
    -- Trigger server event for blessing
    TriggerServerEvent('priest:server:bless', GetEntityCoords(PlayerPedId()))
    
    -- Set cooldown
    onCooldown = true
    SetTimeout(Config.Blessing.cooldown, function()
        onCooldown = false
    end)
end

-- Receive blessing notification
RegisterNetEvent('priest:client:receiveBlessing', function(healAmount)
    lib.notify({
        title = 'Divine Blessing',
        description = Config.Messages.blessed,
        type = 'success',
        duration = 5000,
        icon = 'cross'
    })
end)

-- Receive blessing count
RegisterNetEvent('priest:client:blessingCount', function(count)
    if count > 0 then
        lib.notify({
            title = 'Blessing Complete',
            description = string.format(Config.Messages.blessedSelf, count),
            type = 'success',
            duration = 5000,
            icon = 'hands-praying'
        })
    else
        lib.notify({
            title = 'Blessing',
            description = Config.Messages.noNearby,
            type = 'warning',
            duration = 3000,
            icon = 'triangle-exclamation'
        })
    end
end)

---------------------------------
-- PREACHING FUNCTIONS
---------------------------------

-- Forward declaration
local OpenBibleMenu

-- Function to open sermon selection
local function SelectSermon()
    local sermonOptions = {}
    
    for _, sermon in ipairs(Config.Sermons) do
        table.insert(sermonOptions, {
            title = sermon.title,
            description = sermon.description,
            icon = 'book-bible',
            onSelect = function()
                if sermon.custom then
                    -- Open custom input
                    local input = lib.inputDialog('Custom Sermon', {
                        {
                            type = 'textarea',
                            label = 'Your Message',
                            description = 'Enter your sermon message',
                            required = true,
                            min = 10,
                            max = 500
                        }
                    })
                    
                    if input and input[1] then
                        TriggerServerEvent('priest:server:preach', input[1])
                        -- Re-open bible menu after preaching
                        Wait(100)
                        OpenBibleMenu()
                    else
                        -- If cancelled, go back to bible menu
                        OpenBibleMenu()
                    end
                else
                    TriggerServerEvent('priest:server:preach', sermon.message)
                    -- Re-open bible menu after preaching
                    Wait(100)
                    OpenBibleMenu()
                end
            end
        })
    end
    
    -- Add back button
    table.insert(sermonOptions, {
        title = '← Back',
        description = 'Return to bible menu',
        icon = 'arrow-left',
        onSelect = function()
            OpenBibleMenu()
        end
    })
    
    lib.registerContext({
        id = 'sermon_menu',
        title = '📖 Select Sermon',
        menu = 'bible_menu',
        options = sermonOptions
    })
    
    lib.showContext('sermon_menu')
end

-- Function to preach
local function Preach()
    if isHoldingBible then
        StopBibleAnimation()
    end
    
    StartBibleScenario()
    
    isHoldingBible = true
    currentAction = 'preaching'
    
    lib.notify({
        title = 'Holy Bible',
        description = Config.Messages.preaching,
        type = 'info',
        duration = 5000,
        icon = 'church'
    })
    
    -- Show sermon selection (menu stays in context chain)
    SelectSermon()
end

---------------------------------
-- HYMN FUNCTIONS
---------------------------------

-- Function to stop hymn
local function StopHymn()
    if activeHymnSound then
        exports.xsound:Destroy(activeHymnSound)
        activeHymnSound = nil
    end
    
    -- Ensure flag is reset
    hymnPlaying = false
    
    lib.notify({
        title = 'Hymn Ended',
        description = Config.Messages.hymnStopped,
        type = 'info',
        duration = 3000,
        icon = 'music'
    })
end

-- Function to play hymn
local function PlayHymn(hymnTitle, hymnUrl)
    if not isXsoundAvailable() then
        lib.notify({
            title = 'Error',
            description = Config.Messages.xsoundNotFound,
            type = 'error',
            duration = 5000,
            icon = 'exclamation-triangle'
        })
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    -- Stop any existing hymn first
    if hymnPlaying or activeHymnSound then
        TriggerServerEvent('priest:server:stopHymn')
        Wait(500) -- Wait for stop to process
    end
    
    -- Trigger server to play for all nearby
    TriggerServerEvent('priest:server:playHymn', playerCoords, hymnTitle, hymnUrl)
end

-- Function to open hymn selection
local function SelectHymn()
    if not Config.Hymns.enabled then
        lib.notify({
            title = 'Hymns',
            description = 'Hymns are currently disabled',
            type = 'error',
            duration = 3000,
            icon = 'music'
        })
        return
    end
    
    local hymnOptions = {}
    
    for _, hymn in ipairs(Config.Hymns.songs) do
        table.insert(hymnOptions, {
            title = hymn.title,
            description = hymn.description,
            icon = 'music',
            iconColor = '#9b59b6',
            onSelect = function()
                if hymn.custom then
                    -- Open custom input for URL
                    local input = lib.inputDialog('Custom Hymn', {
                        {
                            type = 'input',
                            label = 'Hymn Title',
                            description = 'Enter the hymn name',
                            required = true,
                            min = 3,
                            max = 50
                        },
                        {
                            type = 'input',
                            label = 'YouTube URL',
                            description = 'Enter YouTube or direct audio URL',
                            required = true,
                            min = 10,
                            max = 200
                        }
                    })
                    
                    if input and input[1] and input[2] then
                        PlayHymn(input[1], input[2])
                        Wait(100)
                        OpenBibleMenu()
                    else
                        OpenBibleMenu()
                    end
                else
                    PlayHymn(hymn.title, hymn.url)
                    Wait(100)
                    OpenBibleMenu()
                end
            end
        })
    end
    
    -- Add stop hymn option if playing
    if hymnPlaying then
        table.insert(hymnOptions, 1, {
            title = '⏹ Stop Current Hymn',
            description = 'End the hymn that is currently playing',
            icon = 'stop',
            iconColor = '#e74c3c',
            onSelect = function()
                TriggerServerEvent('priest:server:stopHymn')
                Wait(500) -- Wait for stop to complete
                OpenBibleMenu()
            end
        })
    end
    
    -- Add back button
    table.insert(hymnOptions, {
        title = '← Back',
        description = 'Return to bible menu',
        icon = 'arrow-left',
        onSelect = function()
            OpenBibleMenu()
        end
    })
    
    lib.registerContext({
        id = 'hymn_menu',
        title = '🎵 Select Hymn',
        menu = 'bible_menu',
        options = hymnOptions
    })
    
    lib.showContext('hymn_menu')
end

-- Receive hymn play event
RegisterNetEvent('priest:client:playHymn', function(coords, radius, hymnTitle, hymnUrl, volume)
    if not isXsoundAvailable() then return end
    
    -- Stop any existing hymn first
    if activeHymnSound then
        exports.xsound:Destroy(activeHymnSound)
        Wait(100)
    end
    
    -- Reset flag
    hymnPlaying = false
    
    -- Create unique sound ID
    local soundId = 'priest_hymn_' .. math.random(10000, 99999)
    activeHymnSound = soundId
    
    -- Play the hymn using xsound
    exports.xsound:PlayUrlPos(soundId, hymnUrl, volume, coords, false)
    exports.xsound:Distance(soundId, radius)
    
    -- Set flag after successful play
    Wait(100)
    hymnPlaying = true
    
    lib.notify({
        title = 'Sacred Hymn',
        description = string.format(Config.Messages.hymnPlaying, hymnTitle),
        type = 'info',
        duration = 5000,
        icon = 'music',
        iconColor = '#9b59b6'
    })
end)

-- Receive hymn stop event
RegisterNetEvent('priest:client:stopHymn', function()
    StopHymn()
end)

---------------------------------
-- GIVE BIBLE FUNCTIONS
---------------------------------

-- Function to give bible
local function GiveBible()
    -- Request player list from server
    RSGCore.Functions.TriggerCallback('priest:server:getPlayers', function(players)
        if not players or #players == 0 then
            lib.notify({
                title = 'Give Bible',
                description = Config.Messages.noPlayers,
                type = 'warning',
                duration = 3000,
                icon = 'users'
            })
            return
        end
        
        local playerOptions = {}
        
        for _, player in ipairs(players) do
            -- Different styling for self
            local iconColor = player.isSelf and '#3498db' or '#d4af37'
            local description = player.isSelf and 'Take another bible for yourself' or ('ID: ' .. player.id .. ' | Give them a holy bible')
            
            table.insert(playerOptions, {
                title = player.name,
                description = description,
                icon = 'user',
                iconColor = iconColor,
                onSelect = function()
                    TriggerServerEvent('priest:server:giveBible', player.id)
                    -- Re-open bible menu after giving
                    Wait(100)
                    OpenBibleMenu()
                end
            })
        end
        
        -- Add back button
        table.insert(playerOptions, {
            title = '← Back',
            description = 'Return to bible menu',
            icon = 'arrow-left',
            onSelect = function()
                OpenBibleMenu()
            end
        })
        
        lib.registerContext({
            id = 'give_bible_menu',
            title = '📖 Give Bible To...',
            menu = 'bible_menu',
            options = playerOptions
        })
        
        lib.showContext('give_bible_menu')
    end)
end

-- Receive bible notification
RegisterNetEvent('priest:client:receiveBible', function(priestName)
    lib.notify({
        title = 'Holy Gift',
        description = string.format(Config.Messages.bibleReceived, priestName),
        type = 'success',
        duration = 7000,
        icon = 'book-bible',
        iconColor = '#d4af37'
    })
end)

-- Bible given notification
RegisterNetEvent('priest:client:bibleGiven', function(playerName)
    lib.notify({
        title = 'Bible Given',
        description = string.format(Config.Messages.bibleGiven, playerName),
        type = 'success',
        duration = 5000,
        icon = 'gift',
        iconColor = '#2ecc71'
    })
end)

---------------------------------
-- MAIN MENU
---------------------------------

-- Function to open bible menu
function OpenBibleMenu()
    local options = {}
    
    for _, option in ipairs(Config.MenuOptions) do
        table.insert(options, {
            title = option.title,
            description = option.description,
            icon = option.icon,
            onSelect = function()
                if option.action == 'read' then
                    ReadBible()
                elseif option.action == 'hold' then
                    HoldBible()
                elseif option.action == 'preach' then
                    Preach()
                elseif option.action == 'hymn' then
                    SelectHymn()
                elseif option.action == 'bless' then
                    Bless()
                elseif option.action == 'give' then
                    GiveBible()
                elseif option.action == 'stop' then
                    StopBibleAnimation()
                    lib.notify({
                        title = 'Holy Bible',
                        description = Config.Messages.stopped,
                        type = 'info',
                        duration = 3000,
                        icon = 'book'
                    })
                end
            end
        })
    end
    
    -- Add dynamic "Stop Hymn" option if hymn is currently playing
    if hymnPlaying then
        -- Insert before the last "Stop" option
        table.insert(options, #options, {
            title = '⏹ Stop Hymn',
            description = 'Stop the currently playing hymn',
            icon = 'stop',
            iconColor = '#e74c3c',
            onSelect = function()
                TriggerServerEvent('priest:server:stopHymn')
                Wait(500)
                OpenBibleMenu()
            end
        })
    end
    
    lib.registerContext({
        id = 'bible_menu',
        title = '📖 Holy Bible',
        options = options
    })
    
    lib.showContext('bible_menu')
end

---------------------------------
-- EVENTS
---------------------------------

-- Register usable item
RegisterNetEvent('priest:client:useBible', function()
    local PlayerData = RSGCore.Functions.GetPlayerData()
    
    -- Check if player is a priest (optional - remove if you want anyone to use it)
    if Config.PriestJob and PlayerData.job.name ~= Config.PriestJob then
        lib.notify({
            title = 'Holy Bible',
            description = Config.Messages.notPriest,
            type = 'error',
            duration = 3000,
            icon = 'ban'
        })
        return
    end
    
    OpenBibleMenu()
end)

---------------------------------
-- CLEANUP & SAFETY
---------------------------------

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if isHoldingBible then
            StopBibleAnimation()
        end
        if activeHymnSound then
            StopHymn()
        end
    end
end)

-- Clean up when player dies
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

-- Stop bible when entering vehicle
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