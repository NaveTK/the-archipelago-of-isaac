---@class ProgressionManager
---@field mod ModReference
---@field run_finished boolean
---@field new_run boolean
---@field init_on_connect boolean
---@field check_special_exists_next_frame boolean
local ProgressionManager = {
}
local rng = RNG()

function ProgressionManager:on_run_start(continued)
  self.run_finished = false
  self.mod.dbg('Run started, continued: ' .. tostring(continued))
  rng:SetSeed(Game():GetSeeds():GetStartSeed(), 35)
  self.new_run = false
  if not continued then
    if self.mod.client_manager.state == "Connected" then
      self:init_new_run()
    else
      self.init_on_connect = true
    end
  end
end

function ProgressionManager:init_new_run()
    self.init_on_connect = false
    if self.run_finished then return end
    self.new_run = false
    self.mod.dbg('RunInfo cleared #initnew_run()')
    self.mod.client_manager.run_info = {
        is_active = true,
        received_items = {},
        to_be_distributed = {},
        unspawned_locations = {},
        discarded_items = {}
    }
    self.mod.client_manager.block_death_link = 0
    self.mod.item_manager:init_new_run()
    self.mod.client_manager:update_run_info()
    self:on_new_level()
end

---@param unlock string
---@return boolean
function ProgressionManager:has_unlock(unlock)
  return self.mod.client_manager.available_items[unlock .. ' Unlock'] and self.mod.client_manager.available_items[unlock .. ' Unlock'] > 0
end

function ProgressionManager:get_unlocked_stage_types(currentStage, currentStageType)
  local available_types = {}
  if currentStage == LevelStage.STAGE1_1 or currentStage == LevelStage.STAGE1_2 then
    if currentStageType == StageType.STAGETYPE_REPENTANCE or currentStageType == StageType.STAGETYPE_REPENTANCE_B then --Downpour/Dross
      if self:has_unlock('Downpour') then
        table.insert(available_types, StageType.STAGETYPE_REPENTANCE)
      end
      if self:has_unlock('Dross') then
        table.insert(available_types, StageType.STAGETYPE_REPENTANCE_B)
      end
    else --Basement/Cellar/Burning Basement
      table.insert(available_types, StageType.STAGETYPE_ORIGINAL)
      if self:has_unlock('Cellar') then
        table.insert(available_types, StageType.STAGETYPE_WOTL)
      end
      if self:has_unlock('Burning Basement') then
        table.insert(available_types, StageType.STAGETYPE_AFTERBIRTH)
      end
    end
  elseif currentStage == LevelStage.STAGE2_1 or currentStage == LevelStage.STAGE2_2 then
    if currentStageType == StageType.STAGETYPE_REPENTANCE or currentStageType == StageType.STAGETYPE_REPENTANCE_B then --Mines/Ashpit
      if self:has_unlock('Mines') then
        table.insert(available_types, StageType.STAGETYPE_REPENTANCE)
      end
      if self:has_unlock('Ashpit') then
        table.insert(available_types, StageType.STAGETYPE_REPENTANCE_B)
      end
    else --Caves/Catacombs/Flooded Caes
      table.insert(available_types, StageType.STAGETYPE_ORIGINAL)
      if self:has_unlock('Catacombs') then
        table.insert(available_types, StageType.STAGETYPE_WOTL)
      end
      if self:has_unlock('Flooded Caves') then
        table.insert(available_types, StageType.STAGETYPE_AFTERBIRTH)
      end
    end
  elseif currentStage == LevelStage.STAGE3_1 or currentStage == LevelStage.STAGE3_2 then
    if currentStageType == StageType.STAGETYPE_REPENTANCE or currentStageType == StageType.STAGETYPE_REPENTANCE_B then --Mausoleum/Gehenna
      if self:has_unlock('Mausoleum') then
      table.insert(available_types, StageType.STAGETYPE_REPENTANCE)
      end
      if self:has_unlock('Gehenna') then
        table.insert(available_types, StageType.STAGETYPE_REPENTANCE_B)
      end
    else --Depths/Necropolis/Dank Depths
      table.insert(available_types, StageType.STAGETYPE_ORIGINAL)
      if self:has_unlock('Necropolis') then
        table.insert(available_types, StageType.STAGETYPE_WOTL)
      end
      if self:has_unlock('Dank Depths') then
        table.insert(available_types, StageType.STAGETYPE_AFTERBIRTH)
      end
    end
  elseif currentStage == LevelStage.STAGE4_1 or currentStage == LevelStage.STAGE4_2 then
    if currentStageType == StageType.STAGETYPE_REPENTANCE or currentStageType == StageType.STAGETYPE_REPENTANCE_B then --Womb/Utero/Scarred Womb
    -- nothing
    else --Womb/Utero/Scarred Womb
      if self:has_unlock('Womb') or self:has_unlock('We Need To Go Deeper!') then
        table.insert(available_types, StageType.STAGETYPE_ORIGINAL)
      end
      if self:has_unlock('Utero') then
        table.insert(available_types, StageType.STAGETYPE_WOTL)
      end
      if self:has_unlock('Scarred Womb') then
        table.insert(available_types, StageType.STAGETYPE_AFTERBIRTH)
      end
    end
  end
  return available_types
