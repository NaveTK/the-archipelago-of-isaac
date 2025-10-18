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
---@field deathlink integer
---@field scatter_previous_items integer
---@field fortunes_are_hints integer
---@field additional_boss_rewards integer
---@field retain_one_ups_percentage integer
---@field retain_items_percentage integer
---@field retain_junk_percentage integer
---@field item_location_percentage integer
--@field win_collects_missed_locations integer
--@field additional_item_locations integer

---@class Hint
---@field receiving_player integer
---@field finding_player integer
---@field location integer
---@field item integer
---@field found boolean
---@field entrance string
---@field item_flags integer
---@field status integer

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
---@field item_names table<string, table<integer, string>>
---@field location_names table<string, string>
---@field location_ids table<string, string>
---@field slot_info table<integer, Slot>
---@field slot integer
---@field options APOptions
---@field scouted_locations table<integer, NetworkItem>
---@field hints Hint[]
local ClientManager = {
  state = "Disconnected",
  session_id = "",
  commands_to_be_sent = {}
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
  self.mod.dbg('Code ' .. tostring(code))
  self.mod.dbg('Game ' .. game)
  self.mod.dbg('self.item_names[game][tostring(code)] ' .. tostring(self.item_names[game][tostring(code)]))
  self.mod.dbg('self.item_names[game][tonumber(code)] ' .. tostring(self.item_names[game][tonumber(code)]))
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
  if self.location_ids[name] then
    return tonumber(self.location_ids[name])
  end
  return nil
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
    else
      self.mod.notification_manager:show_message(item_name, sub)
    end
    if item_name:find('Trap$') then
      self.mod.item_manager.trap_queue:push(item_name)
    end
  end
end

---@param cmd Command
function ClientManager:process_mod_command(cmd)
  self.mod.dbg('Command type: ' .. cmd.type)
  if cmd.type == "AllData" then
    self.session_id = cmd.payload["session_id"]
    self.run_info = cmd.payload["run_info"]
    self.checked_locations = cmd.payload["checked_locations"]
    self.missing_locations = cmd.payload["missing_locations"]
    self.received_items = cmd.payload["received_items"]
    self.item_names = cmd.payload["item_names"]
    self.location_names = cmd.payload["location_names"]
    self.slot_info = cmd.payload["slot_info"]
    self.slot = cmd.payload["slot"]
    self.options = cmd.payload["options"]
    self.scouted_locations = cmd.payload["scouted_locations"]
    self.hints = cmd.payload["hints"]
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
  end
  if cmd.type == "ReceiveItems" then
    local items = cmd.payload
    for _, item in ipairs(items) do
      self:add_available_item(item, true)
    end
    self.mod.item_manager:give_items()
  end
end

---@param item string
---@return boolean
function ClientManager:has_unlock(item)
  return self.available_items and self.available_items[item .. ' Unlock'] and self.available_items[item .. ' Unlock'] > 0
end

local function valueInList(value, list)
  for _, v in ipairs(list) do
    if v == value then
      return true
    end
  end
  return false
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

---@param names string[]
function ClientManager:unlock_locations(names)
  local loc_ids = {}
  for _, name in ipairs(names) do
    local id = self:get_location_id(name)
    if id then
      if valueInList(id, self.missing_locations) then
        removeValueFromList(id, self.missing_locations)
        table.insert(self.checked_locations, id)
        table.insert(loc_ids, id)
        local item = self.scouted_locations[tostring(id)]
        if item.player ~= self.slot then
          local item_name = self:get_item_name(item.item, self:get_game_name(item.player))
          self.mod.notification_manager:show_message('Sent ' .. item_name, 'To ' .. self:get_player_name(item.player))
        end
      end
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
---@param amount integer
function ClientManager:add_received_item(item, amount)
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
  local init_save_data = SaveData({
    actor = "mod",
    timestamp = Isaac.GetTime(),
    commands = { Command({type = "RequestAll"}) }
  })

  self.mod:SaveData(json.encode(init_save_data))
end

function ClientManager:poll()
    if Game():IsPaused() then return end
    local save_data = SaveData(json.decode(self.mod:LoadData()))

    if save_data.session_id ~= self.session_id then
      self:connection_request()
      self.session_id = save_data.session_id
      return
    end
    if save_data.actor == "mod" and Isaac.GetTime() - save_data.timestamp > 3000 then self.state = "Disconnected" return end
    if save_data.actor ~= "client" then return end
    if self.session_id ~= "" and save_data.session_id ~= self.session_id then return end

    self.state = "Connected"

    for _, cmd in ipairs(save_data.commands) do
      self:process_mod_command(cmd)
    end

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
    Isaac.RenderScaledText('Connected', 2, 2, 0.5, 0.5, 0, 1, 0, 255)
  else
    Isaac.RenderScaledText('Disconnected', 2, 2, 0.5, 0.5, 1, 0, 0, 255)
  end

  if Isaac.GetFrameCount() % 6 == 0 and self.mod:HasData() then
    self:poll()
  end
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

---@param mod ModReference
function ClientManager:Init(mod)
  self.mod = mod

  mod:AddCallback(ModCallbacks.MC_POST_RENDER, function() self:on_post_render() end)

end

return ClientManager