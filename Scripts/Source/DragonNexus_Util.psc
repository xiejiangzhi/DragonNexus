
Scriptname DragonNexus_Util extends Quest

import MiscUtil

Spell Property NewMsgSpell auto
Form Property MsgActivator auto
Form Property MyMsgActivator auto
Form Property DeathMsgActivator auto
DragonNexus_LoadThread[] Property Threads auto

string Property MsgHost auto
int Property MaxCellMsg auto

string ConfFile = "DragonNexus.json"

Actor Player = None
String PlayerName = "None"

float UpdateInterval = 1.5
Cell LastCell = None

string[] MsgHeaderKeys
string[] MsgHeaderVals
int SendMsgHandle

float LastResetActivatorAt = 0.
float LastClearBlockedMsgAt = 0.

float LastSendMsgTime = -1000.
float SendMsgCooldown = 60.

float DeathMsgHealth = 1.
bool HealthRestored = false
string DeathMsg = "I just took an arrow in the knee..."

Event OnInit()
  Player = Game.GetPlayer()
  Player.AddSpell(NewMsgSpell)

  PlayerEnterGame()

  RegisterForSingleUpdate(UpdateInterval)

  ; PO3_Events_Form.RegisterForCellFullyLoaded(self as form)
endEvent

; Event OnCellFullyLoaded(Cell akCell)
;   Log("PO3 cell load: " + akCell)
;   LoadCellMsgs(akCell)
; EndEvent

Event OnUpdate()
  RegisterForSingleUpdate(UpdateInterval)
  Cell current_cell = Player.GetParentCell()
  if current_cell == LastCell
    float hp = player.GetAV("Health")
    if hp >= 100
      HealthRestored = true
    elseif HealthRestored && hp <= DeathMsgHealth && CanSendMsg(false)
      HealthRestored = false
      SendDeathMsg()
    endif
    return
  endif

  LastCell = current_cell
  LoadCellMsgs(current_cell)
EndEvent

function PlayerEnterGame()
  LastCell = None
  LastSendMsgTime = -1000.

  MsgHost = JsonUtil.GetPathStringValue(ConfFile, "Host", "http://127.0.0.1:3000")
  Log("Host: " + MsgHost)
  MaxCellMsg = JsonUtil.GetPathIntValue(ConfFile, "MaxCellMsg", 32)

  DeathMsgHealth = JsonUtil.GetPathFloatValue(ConfFile, "DeathMsgHealth", 1.)
  DeathMsg = JsonUtil.GetPathStringValue(ConfFile, "DeathMsg", "")

  PlayerName = JsonUtil.GetPathStringValue(ConfFile, "PlayerName", "")
  if PlayerName == ""
    PlayerName = Player.GetLeveledActorBase().GetName()
  endif

  float days = Utility.GetCurrentGameTime()
  float ResetActivatorInterval = JsonUtil.GetPathIntValue(ConfFile, "ResetActivatorHour", 24) / 24.
  if days > (LastResetActivatorAt + ResetActivatorInterval)
    StorageUtil.ClearObjIntValuePrefix(self as Form, "act_msg_")
    LastResetActivatorAt = days
    Log("Reset activator")
  endif

  float BlockedResetInterval = JsonUtil.GetPathIntValue(ConfFile, "ClearBlockedMsgHour", 168) / 24.
  if days > (LastClearBlockedMsgAt + BlockedResetInterval)
    StorageUtil.ClearObjIntValuePrefix(self as Form, "blocked_msg_")
    LastClearBlockedMsgAt = days
    Log("Clear blocked messages")
  endif

  ; server pri_id maybe expired, clear it to avoid get invalid pri_id
  StorageUtil.ClearObjIntValuePrefix(self as Form, "msg_pri_id_")
endfunction

function LoadCellMsgs(Cell tcell)
  if !tcell.IsAttached()
    ; Log("Skip loaded cell: " + tcell)
    return
  endif

  ; take a thread
  DragonNexus_LoadThread thread = TakeThread()
  while !thread && tcell.IsAttached()
    thread = TakeThread()
    Utility.wait(1.5)
  endwhile

  if thread
    Log("Pull cell msg: " + tcell)
    thread.StartLoadCell(tcell)
  else
    Log("Not found idle thread.")
  endif
