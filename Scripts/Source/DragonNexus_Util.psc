
Scriptname DragonNexus_Util extends Quest

Spell Property NewMsgSpell auto
Form Property MsgActivator auto
Form Property MyMsgActivator auto
Form Property DeathMsgActivator auto
DragonNexus_LoadThread[] Property Threads auto

string Property MsgHost auto
int Property MaxCellMsg auto
string Property PlayerToken auto

string ConfFile = "../DragonNexus.json"
string UserConfFile = "../DragonNexus.User.json"
string DefaultConfFile = "../DragonNexus.json"

Actor Player = None
String PlayerName = "None"

Cell LastCell = None

string[] EmptyStringArray
string[] MsgHeaderKeys
string[] MsgHeaderVals
int SendMsgHandle
string SendMsgAreaId
int SigninHandle
int UserStatusHandle
int LastUserLikeCount

float LastResetActivatorAt = 0.
float LastClearBlockedMsgAt = 0.

float LastSendMsgTime = -1000.
float SendMsgCooldown = 60.

float DeathMsgHealth = 1.
bool HealthRestored = false
string DeathMsg = "I just took an arrow in the knee..."

int LatestMsgId = 0
float NotifyLatestMsgInterval = 30.
float LastNotifyLatestMsgTime = 0.
bool DisableNotifyLatestMsg = false

string DefaultMsg = "I was here."

Event OnInit()
  Player = Game.GetPlayer()
  Player.AddSpell(NewMsgSpell)

  PlayerEnterGame()

  RegisterForSingleUpdate(1.5)
endEvent

Event OnUpdate()
  RegisterForSingleUpdate(1.5)
  Cell current_cell = Player.GetParentCell()
  if current_cell == LastCell
    return
  endif
  LastCell = current_cell
  Log(LastCell + ", Name: " + GetCellName(LastCell))

  Cell[] AttachedCells = PO3_SKSEFunctions.GetAttachedCells()
  LoadCellsMsgs(AttachedCells)
EndEvent

function OnHitPlayer()
  float hp = Game.GetPlayer().GetAV("Health")
  if HealthRestored
    if hp <= DeathMsgHealth && CanSendMsg(false)
      HealthRestored = false
      SendDeathMsg()
    endif
  elseif hp >= 100
    HealthRestored = true
  endif
endfunction

string function GetConfString(string key, string default)
  return JsonUtil.GetPathStringValue(ConfFile, key, default)
endfunction

float function GetConfFloat(string key, float default)
  return JsonUtil.GetPathFloatValue(ConfFile, key, default)
endfunction

int function GetConfInt(string key, int default)
  return JsonUtil.GetPathIntValue(ConfFile, key, default)
endfunction

bool function GetConfBool(string key, bool default)
  return JsonUtil.GetPathBoolValue(ConfFile, key, default)
endfunction

function PlayerEnterGame()
  LastCell = None
  LastSendMsgTime = -1000.

  if JsonUtil.JsonExists(UserConfFile) && JsonUtil.IsGood(UserConfFile)
    ConfFile = UserConfFile
  else
    ConfFile = DefaultConfFile
  endif
  Log("Load config from " + ConfFile)

  MsgHost = GetConfString("Host", "https://skyrimmsg.xjz.pw")
  Log("Host: " + MsgHost)
  MaxCellMsg = GetConfInt("MaxCellMsg", 32)

  DeathMsgHealth = GetConfFloat("DeathMsgHealth", 1.)
  DeathMsg = GetConfString("DeathMsg", "I just took an arrow in the knee...")

  DefaultMsg = GetConfString("DefaultMsg", "I was here.")

  LastNotifyLatestMsgTime = 0.
  DisableNotifyLatestMsg = GetConfBool("DisableNotifyLatestMsg", false)
  NotifyLatestMsgInterval = GetConfFloat("NotifyLatestMsgInterval", 30.)

  PlayerName = GetConfString("PlayerName", "")
  if PlayerName == ""
    PlayerName = Player.GetLeveledActorBase().GetName()
  endif

  float days = Utility.GetCurrentGameTime()
  float ResetActivatorInterval = GetConfInt("ResetActivatorHour", 24) / 24.
  if days > (LastResetActivatorAt + ResetActivatorInterval)
    StorageUtil.ClearObjIntValuePrefix(self as Form, "act_msg_")
    LastResetActivatorAt = days
    Log("Reset activator")
  endif

  float BlockedResetInterval = GetConfInt("ClearBlockedMsgHour", 168) / 24.
  if days > (LastClearBlockedMsgAt + BlockedResetInterval)
    StorageUtil.ClearObjIntValuePrefix(self as Form, "blocked_msg_")
    LastClearBlockedMsgAt = days
    Log("Clear blocked messages")
  endif

  ; server pri_id maybe expired, clear it to avoid get invalid pri_id
  StorageUtil.ClearObjIntValuePrefix(self as Form, "msg_pri_id_")

  Signin()
