local Config = Config

-- Globales Session-Management: Alle Sessions werden hier gespeichert
local ServerSessions = {}

-- Log-Funktionalität
local LogFolder = "log"
local retentionDays = Config.LogRotation.retentionDays or 7

local function ensureLogFolder()
    os.execute("mkdir -p " .. LogFolder)
end
ensureLogFolder()

local function writeLog(message)
    local date = os.date("%Y-%m-%d")
    local filePath = LogFolder .. "/" .. date .. ".txt"
    local file = io.open(filePath, "a")
    if file then
        file:write("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] " .. message .. "\n")
        file:close()
    end
end

local function rotateLogs()
    local retentionSeconds = retentionDays * 24 * 60 * 60
    local currentTime = os.time()
    local hasLFS, lfs = pcall(require, "lfs")
    if hasLFS then
        for file in lfs.dir(LogFolder) do
            if file ~= "." and file ~= ".." then
                local filePath = LogFolder .. "/" .. file
                local attr = lfs.attributes(filePath)
                if attr and attr.modification then
                    if (currentTime - attr.modification) > retentionSeconds then
                        os.remove(filePath)
                    end
                end
            end
        end
    else
        writeLog("LuaFileSystem nicht verfügbar – Logrotation wird übersprungen.")
    end
end
rotateLogs()

-- Logging-Wrapper: Loggt Aktionen und sendet sie via Discord
local function logAction(action, details)
    local msg = string.format("%s: %s", action, details or "")
    writeLog(msg)
    FreeTime_DiscordLog(action, details or "")
end

