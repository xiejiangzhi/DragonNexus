
Scriptname DragonNexus_LoadThread extends Quest

DragonNexus_Util Property Util auto

int Property ThreadIdx auto

Cell TargetCell = None
String Status = "WaitMsg"

int GetMsgHandle
int MaxCellMsg = 32

string[] EmptyStrList


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

  Status = "WaitMsg"
  GetMsgHandle = PullCellMsgs(tcell)
endfunction

function StopThread()
  TargetCell = None
  if GetMsgHandle
    HTTPUtils.Destroy(GetMsgHandle)
  endif
  Util.PushIdleThread(self)
endfunction

; return http_handle
int function PullCellMsgs(Cell tcell)
  string url = Util.MsgHost + "/msg/list?area_id=SSE_" + Util.CalcCellID(tcell)
  return HTTPUtils.RequestJSON_GET(self, url, 5000, EmptyStrList, EmptyStrList, EmptyStrList, EmptyStrList)
endfunction

Event OnRequestSuccess(Int aiHandle, String asResponse)
  if HTTPUtils.ValidateJSON(aiHandle)
    int total = HTTPUtils.GetJSONArrayLength(aiHandle, "/msgs")
    if total > MaxCellMsg
      total = MaxCellMsg
    endif
    int i = 0
    while i < total && TargetCell.IsAttached()
      int id = HTTPUtils.GetJSONInt(aiHandle, "/msgs/" + i + "/id")
      if Util.CanPlaceMsg(id)
        string sender = HTTPUtils.GetJSONString(aiHandle, "/msgs/" + i + "/player")
        string msg = HTTPUtils.GetJSONString(aiHandle, "/msgs/" + i + "/msg")
        string msg_type = HTTPUtils.GetJSONString(aiHandle, "/msgs/" + i + "/msg_type")
        string msg_val = HTTPUtils.GetJSONString(aiHandle, "/msgs/" + i + "/msg_val")
        float x = HTTPUtils.GetJSONFloat(aiHandle, "/msgs/" + i + "/x")
        float y = HTTPUtils.GetJSONFloat(aiHandle, "/msgs/" + i + "/y")
        float z = HTTPUtils.GetJSONFloat(aiHandle, "/msgs/" + i + "/z")
        float angle = HTTPUtils.GetJSONFloat(aiHandle, "/msgs/" + i + "/angle")
        int like_level = HTTPUtils.GetJSONInt(aiHandle, "/msgs/" + i + "/like_level")
        Util.PlaceMsg(id, sender, msg, msg_type, msg_val, x, y, z, angle, like_level)
        Utility.Wait(0.1)
      endif
      i += 1
    endwhile
    StopThread()
  else
    Status = "Failed"
    Util.Log("Invalid cell msgs data")
    StopThread()
  endif
EndEvent

Event OnRequestFail(Int aiHandle, Int aiStatusCode)
  Util.Log("Failed to pull cell msgs:" + aiStatusCode)
  Status = "Failed"
  StopThread()
EndEvent
