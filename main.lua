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
local json = require('json')
require('utils')
local game_name = 'The Binding of Isaac Repentance'
local items_handling = 7
local client_version = {0, 5, 3}
local message_format = AP.RenderFormat.TEXT

local function valueInList(value, list)
  for _, v in ipairs(list) do
    if v == value then
      return true
    end
  end
  return false
end

---@type APClient
local ap = nil

local cfg = {
  address = 'archipelago.gg',
  port = '38281',
  password = '',
  slot = 'Player'
}
if mod:HasData() then
  local ok, data = pcall(json.decode, mod:LoadData())
  if ok and type(data) == 'table' then
    cfg = data
  end
end

mod:dbg('Archipelago mod loaded')
local runInfo = nil
local options = nil
local availableItems = nil
local checked_items = 1
local newRun = Game() == nil
local runFinished = false
local trapQueue = Stack()
local fortune_cdr = 2
local last_death_link = nil

function connect(server, slot, password)
  local connect_attempts = 0

  function on_socket_connected()
    mod:dbg('Socket connected')
    connect_attempts = 0
  end

  function on_socket_error(msg)
    mod:dbg('Socket error: ' .. msg)
    connect_attempts = connect_attempts + 1
    if connect_attempts > 5 then
      mod:showMessage('Failed to connect', msg)
      ap = nil
      collectgarbage('collect')
    end
  end

  function on_socket_disconnected()
    mod:dbg('Socket disconnected')
  end

  function on_room_info()
    mod:dbg('Room info')
    ap:ConnectSlot(slot, password, items_handling, {'Lua-APClientPP'}, client_version)
  end

  function on_slot_connected(slot_data)
    mod:dbg('Slot connected')
    options = slot_data['options']
    mod:dbg('Options:')
    for key, value in pairs(slot_data['options']) do
      if type(value) == 'table' then
        mod:dbg('  ' .. key .. ': ')
        for subkey, subvalue in pairs(value) do
          mod:dbg('  ' .. subkey .. ': ' .. tostring(subvalue))
        end
      else
        mod:dbg('  ' .. key .. ': ' .. tostring(value))
      end
    end
    mod:dbg('missing locations: ' .. table.concat(ap.missing_locations, ', '))
    mod:dbg('checked locations: ' .. table.concat(ap.checked_locations, ', '))
    mod:dbg('Players:')
    local players = ap:get_players()
    for _, player in ipairs(players) do
      mod:dbg('  ' .. tostring(player.slot) .. ': ' .. player.name ..
          ' playing ' .. ap:get_player_game(player.slot))
    end

    if options and options['deathlink'] then
      ap:ConnectUpdate(items_handling, {'Lua-APClientPP', 'DeathLink'})
    end

    availableItems = {}
    mod:dbg('RunInfo cleared #on_slot_connected()')
    runInfo = nil
    ap:Get({cfg.slot .. '_checked_items'}, {})
    ap:Get({cfg.slot .. '_run_info'}, {})
  end

  function on_slot_refused(reasons)
    mod:dbg('Slot refused: ' .. table.concat(reasons, ', '))
  end

  function on_items_received(items)
    mod:dbg('Items received:')
    if not availableItems then
      availableItems = {}
    end
    for _, item in ipairs(items) do
      if mod:isActiveRun() then
        if itemName:find('^Unlock') then
          SFXManager():Play(SoundEffect.SOUND_GOLDENKEY)
        elseif itemName:find('Trap') then
          SFXManager():Play(SoundEffect.SOUND_HEARTBEAT)
          trapQueue:push(itemName)
        elseif itemName:find('^Random') then
          SFXManager():Play(SoundEffect.SOUND_PORTAL_SPAWN)
        end
        if item.player ~= ap:get_player_number() then
          mod:showMessage(itemName, 'from ' .. ap:get_player_alias(item.player))
        else
          mod:showMessage(itemName, '')
        end
      end
    end
    -- ap:Set('game_info', gameInfo, false, {})
    --for _, item in ipairs(items) do
    --  mod:dbg(item.item)
    --  local itemName = ap:get_item_name(item.item, game_name)
    --  mod:dbg('Type: ' .. type(itemName))
    --  mod:giveItem(itemName)
    --end
    if runInfo then
      mod:giveItems()
    end
    if not mod:isActiveRun() then
      ap:Get({cfg.slot .. '_run_info'})
    end
  end

  ---@param items NetworkItem
  function on_location_info(items)
    mod:dbg('Locations scouted:')
    for _, item in ipairs(items) do
      mod:dbg(ap:get_item_name(item.item, ap:get_player_game(item.player)))
      mod:dbg(ap:get_location_nClientManagerame(item.location, ap:get_game()))
      mod:dbg(ap:get_player_alias(item.player))
      mod:dbg(item.flags)
      local is_hint = valueInList(item.location, ap.missing_locations)
      if is_hint then
        if item.player ~= ap:get_player_number() then
          mod:showFortune(ap:get_player_alias(item.player) .. '\'s ' .. ap:get_item_name(item.item, ap:get_player_game(item.player)), 'is at ' .. ap:get_location_name(item.location, ap:get_game()))
        else
          mod:showFortune(ap:get_item_name(item.item, ap:get_player_game(item.player)), 'is at ' .. ap:get_location_name(item.location, ap:get_game()))
        end
        fortune_cdr = 5
      else
        if item.player ~= ap:get_player_number() then
          mod:showMessage(ap:get_item_name(item.item, ap:get_player_game(item.player)), 'to ' .. ap:get_player_alias(item.player))
        end
      end
    end
  end

  function on_location_checked(locations)
    mod:dbg('Locations checked:' .. table.concat(locations, ', '))
    mod:dbg('Checked locations: ' .. table.concat(ap.checked_locations, ', '))
  end

  function on_data_package_changed(data_package)
    mod:dbg('Data package changed:')
    mod:dbg(tostring(data_package))
  end

  function on_print(msg)
    mod:dbg(msg)
  end

  function on_print_json(msg, extra)
    mod:dbg(ap:render_json(msg, message_format))
    for key, value in pairs(extra) do
      -- print('  ' .. key .. ': ' .. tostring(value))
    end
  end

  function on_bounced(bounce)
    mod:dbg('Bounced:')
    mod:dbg(tostring(bounce))
    if bounce.tags and valueInList('DeathLink', bounce.tags) and bounce.data then
      if last_death_link ~= nil and tostring(last_death_link) == tostring(bounce.data.time) then
        -- our own package -> Do nothing
      else
        Isaac.GetPlayer():Die()
        local cause = bounce.data.cause or 'unknown'
        local source = bounce.data.source or 'unknown'
        mod:showMessage('Killed by ' .. source, cause)
      end
    end
  end

  function mod:printRunInfo()
    mod:dbg('RunInfo:')
    if runInfo then
      for key, value in pairs(runInfo) do
        if type(value) == 'table' then
          mod:dbg('  ' .. key .. ': ')
          for subkey, subvalue in pairs(value) do
            if type(subvalue) == 'table' then
              mod:dbg('  ' .. subkey .. ': ')
              for subsubkey, subsubvalue in pairs(subvalue) do
                mod:dbg('    ' .. subsubkey .. ': ' .. tostring(subsubvalue))
              end
            else
              mod:dbg('  ' .. subkey .. ': ' .. tostring(subvalue))
            end
          end
        else
          mod:dbg('  ' .. key .. ': ' .. tostring(value))
        end
      end
    else
      mod:dbg('runInfo empty.')
    end
  end

  function on_retrieved(map, keys, extra)
    mod:dbg('Retrieved:')
    -- since lua tables won't contain nil values, we can use keys array
    for _, key in ipairs(keys) do
      mod:dbg('  ' .. key .. ': ' .. tostring(map[key]))
      if key == cfg.slot .. '_run_info' then
        
        mod:dbg('RunInfo updated #on_retrieved()')
        runInfo = map[key]
        mod:dbg('Run Info updated')
        if mod:isActiveRun() then
          mod:giveItems()
        else
          mod:initNewRun()
        end
        mod:printRunInfo()
      end
      if key == cfg.slot .. '_checked_items' then
        checked_items = map[key]
        if not checked_items then
          checked_items = 1
        end
      end
    end
    -- extra will include extra fields from Get
    mod:dbg('Extra:')
    for key, value in pairs(extra) do
      mod:dbg('  ' .. key .. ': ' .. tostring(value))
    end
    -- both keys and extra are optional
  end

  function on_set_reply(message)
    mod:dbg('Set Reply:')
    for key, value in pairs(message) do
      mod:dbg('  ' .. key .. ': ' .. tostring(value))
      if key == 'value' and type(value) == 'table' then
        for subkey, subvalue in pairs(value) do
          mod:dbg('  ' .. subkey .. ': ' .. tostring(subvalue))
        end
      end
    end
  end

  local uuid = ''
  ap = AP(uuid, game_name, server);

  ap:set_socket_connected_handler(on_socket_connected)
  ap:set_socket_error_handler(on_socket_error)
  ap:set_socket_disconnected_handler(on_socket_disconnected)
  ap:set_room_info_handler(on_room_info)
  ap:set_slot_connected_handler(on_slot_connected)
  ap:set_slot_refused_handler(on_slot_refused)
  ap:set_items_received_handler(on_items_received)
  ap:set_location_info_handler(on_location_info)
  ap:set_location_checked_handler(on_location_checked)
  ap:set_data_package_changed_handler(on_data_package_changed)
  ap:set_print_handler(on_print)
  ap:set_print_json_handler(on_print_json)
  ap:set_bounced_handler(on_bounced)
  ap:set_retrieved_handler(on_retrieved)
  ap:set_set_reply_handler(on_set_reply)
