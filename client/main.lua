------------------------------
-- Globale Variablen & Defaults
------------------------------
local currentSession = nil          -- Aktive Session des Spielers
local Sessions = {}                 -- Alle bekannten Sessions
local currentBodenProp = nil        -- Aktuell gespawnter Boden-Prop
local currentVorhangProp = nil      -- Aktuell gespawnter Vorhang-Prop

-- Standard Marker-Konfiguration (anpassbar via UI)
local defaultMarkerConfig = {
    markerType = 1,
    size = vector3(1.0, 1.0, 1.0),
    color = { r = 255, g = 0, b = 0, a = 100 },
    bounce = true,
    rotate = false,
    radius = 5.0,
    position = nil -- wird beim Erstellen der Session gesetzt
}

-- Standard Props-Konfiguration (anpassbar via UI)
local defaultPropsConfig = {
    useBodenProp = true,
    propBoden = "prop_carpet", -- Beispiel: Teppich-Prop
    countVorhangProps = 4,
    vorhangProps = { "prop_vorhang1", "prop_vorhang2", "prop_vorhang3", "prop_vorhang4" }
}

------------------------------
-- Prop-Spawning & -Entfernen
------------------------------
local function spawnProp(model, position)
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    local timeout = 1000
    while not HasModelLoaded(modelHash) and timeout > 0 do
        Wait(10)
        timeout = timeout - 10
    end
    if timeout <= 0 then
        print("Modell " .. model .. " konnte nicht geladen werden.")
        return nil
    end
    local obj = CreateObject(modelHash, position.x, position.y, position.z, false, false, false)
    PlaceObjectOnGroundProperly(obj)
    return obj
end

local function removeProp(obj)
    if obj and DoesEntityExist(obj) then
        DeleteObject(obj)
    end
end

------------------------------
-- Funktion: Update Props anhand der Session-Daten
------------------------------
local function updateProps(session)
    local pos = session.position
    local propsConfig = session.props_config

    -- Sicheres Entfernen des aktuellen Vorhang-Props
    if currentVorhangProp and DoesEntityExist(currentVorhangProp) then
        removeProp(currentVorhangProp)
        currentVorhangProp = nil
        Wait(50) -- kleiner Delay zur Stabilität
    end

    -- Boden-Prop: je nach Einstellung spawnen oder entfernen
    if propsConfig.useBodenProp then
        if currentBodenProp and DoesEntityExist(currentBodenProp) then
            removeProp(currentBodenProp)
            Wait(50)
        end
        currentBodenProp = spawnProp(propsConfig.propBoden, pos)
    else
        if currentBodenProp and DoesEntityExist(currentBodenProp) then
            removeProp(currentBodenProp)
            currentBodenProp = nil
        end
    end

    -- Spawne den Vorhang-Prop basierend auf dem aktuellen Index
    local index = session.current_prop_index or 1
    local vorhangModel = propsConfig.vorhangProps[index]
    if vorhangModel then
        currentVorhangProp = spawnProp(vorhangModel, pos)
    end
end

------------------------------
-- Session-Initialisierung & Speicherung
------------------------------
local function initializeSession()
    if not currentSession then
        local playerPos = GetEntityCoords(PlayerPedId())
        currentSession = {
            session_id = "session_" .. tostring(math.random(100000, 999999)),
            position = playerPos,
            marker_config = defaultMarkerConfig,
            props_config = defaultPropsConfig,
            current_prop_index = 1
        }
        currentSession.marker_config.position = playerPos
        Sessions[currentSession.session_id] = currentSession

        -- Neue Session an den Server senden (Speicherung & Broadcast)
        TriggerServerEvent("FreeTime_Neja_Vorhang:server:SaveSession", currentSession)
    end
end

------------------------------
-- Clientseitige Event-Handler für UI-Aktionen
------------------------------

-- Vorhang hoch: Leite den Befehl an den Server weiter
RegisterNetEvent("FreeTime_Neja_Vorhang:client:Raise", function()
    if currentSession then
        TriggerServerEvent("FreeTime_Neja_Vorhang:server:Raise", currentSession.session_id)
    else
        exports.ox_lib:notify({description = "Keine aktive Session vorhanden."})
    end
end)

-- Vorhang runter: Leite den Befehl an den Server weiter
RegisterNetEvent("FreeTime_Neja_Vorhang:client:Lower", function()
    if currentSession then
        TriggerServerEvent("FreeTime_Neja_Vorhang:server:Lower", currentSession.session_id)
    else
        exports.ox_lib:notify({description = "Keine aktive Session vorhanden."})
    end
end)

-- Vorhang reset: Leite den Befehl an den Server weiter
RegisterNetEvent("FreeTime_Neja_Vorhang:client:Reset", function()
    if currentSession then
        TriggerServerEvent("FreeTime_Neja_Vorhang:server:Reset", currentSession.session_id)
    else
        exports.ox_lib:notify({description = "Keine aktive Session vorhanden."})
    end
end)

-- Marker-Platzierung: Spieler setzt Marker an aktueller Position
RegisterNetEvent("FreeTime_Neja_Vorhang:client:SetMarker", function()
    exports.ox_lib:notify({description = "Positioniere dich an der gewünschten Marker-Position und drücke ENTER zum Speichern."})
    Citizen.CreateThread(function()
        local placing = true
        while placing do
            Citizen.Wait(0)
            if IsControlJustReleased(0, 191) then  -- Enter-Taste
                local pos = GetEntityCoords(PlayerPedId())
                if currentSession then
                    currentSession.position = pos
                    currentSession.marker_config.position = pos
                    TriggerServerEvent("FreeTime_Neja_Vorhang:server:SaveSession", currentSession)
                    updateProps(currentSession)
                    exports.ox_lib:notify({description = "Marker-Position gespeichert."})
                end
                placing = false
            end
        end
    end)
end)

