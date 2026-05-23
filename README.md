# Raid Buff Counter

A lightweight World of Warcraft **Classic** addon that counts raid utility casts per player while you are in a raid.

## Features

- Tracks casts from **your raid only** (combat log affiliation flags + `IsInRaid()`)
- Class dropdown: **Mage**, **Warlock**, **Druid**, **Priest**, **Paladin**, **Warrior**
- Per-caster counts with realm stripped from names (`Player-Realm` → `Player`)
- Draggable window with minimize button
- Auto-minimizes out of raid; expands when you join a raid
- Options: reset on login / logout (login reset off by default — counts survive `/reload`)

## Tracked spells

| Class   | Columns | Spells |
|---------|---------|--------|
| Mage    | AI, AB  | Arcane Intellect, Arcane Brilliance |
| Warlock | HS, SS  | Create Healthstone (all ranks), Create Soulstone (all ranks) |
| Druid   | MotW, GotW, Reb | Mark of the Wild, Gift of the Wild, Rebirth |
| Priest  | PoF, PW:F, Res, SP, PoSP | Prayer of Fortitude, Power Word: Fortitude, Resurrection, Shadow Protection, Prayer of Shadow Protection |
| Paladin | Red       | Redemption (all ranks) |
| Warrior | SA        | Sunder Armor |

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
| `/rbc reset` or `reset all` | Clear all counts |
| `/rbc reset <class>` | Clear one class (e.g. `reset priest`) |
| `/rbc toggle` | Show or hide the window |
| `/rbc options` | Open options |
| `/rbc mini` | Minimize or expand |
| `/rbc druid` | Switch to Druid view |
| `/rbc mage` | Switch to Mage view |
| `/rbc paladin` | Switch to Paladin view |
| `/rbc priest` | Switch to Priest view |
| `/rbc warlock` | Switch to Warlock view |
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
