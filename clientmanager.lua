---@class Command
---@field type string
---@field payload any

---@class SaveData
---@field session_id string
---@field timestamp integer
---@field actor string
---@field commands Command[]

---@class RunInfo
---@field is_active boolean
---@field received_items table<string, integer>
---@field to_be_distributed table<integer, table<string, integer>>
---@field unspawned_locations table<string, string[]>
---@field discarded_items table<string, integer>

---@class Slot
---@field name string
---@field game string

---@class APOptions
---@field bad_rng_protection boolean
---@field scatter_previous_items boolean
---@field additional_boss_rewards boolean
---@field retain_one_ups_percentage integer
---@field retain_items_percentage integer
---@field retain_junk_percentage integer
---@field item_location_percentage integer
---@field fortune_machine_hint_percentage integer
---@field crystal_ball_hint_percentage integer
---@field fortune_cookie_hint_percentage integer
---@field start_out_nerfed integer
---@field exclude_items_as_rewards string[]
---@field floor_variations boolean
---@field death_link_severity integer
---@field rng_rooms integer
---@field ultra_secret_room integer
---@field error_room integer
---@field crawl_space integer
---@field planetarium integer

---@class Hint
---@field receiving_player integer
---@field finding_player integer
---@field location integer
---@field item integer
---@field found boolean
---@field entrance string
---@field item_flags integer
---@field status integer

---@class NetworkItem
---@field item integer
---@field location integer
---@field player integer
---@field flags integer

---@param t table
---@return Command
local function Command(t)
  t.type = t.type or ""
  t.payload = t.payload or {}
  return t
end

---@param t table
---@return SaveData
local function SaveData(t)
  t.session_id = t.session_id or ""
  t.timestamp = t.timestamp or 0
  t.actor = t.actor or ""
  t.commands = t.commands or {}
  for i, cmd in ipairs(t.commands) do
    t.commands[i] = Command(cmd)
  end
  return t
end

local json = require('json')

---@class ClientManager
---@field state string
---@field session_id string
---@field mod ModReference
---@field commands_to_be_sent Command[]
---@field run_info RunInfo
---@field checked_locations integer[]
---@field missing_locations integer[]
---@field received_items NetworkItem[]
---@field available_items table<string, integer>
---@field goals table<string, boolean>
---@field item_names table<string, table<integer, string>>
---@field location_names table<string, string>
---@field location_ids table<string, string>
---@field slot_info table<integer, Slot>
---@field slot integer
---@field options APOptions
---@field scouted_locations table<integer, NetworkItem>
---@field hintable_locations integer[]
---@field forbidden_items integer[]
---@field block_death_link integer
local ClientManager = {
  state = "Disconnected",
  session_id = "",
  commands_to_be_sent = {},
  block_death_link = 0
}

function ClientManager:own_game()
  return self.slot_info[tostring(self.slot)].game
end

---@param slot integer
function ClientManager:get_game_name(slot)
  return self.slot_info[tostring(slot)].game
end

---@param slot integer
function ClientManager:get_player_name(slot)
  return self.slot_info[tostring(slot)].name
end

---@param code integer
---@param game string
function ClientManager:get_item_name(code, game)
  return self.item_names[game][tostring(code)]
end

---@param code integer
---@return string|nil
function ClientManager:get_location_name(code)
  return self.location_names[tostring(code)]
end

---@param name string
---@return integer|nil
function ClientManager:get_location_id(name)
  if self.location_ids and self.location_ids[name] then
    return tonumber(self.location_ids[name])
  end
  return nil
end

local function valueInList(value, list)
  for _, v in ipairs(list) do
    if v == value then
      return true
    end
  end
  return false
end

local function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, tonumber(n)) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[tostring(a[i])]
    end
  end
  return iter
end