end

local pool  = Game():GetItemPool()
local rng   = RNG()
rng:SetSeed(Game():GetSeeds():GetStartSeed(), 35)
local ap_item_id = Isaac.GetItemIdByName('AP Item')
local next_ap_item = 1

function mod:hasUnlock(unlockable)
  return availableItems and availableItems['Unlock ' .. unlockable] and availableItems['Unlock ' .. unlockable] > 0
end


function mod:isActiveRun()
  if runInfo and runInfo['is_active'] then
    return true
  end
  return false
end

local giveQueue = Stack()
local consumableQueue = Stack()
local messageQueue = Stack()
local queueTimer = 0


local lock_item = false


function mod:giveNext()  
  if giveQueue.count > 0 then
    local itemId = giveQueue:pop()
    mod:dbg('Give Item with id: ' .. tostring(itemId))
    local cfgItem = Isaac.GetItemConfig():GetCollectible(itemId)
    if cfgItem.Type == ItemType.ITEM_ACTIVE then
      local pos = Vector(Isaac.GetPlayer().Position.X + rng:RandomInt(80) - 40, Isaac.GetPlayer().Position.Y + rng:RandomInt(80) - 40)
      Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, itemId, pos, Vector.Zero, nil)
    else
      Isaac.GetPlayer():AnimateCollectible(itemId, 'Pickup', 'PlayerPickupSparkle')
      Isaac.GetPlayer():QueueItem(cfgItem, 0, false, false, 0)
    end
    if itemId == CollectibleType.COLLECTIBLE_1UP then
      SFXManager():Play(SoundEffect.SOUND_1UP)
    else
      SFXManager():Play(SoundEffect.SOUND_POWERUP1)
    end
    --Game():GetHUD():ShowItemText(Isaac.GetPlayer(), cfgItem, true)
    queueTimer = 15
    return
  end
  if consumableQueue.count > 0 then
    local consumable = consumableQueue:pop()
    
    local pos = Vector(Isaac.GetPlayer().Position.X + rng:RandomInt(80) - 40, Isaac.GetPlayer().Position.Y + rng:RandomInt(80) - 40)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, consumable, 0, pos, Vector.Zero, nil)

    queueTimer = 3
  end
  if trapQueue.count > 0 then
    local trap = trapQueue:pop()
    mod:dbg('Activating trap: ' .. trap)
    if trap == 'Curse Trap' then
      local curses = {LevelCurse.CURSE_OF_BLIND, LevelCurse.CURSE_OF_DARKNESS, LevelCurse.CURSE_OF_THE_UNKNOWN, LevelCurse.CURSE_OF_THE_LOST}
      Game():GetLevel():AddCurse(curses[rng:RandomInt(4) + 1], false)
      rng:Next()
    elseif trap == 'Paralysis Trap' then
      Isaac.GetPlayer():UsePill(PillEffect.PILLEFFECT_PARALYSIS, PillColor.PILL_WHITE_WHITE, UseFlag.USE_NOANIM)
    elseif trap == 'Retro Vision Trap' then
      Isaac.GetPlayer():UsePill(PillEffect.PILLEFFECT_RETRO_VISION, PillColor.PILL_WHITE_WHITE, UseFlag.USE_NOANIM)
    elseif trap == 'Teleport Trap' then
      Isaac.GetPlayer():UsePill(PillEffect.PILLEFFECT_TELEPILLS, PillColor.PILL_WHITE_WHITE, UseFlag.USE_NOANIM)
    elseif trap == 'Troll Bomb Trap' then
      local pos = Vector(Isaac.GetPlayer().Position.X + rng:RandomInt(80) - 40, Isaac.GetPlayer().Position.Y + rng:RandomInt(80) - 40)
      Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, BombSubType.BOMB_SUPERTROLL, pos, Vector.Zero, nil)
    elseif trap == 'Wavy Cap Trap' then
      Isaac.GetPlayer():UseActiveItem(CollectibleType.COLLECTIBLE_WAVY_CAP, UseFlag.USE_NOANIM)
    end
    queueTimer = 3
  end