endfunction

function ActivateMsg(int id)
  StorageUtil.SetIntValue(self as Form, "act_msg_" + id, 1)
endfunction

bool function IsActivatedMsg(int id)
  return StorageUtil.HasIntValue(self as Form, "act_msg_" + id)
endfunction

function LikeMsg(int id)
  string url = MsgHost + "/msg/like?msg_id=" + id
  HTTPUtils.Request_POST(self, url, 3000, "", MsgHeaderKeys, MsgHeaderVals)
endfunction

function DislikeMsg(int id)
  StorageUtil.SetIntValue(self as Form, "blocked_msg_" + id, 1)
  string url = MsgHost + "/msg/dislike?msg_id=" + id
  HTTPUtils.Request_POST(self, url, 3000, "", MsgHeaderKeys, MsgHeaderVals)
endfunction

bool function CanPlaceMsg(int id)
  return !StorageUtil.HasIntValue(self as Form, "blocked_msg_" + id) && !StorageUtil.HasIntValue(self as Form, "msg_" + id)
endfunction

DragonNexus_LoadThread function TakeThread()
  int i = 0
  while i <= 2
    DragonNexus_LoadThread t = Threads[i]
    if t
      Threads[i] = None
      t.ThreadIdx = i
      return t
    endif
    i += 1
  endwhile
endfunction

function PushIdleThread(DragonNexus_LoadThread thread)
  Threads[thread.ThreadIdx] = thread
endfunction

ObjectReference function PlaceMsg(int id, string sender, string msg, string msg_type, string msg_val, float x, float y, float z, float angle, int like_level)
  ObjectReference obj
  if msg_type == "death"
    obj = Player.PlaceAtMe(DeathMsgActivator, 1)
  elseif sender == PlayerName
    obj = Player.PlaceAtMe(MyMsgActivator, 1)
  else
    obj = Player.PlaceAtMe(MsgActivator, 1)
  endif
  if obj
    DragonNexus_Msg msg_obj = obj as DragonNexus_Msg
    msg_obj.SetPosition(x, y, z)
    msg_obj.SetAngle(0, 0, angle)
    msg_obj.SetMsgData(id, sender, msg, msg_type, msg_val, like_level)
    StorageUtil.SetIntValue(self as Form, "msg_" + id, 1)
  endif

  return obj
endfunction

bool function CanSendMsg(bool show_msg = false)
  if !LastCell
    Debug.Notification("Invalid area")
    return false
  endif

  float time = Utility.GetCurrentRealTime()
  if time < (LastSendMsgTime + SendMsgCooldown)
    if show_msg
      float v = (LastSendMsgTime + SendMsgCooldown) - time
      Debug.Notification("DragonNexus cooldown " + (v as int) + "s")
    endif
    return false
  endif
  return true
endfunction

function SendMsg(string msg, string msg_type, string msg_val, int duration = 0)
  if !LastCell
    return
  endif

  float time = Utility.GetCurrentRealTime()
  if time < (LastSendMsgTime + SendMsgCooldown)
    float v = (LastSendMsgTime + SendMsgCooldown) - time
    Debug.Notification("DragonNexus cooldown " + v as int + "s")
    return
  endif
  LastSendMsgTime = time

  if SendMsgHandle
    HTTPUtils.Destroy(SendMsgHandle)
  endif

  if !ApplyMsgCost(msg_type, msg_val, duration)
    return
  endif

  string[] keys = new string[10]
  string[] vals = new string[10]
  keys[0] = "area_id"
  keys[1] = "player"
  keys[2] = "msg"
  keys[3] = "msg_type"
  keys[4] = "msg_val"
  keys[5] = "x"
  keys[6] = "y"
  keys[7] = "z"
  keys[8] = "angle"
  keys[9] = "duration"

  vals[0] = "SSE_" + CalcCellID(LastCell)
  vals[1] = PlayerName
  vals[2] = msg
  vals[3] = msg_type
  vals[4] = msg_val
  vals[5] = Player.x as string
  vals[6] = Player.y as string
  vals[7] = Player.z as string
  vals[8] = Player.GetAngleZ() as string
  vals[9] = duration as string

  Debug.Notification("[DragonNexus] Sending message...")
  string url = MsgHost + "/msg/add"
  string body = HTTPUtils.FormatJSON(keys, vals, true)
  SendMsgHandle = HTTPUtils.RequestJSON_POST(self, url, 3000, body, MsgHeaderKeys, MsgHeaderVals)
