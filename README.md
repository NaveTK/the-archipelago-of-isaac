# The Archipelago of Isaac Mod

This mod enables the ability to connect to an Archipelago MultiWorld.

## Installation Instructions
1. Download the mod files.
2. Extract the contents into your `mods` directory.
3. Ensure that the `metadata.xml` file is present in the root of the mod folder.
4. Launch the game and enable the mod from the mods menu.

## Usage Guidelines
- Only compatible with all DLCs for The Binding of Isaac: Rebirth up to Repentance.
- Requires a savefile which has all paths to the lategame bosses unlocked already.
- As network capabilities are blocked by default. This mod requires the `--luadebug` flag to be set as a start option for The Binding of Isaac on Steam

----
## TODOs

### Changes
- [ ] Key pieces should be removed not replaced without Mega Satan unlock
- [ ] Rename Unlocks to what they actually unlock (i.e. Unlock Negative instead of Unlock Dark Room)
- [ ] Code cleanup and refactoring
- [ ] Make RNG heavy room checks once per Act, not per stage type (Vault, Bedroom, Dice room, Library)
- [ ] External game client for networking instead of --luadbg
- [ ] In-game indicator showing what rooms to check on current floor
- [ ] Add Planetarium, Ultra Secret Room, Crawl Space and ERROR Room to location checks for act
- [ ] Add telescope lense, Red Key, Shovel and Undefined as unlockable starting items
- [ ] Option to distribute those starting items only to a random set of characters
- [ ] Put Sheol in-logic with Shovel unlocked
- [ ] Put Chest/Dark room in-logic with Undefined unlocked
- [ ] Refactor "win collects missed locations" to only consider rooms that didn't spawn, not those skipped on purpose, also make an option to have it only collect a set amount, not all
- [ ] Merge with limeslime secret-based system for asyncs
- [ ] Instead of X AP items, spread them over different Acts so they can have progression items and work with spheres
- [ ] Merge Mirrorworld and Escape unlocks
- [ ] Fortune hint options for Progressive/Usefull only
- [ ] Fortune hint option for hint percentage instead of 100%
- [ ] Fortune hints on Fortune Cookie / Crystal ball
- [ ] No Mausoleum for Ascend required but put Mausoleum in-logic after Home + Polaroid/Negative unlocks
- [ ] Option to exclude TM-Trainer and Missing No. as AP rewards

### Bugs
- [x] ~~Generation sometimes fails~~
- [ ] Key pieces still spawn for Angels in Sacrifice room without Mega Satan unlock
- [ ] Victory runs shouldn't count
- [ ] Death link is always on regardless of settings
- [ ] Black candle doesn't block curse traps
- [ ] Item previews indicate wrong items (Guppy's eye, Crane game)
- [ ] Dice room rerolls may delete your items
- [ ] Using Glowing Hourglass on Lilith sometimes deletes your Incubus (not sure if this has something to do with the mod or if it is a vanilla Isaac bug)
- [ ] Lost soul sometimes gives rewards even if it died last floor
- [ ] Found soul dying triggers death link (lol)
- [ ] Modeling Clay crashes game
- [ ] XL floors may mess up progression locks
- [ ] Boss rush and other Boss room locations do not get checked properly
- [ ] Scatter items option isn't respected properly
- [ ] Binge eater / Glitched crown / Soul of Isaac / Tainted Isaac / Birthrights (Isaac) may show items from wrong item pools
