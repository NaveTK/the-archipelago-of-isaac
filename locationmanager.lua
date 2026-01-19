---@class LocationManager
---@field mod ModReference
---@field played_fortune_machines table<integer, EntityRef>
local LocationManager = {
    played_fortune_machines = {}
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

---@param room_type integer
---@param room_index integer
function LocationManager:get_location_name(room_type, room_index)
  local location_name = nil
  if stage_room_names[room_type] then
    location_name = self.mod.progression_manager:get_current_stage_name() .. ' - ' .. stage_room_names[room_type]
  end
  if chapter_room_names[room_type] then
    location_name = chapter_names[Game():GetLevel():GetStage()] .. ' - ' .. chapter_room_names[room_type]
  end
  if room_index == 94 and Game():GetLevel():GetStage() == LevelStage.STAGE8 then
    location_name = 'Home - Closet'
  end
  if Game():GetLevel():GetStateFlag(LevelStateFlag.STATE_MINESHAFT_ESCAPE) then
    location_name = 'The Escape - Knife Piece'
  end
  if room_type == RoomType.ROOM_BOSSRUSH then
    location_name = 'Boss Rush - Boss Room'
  end
  if room_index == -7 and Game():GetLevel():GetStage() == LevelStage.STAGE6 then
    location_name = 'Mega Satan - Boss Room'
  end
  if room_index == -10 and Game():GetLevel():GetStage() == LevelStage.STAGE8 then
    location_name = 'Home - Boss Room'
  end
  return location_name
end

function LocationManager:unlock_location()
  local location_name = self:get_location_name(Game():GetRoom():GetType(), Game():GetLevel():GetCurrentRoomIndex())
  self.mod.dbg('Current location name: ' .. tostring(location_name))
  if not location_name then return end
  self.mod.client_manager:unlock_locations({location_name})
  if Game():GetLevel():GetCurrentRoomDesc().SurpriseMiniboss then
    location_name = self.mod.progression_manager:get_current_stage_name() .. ' - Miniboss Room'
    self.mod.client_manager:unlock_locations({location_name})
  end
end

function LocationManager:enter_room()
  if not self.mod.client_manager.run_info or not self.mod.client_manager.run_info.is_active then return end

  if Game():GetRoom():IsClear() and Game():GetRoom():GetType() ~= RoomType.ROOM_CHALLENGE and Game():GetRoom():GetType() ~= RoomType.ROOM_BOSSRUSH and not (Game():GetLevel():GetCurrentRoomIndex() == -7 and Game():GetLevel():GetStage() == LevelStage.STAGE7) then
    self:unlock_location()
  end

  for slot=0,DoorSlot.NUM_DOOR_SLOTS-1 do
    local door = Game():GetRoom():GetDoor(slot)
    if door then
      local location = self:get_location_name(door.TargetRoomType, door.TargetRoomIndex)
      if location then
        local id = self.mod.client_manager:get_location_id(location)
        if self.mod.client_manager:is_missing(id) then
          self:show_ap_on_door(door)
        end
      end
    end
  end
end

---@param door GridEntityDoor?
function LocationManager:show_ap_on_door(door)
  if not door then return end
  if door:GetSprite():GetAnimation() == "Hidden" then return end

  local dir_offsets = {
    [Direction.DOWN] = Vector(8, 35),
    [Direction.LEFT] = Vector(-23, 6),
    [Direction.RIGHT] = Vector(36, 6),
    [Direction.UP] = Vector(8, -23),
    [Direction.NO_DIRECTION] = Vector.Zero
  }

  local ap_icon = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.LADDER, 0, door.Position + dir_offsets[door.Direction], Vector.Zero, nil):ToEffect()
  if ap_icon then
    ap_icon:GetSprite():LoadGraphics()
    ap_icon:GetSprite():ReplaceSpritesheet(0, "gfx/Items/Collectibles/ap_icon_small.png")
    ap_icon:GetSprite():LoadGraphics()
    ap_icon:SetTimeout(-1)
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
  if Game():GetRoom():GetType() == RoomType.ROOM_BOSS and Game():GetLevel():GetStage() == LevelStage.STAGE7 and Game():GetLevel():GetCurrentRoom():GetRoomShape() == RoomShape.ROOMSHAPE_2x2 then
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
    if self.mod.client_manager.options.additional_boss_rewards then
      local locations = {}
      for i = 1, boss_rewards[boss]+1 do
        table.insert(locations, boss .. ' Reward #' .. tostring(i))
      end

      self.mod.client_manager:unlock_locations(locations)
    end
    self.mod.client_manager:send_goal(boss)
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

      local next_location = self.mod.client_manager:get_item_location(self.mod.progression_manager:get_current_stage_name())
      if not next_location then
        for _, entity in ipairs(Isaac.GetRoomEntities()) do
          if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and entity.SubType == ap_item_id then
            local pickup = entity:ToPickup()
            if pickup then
              pickup:Morph(pickup.Type, pickup.Variant, Game():GetItemPool():GetCollectible(Game():GetItemPool():GetPoolForRoom(Game():GetRoom():GetType(), Random()), true, Random()), true, true, true)
            end
          end
        end
      end
    end
  end
  if Isaac.GetPlayer():GetOtherTwin() ~= nil then
    if Isaac.GetPlayer():GetOtherTwin():HasCollectible(ap_item_id, true) then
      Isaac.GetPlayer():GetOtherTwin():RemoveCollectible(ap_item_id)
      local location = self.mod.client_manager:get_item_location(self.mod.progression_manager:get_current_stage_name())
      self.mod.dbg(tostring(location))
      if location then
        self.mod.client_manager:unlock_locations({location})

        local next_location = self.mod.client_manager:get_item_location(self.mod.progression_manager:get_current_stage_name())
        if not next_location then
          for _, entity in ipairs(Isaac.GetRoomEntities()) do
            if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and entity.SubType == ap_item_id then
              local pickup = entity:ToPickup()
              if pickup then
                pickup:Morph(pickup.Type, pickup.Variant, Game():GetItemPool():GetCollectible(Game():GetItemPool():GetPoolForRoom(Game():GetRoom():GetType(), Random()), true, Random()), true, true, true)
              end
            end
          end
        end
      end
    end
  end

  for idx, ref in pairs(self.played_fortune_machines) do
    local machine = ref.Entity
    if machine:GetSprite():IsEventTriggered('Prize') then
      self.played_fortune_machines[idx] = nil
      self.mod.dbg('Fortune machine popped!')
      if math.random(100) <= self.mod.client_manager.options.fortune_machine_hint_percentage then
        self.mod.client_manager:send_hint()
      end
    end
  end
