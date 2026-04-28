# 🚀 Spacebar

**Arcade / Multitasking Endless-Game**  
Godot Wildjam #92 · 2026  
Team: Daweenci, Klagmester55, Emir0461

---

## Spielübersicht

Spacebar ist ein Endless-Arcade-Spiel mit Splitscreen-Mechanik: Die linke Bildschirmhälfte zeigt eine Bar, die rechte einen unendlich scrollenden Weltraum. Beide Hälften laufen **gleichzeitig** – der Spieler muss parallel Asteroiden ausweichen und Kundenbestellungen brauen. Das Spiel endet wenn alle 5 HP verbraucht sind oder die Reputation auf null sinkt.

---

## Gameplay

### Spielziel
So lange wie möglich überleben und dabei möglichst viele Sterne durch korrekte Getränkebestellungen sammeln.

### Spielablauf
1. **Fliegen** – Das Raumschiff weicht Asteroiden aus, indem der Spieler zwischen vier Spuren wechselt.
2. **Kundenphase** – Ein Kundenschiff fliegt auf Spur 5 ein. Der Spieler hat **6 Sekunden**, um auf Spur 4 zu wechseln und den Auftrag anzunehmen.
3. **Brauen** – Das Rezept wird angezeigt und muss der Reihe nach nachgebraut werden. Dabei läuft ein gemeinsamer **20-Sekunden-Timer** für Merken, Brauen und Abgabe.
4. **Abgabe** – Fertig gebraut auf Spur 4 fahren, um das Getränk abzugeben. Bewertung: **1–5 Sterne** je nach korrekten Zutaten in richtiger Reihenfolge.

### Progression
- Rezeptlänge startet bei 3 Zutaten
- Alle 10 Punkte kommt eine Zutat hinzu
- Maximum: 12 Zutaten

### Bewertungssystem
| Sterne | Reputationseffekt |
|--------|------------------|
| 5 ⭐ | +2 Reputation |
| 4 ⭐ | +1 Reputation |
| 3 ⭐ | ±0 |
| 2 ⭐ | −1 Reputation |
| 1 ⭐ | −2 Reputation |

Nicht angenommene oder abgelaufene Aufträge zählen als 1 Stern.

---

## Steuerung

### PC
|            Aktion          |         Taste        |
|----------------------------|----------------------|
| Spur wechseln              |  ← / → Pfeiltasten   |
| Frucht auswählen           |     W / A / S / D    |
| Rezept bestätigen / weiter | Beliebige WASD-Taste |
| Menü öffnen                |      Escape/Tab      |

### Mobile
|      Aktion       |                      Geste                       |
|-------------------|--------------------------------------------------|
|  Spur wechseln    | Wischen links / rechts (rechte Bildschirmhälfte) |
| Frucht auswählen  |             Direkt auf Slot tippen               |
| Rezept bestätigen |            Auf Rezept-Scroll tippen              |

---

## Installation & Ausführen

### Projekt in Godot öffnen
1. **Godot 4.x** installieren (getestet mit Godot 4.6.2)
2. Repository klonen oder ZIP herunterladen
3. Godot öffnen → „Importieren" → `project.godot` auswählen
4. Szene `Node2D.tscn` als Hauptszene starten (F5)

### Exportierter Build
Ein fertiger Export ist auf [itch.io](https://klagmester55.itch.io/spacebar) verfügbar.

---

## Credits

### Team & Eigenleistungen

Team (Itch.io names)
Game Design: Daweenci, Emir0461, Klagmester55
Programming: Daweenci 
Art: Daweenci, Emir0461, Klagmester55 
Sound Design: Daweenci 
Website: Klagmester55

**Alle Grafiken** (Sprites, Charaktere, UI-Elemente, Hintergründe) wurden **vollständig selbst erstellt** – handgepixelt in [Aseprite](https://www.aseprite.org/). bis auf eine Ausnahme ("Pixelart animated Star by Narik")

### Externe Assets & Tools

Assets 
Music: Blue Cat Blues by Albert Behar
Fonts: Pixeloid Mono 
Assets: Pixelart animated Star by Narik

> ⚠️ **Alle Grafiken sind Eigenleistung.** Fremde Assets sind in der Tabelle oben vollständig aufgeführt.

---

*Spacebar · Godot Wildjam #92 · 2026 · Daweenci, Klagmester55, Emir0461*