-- Datenbank-Tabelle für Sessions erstellen
local function createDatabaseTable()
    local query = [[
        CREATE TABLE IF NOT EXISTS `]] .. Config.Database.tableName .. [[` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `session_id` VARCHAR(50) NOT NULL,
            `owner` VARCHAR(50) NOT NULL,
            `position` JSON NOT NULL,
            `marker_config` JSON NOT NULL,
            `props_config` JSON NOT NULL,
            `current_prop_index` INT NOT NULL DEFAULT 1,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_session` (`session_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]
    MySQL.Async.execute(query, {}, function(affectedRows)
        logAction("DB", "Tabelle erstellt/überprüft: " .. Config.Database.tableName)
    end)
end
createDatabaseTable()

-- Berechtigungsprüfung: Servergruppen, Jobs und Identifier
local function isAuthorized(xPlayer)
    local allowed = false
    local permissions = Config.Permissions

    if xPlayer.getGroup then
        local playerGroup = xPlayer.getGroup()
        if permissions.serverGroups.mode == "minimum" then
            for _, group in ipairs(permissions.serverGroups.groups) do
                if playerGroup == group then
                    allowed = true
                    break
                end
            end
        elseif permissions.serverGroups.mode == "explicit" then
            for _, group in ipairs(permissions.serverGroups.groups) do
                if playerGroup == group then
                    allowed = true
                    break
                end
            end
        end
    end

    if permissions.jobs.enabled and xPlayer.job then
        local jobName = xPlayer.job.name
        local jobGrade = xPlayer.job.grade
        if permissions.jobs.jobs[jobName] then
            if permissions.jobs.mode == "minimum" then
                if jobGrade >= permissions.jobs.jobs[jobName] then
                    allowed = true
                end
            elseif permissions.jobs.mode == "explicit" then
                if jobGrade == permissions.jobs.jobs[jobName] then
                    allowed = true
                end
            end
        end
    end

    if permissions.identifiers.enabled then
        local identifiers = xPlayer.getIdentifiers() or {}
        -- Falls eine Allowed-Liste definiert wurde, wird nur diese geprüft:
        if permissions.identifiers.allowed then
            for _, allowedId in ipairs(permissions.identifiers.allowed) do
                for _, id in ipairs(identifiers) do
                    if id == allowedId then
                        allowed = true
                        break
                    end
                end
                if allowed then break end
            end
        else
            for _, idType in ipairs(permissions.identifiers.types) do
                for _, id in ipairs(identifiers) do
                    if string.find(id, idType) then
                        allowed = true
                        break
                    end
                end
                if allowed then break end
            end
        end
    end

    return allowed
end

-- Registrierung des serverseitigen Commands via ESX
ESX.RegisterCommand('vorhang', 'user', function(xPlayer, args, showError)
    if not isAuthorized(xPlayer) then
        showError("Du hast keine Berechtigung für diesen Befehl.")
        return
    end

    TriggerClientEvent("FreeTime_Neja_Vorhang:client:OpenMenu", xPlayer.source)
    logAction("Command", "Spieler " .. xPlayer.identifier .. " hat den Command für den Vorhang genutzt.")
end, false, {
    help = "Öffne das Vorhang Menü",
    validate = false,
    arguments = {}
})

-----------------------------------------------------
-- Session-Management: Speichern, Aktualisieren & Broadcast
-----------------------------------------------------
RegisterNetEvent("FreeTime_Neja_Vorhang:server:SaveSession", function(sessionData)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not isAuthorized(xPlayer) then return end

    -- Speichere bzw. aktualisiere die Session in der globalen Tabelle
    ServerSessions[sessionData.session_id] = sessionData

    local query = [[
        INSERT INTO `]] .. Config.Database.tableName .. [[` 
        (session_id, owner, position, marker_config, props_config, current_prop_index)
        VALUES (@session_id, @owner, @position, @marker_config, @props_config, @current_prop_index)
        ON DUPLICATE KEY UPDATE
            position = @position,
            marker_config = @marker_config,
            props_config = @props_config,
            current_prop_index = @current_prop_index,
            updated_at = CURRENT_TIMESTAMP
    ]]
    local params = {
        ["@session_id"] = sessionData.session_id,
        ["@owner"] = xPlayer.identifier,
        ["@position"] = json.encode(sessionData.position),
        ["@marker_config"] = json.encode(sessionData.marker_config),
        ["@props_config"] = json.encode(sessionData.props_config),
        ["@current_prop_index"] = sessionData.current_prop_index or 1
    }
    MySQL.Async.execute(query, params, function(affectedRows)
        logAction("Session gespeichert", "Session: " .. sessionData.session_id .. " von Spieler: " .. xPlayer.identifier)
        -- Sende den aktualisierten Session-Status an alle Clients
        TriggerClientEvent("FreeTime_Neja_Vorhang:client:UpdateSession", -1, sessionData)
    end)
end)

local function updateAndBroadcastSession(session)
    if session then
        TriggerEvent("FreeTime_Neja_Vorhang:server:SaveSession", session)
    end
end

-----------------------------------------------------
-- Vorhang-Aktionen: Raise, Lower, Reset
-----------------------------------------------------
RegisterNetEvent("FreeTime_Neja_Vorhang:server:Raise", function(sessionId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not isAuthorized(xPlayer) then return end

    local session = ServerSessions[sessionId]
    if session then
        if session.current_prop_index < session.props_config.countVorhangProps then
            session.current_prop_index = session.current_prop_index + 1
            updateAndBroadcastSession(session)
            logAction("Vorhang hoch", "Session: " .. sessionId .. " von Spieler: " .. xPlayer.identifier)
        else
            TriggerClientEvent("ox_lib:notify", src, {description = "Vorhang ist bereits vollständig hochgezogen."})
        end
    end
end)

RegisterNetEvent("FreeTime_Neja_Vorhang:server:Lower", function(sessionId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not isAuthorized(xPlayer) then return end

    local session = ServerSessions[sessionId]
    if session then
        if session.current_prop_index > 1 then
            session.current_prop_index = session.current_prop_index - 1
            updateAndBroadcastSession(session)
            logAction("Vorhang runter", "Session: " .. sessionId .. " von Spieler: " .. xPlayer.identifier)
        else
            TriggerClientEvent("ox_lib:notify", src, {description = "Vorhang ist bereits vollständig runter."})
        end
    end
end)

RegisterNetEvent("FreeTime_Neja_Vorhang:server:Reset", function(sessionId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not isAuthorized(xPlayer) then return end

    local session = ServerSessions[sessionId]
    if session then
        session.current_prop_index = 1
        updateAndBroadcastSession(session)
        logAction("Vorhang reset", "Session: " .. sessionId .. " von Spieler: " .. xPlayer.identifier)
    end
end)

-----------------------------------------------------
-- Session-Löschung
-----------------------------------------------------
RegisterNetEvent("FreeTime_Neja_Vorhang:server:DeleteSession", function(sessionId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not isAuthorized(xPlayer) then return end

    local query = "DELETE FROM `" .. Config.Database.tableName .. "` WHERE session_id = @session_id"
    MySQL.Async.execute(query, {["@session_id"] = sessionId}, function(affectedRows)
        logAction("Session gelöscht", "Session: " .. sessionId .. " von Spieler: " .. xPlayer.identifier)
        TriggerClientEvent("FreeTime_Neja_Vorhang:client:DeleteSession", -1, sessionId)
        ServerSessions[sessionId] = nil
    end)
end)

-----------------------------------------------------
-- Beim Start der Resource: Bestehende Sessions wiederherstellen
-----------------------------------------------------
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    local query = "SELECT * FROM `" .. Config.Database.tableName .. "`"
    MySQL.Async.fetchAll(query, {}, function(sessions)
        for _, session in ipairs(sessions) do
            local sessionData = {
                session_id = session.session_id,
                owner = session.owner,
                position = json.decode(session.position),
                marker_config = json.decode(session.marker_config),
                props_config = json.decode(session.props_config),
                current_prop_index = session.current_prop_index
            }
            ServerSessions[sessionData.session_id] = sessionData
            TriggerClientEvent("FreeTime_Neja_Vorhang:client:RestoreSession", -1, sessionData)
            logAction("Session restored", "Session: " .. session.session_id)
        end
    end)
end)

-----------------------------------------------------
-- Beim Stoppen der Resource: Cleanup aller Sessions auf den Clients
-----------------------------------------------------
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    TriggerClientEvent("FreeTime_Neja_Vorhang:client:CleanupAll", -1)
    logAction("Resource Stopped", "Cleanup aller Sessions wurde ausgelöst.")
end)
