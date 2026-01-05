---@class LocationManager
---@field mod ModReference
local LocationManager = {
    
}

local chapter_room_names = {
  [RoomType.ROOM_LIBRARY] = 'Library',
  [RoomType.ROOM_DICE] = 'Dice Room',
  [RoomType.ROOM_CHEST] = 'Vault',
  [RoomType.ROOM_ISAACS] = 'Bedroom',
  [RoomType.ROOM_BARREN] = 'Bedroom',
  [RoomType.ROOM_PLANETARIUM] = 'Planetarium',
  [RoomType.ROOM_ERROR] = 'I AM ERROR',
  [RoomType.ROOM_ULTRASECRET] = 'Ultra Secret Room',
  [RoomType.ROOM_DUNGEON] = 'Crawl Space'
}

local stage_room_names = {
  [RoomType.ROOM_BOSS] = 'Boss Room',
  [RoomType.ROOM_SHOP] = 'Shop',
  [RoomType.ROOM_TREASURE] = 'Treasure Room',
  [RoomType.ROOM_SECRET] = 'Secret Room',
  [RoomType.ROOM_SUPERSECRET] = 'Super Secret Room',
  [RoomType.ROOM_CURSE] = 'Curse Room',
  [RoomType.ROOM_CHALLENGE] = 'Challenge Room',
  [RoomType.ROOM_ARCADE] = 'Arcade',
  [RoomType.ROOM_DEVIL] = 'Deal Room',
  [RoomType.ROOM_ANGEL] = 'Deal Room',
  [RoomType.ROOM_MINIBOSS] = 'Miniboss Room',
  [RoomType.ROOM_SACRIFICE] = 'Sacrifice Room'
}

local chapter_names = {
  [LevelStage.STAGE1_1] = 'Chapter 1',
  [LevelStage.STAGE1_2] = 'Chapter 1',
  [LevelStage.STAGE2_1] = 'Chapter 2',
  [LevelStage.STAGE2_2] = 'Chapter 2',
  [LevelStage.STAGE3_1] = 'Chapter 3',
  [LevelStage.STAGE3_2] = 'Chapter 3',
  [LevelStage.STAGE4_1] = 'Chapter 4',
  [LevelStage.STAGE4_2] = 'Chapter 4',
  [LevelStage.STAGE4_3] = 'Chapter 4',
  [LevelStage.STAGE5] = 'Chapter 5',
  [LevelStage.STAGE6] = 'Chapter 6',
  [LevelStage.STAGE7] = 'Chapter 7',
  [LevelStage.STAGE8] = 'Chapter 8'
}

function LocationManager:unlock_location()
  local roomType = Game():GetRoom():GetType()
  local location_name = nil
  if stage_room_names[roomType] then
    location_name = self.mod.progression_manager:get_current_stage_name() .. ' - ' .. stage_room_names[roomType]
  end
  if chapter_room_names[roomType] then
    location_name = chapter_names[Game():GetLevel():GetStage()] .. ' - ' .. chapter_room_names[roomType]
  end
  if Game():GetLevel():GetCurrentRoomIndex() == 94 and Game():GetLevel():GetStage() == LevelStage.STAGE8 then
    location_name = 'Home - Closet'
  end
  if Game():GetLevel():GetStateFlag(LevelStateFlag.STATE_MINESHAFT_ESCAPE) then
    location_name = 'The Escape - Knife Piece'
  end
  if roomType == RoomType.ROOM_BOSSRUSH then
    location_name = 'Boss Rush - Boss Room'
  end
  if Game():GetLevel():GetCurrentRoomIndex() == -7 and Game():GetLevel():GetStage() == LevelStage.STAGE6 then
    location_name = 'Mega Satan - Boss Room'
  end
  if Game():GetLevel():GetCurrentRoomIndex() == -10 and Game():GetLevel():GetStage() == LevelStage.STAGE8 then
    location_name = 'Home - Boss Room'
  end
  self.mod.dbg('Current location name: ' .. tostring(location_name))
  if not location_name then return end
  self.mod.client_manager:unlock_locations({location_name})
end

function LocationManager:enter_room()
  if Game():GetRoom():IsClear() and Game():GetRoom():GetType() ~= RoomType.ROOM_CHALLENGE and Game():GetRoom():GetType() ~= RoomType.ROOM_BOSSRUSH and not (Game():GetLevel():GetCurrentRoomIndex() == -7 and Game():GetLevel():GetStage() == LevelStage.STAGE7) then
    self:unlock_location()
  end
end


