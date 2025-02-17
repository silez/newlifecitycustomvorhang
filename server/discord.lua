-- Discord Logging und Webhook-Konfiguration

local DiscordConfig = {
    webhook = "https://discord.com/api/webhooks/DEIN_WEBHOOK_URL",
    name = "New Life City Vorhang Log",
    avatar = "https://i.imgur.com/youravatar.png" -- Optional: URL zu einem Avatar-Bild
}

--- Sendet eine Nachricht an Discord via Webhook
---@param title string Überschrift der Nachricht
---@param message string Inhalt der Nachricht
---@param color number Farbe des Embeds (Standard: Blau)
local function sendToDiscord(title, message, color)
    if not DiscordConfig.webhook or DiscordConfig.webhook == "" then
        return
    end

    local embed = {
        {
            title = title,
            description = message,
            color = color or 3447003,
            footer = {
                text = os.date("%c")
            }
        }
    }

    PerformHttpRequest(DiscordConfig.webhook, function(err, text, headers) end, 'POST', json.encode({
        username = DiscordConfig.name,
        embeds = embed,
        avatar_url = DiscordConfig.avatar,
    }), { ['Content-Type'] = 'application/json' })
end

--- Exponierte Funktion zum Versenden von Discord-Logs
---@param title string Überschrift
---@param message string Nachricht
---@param color number Farbe (optional)
function FreeTime_DiscordLog(title, message, color)
    sendToDiscord(title, message, color)
end
