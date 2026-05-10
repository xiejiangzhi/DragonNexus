
Scriptname DragonNexus_Msg extends ObjectReference

DragonNexus_Util Property Util auto
Message Property MsgMenu auto
Message Property MyMsgMenu auto
FormList Property Monsters auto
FormList Property Items auto
FormList Property Spells auto

int msg_id = -1
string sender
string msg
string msg_type
string msg_val
bool activated = false ; cannot activate again
bool liked = false
string area_id
int like_level = 0

function SetMsgData(int _id, string _sender, string _msg, string _msg_type, string _msg_val, int _like_level, string _area_id)
  msg_id = _id
  msg = _msg
  msg_type = _msg_type
  msg_val = _msg_val
  sender = _sender
  liked = Util.IsLikedMsg(msg_id)
  activated = Util.IsActivatedMsg(msg_id)
  area_id = _area_id
  like_level = _like_level
  self.SetDisplayName("From: " + sender + "(" + like_level + ")", true)
endfunction

Event OnLoad()
  if sender
    self.SetDisplayName("From: " + sender + "(" + like_level + ")", true)
  endif
EndEvent

Event OnActivate(ObjectReference akActionRef)
  Actor player = Game.GetPlayer()
  if akActionRef != player
    return
  endif

  Util.ShowMsg(sender, msg)

  if player.IsSneaking()
    if MyMsgMenu && Util.CanDelMsg(msg_id)
      int ret = MyMsgMenu.Show()
      if ret == 0
        ; delete
        Util.DelMsg(msg_id)
        MarkDeleted()
        self.Disable()
        self.Delete()
      elseif ret == 1
        Util.HideMsg(msg_id)
        MarkDeleted()
        self.Disable()
        self.Delete()
      endif
    else
      int ret = MsgMenu.Show()
      if ret == 0
        if !activated
          activated = true
          ApplyMsgAction()
          Util.ActivateMsg(msg_id)
        endif
      elseif ret == 1
        if !liked
          Util.LikeMsg(msg_id)
          Util.TakeGold(10)
          liked = true
          like_level += 1
          self.SetDisplayName("From: " + sender + "(" + like_level + ")", true)
        endif
      elseif ret == 2
        Util.HideMsg(msg_id)
        MarkDeleted()
        self.Disable()
        self.Delete()
      elseif ret == 3
        Util.DislikeMsg(msg_id)
        MarkDeleted()
        self.Disable()
        self.Delete()
      endif
    endif
  elseif !activated
    activated = true
    ApplyMsgAction()
    Util.ActivateMsg(msg_id)
  endif
endEvent

Event OnCellUnload()
  if msg_id > 0
    MarkDeleted()
    Util.ResetCellTotalMsgs(area_id)
  endif
  self.Disable()
  self.Delete()
EndEvent

Event OnCellDetach()
  if msg_id > 0
    MarkDeleted()
    Util.ResetCellTotalMsgs(area_id)
  endif
  self.Disable()
  self.Delete()
EndEvent

function MarkDeleted()
  StorageUtil.UnsetIntValue(Util as Form, "msg_" + msg_id)
endfunction

function ApplyMsgAction()
  Actor player = Game.GetPlayer()

  if msg_type == "monster"
    if !Util.DisableMessageMonster
      Form monster = Monsters.GetAt(msg_val as int)
      if monster
        self.PlaceAtMe(monster)
      endif
    endif
  elseif msg_type == "item"
    if !Util.DisableMessageItem
      Form item = Items.GetAt(msg_val as int)
      if item
        player.AddItem(item, 1)
      endif
    endif
  elseif msg_type == "spell"
    if !Util.DisableMessageSpell
      Spell sp = Spells.GetAt(msg_val as int) as Spell
      if sp
        sp.Cast(player)
      endif
    endif
  elseif msg_type == "misc"
    if !Util.DisableMessageMisc
      if msg_val == "0"; push
        self.PushActorAway(player, 1.4 + Utility.RandomFloat() * 2.0)
      elseif msg_val == "1" ; steal coin
        Form coin = Game.GetForm(0xf)
        player.RemoveItem(coin, 10 + Utility.RandomInt(10, 40))
      endif
    endif
  endif
endfunction
