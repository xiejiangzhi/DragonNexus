
Scriptname DragonNexus_CellMarker extends ObjectReference

DragonNexus_Util Property Util auto

Cell CurrentCell = None

Event OnLoad()
  if !CurrentCell
    CurrentCell = GetParentCell()
  endif
  if CurrentCell
    Util.MarkCellLoaded(CurrentCell)
  endif
EndEvent

Event OnCellLoad()
  if !CurrentCell
    CurrentCell = GetParentCell()
  endif
  if CurrentCell
    Util.MarkCellLoaded(CurrentCell)
  endif
EndEvent

Event OnCellAttach()
  if !CurrentCell
    CurrentCell = GetParentCell()
  endif
  if CurrentCell
    Util.MarkCellLoaded(CurrentCell)
  endif
EndEvent

Event OnUnload()
  if CurrentCell
    Util.MarkCellUnloaded(CurrentCell)
  endif

  self.Disable()
  self.Delete()
EndEvent

Event OnCellUnload()
  if CurrentCell
    Util.MarkCellUnloaded(CurrentCell)
  endif

  self.Disable()
  self.Delete()
EndEvent

Event OnCellDetach()
  if CurrentCell
    Util.MarkCellUnloaded(CurrentCell)
  endif

  self.Disable()
  self.Delete()
endEvent
