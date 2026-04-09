
Scriptname DragonNexus_Msg extends ObjectReference

DragonNexus_Util Property Util auto
Message Property MsgMenu auto
FormList Property Monsters auto
FormList Property Items auto

string msg
string msg_type
string msg_val
bool activated = false

function SetMsgData(string _msg, string _msg_type, string _msg_val)
  msg = _msg
  msg_type = _msg_type
  msg_val = _msg_val
endfunction

Event OnActivate(ObjectReference akActionRef)
  Debug.Notification(msg)

  if !activated
    ApplyMsgAction()
    activated = true
  else
    MsgMenu.Show()
  endif

  ; self.Disable()
  ; self.Delete()
endEvent

; Event OnUnload()
;   MiscUtil.PrintConsole("[DragNexus] unload Msg ")

;   self.Disable()
;   self.Delete()
; EndEvent

Event OnCellUnload()
  MiscUtil.PrintConsole("[DragNexus] unload Msg2 ")
  self.Disable()
  self.Delete()
EndEvent

Event OnCellDetach()
  MiscUtil.PrintConsole("[DragNexus] unload Msg3 ")
  self.Disable()
  self.Delete()
EndEvent

function ApplyMsgAction()
  Actor player = Game.GetPlayer()
  if msg_type == "monster"
    Form monster = Monsters.GetAt(msg_val as int)
    if monster
      player.PlaceAtMe(monster)
    endif
  elseif  msg_type == "item"
    Form item = Items.GetAt(msg_val as int)
    if item
      player.AddItem(item, 1)
    endif
  elseif msg_type == "misc"
    if msg_val == "1" ; restore
      player.RestoreActorValue("Health", 99999.)
      player.RestoreActorValue("Magicka", 99999.)
      player.RestoreActorValue("Stamina", 99999.)
    elseif msg_val == "2" ; give_coin
      Form coin = Game.GetForm(0xf)
      player.AddItem(coin, 10 + Utility.RandomInt(10, 50))
    elseif msg_val == "3" ; steal_coin
      Form coin = Game.GetForm(0xf)
      player.RemoveItem(coin, 10 + Utility.RandomInt(10, 50))
    endif
  endif
endfunction
