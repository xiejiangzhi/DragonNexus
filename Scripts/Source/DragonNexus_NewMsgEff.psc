
Scriptname DragonNexus_NewMsgEff extends ActiveMagicEffect

DragonNexus_Util Property Util auto
Message Property NewMsgMenu auto
Message Property MsgTypemenu auto
Message Property MsgTypeMonsterMenu auto
Message Property MsgTypeItemMenu auto
Message Property MsgTypeMiscMenu auto

string msg = "hello"
string msg_type = "plain"
string msg_val = ""

Event OnEffectStart(Actor akTarget, Actor akCaster)
  MiscUtil.PrintConsole("[DragNexus] New Msg")

  ShowMsgMenu()

  ; Util.AddMsg("Hello world", "Hello", "")
endEvent

function ShowMsgMenu()
  int ret = NewMsgMenu.Show()
  if ret == 0
    ; input
    int text_ret = UIExtensions.OpenMenu("UITextEntryMenu")
    msg = UIExtensions.GetMenuResultString("UITextEntryMenu")
    MiscUtil.PrintConsole("[DragNexus] Input Msg: " + msg)
    ShowMsgMenu()
  elseif ret == 1
    ShowMsgTypeMenu()
  elseif ret == 2
    ; send
    Actor player = Game.GetPlayer()
    Util.PlaceMsg(msg, msg_type, msg_val, player.x, player.y, player.z, player.GetAngleY())
  elseif ret == 3
    ; cancel
  endif
endfunction

function ShowMsgTypeMenu()
  int ret = MsgTypeMenu.Show()
  if ret == 0
    msg_type = "plain"
  elseif ret == 1
    msg_type = "monster"
    ShowMsgTypeMonsterMenu()
  elseif ret == 2
    msg_type = "item"
    ShowMsgTypeItemMenu()
  elseif ret == 3
    msg_type = "misc"
    ShowMsgTypeMiscMenu()
  else
    ShowMsgMenu()
  endif
endfunction

function ShowMsgTypeMonsterMenu()
  int ret = MsgTypeMonsterMenu.Show()
  msg_type = ret as string
  ShowMsgMenu()
endfunction

function ShowMsgTypeItemMenu()
  int ret = MsgTypeItemMenu.Show()
  msg_type = ret as string
  ShowMsgMenu()
endfunction

function ShowMsgTypeMiscMenu()
  int ret = MsgTypeMiscMenu.Show()
  msg_type = ret as string
  ShowMsgMenu()
endfunction
