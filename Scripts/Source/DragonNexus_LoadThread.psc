
Scriptname DragonNexus_LoadThread extends Quest

DragonNexus_Util Property Util auto

int Property ThreadIdx auto

Cell TargetCell = None
String Status = "WaitMsg"

int GetMsgHandle


; 保存 loaded cell
; 通过 unload 事件来知道 cell unload 了

function StartLoadCell(Cell tcell)
  if !tcell
    StopThread()
    return
  endif

  if !IsRunning()
    Start()
    Utility.Wait(0.5)
  endif
  TargetCell = tcell

  string area_id = "SSE:" tcell.GetFormID()
  MiscUtil.PrintConsole(
    "[DragNexus] Start load thread: " + tcell + ", area_id: " + area_id + ", thread: " + ThreadIdx
  )

  Status = "WaitMsg"
  GetMsgHandle = Util.PullCellMsgs(self, tcell)
endfunction

function StopThread()
  TargetCell = None
  HTTPUtils.Destroy(GetMsgHandle)
  Util.PushIdleThread(self)
endfunction

Event OnUpdate()
  if !TargetCell
    MiscUtil.PrintConsole("[DragNexus] Stop inactive thread")
    return
  endif

  if !Util.IsCellLoaded(TargetCell)
    MiscUtil.PrintConsole("[DragNexus] Stop thread, cell is unloaded: " + TargetCell)
    StopThread()
    return
  endif

  Actor player = Game.GetPlayer()
  Util.PlaceMsg("hello", "plain", "", player.x, player.y, player.z, player.GetAngleY())


  ; if failed to place or msgs == 0
  ; Util.MarkCellUnloaded(tcell)

  StopThread()
  ; RegisterForSingleUpdate(UpdateInterval)
EndEvent

Event OnRequestSuccess(Int aiHandle, String asResponse)
  MiscUtil.PrintConsole("[DragNexus] Success pull msgs")

  if HTTPUtils.ValidateJSON(aiHandle)
    Status = "Success"
    ; if HTTPUtils.GetJSONInt(aiHandle, "count") > 0
    RegisterForSingleUpdate(0.1)
  else
    Status = "Failed"
    MiscUtil.PrintConsole("[DragNexus] Invalid msgs data")
    StopThread()
  endif
EndEvent

Event OnRequestFail(Int aiHandle, Int aiStatusCode)
  Status = "Failed"
  MiscUtil.PrintConsole("[DragNexus] Failed to pull msgs")
  StopThread()
EndEvent
