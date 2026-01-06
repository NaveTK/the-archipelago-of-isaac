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