endfunction

function SendDeathMsg()
  if DeathMsg != ""
    SendMsg(DeathMsg, "death", "", 0)
  endif
endfunction

bool function CanDelMsg(int msg_id)
  int pri_id = StorageUtil.GetIntValue(self as Form, "msg_pri_id_" + msg_id, -1)
  return pri_id >= 0
endfunction

function DelMsg(int msg_id)
  int pri_id = StorageUtil.GetIntValue(self as Form, "msg_pri_id_" + msg_id, -1)
  if pri_id >= 0
    string url = MsgHost + "/msg/del?msg_id=" + msg_id + "&pri_id=" + pri_id
    HTTPUtils.RequestJSON_POST(self, url, 3000, "", MsgHeaderKeys, MsgHeaderVals)
  endif
endfunction

bool function ApplyMsgCost(string msg_type, string msg_val, int duration)
  if msg_type == "monster"
    Form gem = Game.GetForm(0x2E4F3)
    if Player.GetItemCount(gem) >= 1
      Player.RemoveItem(gem, 1)
      return true
    else
      Debug.Notification("Not enough " + gem.GetName())
    endif
  elseif msg_type == "item"
    Form coin = Game.GetForm(0xf)
    if Player.GetItemCount(coin) >= 500
      Player.RemoveItem(coin, 500)
      return true
    else
      Debug.Notification("Not enough " + coin.GetName())
    endif
  elseif msg_type == "misc"
    Form coin = Game.GetForm(0xf)
    if Player.GetItemCount(coin) >= 500
      Player.RemoveItem(coin, 500)
      return true
    else
      Debug.Notification("Not enough " + coin.GetName())
    endif
  else
    return true
  endif

  if duration > 86400
    Form gem
    if duration >= (86400 * 3)
      gem = Game.GetForm(0x2E4FF)
    elseif duration >= (86400 * 2)
      gem = Game.GetForm(0x2E4FB)
    endif

    if gem && Player.GetItemCount(gem) >= 1
      Player.RemoveItem(gem, 1)
      return true
    else
      Debug.Notification("Not enough " + gem.GetName())
    endif
  endif
  return false
endfunction

function Log(string msg)
  MiscUtil.PrintConsole("[DragonNexus] " + msg)
endfunction

string function CalcCellID(Cell tcell)
  int fid = tcell.GetFormID()
  int mod_idx = fid / 16777216
  int rid = fid - (mod_idx * 16777216)
  return Game.GetModName(mod_idx) + ":" + rid
endfunction

Event OnRequestSuccess(Int aiHandle, String asResponse)
  if aiHandle == SendMsgHandle
    Log("Successfully send msg")

    int id = HTTPUtils.GetJSONInt(aiHandle, "/id")
    string sender = HTTPUtils.GetJSONString(aiHandle, "/player")
    string msg = HTTPUtils.GetJSONString(aiHandle, "/msg")
    string msg_type = HTTPUtils.GetJSONString(aiHandle, "/msg_type")
    string msg_val = HTTPUtils.GetJSONString(aiHandle, "/msg_val")
    float x = HTTPUtils.GetJSONFloat(aiHandle, "/x")
    float y = HTTPUtils.GetJSONFloat(aiHandle, "/y")
    float z = HTTPUtils.GetJSONFloat(aiHandle, "/z")
    float angle = HTTPUtils.GetJSONFloat(aiHandle, "/angle")
    int like_level = HTTPUtils.GetJSONInt(aiHandle, "/like_level")
    int pri_id = HTTPUtils.GetJSONInt(aiHandle, "/pri_id")

    StorageUtil.SetIntValue(self as Form, "msg_pri_id_" + id, pri_id)
    PlaceMsg(id, sender, msg, msg_type, msg_val, x, y, z, angle, like_level)
  endif
EndEvent

Event OnRequestFail(Int aiHandle, Int aiStatusCode)
  if aiHandle == SendMsgHandle
    Debug.Notification("[DragonNexus] Failed to send message")
  else
    Log("Failed to send HTTP request")
  endif
EndEvent
