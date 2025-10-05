---@class Queue
local queue = {}
queue.__index = queue

function queue.new()
  return setmetatable({ first = 1, last = 0, data = {} }, queue)
end

function queue:push(value)
  self.last = self.last + 1
  self.data[self.last] = value
end

function queue:pop()
  if self.first > self.last then return nil end
  local value = self.data[self.first]
  self.data[self.first] = nil
  self.first = self.first + 1
  return value
end

function queue:clear()
  self.data = {}
  self.first = 1
  self.last = 0
end

return {
  new = queue.new
}