
Scriptname DragonNexus_Util extends Quest

import MiscUtil

Spell Property NewMsgSpell auto
Form Property MsgActivator auto
Form Property CellMarker auto
DragonNexus_LoadThread[] Property Threads auto

string Property MsgHost auto
int Property MaxCellMsg auto

string ConfFile = "DragonNexus.json"

Actor Player = None

Int UpdateInterval = 3
Cell LastCell = None

string[] MsgHeaderKeys
string[] MsgHeaderVals
int SendMsgHandle

float LastResetActivatorAt = 0.
float LastClearBlockedMsgAt = 0.

Event OnInit()
  Player = Game.GetPlayer()
  Player.AddSpell(NewMsgSpell)

  PlayerEnterGame()

  ; PO3_Events_Form.RegisterForCellFullyLoaded(self)
  RegisterForSingleUpdate(UpdateInterval)
endEvent

Event OnUpdate()
  RegisterForSingleUpdate(UpdateInterval)

  Cell current_cell = Game.GetPlayer().GetParentCell()
  if current_cell == LastCell
    return
  endif

  LastCell = current_cell
  Log("enter new cell: " + current_cell)
  LoadCellMsgs(current_cell)
EndEvent

function PlayerEnterGame()
  MsgHost = JsonUtil.GetPathStringValue(ConfFile, "Host", "http://127.0.0.1:3000")
  Log("Host: " + MsgHost)
  MaxCellMsg = JsonUtil.GetPathIntValue(ConfFile, "MaxCellMsg", 32)

  float time = Utility.GetCurrentRealTime()
  float ResetActivatorInterval = JsonUtil.GetPathIntValue(ConfFile, "ResetActivatorHour", 24) * 3600.
  if time > (LastResetActivatorAt + ResetActivatorInterval)
    StorageUtil.ClearObjIntValuePrefix(self as Form, "act_msg_")
    LastResetActivatorAt = time
  endif

  float BlockedResetInterval = JsonUtil.GetPathIntValue(ConfFile, "ClearBlockedMsgHour", 72) * 3600.
  if time > (LastClearBlockedMsgAt + BlockedResetInterval)
    StorageUtil.ClearObjIntValuePrefix(self as Form, "blocked_msg_")
    LastClearBlockedMsgAt = time
  endif
endfunction

function LoadCellMsgs(Cell tcell)
  if IsCellLoaded(tcell)
    Log("SKip loaded cell: " + tcell)
    return
  endif

  if !PlaceCellMarker()
    return
  endif
  Utility.wait(0.1)

  Log("Pull cell msg: " + tcell)
  DragonNexus_LoadThread thread = TakeThread()
  if thread
    thread.StartLoadCell(tcell)
  else
    Log("Not found idle thread.")
  endif
endfunction

bool function IsCellLoaded(Cell tcell)
  string cell_id = "cell_" + tcell.GetFormID() as string
  return StorageUtil.HasIntValue(self as Form, cell_id)
endfunction

function MarkCellLoaded(Cell tcell)
  ; don't allow duplicate
  string cell_id = "cell_" + tcell.GetFormID() as string
  StorageUtil.SetIntValue(self as Form, cell_id, 1)
endfunction

function MarkCellUnloaded(Cell tcell)
  string cell_id = "cell_" + tcell.GetFormID() as string
  StorageUtil.UnsetIntValue(self as Form, cell_id)
endfunction

function ActivateMsg(int id)
  StorageUtil.SetIntValue(self as Form, "act_msg_" + id, 1)
endfunction

bool function IsActivatedMsg(int id)
  return StorageUtil.HasIntValue(self as Form, "act_msg_" + id)
endfunction

function LikeMsg(int id)
  string url = MsgHost + "/msg/like?id=" + id
  HTTPUtils.Request_POST(self, url, 5000, "", MsgHeaderKeys, MsgHeaderVals)
endfunction

function DislikeMsg(int id)
  StorageUtil.SetIntValue(self as Form, "blocked_msg_" + id, 1)
  string url = MsgHost + "/msg/dislike?id=" + id
  HTTPUtils.Request_POST(self, url, 5000, "", MsgHeaderKeys, MsgHeaderVals)
endfunction

bool function IsBlockedMsg(int id)
  return StorageUtil.HasIntValue(self as Form, "blocked_msg_" + id)
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

bool function PlaceCellMarker()
  ObjectReference marker = Player.PlaceAtMe(CellMarker, 1)
  if marker
    ; marker.setScale(0.001)
    return true
  endif
endfunction

ObjectReference function PlaceMsg(int id, string sender, string msg, string msg_type, string msg_val, float x, float y, float z, float angle)
  ObjectReference obj = Player.PlaceAtMe(MsgActivator, 1)
  if obj
    DragonNexus_Msg msg_obj = obj as DragonNexus_Msg
    msg_obj.SetPosition(x, y, z)
    msg_obj.SetAngle(0, angle, 0)
    msg_obj.SetMsgData(id, sender, msg, msg_type, msg_val)
    ; Log("success place activator")
  ; else
    ; Log("Failed to place activator")
  endif

  return obj
endfunction

function SendMsg(string msg, string msg_type, string msg_val, int duration = 0)
  if !LastCell
    return
  endif

  if SendMsgHandle
    HTTPUtils.Destroy(SendMsgHandle)
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

  Actor player = Game.GetPlayer()
  string sender = player.GetLeveledActorBase().GetName()
  vals[0] = "SSE_" + LastCell.GetFormID() as string
  vals[1] = sender
  vals[2] = msg
  vals[3] = msg_type
  vals[4] = msg_val
  vals[5] = player.x as string
  vals[6] = player.y as string
  vals[7] = player.z as string
  vals[8] = player.GetAngleY() as string
  vals[9] = duration as string

  Debug.Notification("[DragonNexus] Sending message...")
  string url = MsgHost + "/msg/add"
  string body = HTTPUtils.FormatJSON(keys, vals, true)
  SendMsgHandle = HTTPUtils.RequestJSON_POST(self, url, 5000, body, MsgHeaderKeys, MsgHeaderVals)
endfunction

function Log(string msg)
  MiscUtil.PrintConsole("[DragonNexus] " + msg)
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

    PlaceMsg(id, sender, msg, msg_type, msg_val, x, y, z, angle)
  endif
EndEvent

Event OnRequestFail(Int aiHandle, Int aiStatusCode)
  Debug.Notification("[DragonNexus] Failed to send message")
EndEvent