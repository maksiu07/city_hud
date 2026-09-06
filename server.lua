local function broadcastStats(target)
    local count = #GetPlayers()
    local maxPlayers = GetConvarInt('sv_maxclients', 48)
    local hostname = GetConvar('sv_hostname', 'FiveM Server')
    TriggerClientEvent('city_hud:serverStats', target or -1, count, maxPlayers, hostname)
end

RegisterNetEvent('city_hud:requestStats', function()
    broadcastStats(source)
end)

AddEventHandler('playerJoining', function()
    SetTimeout(1000, function()
        broadcastStats(-1)
    end)
end)

AddEventHandler('playerDropped', function()
    SetTimeout(250, function()
        broadcastStats(-1)
    end)
end)

CreateThread(function()
    while true do
        Wait(10000)
        broadcastStats(-1)
    end
end)