-- Props Einstellungen via UI
RegisterNetEvent("FreeTime_Neja_Vorhang:client:ToggleBodenProp", function()
    if currentSession then
        local propsConfig = currentSession.props_config
        propsConfig.useBodenProp = not propsConfig.useBodenProp
        TriggerServerEvent("FreeTime_Neja_Vorhang:server:SaveSession", currentSession)
        exports.ox_lib:notify({description = "Boden-Prop " .. (propsConfig.useBodenProp and "aktiviert" or "deaktiviert")})
    end
end)

RegisterNetEvent("FreeTime_Neja_Vorhang:client:SetPropCount", function()
    if currentSession then
        lib.inputDialog("Vorhang Props", {"Anzahl der Vorhang-Props:"}, function(result)
            if result then
                local count = tonumber(result[1])
                if count and count > 0 then
                    currentSession.props_config.countVorhangProps = count
                    TriggerServerEvent("FreeTime_Neja_Vorhang:server:SaveSession", currentSession)
                    exports.ox_lib:notify({description = "Anzahl der Vorhang-Props gesetzt: " .. count})
                else
                    exports.ox_lib:notify({description = "Ungültige Anzahl."})
                end
            end
        end)
    end
end)

RegisterNetEvent("FreeTime_Neja_Vorhang:client:SetPropNames", function()
    if currentSession then
        lib.inputDialog("Vorhang Prop Namen", {"Gib die Namen der Vorhang-Props ein (kommagetrennt):"}, function(result)
            if result then
                local namesStr = result[1]
                local names = {}
                for name in string.gmatch(namesStr, '([^,]+)') do
                    table.insert(names, name:match("^%s*(.-)%s*$"))
                end
                if #names > 0 then
                    currentSession.props_config.vorhangProps = names
                    TriggerServerEvent("FreeTime_Neja_Vorhang:server:SaveSession", currentSession)
                    exports.ox_lib:notify({description = "Vorhang Prop Namen aktualisiert."})
                else
                    exports.ox_lib:notify({description = "Keine gültigen Namen eingegeben."})
                end
            end
        end)
    end
end)

RegisterNetEvent("FreeTime_Neja_Vorhang:client:SetLogRetention", function()
    lib.inputDialog("Log Einstellungen", {"Log-Retention Tage:"}, function(result)
        if result then
            local days = tonumber(result[1])
            if days and days > 0 then
                exports.ox_lib:notify({description = "Log-Retention Tage gesetzt auf: " .. days .. ". (Dauerhaft in shared/config.lua anpassen)"})
            else
                exports.ox_lib:notify({description = "Ungültige Anzahl an Tagen."})
            end
        end
    end)
end)

------------------------------
-- Synchronisation: Empfang von Session-Updates vom Server
------------------------------
RegisterNetEvent("FreeTime_Neja_Vorhang:client:UpdateSession", function(sessionData)
    -- Aktualisiere lokale Daten, wenn es sich um die aktive Session handelt
    if currentSession and currentSession.session_id == sessionData.session_id then
        currentSession = sessionData
        updateProps(currentSession)
        exports.ox_lib:notify({description = "Vorhang Status aktualisiert."})
    end
    -- Aktualisiere globale Sessions-Tabelle
    Sessions[sessionData.session_id] = sessionData
end)

------------------------------
-- Session-Wiederherstellung & -Löschung
------------------------------
RegisterNetEvent("FreeTime_Neja_Vorhang:client:RestoreSession", function(sessionData)
    Sessions[sessionData.session_id] = sessionData
    if currentSession and currentSession.session_id == sessionData.session_id then
        currentSession = sessionData
        updateProps(currentSession)
    end
end)

RegisterNetEvent("FreeTime_Neja_Vorhang:client:DeleteSession", function(sessionId)
    if currentSession and currentSession.session_id == sessionId then
        if currentBodenProp then removeProp(currentBodenProp) currentBodenProp = nil end
        if currentVorhangProp then removeProp(currentVorhangProp) currentVorhangProp = nil end
        currentSession = nil
        exports.ox_lib:notify({description = "Session gelöscht."})
    end
    Sessions[sessionId] = nil
end)

RegisterNetEvent("FreeTime_Neja_Vorhang:client:CleanupAll", function()
    if currentBodenProp then removeProp(currentBodenProp) currentBodenProp = nil end
    if currentVorhangProp then removeProp(currentVorhangProp) currentVorhangProp = nil end
    currentSession = nil
    exports.ox_lib:notify({description = "Alle Vorhang-Objekte wurden entfernt."})
end)

------------------------------
-- Menüöffnung: Initialisiere Session und öffne UI-Menü
------------------------------
RegisterNetEvent("FreeTime_Neja_Vorhang:client:OpenMenu", function()
    initializeSession()
    TriggerEvent("FreeTime_Neja_Vorhang:client:OpenMainMenu")
end)

------------------------------
-- Marker-Darstellung: Kontinuierlicher Thread
------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPos = GetEntityCoords(PlayerPedId())
        for _, session in pairs(Sessions) do
            if session.marker_config and session.marker_config.position then
                local distance = #(playerPos - session.marker_config.position)
                if distance < session.marker_config.radius then
                    DrawMarker(
                        session.marker_config.markerType,
                        session.marker_config.position.x, session.marker_config.position.y, session.marker_config.position.z - 1.0,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        session.marker_config.size.x, session.marker_config.size.y, session.marker_config.size.z,
                        session.marker_config.color.r, session.marker_config.color.g, session.marker_config.color.b, session.marker_config.color.a,
                        session.marker_config.bounce, session.marker_config.rotate, 2, false, nil, nil, false
                    )
                end
            end
        end
    end
end)