end

local stage_names = {
    [tostring(LevelStage.STAGE1_1) .. '_' .. tostring(StageType.STAGETYPE_ORIGINAL)] = 'Basement',
    [tostring(LevelStage.STAGE1_1) .. '_' .. tostring(StageType.STAGETYPE_WOTL)] = 'Cellar',
    [tostring(LevelStage.STAGE1_1) .. '_' .. tostring(StageType.STAGETYPE_AFTERBIRTH)] = 'Burning Basement',
    [tostring(LevelStage.STAGE1_1) .. '_' .. tostring(StageType.STAGETYPE_REPENTANCE)] = 'Downpour',
    [tostring(LevelStage.STAGE1_1) .. '_' .. tostring(StageType.STAGETYPE_REPENTANCE_B)] = 'Dross',
    [tostring(LevelStage.STAGE2_1) .. '_' .. tostring(StageType.STAGETYPE_ORIGINAL)] = 'Caves',
    [tostring(LevelStage.STAGE2_1) .. '_' .. tostring(StageType.STAGETYPE_WOTL)] = 'Catacombs',
    [tostring(LevelStage.STAGE2_1) .. '_' .. tostring(StageType.STAGETYPE_AFTERBIRTH)] = 'Flooded Caves',
    [tostring(LevelStage.STAGE2_1) .. '_' .. tostring(StageType.STAGETYPE_REPENTANCE)] = 'Mines',
    [tostring(LevelStage.STAGE2_1) .. '_' .. tostring(StageType.STAGETYPE_REPENTANCE_B)] = 'Ashpit',
    [tostring(LevelStage.STAGE3_1) .. '_' .. tostring(StageType.STAGETYPE_ORIGINAL)] = 'Depths',
    [tostring(LevelStage.STAGE3_1) .. '_' .. tostring(StageType.STAGETYPE_WOTL)] = 'Necropolis',
    [tostring(LevelStage.STAGE3_1) .. '_' .. tostring(StageType.STAGETYPE_AFTERBIRTH)] = 'Dank Depths',
    [tostring(LevelStage.STAGE3_1) .. '_' .. tostring(StageType.STAGETYPE_REPENTANCE)] = 'Mausoleum',
    [tostring(LevelStage.STAGE3_1) .. '_' .. tostring(StageType.STAGETYPE_REPENTANCE_B)] = 'Gehenna',
    [tostring(LevelStage.STAGE4_1) .. '_' .. tostring(StageType.STAGETYPE_ORIGINAL)] = 'Womb',
    [tostring(LevelStage.STAGE4_1) .. '_' .. tostring(StageType.STAGETYPE_WOTL)] = 'Utero',
    [tostring(LevelStage.STAGE4_1) .. '_' .. tostring(StageType.STAGETYPE_AFTERBIRTH)] = 'Scarred Womb',
    [tostring(LevelStage.STAGE4_1) .. '_' .. tostring(StageType.STAGETYPE_REPENTANCE)] = 'Corpse',
    [tostring(LevelStage.STAGE4_1) .. '_' .. tostring(StageType.STAGETYPE_REPENTANCE_B)] = 'Corpse',
    [tostring(LevelStage.STAGE4_3)] = '???',
    [tostring(LevelStage.STAGE5) .. '_Negative'] = 'Sheol',
    [tostring(LevelStage.STAGE5) .. '_Polaroid'] = 'Cathedral',
    [tostring(LevelStage.STAGE6) .. '_Negative'] = 'Dark Room',
    [tostring(LevelStage.STAGE6) .. '_Polaroid'] = 'Chest',
    [tostring(LevelStage.STAGE7)] = 'The Void',
    [tostring(LevelStage.STAGE8)] = 'Home'
}

