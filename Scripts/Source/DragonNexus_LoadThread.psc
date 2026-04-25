
Scriptname DragonNexus_LoadThread extends Quest

DragonNexus_Util Property Util auto

int Property ThreadIdx auto

int GetMsgHandle
int MaxCellMsg = 32
int MaxApiMsgs = 256

string[] EmptyStrList

function StartLoadCellMsgs(Cell tcell)
  if !IsRunning()
    Start()
    Utility.Wait(0.5)
  endif

  string area_id = "SSE_" + Util.CalcCellID(tcell)
  StorageUtil.SetFormValue(self as Form, area_id, tcell)
  GetMsgHandle = PullMsgs(area_id)
endfunction

function StartLoadCellsMsgs(Cell[] tcells)
  if !IsRunning()
    Start()
    Utility.Wait(0.5)
  endif

  string area_ids = ""
  int i = 0
  while i < tcells.length
    Cell tcell = tcells[i]
    string area_id = "SSE_" + Util.CalcCellID(tcell)
    if tcell.IsAttached() && Util.GetCellTotalMsgs(area_id) < MaxCellMsg
      StorageUtil.SetFormValue(self as Form, area_id, tcell)
      if area_ids == ""
        area_ids = area_id
      else
        area_ids = area_ids + "," + area_id
      endif
    endif
    i += 1
  endwhile

  if area_ids == ""
    Util.Log("Skip pull loaded areas")
    return
  endif

  GetMsgHandle = PullMsgs(area_ids)
endfunction

function StopThread()
  if GetMsgHandle
    HTTPUtils.Destroy(GetMsgHandle)
    GetMsgHandle = 0
  endif
  StorageUtil.ClearObjFormValuePrefix(self as Form, "SSE_")
  Util.PushIdleThread(self)
endfunction

; return http_handle
int function PullMsgs(string area_ids)
  string url = Util.MsgHost + "/msg/list"
  string[] keys = new string[1]
  keys[0] = "area_ids"
  string[] vals = new string[1]
  vals[0] = area_ids
  Util.Log("HTTP pull msgs " + url + " | area_ids: " + area_ids + ", time: " + Utility.GetCurrentRealTime())
  int handle = HTTPUtils.RequestJSON_GET(self, url, 4500, keys, vals, EmptyStrList, EmptyStrList)
  return handle
endfunction

Event OnRequestSuccess(Int aiHandle, String asResponse)
  if aiHandle == GetMsgHandle && HTTPUtils.ValidateJSON(aiHandle)
    int total = HTTPUtils.GetJSONArrayLength(aiHandle, "/msgs")
    Util.Log("Found msgs: " + total)
    if total > MaxApiMsgs
      total = MaxApiMsgs
    endif
    int i = 0
    while i < total && aiHandle == GetMsgHandle
      int id = HTTPUtils.GetJSONInt(aiHandle, "/msgs/" + i + "/id")
      if Util.CanPlaceMsg(id)
        string area_id = HTTPUtils.GetJSONString(aiHandle, "/msgs/" + i + "/area_id")
        Cell mcell = StorageUtil.GetFormValue(self as Form, area_id) as Cell
        if !mcell
          mcell = Util.GetCellByAreaId(area_id)
        endif

        if mcell && mcell.IsAttached()
          string sender = HTTPUtils.GetJSONString(aiHandle, "/msgs/" + i + "/player")
          string msg = HTTPUtils.GetJSONString(aiHandle, "/msgs/" + i + "/msg")
          string msg_type = HTTPUtils.GetJSONString(aiHandle, "/msgs/" + i + "/msg_type")
          string msg_val = HTTPUtils.GetJSONString(aiHandle, "/msgs/" + i + "/msg_val")
          float x = HTTPUtils.GetJSONFloat(aiHandle, "/msgs/" + i + "/x")
          float y = HTTPUtils.GetJSONFloat(aiHandle, "/msgs/" + i + "/y")
          float z = HTTPUtils.GetJSONFloat(aiHandle, "/msgs/" + i + "/z")
          float angle = HTTPUtils.GetJSONFloat(aiHandle, "/msgs/" + i + "/angle")
          int like_level = HTTPUtils.GetJSONInt(aiHandle, "/msgs/" + i + "/like_level")
          Util.PlaceMsg(id, sender, msg, msg_type, msg_val, x, y, z, angle, like_level, area_id)
          Utility.Wait(0.1)
        else
          Utility.Wait(0.01)
        endif
      endif
      i += 1
    endwhile

    int last_msg_id = HTTPUtils.GetJSONInt(aiHandle, "/last_msg/id", 0)
    if last_msg_id > 0 && Util.CanNotifyLatestMsg(last_msg_id)
      string last_sender = HTTPUtils.GetJSONString(aiHandle, "/last_msg/player")
      string last_area_id = HTTPUtils.GetJSONString(aiHandle, "/last_msg/area_id")
      string last_msg_type = HTTPUtils.GetJSONString(aiHandle, "/last_msg/msg_type")
      Util.NotifyLatestMsg(last_msg_id, last_area_id, last_sender, last_msg_type)
    endif
    StopThread()
  else
    Util.Log("Invalid cell msgs data")
    StopThread()
  endif
EndEvent

Event OnRequestFail(Int aiHandle, Int aiStatusCode)
  Util.Log("Failed to pull cell msgs: " + aiStatusCode + " | Time: " + Utility.GetCurrentRealTime())
  StopThread()
EndEvent
