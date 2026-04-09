
Scriptname DragonNexus_Util extends Quest

Spell Property NewMsgSpell auto
Form Property MsgActivator auto
Form Property CellMarker auto

DragonNexus_LoadThread[] Property Threads auto

Actor Player = None

Int UpdateInterval = 3

string MsgHost = "http://127.0.0.1:3000"
string MsgListPath = "/msg/list"
string MsgAddPath = "/msg/add"

string[] MsgHeaderKeys
string[] MsgHeaderVals

int AddMsgHandle

Cell LastCell = None

; 保存 loaded cell
; 通过 unload 事件来知道 cell unload 了

Event OnInit()
  Player = Game.GetPlayer()
  Player.AddSpell(NewMsgSpell)
  MiscUtil.PrintConsole("[DragNexus] Init")

  ; PO3_Events_Form.RegisterForCellFullyLoaded(self)
  RegisterForSingleUpdate(UpdateInterval)
endEvent

Event OnPlayerLoadGame()
endEvent

Event OnUpdate()
  RegisterForSingleUpdate(UpdateInterval)

  Cell current_cell = Game.GetPlayer().GetParentCell()
  if current_cell == LastCell
    return
  endif

  LastCell = current_cell
  MiscUtil.PrintConsole("[DragNexus] enter new cell: " + current_cell)
  LoadCellMsgs(current_cell)
EndEvent

function LoadCellMsgs(Cell tcell)
  if IsCellLoaded(tcell)
    MiscUtil.PrintConsole("[DragNexus] SKip loaded cell: " + tcell)
    return
  endif

  if !PlaceCellMarker()
    return
  endif
  Utility.wait(0.1)

  MiscUtil.PrintConsole("[DragNexus] Load cell: " + tcell)
  DragonNexus_LoadThread thread = TakeThread()
  if thread
    thread.StartLoadCell(tcell)
  else
    MiscUtil.PrintConsole("[DragNexus] Not found idle thread.")
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

function PlaceMsg(string msg, string msg_type, string msg_val, float x, float y, float z, float angle)
  ObjectReference obj = Player.PlaceAtMe(MsgActivator, 1)
  if obj
    DragonNexus_Msg msg_obj = obj as DragonNexus_Msg
    msg_obj.SetPosition(x, y, z)
    ; msg_obj.SetAngle(0, angle, 0)
    msg_obj.SetMsgData(msg, msg_type, msg_val)
    ; msg_obj.setScale(0.4)
    MiscUtil.PrintConsole("[DragNexus] success place activator")
  else
    MiscUtil.PrintConsole("[DragNexus] Failed to place activator")
  endif
endfunction

; return http_handle
int function PullCellMsgs(DragonNexus_LoadThread thread, Cell tcell)
  string[] keys = new string[1]
  string[] vals = new string[1]
  keys[0] = "area_id"
  vals[0] = "SSE_" + tcell.GetFormID()

  string url = MsgHost + MsgListPath
  return HTTPUtils.RequestJSON_GET(thread, url, 5000, keys, vals, MsgHeaderKeys, MsgHeaderVals)
endfunction

function AddMsg(string msg, string msg_type, string msg_val, int duration = 0)
  if AddMsgHandle
    HTTPUtils.Destroy(AddMsgHandle)
  endif

  string[] keys = new string[9]
  string[] vals = new string[9]
  keys[0] = "area_id"
  keys[1] = "player"
  keys[2] = "msg"
  keys[3] = "msg_type"
  keys[4] = "msg_val"
  keys[5] = "x"
  keys[6] = "y"
  keys[7] = "z"
  keys[8] = "duration"

  Actor player = Game.GetPlayer()
  vals[0] = "SSE_" + player.GetFormID()
  vals[1] = player.GetLeveledActorBase().GetName()
  vals[2] = msg
  vals[3] = msg_type
  vals[4] = msg_val
  vals[5] = player.x as string
  vals[6] = player.y as string
  vals[7] = player.z as string
  vals[8] = duration as string

  string url = MsgHost + MsgAddPath
  string body = HTTPUtils.FormatJSON(keys, vals)
  AddMsgHandle = HTTPUtils.Request_POST(self, url, 5000, body, MsgHeaderKeys, MsgHeaderVals)
endfunction