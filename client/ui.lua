-- Variable zur Verwaltung der aktuellen Session (wird ggf. in client/main.lua gesetzt)
local currentSession = nil

-- Registriere den Hauptmenü-Kontext
lib.registerContext({
    id = 'neja_vorhang_main',
    title = 'New Life Vorhang',
    options = {
        {
            title = 'Vorhang hoch',
            description = 'Ziehe den Vorhang hoch',
            arrow = true,
            event = 'FreeTime_Neja_Vorhang:client:Raise'
        },
        {
            title = 'Vorhang runter',
            description = 'Ziehe den Vorhang runter',
            arrow = true,
            event = 'FreeTime_Neja_Vorhang:client:Lower'
        },
        {
            title = 'Vorhang reset',
            description = 'Setze den Vorhang zurück',
            arrow = true,
            event = 'FreeTime_Neja_Vorhang:client:Reset'
        },
        {
            title = 'Einstellungen',
            description = 'Öffne die Einstellungen',
            arrow = true,
            event = 'FreeTime_Neja_Vorhang:client:OpenSettingsMenu'
        }
    }
})

-- Registriere den Einstellungen-Menü-Kontext
lib.registerContext({
    id = 'neja_vorhang_settings',
    title = 'New Life Vorhang - Einstellungen',
    options = {
        {
            title = 'Marker platzieren',
            description = 'Platziere einen Marker an deiner aktuellen Position',
            arrow = false,
            event = 'FreeTime_Neja_Vorhang:client:SetMarker'
        },
        {
            title = 'Props Einstellungen',
            description = 'Konfiguriere Props (Vorhang & Boden)',
            arrow = true,
            event = 'FreeTime_Neja_Vorhang:client:OpenPropsMenu'
        },
        {
            title = 'Log Einstellungen',
            description = 'Passe Log-Rotation etc. an',
            arrow = true,
            event = 'FreeTime_Neja_Vorhang:client:OpenLogSettingsMenu'
        },
        {
            title = 'Zurück',
            description = 'Zurück zum Hauptmenü',
            arrow = true,
            event = 'FreeTime_Neja_Vorhang:client:OpenMainMenu'
        }
    }
})

-- Registriere den Props-Einstellungs-Kontext
lib.registerContext({
    id = 'neja_vorhang_props',
    title = 'Props Einstellungen',
    options = {
        {
            title = 'Boden-Prop aktivieren/deaktivieren',
            description = 'Aktiviere oder deaktiviere das Boden-Prop',
            arrow = false,
            event = 'FreeTime_Neja_Vorhang:client:ToggleBodenProp'
        },
        {
            title = 'Anzahl Vorhang-Props',
            description = 'Lege die Anzahl der Vorhang-Props fest',
            arrow = false,
            event = 'FreeTime_Neja_Vorhang:client:SetPropCount'
        },
        {
            title = 'Vorhang-Prop Namen',
            description = 'Gebe die Namen der Vorhang-Props ein',
            arrow = false,
            event = 'FreeTime_Neja_Vorhang:client:SetPropNames'
        },
        {
            title = 'Zurück',
            description = 'Zurück zu den Einstellungen',
            arrow = true,
            event = 'FreeTime_Neja_Vorhang:client:OpenSettingsMenu'
        }
    }
})

-- Registriere den Log-Einstellungs-Kontext
lib.registerContext({
    id = 'neja_vorhang_logs',
    title = 'Log Einstellungen',
    options = {
        {
            title = 'Log-Retention Tage',
            description = 'Lege fest, wie viele Tage Logs behalten werden',
            arrow = false,
            event = 'FreeTime_Neja_Vorhang:client:SetLogRetention'
        },
        {
            title = 'Zurück',
            description = 'Zurück zu den Einstellungen',
            arrow = true,
            event = 'FreeTime_Neja_Vorhang:client:OpenSettingsMenu'
        }
    }
})

-- Funktionen zum Anzeigen der verschiedenen Menüs
function OpenMainMenu()
    lib.showContext('neja_vorhang_main')
end

function OpenSettingsMenu()
    lib.showContext('neja_vorhang_settings')
end

function OpenPropsMenu()
    lib.showContext('neja_vorhang_props')
end

function OpenLogSettingsMenu()
    lib.showContext('neja_vorhang_logs')
end

-- Event-Handler, um die Menüs zu öffnen (wird z.B. aus client/main.lua angesteuert)
RegisterNetEvent('FreeTime_Neja_Vorhang:client:OpenMainMenu', function()
    OpenMainMenu()
end)

RegisterNetEvent('FreeTime_Neja_Vorhang:client:OpenSettingsMenu', function()
    OpenSettingsMenu()
end)

RegisterNetEvent('FreeTime_Neja_Vorhang:client:OpenPropsMenu', function()
    OpenPropsMenu()
end)

RegisterNetEvent('FreeTime_Neja_Vorhang:client:OpenLogSettingsMenu', function()
    OpenLogSettingsMenu()
end)

-- Hilfsfunktion: Zeige eine Notification an
function ShowNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, true)
end

-- Beispiel-Event für Marker-Platzierung (weitere Logik in client/main.lua)
RegisterNetEvent('FreeTime_Neja_Vorhang:client:SetMarker', function()
    ShowNotification("Bitte stelle dich an die gewünschte Marker-Position und drücke ENTER, um diese zu speichern.")
    -- Hier wird in client/main.lua die Marker-Platzierung abgearbeitet
end)

-- Hinweis:
-- Weitere UI-bezogene Events wie ToggleBodenProp, SetPropCount, SetPropNames oder SetLogRetention
-- sollten in client/main.lua implementiert werden, um die entsprechenden Funktionen auszuführen.

-- Optional: Funktionen exportieren, falls andere Client-Skripte die Menüs öffnen sollen
exports('OpenMainMenu', OpenMainMenu)
