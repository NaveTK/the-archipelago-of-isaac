## Changes
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

## Bugs
- [ ] Generation sometimes fails
- [ ] Key pieces still spawn for Angels in Sacrificr room
- [ ] Victory runs shouldn't count
- [ ] Death link is always on regardless of settings
- [ ] Black candle doesn't block curse traps
- [ ] Dice room rerolls may delete your items
- [ ] Using Glowing Hourglass on Lilith sometimes deletes your Incubus (not sure if this has something to do with the mod or if it is a vanilla Isaac bug)
- [ ] Lost soul sometimes gives rewards even if it died last floor
- [ ] Modeling Clay crashes game
