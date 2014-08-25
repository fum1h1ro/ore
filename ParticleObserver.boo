import UnityEngine

class ParticleObserver (MonoBehaviour):
  private _psys as (ParticleSystem) = null
  def Start():
    _psys = GetComponentsInChildren[of ParticleSystem](true)
    _psys = null if _psys.Length == 0
  def Update():
    inactive = true
    if _psys != null:
      for i in range(_psys.Length):
        if _psys[i].IsAlive():
          inactive = false
          break
    gameObject.SetActive(false) if inactive
  def OnEnable():
    if _psys != null:
      for i in range(_psys.Length):
        _psys[i].Clear()
        _psys[i].Play()
  def OnDisable():
    if _psys != null:
      for i in range(_psys.Length):
        _psys[i].Stop()
