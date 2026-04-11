
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
  ShowMsgMenu()
endEvent

function ShowMsgMenu()
  int ret = NewMsgMenu.Show()
  if ret == 0
    ; input
    UIExtensions.SetMenuPropertyString("UITextEntryMenu", "text", msg)
    UIExtensions.OpenMenu("UITextEntryMenu")
    string str = UIExtensions.GetMenuResultString("UITextEntryMenu")
    if str != ""
      msg = msg
    endif
    ShowMsgMenu()
  elseif ret == 1
    ShowMsgTypeMenu()
  elseif ret == 2
    ; send
    if msg == ""
      return
    endif
    Actor player = Game.GetPlayer()
    if ApplyMsgCost() || true
      Util.SendMsg(msg, msg_type, msg_val)
    endif
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

bool function ApplyMsgCost()
  Actor player = Game.GetPlayer()

  if msg_type == "monster"
    Form gem = Game.GetForm(0x2E4F3)
    if player.GetItemCount(gem) >= 1
      player.RemoveItem(gem, 1)
      return true
    else
      Debug.Notification("Not enough " + gem.GetName())
    endif
  elseif msg_type == "item"
    Form coin = Game.GetForm(0xf)
    if player.GetItemCount(coin) >= 500
      player.RemoveItem(coin, 500)
      return true
    else
      Debug.Notification("Not enough " + coin.GetName())
    endif
  elseif msg_type == "misc"
    Form coin = Game.GetForm(0xf)
    if player.GetItemCount(coin) >= 500
      player.RemoveItem(coin, 500)
      return true
    else
      Debug.Notification("Not enough " + coin.GetName())
    endif
  endif
  return false
endfunction
