
Scriptname DragonNexus_CellMarker extends ObjectReference

DragonNexus_Util Property Util auto

Cell CurrentCell = None

Event OnLoad()
  if !CurrentCell
    CurrentCell = GetParentCell()
  endif
  MiscUtil.PrintConsole("[DragNexus] mark cell loaded " + CurrentCell)
  Util.MarkCellLoaded(CurrentCell)
EndEvent

Event OnCellLoad()
  if !CurrentCell
    CurrentCell = GetParentCell()
  endif
  MiscUtil.PrintConsole("[DragNexus] mark cell loaded2 " + CurrentCell)
  Util.MarkCellLoaded(CurrentCell)
EndEvent

Event OnUnload()
  MiscUtil.PrintConsole("[DragNexus] mark cell unloaded " + CurrentCell)
  Util.MarkCellUnloaded(CurrentCell)

  self.Disable()
  self.Delete()
EndEvent

Event OnCellUnload()
  MiscUtil.PrintConsole("[DragNexus] mark cell unloaded2 " + CurrentCell)
  Util.MarkCellUnloaded(CurrentCell)

  self.Disable()
  self.Delete()
EndEvent

Event OnCellDetach()
  MiscUtil.PrintConsole("[DragNexus] mark cell unloaded3 " + CurrentCell)
  Util.MarkCellUnloaded(CurrentCell)

  self.Disable()
  self.Delete()
endEvent
