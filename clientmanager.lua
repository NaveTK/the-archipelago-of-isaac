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
--@field win_collects_missed_locations integer
--@field item_location_step integer
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
---@field location_names table<integer, string>
---@field slot_info table<integer, Slot>
---@field slot integer
---@field options APOptions
---@field scouted_locations table<integer, NetworkItem>
---@field hints Hint[]
local ClientManager = {
  state = "Disconnected",
  session_id = ""
}

function ClientManager:own_game()
  return self.slot_info[self.slot].game
end

---@param slot integer
function ClientManager:get_game_name(slot)
  return self.slot_info[slot].game
end

---@param code integer
---@param game string
function ClientManager:get_item_name(code, game)
  return self.item_names[game][code]
end

---@param code integer
function ClientManager:get_location_name(code)
  return self.location_names[code]
end

---@param cmd Command
function ClientManager:process_mod_command(cmd)
  self.mod.dbg(cmd.type)
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
      local itemName = self:get_item_name(item.item, self:own_game())
      if not self.available_items[itemName] then
        self.available_items[itemName] = 1
      else
        self.available_items[itemName] = self.available_items[itemName] + 1
      end
    end
  end
end

---@param item string
---@param amount integer
function ClientManager:add_received_item(item, amount)
  if not self.run_info.received_items then self.run_info.received_items = {} end
  if not self.run_info.received_items[item] then self.run_info.received_items[item] = 0 end
  self.run_info.received_items[item] = self.run_info.received_items[item] + amount
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
    local save_data = SaveData(json.decode(self.mod:LoadData()))

    if save_data.session_id ~= self.session_id then self:connection_request() return end
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

  mod:AddCallback(ModCallbacks.MC_POST_RENDER, self.on_post_render)

end

return ClientManager