function ProgressionManager:get_current_stage_name(--[[optional]] stageType)
  local stage = Game():GetLevel():GetStage()
  local type = stageType or Game():GetLevel():GetStageType()
  if Game():GetRoom():IsMirrorWorld() then
    return 'Mirrorworld'
  end
  if Game():GetRoom():GetType() == RoomType.ROOM_BOSSRUSH then
    return 'Boss Rush'
  end
  if stage < LevelStage.STAGE4_3 then
    local firstStage = math.floor((stage - 1) / 2) * 2 + 1
    if self.mod.client_manager.options.floor_variations then
      return stage_names[tostring(firstStage) .. '_' .. tostring(type)]    
    else
      return stage_names[tostring(firstStage) .. '_0']
    end
  end
  if stage == LevelStage.STAGE4_3 or stage >= LevelStage.STAGE7 then
    return stage_names[tostring(stage)]
  end
  if stage == LevelStage.STAGE5 or stage == LevelStage.STAGE6 then
    if Game():GetStateFlag(GameStateFlag.STATE_HEAVEN_PATH) then
      return stage_names[tostring(stage) .. '_Polaroid']
    else
      return stage_names[tostring(stage) .. '_Negative']
    end
  end
end

function ProgressionManager:is_completed_stage_type(stage_type)
    local stage = self:get_current_stage_name(stage_type)
    for _, location in ipairs(self.mod.client_manager.missing_locations) do
        local location_name = self.mod.client_manager:get_location_name(location)
        if location_name and location_name:find('^' .. stage) then
            return false
        end
    end
    return true
end