end

function mod:showMessage(title, text)
  messageQueue:push({type=0, title=title, text=text})
end
function mod:showFortune(line1, line2)
  messageQueue:push({type=1, line1=line1, line2=line2})
end

local checkSpecialExitsNextFrame = false
local played_fortune_machines = {}

function mod:onPostUpdate()
  if messageQueue.count > 0 then
    if fortune_cdr > 0 then
      fortune_cdr = fortune_cdr - 1
    else
      local message = messageQueue:pop()
      if message.type == 0 then
        Game():GetHUD():ShowItemText(message.title, message.text, false, true)
      elseif message.type == 1 then
        Game():GetHUD():ShowFortuneText(message.line1, message.line2)
      end
    end
  end

  for idx, ref in pairs(played_fortune_machines) do
    local machine = ref.Entity
    if machine:GetSprite():IsEventTriggered('Prize') then
      played_fortune_machines[idx] = nil
      mod:dbg('Fortune machine popped!')
      local random_location = ap.missing_locations[rng:RandomInt(#ap.missing_locations) + 1]
      ap:LocationScouts({random_location}, true)
    end
  end

  if not mod:isActiveRun() then return end

  if queueTimer > 0 then
    queueTimer = queueTimer - 1
  end
  if queueTimer == 0 then
    mod:giveNext()
  end
  if checkSpecialExitsNextFrame then
    checkSpecialExitsNextFrame = false
    mod:checkSpecialExits()
  end

  if Isaac.GetPlayer():HasCollectible(ap_item_id) then
    Isaac.GetPlayer():RemoveCollectible(ap_item_id)
    local location_id = ap:get_location_id('Item Pickup #' .. tostring(checked_items))
    ap:LocationChecks({location_id})
    ap:LocationScouts({location_id}, false)
    checked_items = checked_items + 1
    ap:Set(cfg.slot .. '_checked_items', {}, false, { {'replace', checked_items}})
  end
end


function mod:enterRoom()
  mod:dbg('Current stage: ' .. mod:getCurrentStageName())
  mod:dbg('Current Room Index: ' .. Game():GetLevel():GetCurrentRoomIndex())
  if not mod:isActiveRun() then return end
  mod:checkSpecialExits()

  if Game():GetRoom():IsClear() and Game():GetRoom():IsFirstVisit() and Game():GetRoom():GetType() ~= RoomType.ROOM_CHALLENGE then
    mod:unlockLocation()
  end

  if Game():GetRoom():IsMirrorWorld() then
    if not runInfo then
      runInfo = {}
    end
    if not runInfo['visited_stages'] then
      runInfo['visited_stages'] = {}
    end
    if not valueInList('Mirrorworld', runInfo['visited_stages']) then
      table.insert(runInfo['visited_stages'], 'Mirrorworld')
      ap:Set(cfg.slot .. '_run_info', {}, false, { {'replace', runInfo}})
    end
  end
  if Game():GetLevel():GetStateFlag(LevelStateFlag.STATE_MINESHAFT_ESCAPE) then
    if not runInfo then
      runInfo = {}
    end
    if not runInfo['visited_stages'] then
      runInfo['visited_stages'] = {}
    end
    if not valueInList('The Escape', runInfo['visited_stages']) then
      table.insert(runInfo['visited_stages'], 'The Escape')
      ap:Set(cfg.slot .. '_run_info', {}, false, { {'replace', runInfo}})
    end
  end
end

local boss_rewards = {
  [EntityType.ENTITY_MOM] ={ ['name'] = 'Mom', ['rewards'] = 1 },
  [EntityType.ENTITY_MOMS_HEART] ={ ['name'] = 'Mom\'s Heart', ['rewards'] = 2 },
  [-1] ={ ['name'] = 'Boss Rush', ['rewards'] = 2 },
  [EntityType.ENTITY_ISAAC] ={ ['name'] = 'Isaac', ['rewards'] = 3 },
  [EntityType.ENTITY_SATAN] ={ ['name'] = 'Satan', ['rewards'] = 3 },
  [EntityType.ENTITY_HUSH] ={ ['name'] = 'Hush', ['rewards'] = 3 },
  [-2] ={ ['name'] = 'Blue Baby', ['rewards'] = 4 },
  [EntityType.ENTITY_THE_LAMB] ={ ['name'] = 'The Lamb', ['rewards'] = 4 },
  [EntityType.ENTITY_MEGA_SATAN_2] ={ ['name'] = 'Mega Satan', ['rewards'] = 5 },
  [EntityType.ENTITY_MOTHER] ={ ['name'] = 'Mother', ['rewards'] = 5 },
  [EntityType.ENTITY_BEAST] ={ ['name'] = 'Beast', ['rewards'] = 5 },
  [EntityType.ENTITY_DELIRIUM] ={ ['name'] = 'Delirium', ['rewards'] = 5 },
}

function mod:roomCleared()
  mod:dbg('Current room type: ' .. tostring(Game():GetRoom():GetType()))
  if Game():GetRoom():GetType() == RoomType.ROOM_BOSS then
    checkSpecialExitsNextFrame = true
  end
  if Game():GetRoom():GetType() == RoomType.ROOM_BOSSRUSH then
    local boss = boss_rewards[-1]
    if boss then
      if options and options['additional_boss_rewards'] then
        for i = 1, boss['rewards'] do
          ap:LocationChecks({ap:get_location_id(boss['name'] .. ' Reward #' .. tostring(i))})
        end
      end
      if options and valueInList(boss['name'], options['goals']) then
        ap:LocationChecks({ap:get_location_id('Defeat' .. boss['name'])})
        mod:checkGoal()
      end
    end
  end
  mod:unlockLocation()
end


function mod:shouldHaveDoors(current_door_types)
  local should_have_door_types = {}

  local is_boss = Game():GetRoom():IsCurrentRoomLastBoss()
  local alt_path = Game():GetLevel():GetStageType() == StageType.STAGETYPE_REPENTANCE or Game():GetLevel():GetStageType() == StageType.STAGETYPE_REPENTANCE_B

  if (mod:hasUnlock('Downpour') or mod:hasUnlock('Dross')) then
    if (Game():GetLevel():GetStage() == LevelStage.STAGE1_1 or Game():GetLevel():GetStage() == LevelStage.STAGE1_2) and not alt_path then
      table.insert(should_have_door_types, RoomType.ROOM_SECRET_EXIT)
    end
  end
  if (mod:hasUnlock('Mines') or mod:hasUnlock('Ashpit')) then
    if ((Game():GetLevel():GetStage() == LevelStage.STAGE2_1 or Game():GetLevel():GetStage() == LevelStage.STAGE2_2) and not alt_path)
      or (Game():GetLevel():GetStage() == LevelStage.STAGE1_2 and alt_path) then
      table.insert(should_have_door_types, RoomType.ROOM_SECRET_EXIT)
    end
  end
  if (mod:hasUnlock('Mausoleum') or mod:hasUnlock('Gehenna')) then
    if (Game():GetLevel():GetStage() == LevelStage.STAGE3_1 and not alt_path)
      or (Game():GetLevel():GetStage() == LevelStage.STAGE2_2 and alt_path) then
      table.insert(should_have_door_types, RoomType.ROOM_SECRET_EXIT)
    end
  end
  if (mod:hasUnlock('Corpse')) then
    if Game():GetLevel():GetStage() == LevelStage.STAGE3_2 and alt_path then
      table.insert(should_have_door_types, RoomType.ROOM_BOSS)
    end
  end
  if (mod:hasUnlock('Home')) then
    if Game():GetLevel():GetStartingRoomIndex() == Game():GetLevel():GetCurrentRoomIndex() and not alt_path and Game():GetLevel():GetStage() == LevelStage.STAGE3_2 then
      table.insert(should_have_door_types, RoomType.ROOM_SECRET_EXIT)
    end
  end

  if is_boss and Game():GetLevel():GetStage() == LevelStage.STAGE3_2 and mod:hasUnlock('Boss Rush') then
    table.insert(should_have_door_types, RoomType.ROOM_BOSSRUSH)
  end
  if is_boss and Game():GetLevel():GetStage() == LevelStage.STAGE4_2 and mod:hasUnlock('???') then
    table.insert(should_have_door_types, RoomType.ROOM_BOSSRUSH)
  end
  if Game():GetLevel():GetStage() == LevelStage.STAGE1_2 and alt_path and mod:hasUnlock('Mirrorworld') then
    table.insert(should_have_door_types, 'Mirror')
  end

  return should_have_door_types
end

function mod:getDoorSlotOfType(doorType)
  for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
    local door = Game():GetRoom():GetDoor(i)
    if door and door.TargetRoomType == doorType then
      return i
    end
    if door and tostring(door:GetSprite():GetFilename()):find('door_downpour_mirror.anm2') and doorType == 'Mirror' then
      return i
    end
  end
  return 0
end

function mod:checkSpecialExits()
  local has_door_types = {}
  for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
    local door = Game():GetRoom():GetDoor(i)
    if door then
      if tostring(door:GetSprite():GetFilename()):find('door_downpour_mirror.anm2') then
        mod:dbg('Found door to room type: ' .. 'Mirror')
        table.insert(has_door_types, 'Mirror')
      else
        mod:dbg('Found door to room type: ' .. tostring(door.TargetRoomType))
        table.insert(has_door_types, door.TargetRoomType)
      end
    end
  end

  local should_have_door_types = mod:shouldHaveDoors(has_door_types)
  mod:dbg('Should have door types: ' .. table.concat(should_have_door_types, ', '))

  local is_boss = Game():GetRoom():IsCurrentRoomLastBoss()
  local alt_path = Game():GetLevel():GetStageType() == StageType.STAGETYPE_REPENTANCE or Game():GetLevel():GetStageType() == StageType.STAGETYPE_REPENTANCE_B

  if valueInList(RoomType.ROOM_SECRET_EXIT, should_have_door_types) and not valueInList(RoomType.ROOM_SECRET_EXIT, has_door_types) then
    if Game():GetRoom():IsClear() then
      mod:dbg('Adding secret exit')
      Game():GetRoom():TrySpawnSecretExit(true)
    end
  elseif not valueInList(RoomType.ROOM_SECRET_EXIT, should_have_door_types) and valueInList(RoomType.ROOM_SECRET_EXIT, has_door_types) then
    mod:dbg('Removing secret exit')
    Game():GetRoom():RemoveDoor(mod:getDoorSlotOfType(RoomType.ROOM_SECRET_EXIT))
  end
  if Game():GetLevel():GetStage() == LevelStage.STAGE3_2 and alt_path and is_boss then
    if not valueInList(RoomType.ROOM_BOSS, should_have_door_types) and valueInList(RoomType.ROOM_BOSS, has_door_types) then
      mod:dbg('Removing heart boss door')
      Game():GetRoom():RemoveDoor(mod:getDoorSlotOfType(RoomType.ROOM_BOSS))
    end
  end
  if Game():GetLevel():GetStage() == LevelStage.STAGE3_2 and is_boss then
    local trapdoor = Game():GetRoom():GetGridEntity(37)
    mod:dbg('Checking for trapdoor to Womb: ' .. tostring(trapdoor ~= nil))
    if trapdoor and not Game():GetStateFlag(GameStateFlag.STATE_MAUSOLEUM_HEART_KILLED) and not mod:hasUnlock('Womb') and not mod:hasUnlock('Utero') and not mod:hasUnlock('Scarred Womb') then
      mod:dbg('Removing trapdoor to Womb and spawning trophy')
      Game():GetRoom():RemoveGridEntity(trapdoor:GetGridIndex(), 0, false)
      Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TROPHY, 0, Game():GetRoom():GetCenterPos(), Vector.Zero, nil)
    end
  end

  if Game():GetLevel():GetCurrentRoomIndex() == -8 then
    local trapdoor = Game():GetRoom():GetGridEntity(67)
    mod:dbg('Checking for trapdoor to ???: ' .. tostring(trapdoor ~= nil))
    if trapdoor and not mod:hasUnlock('???') then
      mod:dbg('Removing trapdoor to ???')
      Game():GetRoom():RemoveGridEntity(trapdoor:GetGridIndex(), 0, false)
    end
  end

  if Game():GetLevel():GetCurrentRoomIndex() == -10 and Game():GetLevel():GetStage() == LevelStage.STAGE3_2 then
    local trapdoor = Game():GetRoom():GetGridEntity(67)
    mod:dbg('Checking for trapdoor to Mausoleum Ascend Path: ' .. tostring(trapdoor ~= nil))
    if trapdoor and not mod:hasUnlock('Mausoleum') then
      mod:dbg('Removing trapdoor to Mausoleum Ascend Path')
      Game():GetRoom():RemoveGridEntity(trapdoor:GetGridIndex(), 0, false)
    end
  end

  if (Game():GetLevel():GetStage() == LevelStage.STAGE4_2 or Game():GetLevel():GetStage() == LevelStage.STAGE4_3) and is_boss and not alt_path then
    local trapdoor = Game():GetRoom():GetGridEntity(66) or Game():GetRoom():GetGridEntity(125)
    mod:dbg('Checking for trapdoor to Sheol: ' .. tostring(trapdoor ~= nil))
    if trapdoor and not mod:hasUnlock('Sheol') then
      mod:dbg('Removing trapdoor to Sheol')
      Game():GetRoom():RemoveGridEntity(trapdoor:GetGridIndex(), 0, false)
    end

    local beam = nil
    for _, e in ipairs(Isaac.GetRoomEntities()) do
      if e.Type == EntityType.ENTITY_EFFECT and e.Variant == EffectVariant.HEAVEN_LIGHT_DOOR then
        beam = e
        break
      end
    end
    mod:dbg('Checking for beam to Cathedral: ' .. tostring(beam ~= nil))
    if beam and not mod:hasUnlock('Cathedral') then
      mod:dbg('Removing beam to Cathedral')
      beam:Remove()
    end

    if beam and trapdoor and not mod:hasUnlock('Sheol') and not mod:hasUnlock('Cathedral') then
      Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TROPHY, 0, Game():GetRoom():GetCenterPos(), Vector.Zero, nil)
    end
  end

  if Game():GetLevel():GetStage() == LevelStage.STAGE3_2 or Game():GetLevel():GetStage() >= LevelStage.STAGE4_2 then
    if (Game():GetRoom():GetType() == RoomType.ROOM_BOSS or Game():GetLevel():GetCurrentRoomIndex() == -9 or Game():GetLevel():GetCurrentRoomIndex() == -7) and not mod:hasUnlock('The Void') then
      local portal_position = 97
      if Game():GetLevel():GetCurrentRoomIndex() == -9 then
        portal_position = 67
      end
      if Game():GetLevel():GetCurrentRoomIndex() == -7 then
        portal_position = 157
      end
      local portal = Game():GetRoom():GetGridEntity(portal_position)
      mod:dbg('Checking for portal to The Void: ' .. tostring(portal ~= nil))
      if portal then
        mod:dbg('Removing portal to The Void')
        Game():GetRoom():RemoveGridEntity(portal:GetGridIndex(), 0, false)
      end
    end
  end
  
  if not valueInList(RoomType.ROOM_BOSSRUSH, should_have_door_types) and valueInList(RoomType.ROOM_BOSSRUSH, has_door_types) then
    mod:dbg('Removing Boss rush')
    Game():GetRoom():RemoveDoor(mod:getDoorSlotOfType(RoomType.ROOM_BOSSRUSH))
  end

  if not valueInList('Mirror', should_have_door_types) and valueInList('Mirror', has_door_types) then
    mod:dbg('Destroying Mirror')
    local mirror = Game():GetRoom():GetDoor(mod:getDoorSlotOfType('Mirror'))
    if mirror:IsLocked() then
      mirror:TryBlowOpen(true, Isaac.GetPlayer())
    end
  end
