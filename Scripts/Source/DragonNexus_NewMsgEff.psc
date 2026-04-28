
Scriptname DragonNexus_NewMsgEff extends ActiveMagicEffect

DragonNexus_Util Property Util auto
Message Property NewMsgMenu auto
Message Property MsgTypemenu auto
Message Property MsgTypeMonsterMenu auto
Message Property MsgTypeItemMenu auto
Message Property MsgTypeMiscMenu auto
Message Property MsgDurationMenu auto
Message Property RootMenu auto

string msg = "I was here."
string msg_type = "plain"
string msg_val = ""
int duration = 0

string next_menu = ""

Event OnEffectStart(Actor akTarget, Actor akCaster)
  msg = Util.GetDefaultMsg()

  next_menu = "root"
  string mval
  while next_menu != ""
    mval = next_menu
    next_menu = ""
    if mval == "root"
      ShowRootMenu()
    elseif mval == "new_msg"
      ShowMsgMenu()
    elseif mval == "msg_type"
      ShowMsgTypeMenu()
    elseif mval == "type_monster"
      ShowMsgTypeMonsterMenu()
    elseif mval == "type_item"
      ShowMsgTypeItemMenu()
    elseif mval == "type_misc"
      ShowMsgTypeMiscMenu()
    elseif mval == "msg_duration"
      ShowMsgDurationMenu()
    endif
  endwhile
endEvent

function ShowRootMenu()
  int ret = RootMenu.Show()
  if ret == 0
    ; input
    if Util.CanSendMsg(true)
      next_menu = "new_msg"
    else
      return
    endif
  elseif ret == 1
    ; view status & take reward
    Util.ViewUserInfo()
  elseif ret == 2
    ; cancel
  endif
endfunction

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
    next_menu = "new_msg"
  elseif ret == 1
    next_menu = "msg_type"
  elseif ret == 2
    next_menu = "msg_duration"
  elseif ret == 3
    ; send
    if msg == ""
      return
    endif
    Util.SendMsg(msg, msg_type, msg_val, duration)
  elseif ret == 4
    ; cancel
  endif
endfunction

function ShowMsgTypeMenu()
  int ret = MsgTypeMenu.Show()
  if ret == 0
    msg_type = "plain"
    next_menu = "new_msg"
  elseif ret == 1
    Form gem = Game.GetForm(0x2E4F3)
    if Game.GetPlayer().GetItemCount(gem) >= 1
      msg_type = "monster"
      next_menu = "type_monster"
    else
      Debug.Notification("Not enough " + gem.GetName())
      next_menu = "msg_type"
    endif
  elseif ret == 2
    Form coin = Game.GetForm(0xf)
    if Game.GetPlayer().GetItemCount(coin) >= 300
      msg_type = "item"
      next_menu = "type_item"
    else
      Debug.Notification("Not enough " + coin.GetName())
      next_menu = "msg_type"
    endif
  elseif ret == 3
    Form coin = Game.GetForm(0xf)
    if Game.GetPlayer().GetItemCount(coin) >= 500
      msg_type = "misc"
      next_menu = "type_misc"
    else
      Debug.Notification("Not enough " + coin.GetName())
      next_menu = "msg_type"
    endif
  else
    next_menu = "new_msg"
  endif
endfunction

function ShowMsgTypeMonsterMenu()
  msg_val = MsgTypeMonsterMenu.Show() as string
  next_menu = "new_msg"
endfunction

function ShowMsgTypeItemMenu()
  msg_val = MsgTypeItemMenu.Show() as string
  next_menu = "new_msg"
endfunction

function ShowMsgTypeMiscMenu()
  msg_val = MsgTypeMiscMenu.Show() as string
  next_menu = "new_msg"
endfunction

function ShowMsgDurationMenu()
  int ret = MsgDurationMenu.Show()
  if ret == 0
    duration = 0
    next_menu = "new_msg"
  elseif ret == 1
    Form gem = Game.GetForm(0x2E4FB)
    if Game.GetPlayer().GetItemCount(gem) >= 1
      duration = 86400 * 3
      next_menu = "new_msg"
    else
      Debug.Notification("Not enough " + gem.GetName())
      next_menu = "msg_duration"
    endif
  elseif ret == 2
    Form gem = Game.GetForm(0x2E4FF)
    if Game.GetPlayer().GetItemCount(gem) >= 1
      duration = 86400 * 5
      next_menu = "new_msg"
    else
      Debug.Notification("Not enough " + gem.GetName())
      next_menu = "msg_duration"
    endif
  endif
endfunction