function ProgressionManager:on_new_level()
  self.mod.dbg("On new level")
  if not self.mod.client_manager.run_info or not self.mod.client_manager.run_info.is_active or self.new_run then return end

  if Game():GetLevel():GetStage() == LevelStage.STAGE8 and Game():GetLevel():GetStageType() >= StageType.STAGETYPE_WOTL and Game():GetLevel():GetStartingRoomIndex() == Game():GetLevel():GetCurrentRoomIndex() then
    self.mod.dbg('Bugged Home detected!')
    Isaac.ExecuteCommand('stage 13')
    return
  end

  if Game():GetLevel():GetStage() > LevelStage.STAGE4_2 or not self.mod.client_manager.options.floor_variations then self:on_new_level_post_reroll() return end 

  --reroll variant
  local available_types = self:get_unlocked_stage_types(Game():GetLevel():GetStage(), Game():GetLevel():GetStageType())
  self.mod.dbg('Available stage types for current stage: ' .. table.concat(available_types, ', '))

  local uncompleted_types = {}
    for _, type in ipairs(available_types) do
    if not self:is_completed_stage_type(type) then
      table.insert(uncompleted_types, type)
    end
  end
  self.mod.dbg('Uncompleted types: ' .. table.concat(uncompleted_types, ', '))
  if #uncompleted_types > 0 then
    available_types = uncompleted_types
  end
  self.mod.dbg('Available not completed stage types for current stage: ' .. table.concat(available_types, ', '))

  for _, level in ipairs(available_types) do
    if Game():GetLevel():GetStageType() == level then
      self.mod.dbg('Current stage type is already ' .. tostring(level) .. ', not changing')
      self:on_new_level_post_reroll()
      return
    end
  end

  self.mod.dbg('Number available types: ' .. #available_types)
  if #available_types > 0 then
    if rng:GetSeed() == 0 then
      rng:SetSeed(Game():GetSeeds():GetStartSeed(), 35)
    end
    local level = available_types[rng:RandomInt(#available_types) + 1]
    self.mod.dbg('Changing level type to ' .. tostring(level))
    Game():GetLevel():SetStage(Game():GetLevel():GetStage(), level)
    Isaac.ExecuteCommand('reseed')
    self.mod.dbg("Post reseed")
    return
  end
  self:on_new_level_post_reroll()
end


function ProgressionManager:on_new_level_post_reroll()
  self.mod.item_manager:distribute_items()

  local unspawned_locations = self.mod.client_manager.run_info.unspawned_locations
  local stage_name = self:get_current_stage_name()
  if not unspawned_locations[stage_name] then
    unspawned_locations[stage_name] = {"Arcade", "Challenge Room", "Curse Room", "Sacrifice Room", "Miniboss Room"}
  end
  
  local rooms = Game():GetLevel():GetRooms()
  for i = 0, rooms.Size-1 do
    local room_type = rooms:Get(i).Data.Type
    self.mod.dbg("Floor has room with type " .. tostring(room_type))
    if room_type == RoomType.ROOM_ARCADE then
      for i=#unspawned_locations[stage_name],1,-1 do
        if unspawned_locations[stage_name][i] == "Arcade" then
          table.remove(unspawned_locations[stage_name], i)
        end
      end
    end
    if room_type == RoomType.ROOM_CHALLENGE then
      for i=#unspawned_locations[stage_name],1,-1 do
        if unspawned_locations[stage_name][i] == "Challenge Room" then
          table.remove(unspawned_locations[stage_name], i)
        end
      end
    end
    if room_type == RoomType.ROOM_CURSE then
      for i=#unspawned_locations[stage_name],1,-1 do
        if unspawned_locations[stage_name][i] == "Curse Room" then
          table.remove(unspawned_locations[stage_name], i)
        end
      end
    end
    if room_type == RoomType.ROOM_SACRIFICE then
      for i=#unspawned_locations[stage_name],1,-1 do
        if unspawned_locations[stage_name][i] == "Sacrifice Room" then
          table.remove(unspawned_locations[stage_name], i)
        end
      end
    end
    if room_type == RoomType.ROOM_MINIBOSS then
      for i=#unspawned_locations[stage_name],1,-1 do
        if unspawned_locations[stage_name][i] == "Miniboss Room" then
          table.remove(unspawned_locations[stage_name], i)
        end
      end
    end
  end
  self.mod.client_manager:update_run_info()
end

local function valueInList(value, list)
  for _, v in ipairs(list) do
    if v == value then
      return true
    end
  end
  return false
end


function ProgressionManager:get_door_slot_of_type(doorType)
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

function ProgressionManager:should_have_doors()
  local should_have_door_types = {}

  local is_boss = Game():GetRoom():IsCurrentRoomLastBoss()
  local alt_path = Game():GetLevel():GetStageType() == StageType.STAGETYPE_REPENTANCE or Game():GetLevel():GetStageType() == StageType.STAGETYPE_REPENTANCE_B
  local is_xl = Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_LABYRINTH ~= 0
  local moms_foot_floor = (Game():GetLevel():GetStage() == LevelStage.STAGE3_2 or (Game():GetLevel():GetStage() == LevelStage.STAGE3_1 and is_xl))
  local moms_heart_floor = (Game():GetLevel():GetStage() == LevelStage.STAGE4_2 or (Game():GetLevel():GetStage() == LevelStage.STAGE4_1 and is_xl))

  if (self.mod.client_manager:has_unlock('Downpour') or self.mod.client_manager:has_unlock('Dross')) then
    if (Game():GetLevel():GetStage() == LevelStage.STAGE1_1 or Game():GetLevel():GetStage() == LevelStage.STAGE1_2) and not alt_path then
      table.insert(should_have_door_types, RoomType.ROOM_SECRET_EXIT)
    end
  end
  if (self.mod.client_manager:has_unlock('Mines') or self.mod.client_manager:has_unlock('Ashpit')) then
    if ((Game():GetLevel():GetStage() == LevelStage.STAGE2_1 or Game():GetLevel():GetStage() == LevelStage.STAGE2_2) and not alt_path)
      or ((Game():GetLevel():GetStage() == LevelStage.STAGE1_2 or (Game():GetLevel():GetStage() == LevelStage.STAGE1_1 and is_xl)) and alt_path) then
      table.insert(should_have_door_types, RoomType.ROOM_SECRET_EXIT)
    end
  end
  if (self.mod.client_manager:has_unlock('Mausoleum') or self.mod.client_manager:has_unlock('Gehenna')) then
    if (Game():GetLevel():GetStage() == LevelStage.STAGE3_1 and not alt_path and not is_xl)
      or ((Game():GetLevel():GetStage() == LevelStage.STAGE2_2 or (Game():GetLevel():GetStage() == LevelStage.STAGE2_1 and is_xl)) and alt_path) then
      table.insert(should_have_door_types, RoomType.ROOM_SECRET_EXIT)
    end
  end
  if (self.mod.client_manager:has_unlock('Strange Door')) then
    if Game():GetLevel():GetStartingRoomIndex() == Game():GetLevel():GetCurrentRoomIndex() and not alt_path and moms_foot_floor then
      table.insert(should_have_door_types, RoomType.ROOM_SECRET_EXIT)
    end
  end

  if is_boss and moms_foot_floor and self.mod.client_manager:has_unlock('Boss Rush') then
    table.insert(should_have_door_types, RoomType.ROOM_BOSSRUSH)
  end

  return should_have_door_types
end

function ProgressionManager:check_special_exits()
  local has_door_types = {}
  local has_door_indexes = {}
  for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
    local door = Game():GetRoom():GetDoor(i)
    if door then
      self.mod.dbg('Found door to room type: ' .. tostring(door.TargetRoomType) .. ' with index ' .. tostring(door.TargetRoomIndex))
      table.insert(has_door_types, door.TargetRoomType)
      table.insert(has_door_indexes, door.TargetRoomIndex)
    end
  end

  local should_have_door_types = self:should_have_doors()
  self.mod.dbg('Should have door types: ' .. table.concat(should_have_door_types, ', '))
  self.mod.dbg('Should have door indexes: ' .. table.concat(has_door_indexes, ', '))

  local is_boss = Game():GetRoom():IsCurrentRoomLastBoss()
  local alt_path = Game():GetLevel():GetStageType() == StageType.STAGETYPE_REPENTANCE or Game():GetLevel():GetStageType() == StageType.STAGETYPE_REPENTANCE_B
  local is_xl = Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_LABYRINTH ~= 0
  local moms_foot_floor = (Game():GetLevel():GetStage() == LevelStage.STAGE3_2 or (Game():GetLevel():GetStage() == LevelStage.STAGE3_1 and is_xl))
  local moms_heart_floor = (Game():GetLevel():GetStage() == LevelStage.STAGE4_2 or (Game():GetLevel():GetStage() == LevelStage.STAGE4_1 and is_xl))

  if not valueInList(RoomType.ROOM_SECRET_EXIT, should_have_door_types) and valueInList(RoomType.ROOM_SECRET_EXIT, has_door_types) then
    self.mod.dbg('Removing secret exit')
    Game():GetRoom():RemoveDoor(self:get_door_slot_of_type(RoomType.ROOM_SECRET_EXIT))
  end
  if moms_foot_floor and is_boss then
    local trapdoor = Game():GetRoom():GetGridEntity(37)
    self.mod.dbg('Checking for trapdoor to Womb: ' .. tostring(trapdoor ~= nil))
    if trapdoor and not Game():GetStateFlag(GameStateFlag.STATE_MAUSOLEUM_HEART_KILLED) and not self.mod.client_manager:has_unlock('Womb') and not self.mod.client_manager:has_unlock('Utero') and not self.mod.client_manager:has_unlock('Scarred Womb') then
      self.mod.dbg('Removing trapdoor to Womb and spawning trophy')
      Game():GetRoom():RemoveGridEntity(trapdoor:GetGridIndex(), 0, false)
      if Game():GetRoom():IsClear() then
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TROPHY, 0, Game():GetRoom():GetCenterPos(), Vector.Zero, nil)
      end
    end
  end

  if (moms_heart_floor or Game():GetLevel():GetStage() == LevelStage.STAGE4_3) and is_boss and not alt_path then
    local trapdoor = Game():GetRoom():GetGridEntity(66) or Game():GetRoom():GetGridEntity(125)
    self.mod.dbg('Checking for trapdoor to Sheol: ' .. tostring(trapdoor ~= nil))
    if trapdoor and not self.mod.client_manager:has_unlock('Sheol') then
      self.mod.dbg('Removing trapdoor to Sheol')
      Game():GetRoom():RemoveGridEntity(trapdoor:GetGridIndex(), 0, false)
    end

    local beam = nil
    for _, e in ipairs(Isaac.GetRoomEntities()) do
      if e.Type == EntityType.ENTITY_EFFECT and e.Variant == EffectVariant.HEAVEN_LIGHT_DOOR then
        beam = e
        break
      end
    end
    self.mod.dbg('Checking for beam to Cathedral: ' .. tostring(beam ~= nil))
    if beam and not self.mod.client_manager:has_unlock('Cathedral') then
      self.mod.dbg('Removing beam to Cathedral')
      beam:Remove()
    end

    if beam and trapdoor and not self.mod.client_manager:has_unlock('Sheol') and not self.mod.client_manager:has_unlock('Cathedral') and Game():GetRoom():IsClear() then
      Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TROPHY, 0, Game():GetRoom():GetCenterPos(), Vector.Zero, nil)
    end
  end

  if moms_foot_floor or moms_heart_floor or Game():GetLevel():GetStage() >= LevelStage.STAGE4_3 then
    if (is_boss or Game():GetLevel():GetCurrentRoomIndex() == -9 or Game():GetLevel():GetCurrentRoomIndex() == -10 or Game():GetLevel():GetCurrentRoomIndex() == -7) and not self.mod.client_manager:has_unlock('Void Portal') then
      local portal_position = 97
      if Game():GetLevel():GetCurrentRoomIndex() == -10 then
        portal_position = 172
      end
      if Game():GetLevel():GetCurrentRoomIndex() == -9 then
        portal_position = 67
      end
      if Game():GetLevel():GetCurrentRoomIndex() == -7 then
        portal_position = 157
      end
      local portal = Game():GetRoom():GetGridEntity(portal_position)
      self.mod.dbg('Checking for portal to The Void: ' .. tostring(portal ~= nil))
      if portal then
        self.mod.dbg('Removing portal to The Void')
        Game():GetRoom():RemoveGridEntity(portal:GetGridIndex(), 0, false)
      end
    end
  end
  
  if not valueInList(RoomType.ROOM_BOSSRUSH, should_have_door_types) and valueInList(RoomType.ROOM_BOSSRUSH, has_door_types) then
    self.mod.dbg('Removing Boss rush')
    Game():GetRoom():RemoveDoor(self:get_door_slot_of_type(RoomType.ROOM_BOSSRUSH))
  end
  
  if moms_heart_floor and is_boss and not alt_path and not self.mod.client_manager:has_unlock('???') and valueInList(-8, has_door_indexes) then
    self.mod.dbg('Removing Boss rush')
    for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
      local door = Game():GetRoom():GetDoor(i)
      if door and door.TargetRoomIndex == -8 then
        Game():GetRoom():RemoveDoor(i)
      end
    end
  end
end

function ProgressionManager:enter_room()
  if not self.mod.client_manager.run_info or not self.mod.client_manager.run_info.is_active then return end
  self.mod.dbg('Current stage: ' .. self:get_current_stage_name())
  self.mod.dbg('Current Room Index: ' .. Game():GetLevel():GetCurrentRoomIndex())
  self.mod.dbg('Current Room Shape: ' .. Game():GetLevel():GetCurrentRoom():GetRoomShape())
  self:check_special_exits()
end

function ProgressionManager:on_post_update()
  if self.check_special_exists_next_frame then
    self.check_special_exists_next_frame = false
    self:check_special_exits()
  end
end

function ProgressionManager:room_cleared()
  self.mod.dbg('Current room type: ' .. tostring(Game():GetRoom():GetType()))
  if Game():GetRoom():GetType() == RoomType.ROOM_BOSS then
    self.check_special_exists_next_frame = true
  end
end

local ap_item_id = Isaac.GetItemIdByName('AP Item')

---@param pickup EntityPickup
function ProgressionManager:on_pickup_init(pickup)
  self.mod.dbg('Pickup Init: ' .. tostring(pickup.Type) .. '.' .. tostring(pickup.Variant) .. '.' .. tostring(pickup.SubType))
  self.mod.dbg(tostring(pickup.Touched))
  if pickup.Type == EntityType.ENTITY_PICKUP and pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then
    self.mod.dbg('Pickup Reroll Consider')
    local next_location = self.mod.client_manager:get_item_location(self:get_current_stage_name())

    if not next_location and pickup.SubType == ap_item_id then
      pickup:Morph(pickup.Type, pickup.Variant, Game():GetItemPool():GetCollectible(Game():GetItemPool():GetPoolForRoom(Game():GetRoom():GetType(), rng:Next()), true, rng:Next()), true, true, true)
    end

    if not Game():GetRoom():IsFirstVisit() and Game():GetRoom():GetFrameCount() == -1 then self.mod.dbg("Skip Reroll") return end

    if self.mod.item_manager.lock_item then
      self.mod.dbg('LOCK ITEM SET TO FALSE!')
      self.mod.item_manager.lock_item = false
      return
    end

    local item_config = Isaac.GetItemConfig():GetCollectible(pickup.SubType)
    local quest_item = item_config.Tags & ItemConfig.TAG_QUEST ~= 0

    quest_item = quest_item or (pickup.SubType == CollectibleType.COLLECTIBLE_WE_NEED_TO_GO_DEEPER) or (pickup.SubType == CollectibleType.COLLECTIBLE_RED_KEY) or (pickup.SubType == CollectibleType.COLLECTIBLE_UNDEFINED)

    self.mod.dbg('Quest Item: ' .. tostring(quest_item) .. ' Ap item: ' .. tostring(pickup.SubType == ap_item_id) .. ' Drop rng: ' .. tostring(pickup:GetDropRNG():RandomInt(100)) .. ' SubType: ' .. pickup.SubType)

    if next_location and not quest_item and pickup.SubType ~= ap_item_id and pickup:GetDropRNG():RandomInt(100) < self.mod.client_manager.options.item_location_percentage then
      self.mod.dbg("Roll into AP")
      --rng:Next()
      pickup:Morph(pickup.Type, pickup.Variant, ap_item_id, true, false, true)
    end

    if pickup.SubType == CollectibleType.COLLECTIBLE_KNIFE_PIECE_1 and not self.mod.client_manager:has_unlock('Knife Pieces') then
      pickup:Morph(pickup.Type, pickup.Variant, Game():GetItemPool():GetCollectible(ItemPoolType.POOL_TREASURE, true, rng:Next()), true, true, true)
    end
    if pickup.SubType == CollectibleType.COLLECTIBLE_POLAROID and not self.mod.client_manager:has_unlock('The Polaroid') then
      pickup:Morph(pickup.Type, pickup.Variant, Game():GetItemPool():GetCollectible(ItemPoolType.POOL_BOSS, true, rng:Next()), true, true, true)
    end
    if pickup.SubType == CollectibleType.COLLECTIBLE_NEGATIVE and not self.mod.client_manager:has_unlock('The Negative') then
      pickup:Morph(pickup.Type, pickup.Variant, Game():GetItemPool():GetCollectible(ItemPoolType.POOL_BOSS, true, rng:Next()), true, true, true)
    end
    if (pickup.SubType == CollectibleType.COLLECTIBLE_KEY_PIECE_1 or pickup.SubType == CollectibleType.COLLECTIBLE_KEY_PIECE_2) and not self.mod.client_manager:has_unlock('Key Pieces') then
      pickup:Remove()
    end
  end
end

---@param pickup EntityPickup
---@param collider Entity
function ProgressionManager:on_pre_pickup(pickup, collider)
  local player = collider:ToPlayer()
  if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE and pickup.SubType > 0 and player then
    if Isaac.GetItemConfig():GetCollectible(pickup.SubType).Type == ItemType.ITEM_ACTIVE and player:GetActiveItem() > 0 and not player:IsHoldingItem() then
        self.mod.dbg('LOCK ITEM SET TO TRUE!')
        self.mod.item_manager.lock_item = true
    end
  end
end

---@param mod ModReference
function ProgressionManager:Init(mod)
  self.mod = mod

  mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function() self:enter_room() end)
  mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued) self:on_run_start(continued) end)
  mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function() self:on_post_update() end)
  mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function() self:room_cleared() end)
  mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, function(_, pickup) self:on_pickup_init(pickup) end)
  mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function() self:on_new_level() end)
  mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, function(_, pickup, collider) self:on_pre_pickup(pickup, collider) end)
end

return ProgressionManager