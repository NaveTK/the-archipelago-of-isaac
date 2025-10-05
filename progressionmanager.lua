---@class ProgressionManager
---@field mod ModReference
---@field run_finished boolean
---@field new_run boolean
local ProgressionManager = {
    
}
local rng = RNG()

function ProgressionManager:on_run_start(isContinued)
  self.run_finished = false
  self.mod.dbg('Run started, continued: ' .. tostring(isContinued))
  rng:SetSeed(Game():GetSeeds():GetStartSeed(), 35)
  self.new_run = false
  if not isContinued then
    if self.mod.client_manager.state == "Connected" then
      self:init_new_run()
    end
  end
end

function ProgressionManager:init_new_run()
    if self.run_finished then return end
    self.new_run = false
    self.mod.dbg('RunInfo cleared #initnew_run()')
    self.mod.client_manager.run_info = {
        is_active = true,
        received_items = {},
        to_be_distributed = {},
        unspawned_locations = {}
    }
    self.mod.item_manager:init_new_run()
    self.mod.client_manager:update_run_info()
    self:on_new_level()
end

---@param unlock string
---@return boolean
function ProgressionManager:has_unlock(unlock)
  return self.mod.client_manager.available_items[unlock] and self.mod.client_manager.available_items[unlock] > 0
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
      if self:has_unlock('Womb') then
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
  if stage < LevelStage.STAGE4_3 then
    local firstStage = math.floor((stage - 1) / 2) * 2 + 1
    return stage_names[tostring(firstStage) .. '_' .. tostring(type)]
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
    self.mod.dbg(stage)
    for _, location in ipairs(self.mod.client_manager.missing_locations) do
        local location_name = self.mod.client_manager:get_location_name(location)
        if location_name:find('^' .. stage) then
            return false
        end
    end
    return true
end

function ProgressionManager:on_new_level()

  if not self.mod.client_manager.run_info.is_active or self.new_run then return end

  if Game():GetLevel():GetStage() > LevelStage.STAGE4_2 or Game():GetLevel():IsPreAscent() then self:on_new_level_post_reroll() return end 

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
  else
    self:on_new_level_post_reroll()
  end
end


function ProgressionManager:on_new_level_post_reroll()
  self.mod.item_manager:distribute_items()

  if Game():GetLevel():GetStage() <= LevelStage.STAGE4_2 then
    local unspawned_locations = self.mod.client_manager.run_info.unspawned_locations
    local stage_name = self:get_current_stage_name()
    if not unspawned_locations[stage_name] then
      unspawned_locations[stage_name] = {"Arcade", "Challenge Room", "Curse Room", "Sacrifice Room", "Miniboss Room"}
    end
    
    if Game():GetLevel():QueryRoomTypeIndex(RoomType.ROOM_ARCADE, false, rng) ~= -1 then
      for i=#unspawned_locations[stage_name],1,-1 do
        if unspawned_locations[stage_name][i] == "Arcade" then
          table.remove(unspawned_locations[stage_name], i)
        end
      end
    end
    if Game():GetLevel():QueryRoomTypeIndex(RoomType.ROOM_CHALLENGE, false, rng) ~= -1 then
      for i=#unspawned_locations[stage_name],1,-1 do
        if unspawned_locations[stage_name][i] == "Challenge Room" then
          table.remove(unspawned_locations[stage_name], i)
        end
      end
    end
    if Game():GetLevel():QueryRoomTypeIndex(RoomType.ROOM_CURSE, false, rng) ~= -1 then
      for i=#unspawned_locations[stage_name],1,-1 do
        if unspawned_locations[stage_name][i] == "Curse Room" then
          table.remove(unspawned_locations[stage_name], i)
        end
      end
    end
    if Game():GetLevel():QueryRoomTypeIndex(RoomType.ROOM_SACRIFICE, false, rng) ~= -1 then
      for i=#unspawned_locations[stage_name],1,-1 do
        if unspawned_locations[stage_name][i] == "Sacrifice Room" then
          table.remove(unspawned_locations[stage_name], i)
        end
      end
    end
    if Game():GetLevel():QueryRoomTypeIndex(RoomType.ROOM_MINIBOSS, false, rng) ~= -1 then
      for i=#unspawned_locations[stage_name],1,-1 do
        if unspawned_locations[stage_name][i] == "Miniboss Room" then
          table.remove(unspawned_locations[stage_name], i)
        end
      end
    end
    self.mod.client_manager:update_run_info()
  end
end

---@param mod ModReference
function ProgressionManager:Init(mod)
  self.mod = mod

  mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, self.on_run_start)
end

return ProgressionManager