end

function mod:onEntitySpawn(type, variant, sub_type, position, velocity, spawner, seed)
  if type == EntityType.ENTITY_PICKUP and sub_type == CollectibleType.COLLECTIBLE_KNIFE_PIECE_1 then
    if not mod:hasUnlock('The Escape') then
      mod:dbg('Replacing Knife Piece 1 with Treasure Room Item')
      return { EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pool:GetCollectible(ItemPoolType.POOL_TREASURE, true, rng:Next()), seed }
    end
  end
  if type == EntityType.ENTITY_PICKUP and sub_type == CollectibleType.COLLECTIBLE_NEGATIVE then
    if not mod:hasUnlock('Dark Room') then
      mod:dbg('Replacing Negative with Boss Room Item')
      return { EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pool:GetCollectible(ItemPoolType.POOL_BOSS, true, rng:Next()), seed }
    end
  end
  if type == EntityType.ENTITY_PICKUP and sub_type == CollectibleType.COLLECTIBLE_POLAROID then
    if not mod:hasUnlock('Chest') then
      mod:dbg('Replacing Polaroid with Boss Room Item')
      return { EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pool:GetCollectible(ItemPoolType.POOL_BOSS, true, rng:Next()), seed }
    end
  end
  if type == EntityType.ENTITY_PICKUP and (sub_type == CollectibleType.COLLECTIBLE_KEY_PIECE_1 or sub_type == CollectibleType.COLLECTIBLE_KEY_PIECE_2) then
    if not mod:hasUnlock('Mega Satan') then
      mod:dbg('Replacing Key Piece with Angel Room Item')
      return { EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pool:GetCollectible(ItemPoolType.POOL_ANGEL, true, rng:Next()), seed }
    end
  end
  return nil
