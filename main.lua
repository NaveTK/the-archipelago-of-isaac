local DEBUG = true

---@class ModReference
---@field client_manager ClientManager
---@field item_manager ItemManager
---@field location_manager LocationManager
---@field progression_manager ProgressionManager
---@field notification_manager NotificationManager
local mod = RegisterMod('The Archipelago of Isaac', 1)

mod.client_manager = include('clientmanager')
mod.item_manager = include('itemmanager')
mod.location_manager = include('locationmanager')
mod.progression_manager = include('progressionmanager')
mod.notification_manager = include('notificationmanager')
mod.client_manager:Init(mod)
mod.item_manager:Init(mod)
mod.location_manager:Init(mod)
mod.progression_manager:Init(mod)
mod.notification_manager:Init(mod)

function mod.dbg(str)
  if DEBUG then
    Isaac.DebugString(str)
  end
end

--[=[

---@param entity Entity
---@param entity_type EntityType
function mod:onEntityKill(entity, entity_type)
  local player = entity:ToPlayer()
  if entity and entity:IsBoss() then
    mod:dbg('Entity Type: ' .. entity.Type .. ' Variant: ' .. entity.Variant .. ' SubType: ' .. entity.SubType)
  end
  if player and options and options['deathlink'] and not player:WillPlayerRevive() then
    local time = ap:get_server_time()
    local cause = ap:get_player_alias(ap:get_player_number()) .. ' died to Skill Issue.'
    local source = ap:get_player_alias(ap:get_player_number())
    mod:dbg('sendDeathLinkBounce ' .. tostring(time) .. ' ' .. cause .. ' ' .. source)
    last_death_link = time
    ap:Bounce({
      time = time,
      cause = cause,
      source = source
    }, {}, {}, { 'DeathLink' })
  end

end


mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.onPostUpdate)
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, mod.onEntityKill)
mod:AddCallback(ModCallbacks.MC_PRE_GET_COLLECTIBLE, mod.onItemSpawn)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.connectionMenu)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.backToMenu)
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, mod.onItemUse)
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, mod.onFortuneTellingMachine)
]=]