endfunction

; Deprecated
; function LoadCellMsgs(Cell tcell)
;   string area_id = CalcCellID(tcell)
;   if !tcell.IsAttached() || GetCellTotalMsgs(area_id) >= MaxCellMsg
;     Log("Skip load cell msg " + tcell)
;     return
;   endif

;   ; take a thread
;   DragonNexus_LoadThread thread = TakeThread()
;   while !thread && tcell.IsAttached()
;     thread = TakeThread()
;     Utility.wait(0.5)
;   endwhile

;   if thread
;     Log("Start load cell msg: " + tcell)
;     thread.StartLoadCellMsgs(tcell)
;   endif
; endfunction

function LoadCellsMsgs(Cell[] tcells)
  ; take a thread
  DragonNexus_LoadThread thread = TakeThread()
  int i = 0
  while !thread && i < 60
    thread = TakeThread()
    Utility.wait(0.5)
    i += 1
  endwhile

  if thread
    thread.StopThread();
    Log("Start load cells msg: " + tcells.length)
    thread.StartLoadCellsMsgs(tcells)
  endif
endfunction

function ActivateMsg(int id)
  StorageUtil.SetIntValue(self as Form, "act_msg_" + id, 1)
endfunction

bool function IsActivatedMsg(int id)
  return StorageUtil.HasIntValue(self as Form, "act_msg_" + id)
endfunction

function LikeMsg(int id)
  string url = MsgHost + "/msg/like?msg_id=" + id + "&token=" + PlayerToken
  HTTPUtils.Request_POST(self, url, 3000, "", MsgHeaderKeys, MsgHeaderVals)
endfunction

function DislikeMsg(int id)
  StorageUtil.SetIntValue(self as Form, "blocked_msg_" + id, 1)
  string url = MsgHost + "/msg/dislike?msg_id=" + id + "&token=" + PlayerToken
  HTTPUtils.Request_POST(self, url, 3000, "", MsgHeaderKeys, MsgHeaderVals)
endfunction

bool function CanPlaceMsg(int id)
  return !StorageUtil.HasIntValue(self as Form, "blocked_msg_" + id) && !StorageUtil.HasIntValue(self as Form, "msg_" + id)
endfunction

DragonNexus_LoadThread function TakeThread()
  ; new logic use one thread, old logic has 3 threads
  int i = 0
  while i <= Threads.Length
    DragonNexus_LoadThread t = Threads[i]
    if t
      ; Threads[i] = None
      t.ThreadIdx = i
      return t
    endif
    i += 1
  endwhile
endfunction

function PushIdleThread(DragonNexus_LoadThread thread)
  Threads[thread.ThreadIdx] = thread
endfunction

string function GetDefaultMsg()
  return DefaultMsg
endfunction

ObjectReference function PlaceMsg(int id, string sender, string msg, string msg_type, string msg_val, float x, float y, float z, float angle, int like_level, string area_id)
  ObjectReference obj
  if msg_type == "death"
    obj = Player.PlaceAtMe(DeathMsgActivator, 1)
  elseif CanDelMsg(id)
    obj = Player.PlaceAtMe(MyMsgActivator, 1)
  else
    obj = Player.PlaceAtMe(MsgActivator, 1)
  endif
  if obj
    DragonNexus_Msg msg_obj = obj as DragonNexus_Msg
    msg_obj.SetPosition(x, y, z)
    msg_obj.SetAngle(0, 0, angle)
    msg_obj.SetMsgData(id, sender, msg, msg_type, msg_val, like_level, area_id)
    UpdateCellTotalMsgs(area_id, 1)
    StorageUtil.SetIntValue(self as Form, "msg_" + id, 1)
  endif

  return obj