end

local queuedLocations = {} --TODO


local roomNames = {
  [RoomType.ROOM_BOSS] = 'Boss Room',
  [RoomType.ROOM_SHOP] = 'Shop',
  [RoomType.ROOM_TREASURE] = 'Treasure Room',
  [RoomType.ROOM_SECRET] = 'Secret Room',
  [RoomType.ROOM_SUPERSECRET] = 'Super Secret Room',
  [RoomType.ROOM_CURSE] = 'Curse Room',
  [RoomType.ROOM_CHALLENGE] = 'Challenge Room',
  [RoomType.ROOM_LIBRARY] = 'Library',
  [RoomType.ROOM_ARCADE] = 'Arcade',
  [RoomType.ROOM_DICE] = 'Dice Room',
  [RoomType.ROOM_BOSSRUSH] = 'Boss Rush',
  [RoomType.ROOM_DEVIL] = 'Deal Room',
  [RoomType.ROOM_ANGEL] = 'Deal Room',
  [RoomType.ROOM_MINIBOSS] = 'Miniboss Room',
  [RoomType.ROOM_SACRIFICE] = 'Sacrifice Room',
  [RoomType.ROOM_CHEST] = 'Vault',
  [RoomType.ROOM_ISAACS] = 'Bedroom',
  [RoomType.ROOM_BARREN] = 'Bedroom',
  ['Closet'] = 'Closet', --TODO
  ['Knife Piece'] = 'Knife Piece'
}

