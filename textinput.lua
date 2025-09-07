local game = Game()
local sfx = SFXManager()

-- ====== state ======
local TextInput = {
  isOpen = false,
  textFields = { '', '', '', '' },
  focus = 1,
  maxLen = 32,
  onDone = nil,
  font = Font(),
  blink = 0,
  noteSpr = Sprite(),
}

-- Load a vanilla font that ships with the game
-- (these paths are known-good for Repentance)
TextInput.font:Load('font/teammeatfont12.fnt')

-- ====== helpers ======
local function isShift()
  return Input.IsButtonPressed(Keyboard.KEY_LEFT_SHIFT, 0)
      or Input.IsButtonPressed(Keyboard.KEY_RIGHT_SHIFT, 0)
end

local function addChar(c)
  if #TextInput.textFields[TextInput.focus] < TextInput.maxLen then
    TextInput.textFields[TextInput.focus] = TextInput.textFields[TextInput.focus] .. c
    sfx:Play(SoundEffect.SOUND_BEEP, 0.5, 0, false, 1.0)
  end
end

-- Map keys → characters (expand as you like)
local letters = {
  [Keyboard.KEY_A]='a',[Keyboard.KEY_B]='b',[Keyboard.KEY_C]='c',[Keyboard.KEY_D]='d',
  [Keyboard.KEY_E]='e',[Keyboard.KEY_F]='f',[Keyboard.KEY_G]='g',[Keyboard.KEY_H]='h',
  [Keyboard.KEY_I]='i',[Keyboard.KEY_J]='j',[Keyboard.KEY_K]='k',[Keyboard.KEY_L]='l',
  [Keyboard.KEY_M]='m',[Keyboard.KEY_N]='n',[Keyboard.KEY_O]='o',[Keyboard.KEY_P]='p',
  [Keyboard.KEY_Q]='q',[Keyboard.KEY_R]='r',[Keyboard.KEY_S]='s',[Keyboard.KEY_T]='t',
  [Keyboard.KEY_U]='u',[Keyboard.KEY_V]='v',[Keyboard.KEY_W]='w',[Keyboard.KEY_X]='x',
  [Keyboard.KEY_Y]='y',[Keyboard.KEY_Z]='z'
}

local digits = {
  [Keyboard.KEY_0]='0',[Keyboard.KEY_1]='1',[Keyboard.KEY_2]='2',[Keyboard.KEY_3]='3',
  [Keyboard.KEY_4]='4',[Keyboard.KEY_5]='5',[Keyboard.KEY_6]='6',[Keyboard.KEY_7]='7',
  [Keyboard.KEY_8]='8',[Keyboard.KEY_9]='9'
}

local specials = {
  [Keyboard.KEY_SPACE] = ' ',
  [Keyboard.KEY_MINUS] = '-',
  [Keyboard.KEY_APOSTROPHE] = '\'',
  [Keyboard.KEY_COMMA] = ',',
  [Keyboard.KEY_PERIOD] = '.',
  [Keyboard.KEY_SLASH] = '/',
  [Keyboard.KEY_SEMICOLON] = ';',
  [Keyboard.KEY_LEFT_BRACKET] = '[',
  [Keyboard.KEY_RIGHT_BRACKET] = ']',
  [Keyboard.KEY_BACKSLASH] = '\\',
  [Keyboard.KEY_EQUAL] = '=',
}

-- ====== public API ======
function TextInput:OpenTextInput(address, port, password, slot, onDone)
  TextInput.textFields[1] = address
  TextInput.textFields[2] = port
  TextInput.textFields[3] = password
  TextInput.textFields[4] = slot
  TextInput.isOpen = true
  TextInput.maxLen = 32
  TextInput.onDone = onDone
  sfx:Play(SoundEffect.SOUND_MENU_NOTE_APPEAR, 0.7, 0, false, 1.0)
end

