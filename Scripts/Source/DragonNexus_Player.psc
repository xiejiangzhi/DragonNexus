
Scriptname DragonNexus_Player extends ReferenceAlias

DragonNexus_Util Property Util auto

Event OnPlayerLoadGame()
  Util.PlayerEnterGame()
EndEvent

Event OnCellAttach()
  Util.Log("Player cell attach")
EndEvent

Event OnCellDetach()
  Util.Log("Player cell detach")
EndEvent

Event OnCellLoad()
  Util.Log("Player cell load")
EndEvent