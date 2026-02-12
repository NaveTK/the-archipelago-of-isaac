-- https://discord.com/channels/962027940131008653/962045574964715530/1470477894714134792
local PLAYER_VARIANT = 0
-- This is the ShiftIdx that Blade recommended after having reviewing the game's internal functions.
-- Any value between 0 and 80 (inclusive) should work equally well.
-- https://www.jstatsoft.org/article/view/v008i14/xorshift.pdf
local RECOMMENDED_SHIFT_IDX = 35

---@class PlayerUtils
---@field mod ModReference
local PlayerUtils = {
}
PlayerUtils.rng = RNG()

---@return EntityPlayer
function PlayerUtils:GetRandomPlayer()
  local players = self:GetAllActivePlayers()
  local numPlayers = #players
  if numPlayers <= 0 then
    return Isaac.GetPlayer()
  end
  return players[1 + self.rng:RandomInt(numPlayers)]
end

---@return EntityPlayer[]
function PlayerUtils:GetAllActivePlayers()
  local players = {}
  local numPlayers = Game():GetNumPlayers()
  for iPlayer = 0, numPlayers-1 do
    local player = Isaac.GetPlayer(iPlayer)
    -- Checking if Player Variant is PlayerVariant.PLAYER
    if player.Variant == PLAYER_VARIANT and not player:IsCoopGhost() then
      table.insert(players, player)
    end
  end
  return players
end

---@param mod ModReference
function PlayerUtils:Init(mod)
  mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, _) self:on_run_start() end)
end

function PlayerUtils:on_run_start()
  self.rng:SetSeed(Game():GetSeeds():GetStartSeed(), RECOMMENDED_SHIFT_IDX)
end

return PlayerUtils