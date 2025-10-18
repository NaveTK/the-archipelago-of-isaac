local queue = require("utils.queue")

---@class NotificationManager
---@field mod ModReference
---@field message_queue Queue
local NotificationManager = {
  message_queue = queue.new(),
  queue_timer = 0
}

function NotificationManager:on_post_update()
  if self.queue_timer > 0 then
    self.queue_timer = self.queue_timer - 1
    return
  end
  if self.message_queue.size > 0 then    
    local message = self.message_queue:pop()
    if message and message.type == 0 then
      Game():GetHUD():ShowItemText(message.title, message.text, false, true)
      if message.title:find('Trap$') then
        SFXManager():Play(SoundEffect.SOUND_HEARTBEAT)
      elseif message.title:find('^Random') then
        SFXManager():Play(SoundEffect.SOUND_PORTAL_SPAWN)
      end
      self.queue_timer = 30
    elseif message and message.type == 1 then
      Game():GetHUD():ShowFortuneText(message.line1, message.line2)
      SFXManager():Play(SoundEffect.SOUND_GOLDENKEY)
      self.queue_timer = 30
    end
  end
end

function NotificationManager:show_message(title, text)
  self.mod.dbg('Show Message: ' .. title .. ' - ' .. text)
  self.message_queue:push({type=0, title=title, text=text})
end
function NotificationManager:show_fortune(line1, line2)
  self.mod.dbg('Show Fortune: ' .. line1 .. ' - ' .. line2)
  self.message_queue:push({type=1, line1=line1, line2=line2})
end

---@param mod ModReference
function NotificationManager:Init(mod)
  self.mod = mod

  mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function() self:on_post_update() end)
end

return NotificationManager