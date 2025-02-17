# New Life Vorhang

Custom Vorhang Script für New Life City

## Beschreibung
Dieses Script ermöglicht das Erstellen und Verwalten von Vorhang-Sessions in FiveM. Spieler können einen Vorhang mithilfe von Props darstellen, der stückweise hoch- und runtergezogen werden kann. Das Script synchronisiert den aktuellen Status der Vorhang-Props für alle Spieler in der Umgebung und stellt sicher, dass Änderungen (Spawning, Austausch, Löschung) stabil und ohne Abstürze durchgeführt werden.

**Wichtig:**  
Obwohl der Repository-Name und die Beschreibung nun "New Life" lauten, bleiben alle Event- und Funktionsnamen (z. B. `FreeTime_Neja_Vorhang:client:...`) unverändert, wie abgesprochen.

## Features
- **Vorhang-Mechanik:**  
  Schalte zwischen verschiedenen Vorhang-Props, um den Fortschritt des Vorhangs (hoch/runter) darzustellen.
  
- **Marker- & Prop-Platzierung:**  
  Ermöglicht Spielern, Marker und Props (z. B. Boden-Prop als Teppich) an der gewünschten Position zu platzieren.
  
- **Synchronisation:**  
  Der aktuelle Prop-Status wird serverseitig verwaltet und bei Änderungen an alle Clients gesendet, sodass alle Spieler denselben Zustand sehen.
  
- **Session-Verwaltung:**  
  Mehrere Vorhang-Sessions können erstellt, gespeichert, wiederhergestellt und gelöscht werden. Alle Session-Daten werden in einer MySQL-Datenbank (ox_mysql) gespeichert.
  
- **Berechtigungs-Management:**  
  Integration mit ESX Legacy, wobei die Berechtigungen über Servergruppen, Jobs und Spieler-Identifiers (z. B. Discord, license, etc.) konfiguriert werden können.
  
- **Ingame UI:**  
  Einstellungen und Aktionen werden über ein benutzerfreundliches UI (ox_lib) gesteuert.
  
- **Logging:**  
  Aktionen werden in Logdateien geschrieben, inklusive Discord-Webhook-Integration und Log-Rotation.

## Voraussetzungen
- **FiveM Server** mit ESX Legacy Framework
- **ox_lib** (für UI und weitere Utilities)
- **ox_mysql** (für die MySQL-Datenbankintegration)
- Optional: **Discord Webhook** (für Discord Logging)

## Installation
1. Lade das Script in deinen `resources`-Ordner.
2. Füge das Script in deine `server.cfg` ein:
3. Stelle sicher, dass alle Abhängigkeiten (ox_lib, ox_mysql, es_extended) installiert und korrekt konfiguriert sind.
4. Passe die Konfiguration in `shared/config.lua` an deine Bedürfnisse an.

## Konfiguration
- **shared/config.lua:**  
Hier werden grundlegende Einstellungen wie Berechtigungen, Datenbank-Tabelle und Log-Rotation definiert.

- **Ingame UI:**  
Viele Einstellungen (wie Marker, Props und Log-Einstellungen) können während des Spiels über das UI vorgenommen werden.

- **Discord Logging:**  
Die Webhook-URL und weitere Discord-bezogene Einstellungen findest du in `server/discord.lua`.

## Nutzung
- **Command:**  
Verwende `/vorhang`, um das Hauptmenü zu öffnen.

- **Hauptmenü:**  
Bietet folgende Optionen:
- **Vorhang hoch:** Erhöht den Vorhangstatus und spawnt das nächste Prop.
- **Vorhang runter:** Verringert den Vorhangstatus und spawnt das vorherige Prop.
- **Vorhang reset:** Setzt den Vorhang auf den Anfang zurück (erstes Prop).
- **Einstellungen:** Öffnet das Menü zur Konfiguration von Marker, Props und Log-Einstellungen.

Alle Änderungen am Vorhang werden serverseitig verarbeitet und synchronisiert, sodass alle Spieler immer denselben Status sehen.

## Erweiterungsmöglichkeiten
- Zusätzliche Funktionen und erweiterte UI-Optionen können problemlos integriert werden.
- Anpassungen an der Berechtigungslogik sind möglich, um spezifischere Prüfungen durchzuführen.
- Weitere Features (z. B. Animationen oder zusätzliche Marker-Optionen) können ergänzt werden.

## Credits
- **Autor:** XenoKeks
- **Script Name:** New Life Vorhang
- **Beschreibung:** Custom Vorhang Script für New Life City
