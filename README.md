# The Archipelago of Isaac Mod
This mod enables the ability to connect to an Archipelago MultiWorld.

## Installation Instructions
1. Subscribe to the mod on the Steam Workshop [Link soon]
2. Launch the game and enable the mod in the mods menu.

## Usage Guidelines
- Only compatible The Binding of Isaac: Rebirth up to Repentance and Repentance+.
- Requires a savefile which has all paths to the lategame bosses unlocked already.

----
## TODOs

### Changes
- [x] ~~Key pieces should be removed not replaced without Mega Satan unlock~~
- [x] ~~Rename Unlocks to what they actually unlock (i.e. Unlock Negative instead of Unlock Dark Room)~~
- [x] ~~Code cleanup and refactoring~~
- [x] ~~Make RNG heavy room checks once per Act, not per stage type (Vault, Bedroom, Dice room, Library)~~
- [x] ~~External game client for networking instead of --luadbg~~
- [ ] In-game indicator showing what rooms to check on current floor
- [x] ~~Add Planetarium, Ultra Secret Room, Crawl Space and ERROR Room to location checks for act~~
- [x] ~~Add telescope lense, Red Key, Shovel and Undefined as unlockable starting items~~
- [ ] Option to distribute those starting items only to a random set of characters
- [x] ~~Put Sheol in-logic with Shovel unlocked~~
- [x] ~~Put Chest/Dark room in-logic with Undefined unlocked~~
- [x] ~~Refactor "win collects missed locations" to only consider rooms that didn't spawn, not those skipped on purpose, also make an option to have it only collect a set amount, not all~~
- [ ] Merge with limeslime secret-based system for asyncs
- [x] ~~Instead of X AP items, spread them over different Acts so they can have progression items and work with spheres~~
- [x] ~~Merge Mirrorworld and Escape unlocks~~
- [x] ~~Fortune hint options for Progressive/Usefull only~~
- [x] ~~Fortune hint option for hint percentage instead of 100%~~
- [ ] ~~Fortune hints on Fortune Cookie / Crystal ball~~
- [x] ~~No Mausoleum for Ascend required but put Mausoleum in-logic after Home + Polaroid/Negative unlocks~~
- [x] ~~Option to exclude TM-Trainer and Missing No. as AP rewards~~
- [ ] Option on how to handle out-of-logic checks through sequence breaking (Block, None, All, Store)

### Bugs
- [ ] Escape Knife Piece unlock doesnt work properly
- [x] ~~Generation sometimes fails~~
- [x] ~~Key pieces still spawn for Angels in Sacrifice room without Mega Satan unlock~~
- [ ] Victory runs shouldn't count
- [x] ~~Death link is always on regardless of settings~~
- [ ] Black candle doesn't block curse traps
- [x] ~~Item previews indicate wrong items (Guppy's eye, Crane game)~~
- [x] ~~Dice room rerolls may delete your items~~
- [x] ~~Using Glowing Hourglass on Lilith sometimes deletes your Incubus (not sure if this has something to do with the mod or if it is a vanilla Isaac bug)~~
- [ ] Lost soul sometimes gives rewards even if it died last floor
- [x] ~~Found soul dying triggers death link (lol)~~
- [x] ~~Modeling Clay crashes game~~
- [x] ~~XL floors may mess up progression locks~~
- [x] ~~Boss rush and other Boss room locations do not get checked properly~~
- [x] ~~Scatter items option isn't respected properly~~
- [x] ~~Binge eater / Glitched crown / Soul of Isaac / Tainted Isaac / Birthrights (Isaac) may show items from wrong item pools~~
