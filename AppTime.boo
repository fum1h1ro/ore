namespace ore
import UnityEngine

/*
  ゲーム内時間はTime.deltaTimeを使わずにこちらを使う
 */
public class AppTime (MonoBehaviour): 
  static _instance as AppTime = null
  public _layers = (of string: "ALL", "UI", "CAMERA", "OBJECT")
  _timeScale as (single)
  _deltaTime as (single)
  _fadeScale as (single)
  _fadeSpeed as (single)
  static public def GetIndex(name as string):
    return System.Array.IndexOf(_instance._layers, name)
  static public timeScale:
    get:
      return _instance._timeScale
  static public deltaTime:
    get:
      return _instance._deltaTime
  static public def SetScale(layer as uint, sca as single):
    _instance._timeScale[layer] = sca
  static public def SetScaleWithFade(layer as uint, sca as single, time as single):
    _instance._fadeScale[layer] = sca
    _instance._fadeSpeed[layer] = Mathf.Abs(_instance._fadeScale[layer] - _instance._timeScale[layer]) / time
  static public def ResetScale():
    for i in range(_instance._layers.Length):
      _instance._timeScale[i] = 1.0f
      _instance._fadeScale[i] = 0.0f
      _instance._fadeSpeed[i] = 0.0f
  private internal def update_scale():
    for i in range(_layers.Length):
      if _fadeSpeed[i] > 0.0f:
        if _fadeScale[i] > _timeScale[i]:
          _timeScale[i] = Mathf.Min(_timeScale[i] + _fadeSpeed[i] * Time.deltaTime, _fadeScale[i])
          if _fadeScale[i] <= _timeScale[i]:
            _fadeSpeed[i] = 0.0f
        elif _fadeScale[i] < _timeScale[i]:
          _timeScale[i] = Mathf.Max(_timeScale[i] - _fadeSpeed[i] * Time.deltaTime, _fadeScale[i])
          if _fadeScale[i] >= _timeScale[i]:
            _fadeSpeed[i] = 0.0f
      if i == 0:
        _deltaTime[i] = _timeScale[i] * Time.deltaTime
      else:
        _deltaTime[i] = _timeScale[i] * _timeScale[0] * Time.deltaTime

  def Awake():
    if _instance == null:
      _instance = self
      count = _layers.Length
      _timeScale = array(single, count)
      _deltaTime = array(single, count)
      _fadeScale = array(single, count)
      _fadeSpeed = array(single, count)
      ResetScale()
    else:
      Destroy(self)
  def Start():
    pass
  def Update():
    update_scale()
