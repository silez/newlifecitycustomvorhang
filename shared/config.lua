Config = {}

-- Berechtigungen für den Zugriff auf das Script
Config.Permissions = {
    serverGroups = {
        mode = "minimum", -- "minimum": Benutzer mit dieser Gruppe und höher sind erlaubt; "explicit": Nur genau diese Gruppen sind erlaubt.
        groups = {"moderator"} -- Bei "minimum" sind "moderator" und alle höher gestellten Gruppen erlaubt.
    },
    jobs = {
        enabled = false, -- Aktiviert die Job-basierte Berechtigung
        mode = "minimum", -- "minimum": Ab dem angegebenen Rang (Grade) sind Benutzer berechtigt; "explicit": Nur exakt angegebene Ränge.
        jobs = {
            police = 2,    -- Bei "police" sind ab Rang 2 alle berechtigt.
            ambulance = 1  -- Bei "ambulance" ab Rang 1.
        }
    },
    identifiers = {
        enabled = false, -- Aktiviert die Berechtigung via Spieler-Identifikatoren
		allowed = { "discord:1234567890", "license:abcdef123456" }
    }
}

-- Datenbank-Einstellungen für die Sessions
Config.Database = {
    tableName = "neja_vorhang_sessions" -- Tabelle in der Datenbank, in der alle Session-Daten gespeichert werden.
}

-- Logrotationseinstellungen (in Tagen)
Config.LogRotation = {
    retentionDays = 7 -- Gibt an, wieviele Tage Logs behalten werden. (Die Einstellung kann später via Ingame UI angepasst werden.)
}

return Config
