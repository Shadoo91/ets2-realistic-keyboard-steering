# ETS2 - Realistic Keyboard Steering & Authentic Physics Logic (v1.10)

![Game Version](https://shields.io)
![Platform](https://shields.io)
![License](https://shields.io)

This mod fundamentally transforms driving in Euro Truck Simulator 2 (ETS2) by introducing a smart, multi-stage control matrix directly into the game's input engine. Experience razor-sharp steering, multi-tier braking, and realistic weight dynamics – completely independent of global physics files!

---

## 🇺🇸 ENGLISH VERSION

## 🎮 Features & Control Layout

### 🔹 Steering (A / D)
- **Cruise & Maneuver Logic (A / D):** Smooth, precise 40% baseline sensitivity.
- **Maneuvering-Boost (A/D + Spacebar):** Adds 50% extra, totaling 90% max angle.
- **Anti-Snapping:** Dynamically locked spacebar boost when stopped.
- **100% Emergency Steering Bypass (S + LAlt):** Instant max steering.

### 🔹 Throttle
- **Smooth Throttle (W Key):** 35% power for city driving.
- **Partial Throttle (LAlt):** Independent 55% mid-stage.
- **Kickdown / Turbo Gas (W + LAlt):** 90% total throttle.

### 🔹 Braking & Reversing
- **Stage 1 - Soft (S Key):** 10% deceleration.
- **Stage 2 - Mid (S + Spacebar):** 50% controlled deceleration.
- **Stage 3 - Emergency (S + LAlt):** 100% maximum force.

---

## 🚀 Installation Guide

1. **Subscribe** to the official companion core mod on the Steam Workshop.
2. **Disable Steam Cloud (Highly Recommended):** 
   - Start the game once, click **Edit Profile** on your main profile, and **uncheck "Use Steam Cloud"**. 
   - *Note: This forces the game to save files locally so the script can find them. You can safely turn it back on after the installation is complete!*
3. **Optimize Steam Settings:** 
   - Go to Steam -> Right-click **ETS2** -> Properties -> Controller -> Select **"Disable Steam Input"**.
4. **Download & Run Patcher:** 
   - Download the automated profile patcher from this repository (`rks_injector_core.ps1` for Windows / `Launcher_Linux_RKS.sh` for Linux).

### 🖥️ Windows Execution:
- Open PowerShell in the script folder and execute: `.\rks_injector_core.ps1`

### 🐧 Linux & Steam Deck Permissions (Pop!_OS, Ubuntu, etc.):
Linux security requires you to explicitly grant execution permissions to the script before running it. Open your terminal in the script directory and run:
```bash
chmod +x Launcher_Linux_RKS.sh && ./Launcher_Linux_RKS.sh
```
---

## ⚙️ Recommended In-Game Settings

- **Steering Sensitivity / Animation Range:** Full Right (1800° for ATS / 1440° for ETS2)
- **Steering Non-Linearity:** 50% - 80% (Highway damping)
- **Auto-Centering (Gameplay Settings):** **DISABLED / OFF** *(Crucial for the RKS physics engine to take full control!)*
- **Braking Intensity:** **50%** *(Perfectly balanced for the multi-stage brake matrix)*
- **Truck / Trailer Stability:** 80%
- **Suspension / Cabin Stiffness:** 40%

---

## 🇩🇪 DEUTSCHE VERSION

## 🎮 Features & Tastenbelegung

### 🔹 Lenkung (A / D)
- **Cruising-Logik (A / D):** Sanfter, präziser 40% Einschlag.
- **Intelligenter Rangier-Boost (A/D + Leertaste):** 50% Zusatz, insgesamt 90% Winkel.
- **Anti-Ausrast-Schutz:** Dynamisch gesperrter Boost im Stand.
- **100% Notfall-Lenk-Bypass (S + LAlt):** Sofortiger Max-Einschlag.

### 🔹 Gas geben
- **Sanftes Gas (W-Taste):** 35% Leistung für die Stadt.
- **Teil-Beschleunigung (Links-Alt):** Unabhängige 55% Stufe.
- **Kickdown (W + LAlt):** 90% Gesamtleistung.

### 🔹 Bremsen & Rückwärtsfahren
- **Stufe 1 - Sanft (S-Taste):** 10% Verzögerung.
- **Stufe 2 - Mittel (S + Leertaste):** 50% kontrollierte Bremskraft.
- **Stufe 3 - Gefahrenbremsung (S + LAlt):** 100% maximale Kraft.

---

## 🚀 Installations-Anleitung

1. Klicke im Steam Workshop bei der Core-Mod auf **Abonnieren**.
2. **Steam Cloud deaktivieren (Dringend empfohlen):** 
   - Starte das Spiel einmal, klicke bei deinem Hauptprofil auf **Profil bearbeiten** und **entferne den Haken bei "Steam Cloud nutzen"**. 
   - *Hinweis: Dies zwingt das Spiel, die Dateien lokal zu speichern, damit das Skript sie finden kann. Du kannst die Cloud nach der Installation beruhigt wieder einschalten!*
3. **Steam-Einstellungen optimieren:** 
   - Gehe in Steam zu -> Rechtsklick auf **ETS2** -> Eigenschaften -> Controller -> Wähle **"Steam Input deaktivieren"**.
4. **Patcher herunterladen & starten:** 
   - Lade den automatischen Profil-Patcher aus diesem Repository herunter (`rks_injector_core.ps1` für Windows / `Launcher_Linux_RKS.sh` für Linux).

### 🖥️ Windows-Ausführung:
- Öffne die PowerShell im Skript-Ordner und führe folgenden Befehl aus: `.\rks_injector_core.ps1`

### 🐧 Linux & Steam Deck Rechte-Vergabe (Pop!_OS, Ubuntu, etc.):
Die Linux-Sicherheit erfordert es, dass du dem Skript vor dem Start explizit Ausführungsrechte (Execution Permissions) gibst. Öffne dein Terminal im Skript-Ordner und führe diesen Befehl aus:
```bash
chmod +x Launcher_Linux_RKS.sh && ./Launcher_Linux_RKS.sh
```
---


## ⚙️ Empfohlene Ingame-Einstellungen

- **Lenkempfindlichkeit / Animationsbereich:** Ganz nach rechts (1800° für ATS / 1440° für ETS2)
- **Lenkungs-Nichtlinearität:** 50% - 80% (Autobahn-Dämpfung)
- **Automatisches Zentrieren (Gameplay-Optionen):** **DEAKTIVIERT / AUS** *(Zwingend notwendig, damit die RKS-Physikmatrix die volle Kontrolle übernimmt!)*
- **Bremsintensität:** **50%** *(Perfekt ausbalanciert für die mehrstufige Bremsmatrix)*
- **Lkw- / Aufliegerstabilität:** 80%
- **Federungs- / Kabinenhärte:** 40%

---

## 🔒 License & Copyright
© 2026 Shadoo91. All rights reserved. Re-uploading or unauthorized modification of these configuration files is strictly prohibited.
