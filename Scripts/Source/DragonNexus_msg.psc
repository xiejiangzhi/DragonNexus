
Scriptname DragonNexus_Msg extends ObjectReference

DragonNexus_Util Property Util auto
Message Property MsgMenu auto
FormList Property Monsters auto
FormList Property Items auto

int msg_id
string sender
string msg
string msg_type
string msg_val
bool activated = false ; cannot activate again
bool liked = false

function SetMsgData(int _id, string _sender, string _msg, string _msg_type, string _msg_val)
  msg_id = _id
  msg = _msg
  msg_type = _msg_type
  msg_val = _msg_val
  sender = _sender
  activated = Util.IsActivatedMsg(msg_id)
endfunction

Event OnActivate(ObjectReference akActionRef)
  Actor player = Game.GetPlayer()
  if akActionRef != player
    return
  endif

  Debug.Notification(sender + ": " + msg)

  if liked && activated
    return
  endif


  if activated || player.IsSneaking()
    int ret = MsgMenu.Show()
    if ret == 0
      if !activated
        activated = true
        ApplyMsgAction()
        Util.ActivateMsg(msg_id)
      endif
    elseif ret == 1
      ; like
      Util.LikeMsg(msg_id)
      liked = true
    elseif ret == 2
      ; dislike
      Util.DislikeMsg(msg_id)
      self.Disable()
      self.Delete()
    endif
  else
    activated = true
    ApplyMsgAction()
    Util.ActivateMsg(msg_id)
  endif
endEvent

Event OnCellUnload()
  self.Disable()
  self.Delete()
EndEvent

Event OnCellDetach()
  self.Disable()
  self.Delete()
EndEvent

function ApplyMsgAction()
  Actor player = Game.GetPlayer()

  if msg_type == "monster"
    Form monster = Monsters.GetAt(msg_val as int)
    if monster
      self.PlaceAtMe(monster)
    endif
  elseif  msg_type == "item"
    Form item = Items.GetAt(msg_val as int)
    if item
      player.AddItem(item, 1)
    endif
  elseif msg_type == "misc"
    if msg_val == "0" ; restore
      player.RestoreActorValue("Health", 99999.)
      player.RestoreActorValue("Magicka", 99999.)
      player.RestoreActorValue("Stamina", 99999.)
    elseif msg_val == "1" ; steal_coin
      Form coin = Game.GetForm(0xf)
      player.RemoveItem(coin, 10 + Utility.RandomInt(10, 50))
    endif
  endif
endfunction
