local queue = require("utils.queue")

---@class ItemManager
---@field mod ModReference
---@field give_queue Queue
---@field consumable_queue Queue
---@field trap_queue Queue
---@field lock_item boolean
local ItemManager = {
  give_queue = queue.new(),
  consumable_queue = queue.new(),
  trap_queue = queue.new()
}
local rng = RNG()

function ItemManager:init_new_run()
  self.give_queue:clear()
  self.consumable_queue:clear()
  self.trap_queue:clear()
      
  local options = self.mod.client_manager.options
  local available_items = self.mod.client_manager.available_items
  
  if options.scatter_previous_items == 1 then
    self.mod.dbg('Scatter items.')
    self.mod.dbg('Amount of available item categories: ' .. #available_items)
    for item, amount in pairs(available_items) do
      self.mod.dbg('Consider Item: ' .. item .. ' x' .. amount)
      if not item:find('^Unlock') and item ~= 'Victory Condition' and not item:find('Trap') then
      for _=1,amount do
        local remove = false
        if item:find('^Random') and options['retain_junk_percentage'] and rng:RandomInt(100) > math.tointeger(options['retain_junk_percentage']) then
          remove = true
        end
        if item:find('Item') and options['retain_items_percentage'] and rng:RandomInt(100) > math.tointeger(options['retain_items_percentage']) then
          remove = true
        end
        if item == '1-UP' and options['retain_one_ups_percentage'] and rng:RandomInt(100) > math.tointeger(options['retain_one_ups_percentage']) then
          remove = true
        end
        rng:Next()
        
        if remove then
          self.mod.client_manager:add_received_item(item, 1)
        else
          local floor = rng:RandomInt(6) + 1
          if item == '1-UP' then floor = 1 end
            self.mod.client_manager:add_to_be_distributed(floor, item, 1)
            self.mod.dbg('Added to floor ' .. floor)
          end
        end
      end
    end
  else
    for item, amount in pairs(available_items) do
      if not item:find('^Unlock') and item ~= 'Victory Condition' and not item:find('Trap') then
        local reduce = 0
        for _=1,amount do
          if item:find('^Random') and rng:RandomInt(100) > math.tointeger(options.retain_junk_percentage) then
            reduce = reduce + 1
          end
          if item:find('Item') and rng:RandomInt(100) > math.tointeger(options.retain_items_percentage) then
            reduce = reduce + 1
          end
          if item == '1-UP' and rng:RandomInt(100) > math.tointeger(options.retain_one_ups_percentage) then
            reduce = reduce + 1
          end
          rng:Next()
        end
        self.mod.dbg('Loose item ' .. item .. ' x' .. reduce)
        self.mod.client_manager:add_received_item(item, reduce)
      end
    end
  end
end

function ItemManager:distribute_items()
  self.mod.dbg('Empty distribution for floor ' .. tostring(Game():GetLevel():GetStage()))
  for i, _ in pairs(self.mod.client_manager.run_info.to_be_distributed) do
    if Game():GetLevel():GetStage() >= i then
      self.mod.client_manager.run_info.to_be_distributed = {}
    end
  end
  self:give_items()
end

function ItemManager:give_item(itemType)
  self.mod.dbg('Giving item of type: ' .. itemType)
  if itemType == 'Angel Deal Item' then
    self:queue_item_from_pool(ItemPoolType.POOL_ANGEL)
  elseif itemType == 'Boss Item' then
    self:queue_item_from_pool(ItemPoolType.POOL_BOSS)    
  elseif itemType == 'Curse Room Item' then
    self:queue_item_from_pool(ItemPoolType.POOL_CURSE)    
  elseif itemType == 'Devil Deal Item' then
    self:queue_item_from_pool(ItemPoolType.POOL_DEVIL)    
  elseif itemType == 'Golden Chest Item' then
    self:queue_item_from_pool(ItemPoolType.POOL_GOLDEN_CHEST)    
  elseif itemType == 'Library Item' then
    self:queue_item_from_pool(ItemPoolType.POOL_LIBRARY)    
  elseif itemType == 'Planetarium Item' then
    self:queue_item_from_pool(ItemPoolType.POOL_PLANETARIUM)    
  elseif itemType == 'Red Chest Item' then
    self:queue_item_from_pool(ItemPoolType.POOL_RED_CHEST)    
  elseif itemType == 'Secret Room Item' then
    self:queue_item_from_pool(ItemPoolType.POOL_SECRET)    
  elseif itemType == 'Shop Item' then
    self:queue_item_from_pool(ItemPoolType.POOL_SHOP)    
  elseif itemType == 'Treasure Room Item' then
    self:queue_item_from_pool(ItemPoolType.POOL_TREASURE)
  elseif itemType == '1-UP' then
    self.give_queue:push(CollectibleType.COLLECTIBLE_1UP)
  elseif itemType:find('^Random') then
    if itemType:find('Heart') then
      self.consumable_queue:push(PickupVariant.PICKUP_HEART)
    elseif itemType:find('Bomb') then
      self.consumable_queue:push(PickupVariant.PICKUP_BOMB)
    elseif itemType:find('Key') then
      self.consumable_queue:push(PickupVariant.PICKUP_KEY)
    elseif itemType:find('Coin') then
      self.consumable_queue:push(PickupVariant.PICKUP_COIN)
    elseif itemType:find('Card') then
      self.consumable_queue:push(PickupVariant.PICKUP_TAROTCARD)
    elseif itemType:find('Pill') then
      self.consumable_queue:push(PickupVariant.PICKUP_PILL)
    elseif itemType:find('Trinket') then
      self.consumable_queue:push(PickupVariant.PICKUP_TRINKET)
    elseif itemType:find('Chest') then
      self.consumable_queue:push(PickupVariant.PICKUP_CHEST)
    end
  else
    self.mod.dbg('Unknown item type: ' .. itemType)
  end
  self.mod.client_manager:add_received_item(itemType, 1)
end

function ItemManager:give_items()
  local items_to_give = self:get_items_to_give()
  for item_type, amount in pairs(items_to_give) do
    for _ = 1, amount do
      self:give_item(item_type)
    end
  end
  self.mod.client_manager:update_run_info()
end


function ItemManager:get_items_to_give()
  local items_to_give = {}
  self.mod.dbg('Calculating items to give')
  self.mod.dbg('Available items:')
  local available_items = self.mod.client_manager.available_items
  if not available_items then
    return items_to_give
  end
  for item, amount in pairs(available_items) do
    self.mod.dbg(item .. ': ' .. amount)
  end
  for item, amount in pairs(available_items) do
    if not item:find('^Unlock') and item ~= 'Victory Condition' and not item:find('Trap') then
      local not_available = 0
      local run_info = self.mod.client_manager.run_info
      if run_info.received_items and run_info.received_items[item] then
        not_available = not_available + run_info.received_items[item]
      end
      if run_info.to_be_distributed then
        self.mod.dbg('Checking to be distributed')
        for i, items_on_floor in pairs(run_info.to_be_distributed) do
          self.mod.dbg('Checking floor ' .. i)
          if items_on_floor[item] then
            self.mod.dbg('Has ' .. item .. ' x' .. items_on_floor[item])
            not_available = not_available + items_on_floor[item]
          end
        end
      end
      
      if not_available < amount then
        items_to_give[item] = amount - not_available
      end
    end
  end
  return items_to_give
end

function ItemManager:queue_item_from_pool(poolType)
  local pool  = Game():GetItemPool()
  self.mod.dbg('LOCK ITEM SET TO TRUE!')
  self.lock_item = true
  local itemId = pool:GetCollectible(poolType, true, rng:Next())
  self.give_queue:push(itemId)
end

---@param mod ModReference
function ItemManager:Init(mod)
  self.mod = mod

end

return ItemManager