local queue = require("utils.queue")

---@class NotificationManager
---@field mod ModReference
---@field message_queue Queue
---@field logs Queue
---@field show_logs boolean
local NotificationManager = {
  message_queue = queue.new(),
  queue_timer = 0,
  logs = queue.new(),
  show_logs = true
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
      self.queue_timer = 30 - self.message_queue.size
    elseif message and message.type == 1 then
      Game():GetHUD():ShowFortuneText(message.line1, message.line2)
      SFXManager():Play(SoundEffect.SOUND_GOLDENKEY)
      self.queue_timer = 30 - self.message_queue.size
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

function NotificationManager:add_log(log)
  self.logs:push(log)
  if self.logs.size > 38 then
    self.logs:pop()
  end
end

function NotificationManager:on_post_render()
  if Input.IsButtonTriggered(Keyboard.KEY_F2, 0) then
    self.show_logs = not self.show_logs
  end

  if self.show_logs then
    for i, log in self.logs:ipairs() do
      if i > 5 and not Input.IsActionPressed(ButtonAction.ACTION_MAP, 0) then break end
      local alpha = 0.75
      if i == 5 then
        alpha = 0.5
      end
      if Input.IsActionPressed(ButtonAction.ACTION_MAP, 0) then
        alpha = 1
      end
      local x = 80
      for _, segment in ipairs(log) do
        Isaac.RenderScaledText(segment[1], x, 270 - i * 7, 0.5, 0.5, segment[2], segment[3], segment[4], alpha)
        x = x + Isaac.GetTextWidth(segment[1]) * 0.5
      end
    end

    if self.logs.size > 0 then
      Isaac.RenderScaledText('(F2 to hide AP history)', 3, 263, 0.5, 0.5, 1, 1, 1, 0.25)
    end
  else
    if self.logs.size > 0 then
      Isaac.RenderScaledText('(F2 to show AP history)', 3, 263, 0.5, 0.5, 1, 1, 1, 0.25)
    end
  end
end


---@param mod ModReference
function NotificationManager:Init(mod)
  self.mod = mod

  mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function() self:on_post_update() end)
  mod:AddCallback(ModCallbacks.MC_POST_RENDER, function() self:on_post_render() end)
end

return NotificationManager