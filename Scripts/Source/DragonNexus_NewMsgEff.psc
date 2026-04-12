
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
  if Util.CanSendMsg()
    ShowMsgMenu()
  endif
endEvent

function ShowMsgMenu()
  int ret = NewMsgMenu.Show()
  if ret == 0
    ; input
    UIExtensions.SetMenuPropertyString("UITextEntryMenu", "text", msg)
    UIExtensions.OpenMenu("UITextEntryMenu")
    string str = UIExtensions.GetMenuResultString("UITextEntryMenu")
    if str != ""
      msg = str
    endif
    ShowMsgMenu()
  elseif ret == 1
    ShowMsgTypeMenu()
  elseif ret == 2
    ; send
    if msg == ""
      return
    endif
    Util.SendMsg(msg, msg_type, msg_val)
  elseif ret == 3
    ; cancel
  endif
endfunction

function ShowMsgTypeMenu()
  int ret = MsgTypeMenu.Show()
  if ret == 0
    msg_type = "plain"
    ShowMsgMenu()
  elseif ret == 1
    Form gem = Game.GetForm(0x2E4F3)
    if Game.GetPlayer().GetItemCount(gem) >= 1
      msg_type = "monster"
      ShowMsgTypeMonsterMenu()
    else
      Debug.Notification("Not enough " + gem.GetName())
      ShowMsgTypeMenu()
    endif
  elseif ret == 2
    Form coin = Game.GetForm(0xf)
    if Game.GetPlayer().GetItemCount(coin) >= 500
      msg_type = "item"
      ShowMsgTypeItemMenu()
    else
      Debug.Notification("Not enough " + coin.GetName())
      ShowMsgTypeMenu()
    endif
  elseif ret == 3
    Form coin = Game.GetForm(0xf)
    if Game.GetPlayer().GetItemCount(coin) >= 500
      msg_type = "misc"
      ShowMsgTypeMiscMenu()
    else
      Debug.Notification("Not enough " + coin.GetName())
      ShowMsgTypeMenu()
    endif
  else
    ShowMsgMenu()
  endif
endfunction

function ShowMsgTypeMonsterMenu()
  msg_val = MsgTypeMonsterMenu.Show() as string
  ShowMsgMenu()
endfunction

function ShowMsgTypeItemMenu()
  msg_val = MsgTypeItemMenu.Show() as string
  ShowMsgMenu()
endfunction

function ShowMsgTypeMiscMenu()
  msg_val = MsgTypeMiscMenu.Show() as string
  ShowMsgMenu()
endfunction

