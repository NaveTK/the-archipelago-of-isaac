-- Stack Implementation
function Stack()
   return setmetatable({
      -- stack table  
      _stack = {},
      -- size of stack
      count = 0,

      -- push an element to the stack underlying array
      push = function(self, obj)
         -- increment the index
         self.count = self.count + 1
         -- set the element at the end of the array
         rawset(self._stack, self.count, obj)
      end,

      -- pop an element from the stack
      pop = function(self)
         -- decrement the index    
         self.count = self.count - 1
         -- remove and return the last element
         return table.remove(self._stack)
      end,
   }, {
      __index = function(self, index)
      return rawget(self._stack, index)
   end,
})
end