endfunction

function Signin()
  string url = MsgHost + "/user/signin?token=" + PlayerToken
  SigninHandle = HTTPUtils.RequestJSON_POST(self, url, 5000, "", MsgHeaderKeys, MsgHeaderVals)
endfunction

function ViewUserInfo()
  if PlayerToken == ""
    return
  endif
  string url = MsgHost + "/user/info?token=" + PlayerToken
  UserStatusHandle = HTTPUtils.RequestJSON_GET(self, url, 5000, EmptyStringArray, EmptyStringArray, MsgHeaderKeys, MsgHeaderVals)
endfunction

function GiveGold(int total)
  Form gold = Game.GetForm(0xf) ; coin
  Player.AddItem(gold, total)
endfunction

function TakeGold(int total)
  Form gold = Game.GetForm(0xf) ; coin
  Player.RemoveItem(gold, total)
endfunction

bool function CanSendMsg(bool show_msg = false)
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
  float time = Utility.GetCurrentRealTime()
  if time < (LastSendMsgTime + SendMsgCooldown)
    float v = (LastSendMsgTime + SendMsgCooldown) - time
    Debug.Notification("DragonNexus cooldown " + v as int + "s")
    return
  endif
  LastSendMsgTime = time

  if SendMsgHandle
    HTTPUtils.Destroy(SendMsgHandle)
    SendMsgHandle = 0
  endif

  if !ApplyMsgCost(msg_type, msg_val, duration)
    return
  endif

  string[] keys = new string[11]
  string[] vals = new string[11]
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
  keys[10] = "token"

  Cell tcell = Player.GetParentCell()
  SendMsgAreaId = CalcCellID(tcell)
  vals[0] = "SSE_" + SendMsgAreaId
  vals[1] = PlayerName
  vals[2] = msg
  vals[3] = msg_type
  vals[4] = msg_val
  vals[5] = Player.x as string
  vals[6] = Player.y as string
  vals[7] = Player.z as string
  vals[8] = Player.GetAngleZ() as string
  vals[9] = duration as string
  vals[10] = PlayerToken

  Debug.Notification("[DragonNexus] Sending message...")
  string url = MsgHost + "/msg/add"
  string body = HTTPUtils.FormatJSON(keys, vals, true)
  SendMsgHandle = HTTPUtils.RequestJSON_POST(self, url, 5000, body, MsgHeaderKeys, MsgHeaderVals)
endfunction

function SendDeathMsg()
  if DeathMsg != ""
    SendMsg(DeathMsg, "death", "", 0)
  endif
endfunction

bool function CanDelMsg(int msg_id)
  return StorageUtil.IntListHas(self as Form, "my_msg_ids", msg_id)
endfunction

function DelMsg(int msg_id)
  if StorageUtil.IntListHas(self as Form, "my_msg_ids", msg_id)
    string url = MsgHost + "/msg/del?msg_id=" + msg_id + "&token=" + PlayerToken
    HTTPUtils.RequestJSON_POST(self, url, 3000, "", MsgHeaderKeys, MsgHeaderVals)
  endif
endfunction

int function UpdateCellTotalMsgs(string area_id, int mod_n)
  return StorageUtil.AdjustIntValue(self as Form, area_id, mod_n)
endfunction

function ResetCellTotalMsgs(string area_id)
  StorageUtil.UnsetIntValue(self as Form, area_id)
endfunction

int function GetCellTotalMsgs(string area_id)
  return StorageUtil.GetIntValue(self as Form, area_id, 0)
endfunction