function TextInput.Init(mod)
  -- ====== capture keystrokes while open ======
  mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    if not TextInput.isOpen then return end

    TextInput.noteSpr:Load('gfx/ui/main menu/seedunlockpaper.anm2', true)
    TextInput.noteSpr:Play('Idle', true)
    --TextInput.noteSpr.Scale = Vector(1.2, 1.2)

    -- Confirm / cancel
    if Input.IsButtonTriggered(Keyboard.KEY_ENTER, 0) or Input.IsActionTriggered(ButtonAction.ACTION_MENUCONFIRM, Isaac.GetPlayer().ControllerIndex) then
      TextInput.isOpen = false
      sfx:Play(SoundEffect.SOUND_MENU_NOTE_HIDE, 0.8, 0, false, 1.0)
      if TextInput.onDone then TextInput.onDone(true, TextInput.textFields[1], TextInput.textFields[2], TextInput.textFields[3], TextInput.textFields[4]) end
      return
    end
    if Input.IsButtonTriggered(Keyboard.KEY_ESCAPE, 0) then
      TextInput.isOpen = false
      sfx:Play(SoundEffect.SOUND_MENU_NOTE_HIDE, 0.8, 0, false, 1.0)
      if TextInput.onDone then TextInput.onDone(false) end
      return
    end
    
    if Input.IsButtonTriggered(Keyboard.KEY_DOWN, 0) then
      TextInput.focus = TextInput.focus + 1
      if TextInput.focus > 4 then
        TextInput.focus = 4
        sfx:Play(SoundEffect.SOUND_CHARACTER_SELECT_RIGHT, 0.8, 0, false, 0.5)
      else
        sfx:Play(SoundEffect.SOUND_CHARACTER_SELECT_RIGHT, 0.8, 0, false, 1.0)
      end
    end
    
    if Input.IsButtonTriggered(Keyboard.KEY_UP, 0) then
      TextInput.focus = TextInput.focus - 1
      if TextInput.focus < 1 then
        TextInput.focus = 1
        sfx:Play(SoundEffect.SOUND_CHARACTER_SELECT_LEFT, 0.8, 0, false, 0.5)
      else
        sfx:Play(SoundEffect.SOUND_CHARACTER_SELECT_LEFT, 0.8, 0, false, 1.0)
      end
    end

    -- Backspace
    if Input.IsButtonTriggered(Keyboard.KEY_BACKSPACE, 0) then
      if #TextInput.textFields[TextInput.focus] > 0 then
        TextInput.textFields[TextInput.focus] = string.sub(TextInput.textFields[TextInput.focus], 1, #TextInput.textFields[TextInput.focus] - 1)
        sfx:Play(SoundEffect.SOUND_BLACK_POOF, 0.4, 0, false, 1.0)
      end
    end

    -- Letters
    for key, ch in pairs(letters) do
      if Input.IsButtonTriggered(key, 0) then
        addChar(isShift() and string.upper(ch) or ch)
      end
    end
    -- Digits (top row)
    for key, ch in pairs(digits) do
      if Input.IsButtonTriggered(key, 0) then addChar(ch) end
    end
    -- Specials
    for key, ch in pairs(specials) do
      if Input.IsButtonTriggered(key, 0) then
        if isShift() then
          -- crude US keyboard shift mapping (customize as needed)
          local shifted = {
            ['-']='_', ['=']='+', ['[']='{', [']']='}', ['\\']='|',
            [';']=':', ['\'']='"', [',']='<', ['.']='>', ['/']='?'
          }
          addChar(shifted[ch] or ch)
        else
          addChar(ch)
        end
      end
    end
  end)

  -- ====== block gameplay inputs while the modal is up ======
  mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, entity, hook, action)
    if TextInput.isOpen then
      -- Prevent the game from seeing actions
      if hook == InputHook.IS_ACTION_PRESSED
      or hook == InputHook.IS_ACTION_TRIGGERED then
        return false
      end
      if hook == InputHook.GET_ACTION_VALUE then
        return 0
      end
    end
  end)

  -- ====== draw the popup ======
  mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    if not TextInput.isOpen then return end
    local screenW, screenH = Isaac.GetScreenWidth(), Isaac.GetScreenHeight()
    local cx, cy = screenW/2, screenH/2

    -- cheap dim overlay
    Isaac.RenderScaledText(string.rep(' ', 1), 0, 0, 0, 0, 0, 0, 0, 0) -- noop to keep renderer warm

    TextInput.noteSpr:Render(Vector(cx, cy), Vector.Zero, Vector.Zero)

    -- Panel text
    TextInput.font:DrawString('Address:', cx - 34, cy-45, KColor(0,0,0,0.7), 1, false)
    TextInput.font:DrawString('Port:', cx - 34, cy-30, KColor(0,0,0,0.7), 1, false)
    TextInput.font:DrawString('Password:', cx - 34, cy-15, KColor(0,0,0,0.7), 1, false)
    TextInput.font:DrawString('Slot:', cx - 34, cy, KColor(0,0,0,0.7), 1, false)
    for i, text in ipairs(TextInput.textFields) do
      local shown = text
      if i == TextInput.focus then
        -- cursor blink
        TextInput.blink = (TextInput.blink + 1) % 60
        if TextInput.blink < 30 then shown = shown .. '|' end
      end
      TextInput.font:DrawString(shown, cx - 26, cy - 60 + i * 15, KColor(0,0,0,0.7), 0, false)
    end
    TextInput.font:DrawString('[ENTER] Connect   [ESC] Cancel', cx, cy+20, KColor(0,0,0,0.5), 1, true)
  end)
end

return TextInput