--********************************************************************************--
--*                                                                              *--
--*   MFPD-Treadmill - SYNCED ANIMATION AND SOUND EFFECTS TO ALL PLAYERS!         *--
--*                                                                              *--
--********************************************************************************--

local treadmillObject = nil
local isAttachedToTreadmill = false
local currentAnim = nil
local isRunning = false
local treadmillSpawned = false
local netID = NetworkGetNetworkIdFromEntity(PlayerPedId())

function SpawnTreadmill()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    RequestModel("apa_p_apdlc_treadmill_s")
    while not HasModelLoaded("apa_p_apdlc_treadmill_s") do
        Wait(100)
    end
    treadmillObject = CreateObject(GetHashKey("apa_p_apdlc_treadmill_s"), playerCoords.x, playerCoords.y, playerCoords.z - 1, true, true, true)
    SetEntityHeading(treadmillObject, playerHeading + 180)
    AttachEntityToEntity(playerPed, treadmillObject, 0, -0.04, 0.09, 1.18, 0, 0, 180.0, false, false, false, true, 2, true)
    isAttachedToTreadmill = true
    treadmillSpawned = true
end

function AttachPlayerToTreadmill(treadmill)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local treadmillCoords = GetEntityCoords(treadmill)
    local dist = #(playerCoords - treadmillCoords)
    local offset = vector3(0.0, 0.0, 1.18) 
    
    AttachEntityToEntity(playerPed, treadmill, 0, offset.x, offset.y, offset.z, 0, 0, 180.0, false, false, false, true, 2, true)
    isAttachedToTreadmill = true
end

function DetachPlayerFromTreadmill()
    local playerPed = PlayerPedId()
    DetachEntity(playerPed, true, true)
    isAttachedToTreadmill = false
end

function PlayPickupAnimation()
    local playerPed = PlayerPedId()
    RequestAnimDict("anim@heists@narcotics@trash")
    while not HasAnimDictLoaded("anim@heists@narcotics@trash") do
        Wait(100)
    end
    TaskPlayAnim(playerPed, "anim@heists@narcotics@trash", "pickup", 8.0, -8.0, -1, 0, 0, false, false, false)
end

function DeleteTreadmill()
    if treadmillObject then
        DeleteEntity(treadmillObject)
        treadmillObject = nil
    end
end

function PlayCustomSoundToRadius(soundName, volume)
    TriggerServerEvent("Server:SoundToRadius", netID, 20.0, soundName, volume)
end

function StartAnimation(animDict, animName, blendInSpeed, blendOutSpeed)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(100)
    end
    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
    currentAnim = {animDict, animName}
end

function StopAnimation()
    ClearPedTasks(PlayerPedId())
    currentAnim = nil
end

function LeaveTreadmill()
    if isAttachedToTreadmill then
        DeleteTreadmill()
        isAttachedToTreadmill = false
        treadmillSpawned = false
    end
    if isRunning then
        StopAnimation()
        isRunning = false
    end
end

RegisterCommand("run", function()
    if isAttachedToTreadmill then
        StopAnimation()
        StartAnimation("move_m@brave@a", "run", 8.0, -8.0)
        PlayCustomSoundToRadius("run", 1.2)
    end
end)

RegisterKeyMapping('stop', 'Stop using the treadmill', 'keyboard', 'X')
RegisterKeyMapping('run', 'Start Running', 'keyboard', 'N')

RegisterCommand("stop", function()
    if isAttachedToTreadmill then
        DetachPlayerFromTreadmill() 
        PlayPickupAnimation() 
        PlayCustomSoundToRadius("parou", 0.9)
        Citizen.Wait(2000) 
        LeaveTreadmill()
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 73) then 
            ExecuteCommand("stop")
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local treadmill = GetClosestObjectOfType(playerCoords, 1.0, GetHashKey("apa_p_apdlc_treadmill_s"), false, false, false)
        
        if DoesEntityExist(treadmill) then
            local dist = #(playerCoords - GetEntityCoords(treadmill))
            if dist < 1.5 then  
                if IsControlJustReleased(0, 38) then  
                    AttachPlayerToTreadmill(treadmill)
                    StartAnimation("move_m@hurry@c", "walk", 8.0, -8.0)
                    PlayCustomSoundToRadius("andar", 4.2)
                    isRunning = true
                end
            end
        end
    end
end)
