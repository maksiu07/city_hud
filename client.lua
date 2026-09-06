local showHud = true
local serverPlayerCount = 0
local serverMaxPlayers = GetConvarInt('sv_maxclients', 48)
local serverName = GetConvar('sv_hostname', 'FiveM Server')

RegisterNetEvent('city_hud:serverStats', function(count, maxPlayers, hostname)
    serverPlayerCount = tonumber(count) or 0
    serverMaxPlayers = tonumber(maxPlayers) or serverMaxPlayers
    if hostname and hostname ~= '' then serverName = hostname end
end)

RegisterCommand('togglehud', function()
    showHud = not showHud
    SendNUIMessage({ action = 'visibility', visible = showHud })
end, false)

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('city_hud:requestStats')
    while true do
        if showHud then
            local ped = PlayerPedId()
            local playerId = PlayerId()
            local health = math.max(0, GetEntityHealth(ped) - 100)
            local maxHealth = math.max(100, GetEntityMaxHealth(ped) - 100)
            local healthPct = math.floor((health / maxHealth) * 100 + 0.5)
            local armor = math.floor(GetPedArmour(ped) + 0.5)
            local stamina = math.floor(GetPlayerSprintStaminaRemaining(playerId) + 0.5)
            local underwater = IsPedSwimmingUnderWater(ped)
            local vehicle = GetVehiclePedIsIn(ped, false)
            local inVehicle = vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped

            local payload = {
                action = 'update',
                player = {
                    id = GetPlayerServerId(playerId),
                    name = GetPlayerName(playerId) or 'Player',
                    health = math.min(100, math.max(0, healthPct)),
                    armor = math.min(100, math.max(0, armor)),
                    stamina = math.min(100, math.max(0, stamina)),
                    talking = NetworkIsPlayerTalking(playerId)
                },
                server = {
                    name = serverName,
                    players = serverPlayerCount,
                    maxPlayers = serverMaxPlayers
                },
                vehicle = { visible = inVehicle }
            }

            if inVehicle then
                local speed = GetEntitySpeed(vehicle) * 3.6
                local fuel = GetVehicleFuelLevel(vehicle)
                local rpm = GetVehicleCurrentRpm(vehicle) * 100
                local gear = GetVehicleCurrentGear(vehicle)
                local engine = GetIsVehicleEngineRunning(vehicle)
                local seatbelt = false

                -- Standalone HUD cannot know a custom seatbelt state, so this is intentionally local-only.
                payload.vehicle = {
                    visible = true,
                    speed = math.floor(speed + 0.5),
                    fuel = math.floor(math.max(0, math.min(100, fuel)) + 0.5),
                    rpm = math.floor(math.max(0, math.min(100, rpm)) + 0.5),
                    gear = gear == 0 and 'N' or tostring(gear),
                    engine = engine,
                    seatbelt = seatbelt,
                    heading = math.floor(GetEntityHeading(vehicle) + 0.5)
                }
            end

            SendNUIMessage(payload)
        end
        Wait(150)
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        TriggerServerEvent('city_hud:requestStats')
    end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(500)
        SendNUIMessage({ action = 'visibility', visible = showHud })
    end
end)
