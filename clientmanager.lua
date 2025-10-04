---@class Command
---@field type string
---@field payload any

---@class SaveData
---@field seed string
---@field timestamp string
---@field actor string
---@field commands Command[]

---@param t table
---@return Command
local function Command(t)
  -- You can add defaults if you want:
  t.type = t.type or ""
  -- t.payload can be anything
  return t
end

---@param t table
---@return SaveData
local function SaveData(t)
  t.seed = t.seed or ""
  t.timestamp = t.timestamp or ""
  t.actor = t.actor or ""
  t.commands = t.commands or {}
  for i, cmd in ipairs(t.commands) do
    t.commands[i] = Command(cmd)
  end
  return t
end

local json = require('json')

---@class ClientManager
local ClientManager = {
  state = "Disconnected",
  seed_name = "",
  commands_to_be_sent = {},
  mod = nil
}

---@param cmd Command
function ClientManager:process_mod_command(cmd)
end

---@param mod ModReference
function ClientManager.Init(mod)
  ClientManager.mod = mod

  local init_save_data = SaveData({
    actor = "mod",
    timestamp = string(os.date("!%Y-%m-%d %H:%M:%S")),
    commands = { Command({type = "RequestAll"}) }
  })

  mod:SaveData(json.encode(init_save_data))

  mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    if ClientManager.state == "Connected" then
        Isaac.RenderScaledText('Connected', 2, 2, 0.5, 0.5, 0, 1, 0, 255)
    else
        Isaac.RenderScaledText('Disconnected', 2, 2, 0.5, 0.5, 1, 0, 0, 255)
    end

    if Isaac.GetFrameCount() % 6 == 0 and mod:HasData() then
      local save_data = SaveData(json.decode(mod:LoadData()))

      if save_data.actor ~= "client" then return end
      if save_data.seed ~= "" and save_data.seed ~= ClientManager.seed_name then return end

      ClientManager.state = "Connected"

      for _, cmd in ipairs(save_data.commands) do
          ClientManager:process_mod_command(cmd)
      end

      local new_save_data = SaveData({
          seed=ClientManager.seed_name,
          timestamp=string(os.date("!%Y-%m-%d %H:%M:%S")),
          actor="mod",
          commands=ClientManager.commands_to_be_sent
      })
      ClientManager.commands_to_be_sent = {}

      mod:SaveData(json.encode(new_save_data))
    end
  end)

end

return ClientManager