end

function LocationManager:on_crystal_ball_use()
  self.mod.dbg('Crystal ball used!')
  if math.random(100) <= self.mod.client_manager.options.crystal_ball_hint_percentage then
    self.mod.client_manager:send_hint()
  end
end

function LocationManager:on_fortune_cookie_use()
  self.mod.dbg('Crystal ball used!')
  if math.random(100) <= self.mod.client_manager.options.fortune_cookie_hint_percentage then
    self.mod.client_manager:send_hint()
  end
end

function LocationManager:on_run_ended(lost)
  if not self.mod.client_manager.run_info or not self.mod.client_manager.run_info.is_active then return end

  self.mod.dbg('Run result, lost: ' .. tostring(lost))
  if self.mod.client_manager.options.bad_rng_protection then
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
  end

  self.mod.client_manager.run_info.is_active = false
  self.mod.client_manager.run_info.received_items = {}
  self.mod.client_manager.run_info.to_be_distributed = {}
  self.mod.client_manager.run_info.discarded_items = {}
  self.mod.client_manager:update_run_info()

  if lost then
    self.mod.client_manager:send_death()
  end

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

---@param entity_npc EntityNPC
---@param collider Entity
function LocationManager:on_fortune_telling_machine(entity_npc, collider)
  if collider.Type == EntityType.ENTITY_SLOT and collider.Variant == 3 then
    self.mod.dbg('Collision with ' .. collider.Type .. '_' .. collider.SubType .. '_' .. collider.Variant)
    local ref = EntityRef(collider)
    self.played_fortune_machines[collider.Index] = ref
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
  mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, function(_, entity_npc, collider) self:on_fortune_telling_machine(entity_npc, collider) end)
  mod:AddCallback(ModCallbacks.MC_USE_ITEM, function() self:on_crystal_ball_use() end, CollectibleType.COLLECTIBLE_CRYSTAL_BALL)
  mod:AddCallback(ModCallbacks.MC_USE_ITEM, function() self:on_fortune_cookie_use() end, CollectibleType.COLLECTIBLE_FORTUNE_COOKIE)
end

return LocationManager