function mod:unlockLocation()
  local roomType = Game():GetRoom():GetType()
  local location_name = nil
  if roomNames[roomType] then
    location_name = mod:getCurrentStageName() .. ' - ' .. roomNames[roomType]
  end
  if Game():GetLevel():GetCurrentRoomIndex() == 94 and Game():GetLevel():GetStage() == LevelStage.STAGE8 then
    location_name = 'Home - Closet'
  end
  if Game():GetLevel():GetStateFlag(LevelStateFlag.STATE_MINESHAFT_ESCAPE) then
    location_name = 'The Escape - Knife Piece'
  end
  mod:dbg('Current location name: ' .. tostring(location_name))
  if not location_name then return end
  local location_id = ap:get_location_id(location_name)
  if not location_id or location_id < 1 then
    mod:dbg('Unknown location: ' .. location_name)
    return
  end
  if ap and ap:get_state() == ap.State.SLOT_CONNECTED then
    if not valueInList(location_id, ap.checked_locations) then
      ap:LocationChecks({location_id})
      ap:LocationScouts({location_id}, false)
    end
  else
    table.insert(queuedLocations, location_id)
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

function mod:checkGoal()
  for _, location in ipairs(ap.missing_locations) do
    local location_name = ap:get_location_name(location, nil)
    if location_name and location_name:find('^Defeat') then
      return
    end
  end
  ap:StatusUpdate(ap.ClientStatus.GOAL)
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
  if not entity or not entity:IsBoss() then return end
  mod:dbg('Checking Boss Rewards for ' .. tostring(entity.Type))
  local boss = boss_rewards[entity.Type]
  if entity.Type == EntityType.ENTITY_ISAAC and entity.Variant == 1 then
    boss = boss_rewards[-2]
  end
  if entity.Type == EntityType.ENTITY_ISAAC and Game():GetLevel():GetStage() == LevelStage.STAGE4_3 then
    return
  end
  if entity.Type == EntityType.ENTITY_MOTHER and entity.Variant ~= 10 then --Don't trigger on first Mother phase
    return
  end
  if entity.Type == EntityType.ENTITY_BEAST and entity.Variant ~= 0 then --Don't trigger on Horsemen before Beast
    return
  end
  if boss then
    if options and options['additional_boss_rewards'] then
      for i = 1, boss['rewards'] do
        local location_id = ap:get_location_id(boss['name'] .. ' Reward #' .. tostring(i))
        ap:LocationChecks({location_id})
        ap:LocationScouts({location_id}, false)
      end
    end
    if options and valueInList(boss['name'], options['goals']) then
      ap:LocationChecks({ap:get_location_id('Defeat ' .. boss['name'])})
      mod:checkGoal()
    end
  end