function ClientManager:get_floor_locations(floor, chapter)
  local locations = {}
  for code, location in pairsByKeys(self.location_names) do
    if not valueInList(tonumber(code), self.checked_locations) and not valueInList(tonumber(code), self.missing_locations) then
      goto continue
    end
    if location:find('^' .. floor) then
      table.insert(locations, { name = location:sub(#floor + 4), completed = valueInList(tonumber(code), self.checked_locations)})
      self.mod.dbg("Location on floor " .. floor .. " - " .. location .. "[" .. code .. "]")
    end
    if location:find('^' .. chapter) then
      table.insert(locations, { name = location:sub(#chapter + 4), completed = valueInList(tonumber(code), self.checked_locations)})
      self.mod.dbg("Location on chapter " .. chapter .. " - " .. location .. "[" .. code .. "]")
    end
    ::continue::
  end
  return locations
end

---@param item NetworkItem
---@param notification boolean
function ClientManager:add_available_item(item, notification)
  local item_name = self:get_item_name(item.item, self:own_game())
  if not self.available_items[item_name] then
    self.available_items[item_name] = 1
  else
    self.available_items[item_name] = self.available_items[item_name] + 1
  end
  if notification then
    local sub = ''
    if item.player ~= self.slot then
      sub = 'from ' .. self:get_player_name(item.player)
    end
    if item_name:find('Unlock$') then
      self.mod.notification_manager:show_fortune(item_name .. 'ed', sub)
      if item_name == 'We Need To Go Deeper! Unlock' then
        self.mod.item_manager.give_queue:push(CollectibleType.COLLECTIBLE_WE_NEED_TO_GO_DEEPER)
        self.mod.location_manager:recalculate_location_icons()
      end
      if item_name == 'Undefined Unlock' then
        self.mod.item_manager.give_queue:push(CollectibleType.COLLECTIBLE_UNDEFINED)
        self.mod.location_manager:recalculate_location_icons()
      end
      if item_name == 'Telescope Lens Unlock' then
        self.mod.item_manager.consumable_queue:push(TrinketType.TRINKET_TELESCOPE_LENS)
        self.mod.location_manager:recalculate_location_icons()
      end
      if item_name == 'Red Key Unlock' then
        self.mod.item_manager.give_queue:push(CollectibleType.COLLECTIBLE_RED_KEY)
        self.mod.location_manager:recalculate_location_icons()
      end
      self.mod.progression_manager:check_special_exits()
    else
      self.mod.notification_manager:show_message(item_name, sub)
    end
    if item_name:find('Trap$') then
      self.mod.item_manager.trap_queue:push(item_name)
    end
  end
end

local forbidden_items_dict = {
  ["A Pound of Flesh"] = CollectibleType.COLLECTIBLE_POUND_OF_FLESH,
  ["Blood Oath"] = CollectibleType.COLLECTIBLE_BLOOD_OATH,
  ["Blood Puppy"] = CollectibleType.COLLECTIBLE_BLOOD_PUPPY,
  ["Cursed Eye"] = CollectibleType.COLLECTIBLE_CURSED_EYE,
  ["Curse of the Tower"] = CollectibleType.COLLECTIBLE_CURSE_OF_THE_TOWER,
  ["Isaac's Heart"] = CollectibleType.COLLECTIBLE_ISAACS_HEART,
  ["Kidney Stone"] = CollectibleType.COLLECTIBLE_KIDNEY_STONE,
  ["Missing No"] = CollectibleType.COLLECTIBLE_MISSING_NO,
  ["Shard of Glass"] = CollectibleType.COLLECTIBLE_SHARD_OF_GLASS,
  ["TMTrainer"] = CollectibleType.COLLECTIBLE_TMTRAINER,
  ["Bob's Brain"] = CollectibleType.COLLECTIBLE_BOBS_BRAIN,
  ["Dr. Fetus"] = CollectibleType.COLLECTIBLE_DR_FETUS,
  ["Epic Fetus"] = CollectibleType.COLLECTIBLE_EPIC_FETUS,
  ["Fire Mind"] = CollectibleType.COLLECTIBLE_FIRE_MIND
}

---@param cmd Command
function ClientManager:process_mod_command(cmd)
  self.mod.dbg('Command type: ' .. cmd.type)
  if cmd.type == "AllData" then
    self.mod.dbg("AllData")
    self.session_id = cmd.payload["session_id"]
    self.run_info = cmd.payload["run_info"]
    self.goals = cmd.payload["goals"]
    self.checked_locations = cmd.payload["checked_locations"]
    self.missing_locations = cmd.payload["missing_locations"]
    self.received_items = cmd.payload["received_items"]
    self.item_names = cmd.payload["item_names"]
    self.location_names = cmd.payload["location_names"]
    self.slot_info = cmd.payload["slot_info"]
    self.slot = cmd.payload["slot"]
    self.options = cmd.payload["options"]
    self.scouted_locations = cmd.payload["scouted_locations"]
    self.hintable_locations = cmd.payload["hintable_locations"]
    self.forbidden_items = {}
    for _, item in ipairs(self.options.exclude_items_as_rewards) do
      table.insert(self.forbidden_items, forbidden_items_dict[item])
    end
    for _, item in ipairs(self.forbidden_items) do
      self.mod.dbg(item)
    end
    self.available_items = {}
    for _, item in ipairs(self.received_items) do
      self:add_available_item(item, false)
    end
    if self.mod.progression_manager.init_on_connect then
      self.mod.progression_manager:init_new_run()
    end
    self.location_ids = {}
    for id, name in pairs(self.location_names) do
      self.location_ids[name] = id
    end
    self.mod.item_manager:give_items()

    self.mod.location_manager:recalculate_location_icons()
  end
  if cmd.type == "ReceiveItems" then
    local items = cmd.payload
    for _, item in ipairs(items) do
      self:add_available_item(item, true)

      local r = 0
      local g = 0.8
      local b = 0.8
      if (item.flags & 0x1) ~= 0 then
        r = 0.5
        g = 0.5
        b = 1
      elseif (item.flags & 0x2) ~= 0 then
        r = 0.25
        g = 0.5
        b = 0.75
      elseif (item.flags & 0x4) ~= 0 then
        r = 0.75
        g = 0.5
        b = 0.25
      end
      if item.player == self.slot then
        self.mod.notification_manager:add_log({{'You found your ', 1, 1, 1}, {self:get_item_name(item.item, self:own_game()), r, g, b}, {' (', 1, 1, 1}, {self:get_location_name(item.location), 0, 0.9, 0.25}, {')', 1, 1, 1}})
      else
        self.mod.notification_manager:add_log({{self:get_player_name(item.player), 1, 1, 0.75}, {' sent ', 1, 1, 1}, {self:get_item_name(item.item, self:own_game()), r, g, b}, {' to you.', 1, 1, 1}})
      end
    end
    self.mod.item_manager:give_items()
  end
  if cmd.type == "HintableLocations" then
    self.hintable_locations = cmd.payload
  end
  if cmd.type == "Kill" then
    if self.options.death_link_severity == 0 and not Isaac.GetPlayer():IsInvincible() then
      Isaac.GetPlayer():TakeDamage(4, DamageFlag.DAMAGE_TIMER, EntityRef(Isaac.GetPlayer()), 0)
    elseif self.options.death_link_severity == 1 and not Isaac.GetPlayer():IsInvincible() then
      Isaac.GetPlayer():Kill()
    else
      Game():End(1)
    end
    self.block_death_link = Game().TimeCounter + 90
  end
end

---@param item string
---@return boolean
function ClientManager:has_unlock(item)
  return self.available_items and self.available_items[item .. ' Unlock'] and self.available_items[item .. ' Unlock'] > 0
end


local function removeValueFromList(value, list)
  for i=#list,1,-1 do
    if list[i] == value then
      table.remove(list, i)
    end
  end
end

function ClientManager:get_item_location(stage)
  local search = tostring(stage .. ' - Item #')
  for _, location in ipairs(self.missing_locations) do
    local location_name = self:get_location_name(location)
    if location_name and location_name:sub(1, #search) == search then
      return location_name
    end
  end
  return nil
end

function ClientManager:is_missing(id)
  if id then
    return valueInList(id, self.missing_locations)
  end
  return false
end

---@param names string[]
function ClientManager:unlock_locations(names)
  local loc_ids = {}
  for _, name in ipairs(names) do
    local id = self:get_location_id(name)
    if self:is_missing(id) then
      removeValueFromList(id, self.missing_locations)
      table.insert(self.checked_locations, id)
      table.insert(loc_ids, id)
      local item = self.scouted_locations[tostring(id)]
      if item.player ~= self.slot then
        local item_name = self:get_item_name(item.item, self:get_game_name(item.player))
        self.mod.notification_manager:show_message('Sent ' .. item_name, 'To ' .. self:get_player_name(item.player))
        SFXManager():Play(SoundEffect.SOUND_THUMBSUP)

        local r = 0
        local g = 0.8
        local b = 0.8
        if (item.flags & 0x1) ~= 0 then
          r = 0.5
          g = 0.5
          b = 1
        elseif (item.flags & 0x2) ~= 0 then
          r = 0.25
          g = 0.5
          b = 0.75
        elseif (item.flags & 0x4) ~= 0 then
          r = 0.75
          g = 0.5
          b = 0.25
        end
        self.mod.notification_manager:add_log({{'You sent ', 1, 1, 1}, {item_name, r, g, b}, {' to ', 1, 1, 1},{self:get_player_name(item.player), 1, 1, 0.75}, {' (', 1, 1, 1}, {self:get_location_name(item.location), 0, 0.9, 0.25}, {')', 1, 1, 1}})

      end
      self.mod.location_manager:recalculate_location_icons()
    end
  end
  if #loc_ids > 0 then
    self.mod.dbg("Send Locations")
    table.insert(self.commands_to_be_sent, {
      type = "SendLocations",
      payload = loc_ids
    })
  end
end

---@param item string
function ClientManager:count_received_item(item)
  if not self.run_info.received_items then return 0 end
  if not self.run_info.received_items[item] then return 0 end
  return self.run_info.received_items[item]
end

---@param item string
---@param amount integer
function ClientManager:add_received_item(item, amount)
  self.mod.dbg("Add received item: " .. item)
  if not self.run_info.received_items then self.run_info.received_items = {} end
  if not self.run_info.received_items[item] then self.run_info.received_items[item] = 0 end
  self.run_info.received_items[item] = self.run_info.received_items[item] + amount
end

---@param item string
---@param amount integer
function ClientManager:add_discarded_item(item, amount)
  if not self.run_info.discarded_items then self.run_info.discarded_items = {} end
  if not self.run_info.discarded_items[item] then self.run_info.discarded_items[item] = 0 end
  self.run_info.discarded_items[item] = self.run_info.discarded_items[item] + amount
end

---@param floor integer
---@param item string
---@param amount integer
function ClientManager:add_to_be_distributed(floor, item, amount)
  if not self.run_info.to_be_distributed then self.run_info.to_be_distributed = {} end
  if not self.run_info.to_be_distributed[floor] then self.run_info.to_be_distributed[floor] = {} end
  if not self.run_info.to_be_distributed[floor][item] then self.run_info.to_be_distributed[floor][item] = 0 end
  self.run_info.to_be_distributed[floor][item] = self.run_info.to_be_distributed[floor][item] + amount
end

function ClientManager:connection_request()
  self.mod.dbg("Connection request")
  local init_save_data = SaveData({
    actor = "mod",
    timestamp = Isaac.GetTime(),
    commands = { Command({type = "RequestAll"}) },
    session_id = self.session_id
  })
  self.mod:SaveData(json.encode(init_save_data))
  self.state = "Connecting"
end

function ClientManager:poll()
    --if Game():IsPaused() then return end

    local success, js = pcall(function() return json.decode(self.mod:LoadData()) end)
    if not success then self.mod.dbg(tostring(js)) return end

    local save_data = SaveData(js)

    if self.session_id == "" and self.state ~= "Connecting" then
      self.mod.dbg("No session_id")
      self:connection_request()
      return
    end
    if self.session_id ~= save_data.session_id and save_data.session_id ~= "" then
      self.mod.dbg("Session_id missmatch")
      self.mod.dbg(tostring(save_data.session_id) .. " ~= " .. tostring(self.session_id))
      self.session_id = save_data.session_id
      self:connection_request()
      return
    end
    if save_data.actor == "mod" and Isaac.GetTime() - save_data.timestamp > 3000 then self.state = "Disconnected" return end
    if save_data.actor ~= "client" then return end

    self.state = "Connected"
    for _, cmd in ipairs(save_data.commands) do
      self:process_mod_command(cmd)
    end

    self:send_commands()
end

function ClientManager:send_commands()
  local new_save_data = SaveData({
    session_id=self.session_id,
    timestamp=Isaac.GetTime(),
    actor="mod",
    commands=self.commands_to_be_sent
  })
  self.commands_to_be_sent = {}
  self.mod:SaveData(json.encode(new_save_data))
end

function ClientManager:on_post_render()
  if self.state == "Connected" then
    Isaac.RenderScaledText('Connected', 2, 2, 0.5, 0.5, 0, 1, 0, 1)
  elseif self.state == "Connecting" then
    Isaac.RenderScaledText('Connecting', 2, 2, 0.5, 0.5, 1, 1, 0, 1)
  else
    Isaac.RenderScaledText('Disconnected', 2, 2, 0.5, 0.5, 1, 0, 0, 1)
  end

  if Isaac.GetFrameCount() % 12 == 0 and self.mod:HasData() then
    self:poll()
  elseif Isaac.GetFrameCount() % 12 == 0 and not self.mod:HasData() then
    self.mod.dbg("No data found")
    self:connection_request()
  end
end

function ClientManager:send_death()
  if Game().TimeCounter < self.block_death_link then return end
  self.mod.dbg("Send death")
  table.insert(self.commands_to_be_sent, {
    type = "Died",
    payload = nil
  })
end

function ClientManager:update_run_info()
  self.mod.dbg("Set run_info")
  table.insert(self.commands_to_be_sent, {
    type = "Set",
    payload = {
      key = "run_info",
      data = self.run_info
    }
  })
end

function ClientManager:send_goal(boss)
  self.mod.dbg("Send goal")
  if self.goals[boss] ~= nil then
    self.goals[boss] = true
    self.mod.dbg("Set goals")
    table.insert(self.commands_to_be_sent, {
      type = "Set",
      payload = {
        key = "goals",
        data = self.goals
      }
    })
  end
end

function ClientManager:send_hint()
  self.mod.dbg("Send random hint")
  if #self.hintable_locations == 0 then return end
  local idx = math.random(#self.hintable_locations)
  local loc = self.hintable_locations[idx]
  self.mod.dbg(idx .. '/' .. #self.hintable_locations .. ': Location ' .. loc)
  local item = self.scouted_locations[tostring(loc)]
  self.mod.notification_manager.queue_timer = 2
  self.mod.notification_manager:show_fortune(self:get_player_name(item.player) .. "'s " .. self:get_item_name(item.item, self:get_game_name(item.player)), self:get_location_name(item.location))
  table.insert(self.commands_to_be_sent, {
      type = "HintLocations",
      payload = { loc }
    })

  local r = 0
  local g = 0.8
  local b = 0.8
  if (item.flags & 0x1) ~= 0 then
    r = 0.5
    g = 0.5
    b = 1
  elseif (item.flags & 0x2) ~= 0 then
    r = 0.25
    g = 0.5
    b = 0.75
  elseif (item.flags & 0x4) ~= 0 then
    r = 0.75
    g = 0.5
    b = 0.25
  end
  if item.player == self.slot then
    self.mod.notification_manager:add_log({{'Your ', 1, 1, 1}, {self:get_item_name(item.item, self:get_game_name(item.player)), r, g, b}, {' is at ', 1, 1, 1}, {self:get_location_name(item.location), 0, 0.9, 0.25}, {'.', 1, 1, 1}})
  else
    self.mod.notification_manager:add_log({{self:get_player_name(item.player), 1, 1, 0.75}, {'\'s ', 1, 1, 1}, {self:get_item_name(item.item, self:get_game_name(item.player)), r, g, b}, {' is at ', 1, 1, 1}, {self:get_location_name(item.location), 0, 0.9, 0.25}, {'.', 1, 1, 1}})
  end

end

---@param mod ModReference
function ClientManager:Init(mod)
  self.mod = mod

  mod:AddCallback(ModCallbacks.MC_POST_RENDER, function() self:on_post_render() end)
end

return ClientManager