bool function ApplyMsgCost(string msg_type, string msg_val, int duration)
  Form item1
  int item1_cost = 0

  if msg_type == "monster"
    item1 = Game.GetForm(0x2E4F3) ; soul gem
    item1_cost = 1
  elseif msg_type == "item"
    item1 = Game.GetForm(0xf) ; coin
    item1_cost = 300
  elseif msg_type == "misc"
    item1 = Game.GetForm(0xf) ; coin
    item1_cost = 500
  endif
  if item1 && Player.GetItemCount(item1) < item1_cost
    Debug.Notification("Not enough " + item1.GetName())
    return false
  endif

  Form item2
  int item2_cost = 0
  if duration >= (86400 * 5)
    item2 = Game.GetForm(0x2E4FF)
    item2_cost = 1
  elseif duration >= (86400 * 3)
    item2 = Game.GetForm(0x2E4FB)
    item2_cost = 1
  endif
  if item2 && Player.GetItemCount(item2) < item2_cost
    Debug.Notification("Not enough " + item2.GetName())
    return false
  endif

  if item1_cost >= 1
    Player.RemoveItem(item1, item1_cost)
  endif
  if item2_cost >= 1
    Player.RemoveItem(item2, item2_cost)
  endif

  return true
endfunction

bool function CanNotifyLatestMsg(int id)
  return !DisableNotifyLatestMsg && LatestMsgId != id && (Utility.GetCurrentRealTime() - LastNotifyLatestMsgTime) > NotifyLatestMsgInterval
endfunction

function NotifyLatestMsg(int id, string area_id, string sender, string msg_type)
  if LatestMsgId == id
    return
  endif
  LatestMsgId = id
  LastNotifyLatestMsgTime = Utility.GetCurrentRealTime()

  string area_name = GetCellName(GetCellByAreaId(area_id))
  if area_name == ""
    area_name = "???"
  endif
  if msg_type == "death"
    Debug.Notification(sender + " was defeated at " + area_name)
  elseif msg_type == "item"
    Debug.Notification(sender + " placed an item at " + area_name)
  else
    Debug.Notification(sender + " placed a message at " + area_name)
  endif
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

; area_id: SSE_xxx.esm:id
; return name or ""
Cell function GetCellByAreaId(string area_id)
  ; StorageUtil.GetFormValue
  int sep_idx = StringUtil.find(area_id, ":")
  if sep_idx < 0
    return
  endif

  string mod_name = StringUtil.substring(area_id, 4, sep_idx - 4)
  int form_id = StringUtil.substring(area_id, sep_idx + 1) as int
  return Game.GetFormFromFile(form_id, mod_name) as Cell
endfunction


; area_id: SSE_xxx.esm:id
; return name or ""
string function GetCellName(Cell tcell)
  if tcell
    ; TODO cell->GetLocation
    Location[] locs = SPE_Cell.GetExteriorLocations(tcell)
    if locs.length > 0
      return locs[0].GetName()
    else
      return tcell.GetName()
    endif
  endif
  return ""
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

    LatestMsgId = id
    StorageUtil.IntListAdd(self as Form, "my_msg_ids", id)
    PlaceMsg(id, sender, msg, msg_type, msg_val, x, y, z, angle, like_level, SendMsgAreaId)
    SendMsgHandle = 0
  elseif aiHandle == SigninHandle
    PlayerToken = HTTPUtils.GetJSONString(aiHandle, "/token")
    Log("Successfully signin. token: " + PlayerToken)
    SigninHandle  = 0
  elseif aiHandle == UserStatusHandle
    int like_count = HTTPUtils.GetJSONInt(aiHandle, "/like_count")
    int new_like_count = like_count - LastUserLikeCount
    LastUserLikeCount = like_count
    if new_like_count > 0
      GiveGold(new_like_count * 8)
    endif
    Debug.Notification(like_count + " likes received, +" + new_like_count + " new.")
    UserStatusHandle = 0
  endif
  HTTPUtils.Destroy(aiHandle)
EndEvent

Event OnRequestFail(Int aiHandle, Int aiStatusCode)
  if aiHandle == SendMsgHandle
    Log("Failed to send message")
    SendMsgHandle = 0
  elseif aiHandle == SigninHandle
    Log("Failed to sign in")
    SigninHandle = 0
  elseif aiHandle == UserStatusHandle
    Log("Failed to get user info")
    UserStatusHandle = 0
  else
    Log("Failed to send HTTP request")
  endif
  HTTPUtils.Destroy(aiHandle)
EndEvent