end

---@param item_pool_type ItemPoolType
---@param decrease boolean
---@param seed integer
function mod:onItemSpawn(item_pool_type, decrease, seed)
  if not options or lock_item or giveQueue.count > 0 or queueTimer > 0 or item_pool_type == ItemPoolType.POOL_NULL then
    mod:dbg('LOCK ITEM SET TO FALSE!')
    lock_item = false
    return nil
  end
  mod:dbg('checked_items: ' .. checked_items)
  mod:dbg('additional_item_locations: ' .. tonumber(options['additional_item_locations']))
  if checked_items > tonumber(options['additional_item_locations']) then return end
  next_ap_item = next_ap_item - 1
  mod:dbg('Next item in: ' .. next_ap_item)
  if next_ap_item == 0 then
    mod:dbg('Changing item to AP Item: ' .. tostring(ap_item_id))
    next_ap_item = math.tointeger(options['item_location_step']) or 1
    return ap_item_id
  end
end

local TextInput = include('textinput')
TextInput.Init(mod)

function mod:connectionMenu()
  if not TextInput.isOpen and Input.IsButtonTriggered(Keyboard.KEY_F2, 0) then
    TextInput:OpenTextInput(cfg.address, cfg.port, cfg.password, cfg.slot, function(confirm, address, port, password, slot)
    if confirm then
      cfg.address = address
      cfg.port = port
      cfg.slot = slot
      cfg.password = password
      mod:SaveData(json.encode(cfg))
      mod:dbg('Connecting to: ' .. address .. ':' .. port .. ' (' .. slot .. ') PW: ' .. password)
      connect(address .. ':' .. port, slot, password)
    end
  end)
  end
end

function mod:backToMenu()
  newRun = true
end

---@param collectible_type CollectibleType
function mod:onItemUse(collectible_type)
  if collectible_type == CollectibleType.COLLECTIBLE_LEMEGETON then
    lock_item = true
  end
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
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.enterRoom)
mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, mod.roomCleared)
mod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, mod.onEntitySpawn)
mod:AddCallback(ModCallbacks.MC_POST_GAME_END, mod.finishedRun)
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, mod.onEntityKill)
mod:AddCallback(ModCallbacks.MC_PRE_GET_COLLECTIBLE, mod.onItemSpawn)
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, mod.onPickupCollision)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.connectionMenu)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.backToMenu)
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, mod.onItemUse)
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, mod.onFortuneTellingMachine)
]=]