function LocationManager:get_main_boss()
  local is_boss = Game():GetRoom():IsCurrentRoomLastBoss()
  local alt_path = Game():GetLevel():GetStageType() == StageType.STAGETYPE_REPENTANCE or Game():GetLevel():GetStageType() == StageType.STAGETYPE_REPENTANCE_B
  local is_xl = Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_LABYRINTH ~= 0
  local moms_foot_floor = (Game():GetLevel():GetStage() == LevelStage.STAGE3_2 or (Game():GetLevel():GetStage() == LevelStage.STAGE3_1 and is_xl))
  local moms_heart_floor = (Game():GetLevel():GetStage() == LevelStage.STAGE4_2 or (Game():GetLevel():GetStage() == LevelStage.STAGE4_1 and is_xl))

  if is_boss and moms_foot_floor then
    return 'Mom'
  end
  if is_boss and moms_heart_floor and not alt_path then
    return 'Mom\'s Heart'
  end
  if Game():GetRoom():GetType() == RoomType.ROOM_BOSSRUSH then
    return 'Boss Rush'
  end
  if is_boss and Game():GetLevel():GetStage() == LevelStage.STAGE5 and Game():GetStateFlag(GameStateFlag.STATE_HEAVEN_PATH) then
    return 'Isaac'
  end
  if is_boss and Game():GetLevel():GetStage() == LevelStage.STAGE5 and not Game():GetStateFlag(GameStateFlag.STATE_HEAVEN_PATH) then
    return 'Satan'
  end
  if is_boss and Game():GetLevel():GetStage() == LevelStage.STAGE4_3 then
    return 'Hush'
  end
  if is_boss and Game():GetLevel():GetStage() == LevelStage.STAGE6 and Game():GetStateFlag(GameStateFlag.STATE_HEAVEN_PATH) then
    return 'Blue Baby'
  end
  if is_boss and Game():GetLevel():GetStage() == LevelStage.STAGE6 and not Game():GetStateFlag(GameStateFlag.STATE_HEAVEN_PATH) then
    return 'The Lamb'
  end
  if Game():GetLevel():GetCurrentRoomIndex() == -7 and Game():GetLevel():GetStage() == LevelStage.STAGE6 then
    return 'Mega Satan'
  end
  if moms_heart_floor and Game():GetLevel():GetCurrentRoomIndex() == -10 then
    return 'Mother'
  end
  if Game():GetLevel():GetStage() == LevelStage.STAGE8 and Game():GetLevel():GetCurrentRoomIndex() == -10 then
    return 'Beast'
  end
  if is_boss and Game():GetLevel():GetStage() == LevelStage.STAGE7 and Game():GetLevel():GetCurrentRoom():GetRoomShape() == RoomShape.ROOMSHAPE_2x2 then
    return 'Delirium'
  end
  return nil
end

local boss_rewards = {
  ['Mom'] = 1,
  ['Mom\'s Heart'] = 2,
  ['Boss Rush'] = 2,
  ['Isaac'] = 3,
  ['Satan'] = 3,
  ['Hush'] = 3,
  ['Blue Baby'] = 4,
  ['The Lamb'] = 4,
  ['Mega Satan'] = 5,
  ['Mother'] = 5,
  ['Beast'] = 5,
  ['Delirium'] = 5,
}

function LocationManager:room_cleared()
  local boss = self:get_main_boss()
  if boss then
    local locations = {}
    for i = 1, boss_rewards[boss]+1 do
      table.insert(locations, boss .. ' Reward #' .. tostring(i))
    end

    self.mod.client_manager:send_goal(boss)
    self.mod.client_manager:unlock_locations(locations)
  end
  self:unlock_location()
end

local ap_item_id = Isaac.GetItemIdByName('AP Item')

function LocationManager:on_post_update()
  if not self.mod.client_manager.run_info or not self.mod.client_manager.run_info.is_active then return end

  if Isaac.GetPlayer():HasCollectible(ap_item_id, true) then
    Isaac.GetPlayer():RemoveCollectible(ap_item_id)
    local location = self.mod.client_manager:get_item_location(self.mod.progression_manager:get_current_stage_name())
    self.mod.dbg(tostring(location))
    if location then
      self.mod.client_manager:unlock_locations({location})
    end
  end
end

function LocationManager:on_run_ended(lost)
  if not self.mod.client_manager.run_info or not self.mod.client_manager.run_info.is_active then return end

  self.mod.dbg('Run result, lost: ' .. tostring(lost))
  local unspawned_locations = self.mod.client_manager.run_info.unspawned_locations
  local locations = {}
  self.mod.dbg('Unspawned Locations:')
  for floor, rooms in pairs(unspawned_locations) do
    self.mod.dbg('  ' .. floor .. ':')
    for _, room in ipairs(rooms) do
      self.mod.dbg('    ' .. room)
      table.insert(locations, floor .. ' - ' .. room)
    end
  end
  if not lost then
    self.mod.client_manager:unlock_locations(locations)
  end

  self.mod.client_manager.run_info.is_active = false
  self.mod.client_manager.run_info.received_items = {}
  self.mod.client_manager.run_info.to_be_distributed = {}
  self.mod.client_manager.run_info.discarded_items = {}
  self.mod.client_manager:update_run_info()

  self.mod.client_manager:send_commands()
end

---@param entity_pickup EntityPickup
---@param collider Entity
function LocationManager:on_pickup_collision(entity_pickup, collider)
  if collider.Index == Isaac.GetPlayer().Index then
    if entity_pickup.Variant == PickupVariant.PICKUP_TROPHY then
      self:on_run_ended(false)
    end
  end
end

---@param mod ModReference
function LocationManager:Init(mod)
  self.mod = mod

  mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function() self:enter_room() end)
  mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function() self:room_cleared() end)
  mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function() self:on_post_update() end)
  mod:AddCallback(ModCallbacks.MC_POST_GAME_END, function(_, lost) self:on_run_ended(lost) end)
  mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, function(_, entity_pickup, collider) self:on_pickup_collision(entity_pickup, collider) end)
end

return LocationManager