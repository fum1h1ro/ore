namespace ore
import UnityEngine

class Actor (MonoBehaviour): 
  _action as callable = null
  _actionCount = 0
  _actionTimer = 0.0f
  _timeLayer = 0
  //
  actionCount:
    get:
      return _actionCount
  actionTimer:
    get:
      return _actionTimer
    set:
      _actionTimer = value
  timeLayer:
    get:
      return _timeLayer
    set:
      _timeLayer = value
  isFirst:
    get:
      if _actionCount == 0:
        _actionCount = 1
        return true
      return false
  //
  def GetAction():
    return _action
  //
  def SetAction(act):
    _action = act
    _actionCount = 0
    _actionTimer = 0.0f
  //
  def Action():
    if _action != null:
        tmp = _action
        _action(AppTime.deltaTime[_timeLayer])
        if tmp == _action:
            _actionCount += 1
            _actionTimer += AppTime.deltaTime[_timeLayer]
