# Raid Buff Counter

A lightweight World of Warcraft **Classic** addon that counts raid utility casts per player while you are in a raid.

## Features

- Tracks casts from **your raid only** (combat log affiliation flags + `IsInRaid()`)
- Class dropdown: **Mage**, **Warlock**, **Druid**, **Priest**, **Warrior**
- Per-caster counts with realm stripped from names (`Player-Realm` → `Player`)
- Draggable window with minimize button
- Auto-minimizes out of raid; expands when you join a raid
- Options: reset on login / logout
- Counts persist across `/reload`; optional clear on login/logout

## Tracked spells

| Class   | Columns | Spells |
|---------|---------|--------|
| Mage    | AI, AB  | Arcane Intellect, Arcane Brilliance |
| Warlock | HS, SS  | Create Healthstone (all ranks), Create Soulstone (all ranks) |
| Druid   | MotW, GotW | Mark of the Wild, Gift of the Wild |
| Priest  | PoF, PW:F | Prayer of Fortitude, Power Word: Fortitude |
| Warrior | SA      | Sunder Armor |

## Installation

1. Copy the `RaidBuffCounter` folder into:
   ```
   World of Warcraft/_classic_era_/Interface/AddOns/
   ```
   (Use `_classic_` or `_anniversary_` if that matches your client.)

2. Enable **Raid Buff Counter** on the character select AddOns screen.

3. `/reload`

### Upgrading from MageBuffTracker

Remove the old `MageBuffTracker` folder. Saved data migrates automatically from `MageBuffTrackerDB` to `RaidBuffCounterDB`.

## Commands

| Command | Description |
|---------|-------------|
| `/rbc` | Help |
| `/rbc reset` | Clear all counts |
| `/rbc toggle` | Show or hide the window |
| `/rbc options` | Open options |
| `/rbc mini` | Minimize or expand |
| `/rbc mage` | Switch to Mage view |
| `/rbc warlock` | Switch to Warlock view |
| `/rbc druid` | Switch to Druid view |
| `/rbc priest` | Switch to Priest view |
| `/rbc warrior` | Switch to Warrior view |
| `/rbc persist on\|off` | Keep counts after logout (default: off) |

`/mbt` still works but prints a deprecation notice.

## Notes

- Only events in **combat log range** are counted.
- Tracking runs only while you are **in a raid** and the caster is flagged as **raid** or **mine** in the combat log.
- The **Reset** button clears counts for all classes.

## Authors

Mobsonme / Cessiah / efnetdoom2 / CursorAI

## License

Use and modify freely. No warranty.
