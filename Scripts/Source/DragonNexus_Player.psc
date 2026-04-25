
Scriptname DragonNexus_Player extends ReferenceAlias

DragonNexus_Util Property Util auto

Event OnPlayerLoadGame()
  Util.PlayerEnterGame()
EndEvent

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
  Util.OnHitPlayer()
EndEvent