---@class Queue
local queue = {}
queue.__index = queue

function queue.new()
  return setmetatable({ first = 1, last = 0, data = {}, size = 0 }, queue)
end

function queue:push(value)
  self.last = self.last + 1
  self.data[self.last] = value
  self.size = self.size + 1
end

function queue:pop()
  if self.first > self.last then return nil end
  local value = self.data[self.first]
  self.data[self.first] = nil
  self.first = self.first + 1
  self.size = self.size - 1
  return value
end

function queue:clear()
  self.data = {}
  self.first = 1
  self.last = 0
  self.size = 0
end

return {
  new = queue.new
}