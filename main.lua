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

function mod:onPostUpdate()
  for idx, ref in pairs(played_fortune_machines) do
    local machine = ref.Entity
    if machine:GetSprite():IsEventTriggered('Prize') then
      played_fortune_machines[idx] = nil
      mod:dbg('Fortune machine popped!')
      local random_location = ap.missing_locations[rng:RandomInt(#ap.missing_locations) + 1]
      ap:LocationScouts({random_location}, true)
    end
  end

end


---@param entity_pickup EntityPickup
---@param collider Entity
---@param low boolean
function mod:onPickupCollision(entity_pickup, collider, low)
  if collider.Index == Isaac.GetPlayer().Index then
    mod:dbg('Collision with ' .. tostring(entity_pickup.Variant))
    if entity_pickup.Variant == PickupVariant.PICKUP_TROPHY then
      mod:finishedRun(false)
      --Game():End(3)
    end
  end
end

function mod:finishedRun(lost)
  mod:dbg('Run result, lost: ' .. tostring(lost))
  newRun = true
  runFinished = true
  runInfo['is_active'] = false
  ap:Set(cfg.slot .. '_run_info', {}, false, { {'replace', runInfo}})
  if not lost and options and options['win_collects_missed_locations'] and runInfo and runInfo['visited_stages'] then
    local locationsToCheck = {}
    for _, visitedStage in ipairs(runInfo['visited_stages']) do
      for _, roomName in pairs(roomNames) do
        local location_name = visitedStage .. ' - ' .. roomName
        local location_id = ap:get_location_id(location_name)
        if location_id and location_id > 0 then
          table.insert(locationsToCheck, location_id)
        end
      end
    end
    if ap and ap:get_state() == ap.State.SLOT_CONNECTED then
      ap:LocationChecks(locationsToCheck)
    else
      for _, location_id in ipairs(locationsToCheck) do
        table.insert(queuedLocations, location_id)
      end
    end
  end
end

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


function mod:backToMenu()
  newRun = true
end

---@param entity_npc EntityNPC
---@param collider Entity
function mod:onFortuneTellingMachine(entity_npc, collider)
  if collider.Type == EntityType.ENTITY_SLOT and collider.Variant == 3 then
    mod:dbg('Collision with ' .. collider.Type .. '_' .. collider.SubType .. '_' .. collider.Variant)
    local ref = EntityRef(collider)
    played_fortune_machines[collider.Index] = ref
  end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.onPostUpdate)
mod:AddCallback(ModCallbacks.MC_POST_GAME_END, mod.finishedRun)
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, mod.onEntityKill)
mod:AddCallback(ModCallbacks.MC_PRE_GET_COLLECTIBLE, mod.onItemSpawn)
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, mod.onPickupCollision)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.connectionMenu)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.backToMenu)
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, mod.onItemUse)
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, mod.onFortuneTellingMachine)
]=]