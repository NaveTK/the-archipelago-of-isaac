local PLAYER_VARIANT = 0
-- This is the ShiftIdx that Blade recommended after having reviewing the game's internal functions.
-- Any value between 0 and 80 (inclusive) should work equally well.
-- https://www.jstatsoft.org/article/view/v008i14/xorshift.pdf
local RECOMMENDED_SHIFT_IDX = 35
local startSeed = Game():GetSeeds():GetStartSeed()
local rng = RNG()
rng:SetSeed(startSeed, RECOMMENDED_SHIFT_IDX)

---@return EntityPlayer
function GetRandomPlayer()
  local players = GetAllActivePlayers()
  local numPlayers = #players
  if numPlayers == 0 then
    return Isaac.GetPlayer()
  end
  return players[1 + rng:RandomInt(numPlayers)]
end

---@return EntityPlayer[]
function GetAllActivePlayers()
  local players = {}
  local numPlayers = Game():GetNumPlayers()
  for iPlayer = 0, numPlayers-1 do
    local player = Isaac.GetPlayer(iPlayer)
    -- Checking if Player Variant is PlayerVariant.PLAYER https://discord.com/channels/962027940131008653/962045574964715530/1470477894714134792
    if player.Variant == PLAYER_VARIANT and not player:IsCoopGhost() then
      table.insert(players, player)
    end
  end
  return players
end