namespace ore
import UnityEngine

/*
  ゲーム内時間はTime.deltaTimeを使わずにこちらを使う
 */
public class AppTime (MonoBehaviour): 
  public enum Layer:
    ALL
    UI
    CAMERA
    OBJECT
    MAX
  static _timeScale = array(single, Layer.MAX)
  static _deltaTime = array(single, Layer.MAX)
  static _fadeScale = array(single, Layer.MAX)
  static _fadeSpeed = array(single, Layer.MAX)
  static public timeScale:
    get:
      return _timeScale
  static public deltaTime:
    get:
      return _deltaTime
  static public def SetScale(layer as Layer, sca as single):
    _timeScale[layer cast uint] = sca
  static public def SetScaleWithFade(layer as Layer, sca as single, time as single):
    _fadeScale[layer] = sca
    _fadeSpeed[layer] = Mathf.Abs(_fadeScale[layer] - _timeScale[layer]) / time
  static public def ResetScale():
    for i in range(Layer.MAX):
      _timeScale[i] = 1.0f
      _fadeScale[i] = 0.0f
      _fadeSpeed[i] = 0.0f
  static private internal def update_scale():
    for i in range(Layer.MAX):
      if _fadeSpeed[i] > 0.0f:
        if _fadeScale[i] > _timeScale[i]:
          _timeScale[i] = Mathf.Min(_timeScale[i] + _fadeSpeed[i] * Time.deltaTime, _fadeScale[i])
          if _fadeScale[i] <= _timeScale[i]:
            _fadeSpeed[i] = 0.0f
        elif _fadeScale[i] < _timeScale[i]:
          _timeScale[i] = Mathf.Max(_timeScale[i] - _fadeSpeed[i] * Time.deltaTime, _fadeScale[i])
          if _fadeScale[i] >= _timeScale[i]:
            _fadeSpeed[i] = 0.0f
      if i == Layer.ALL:
        _deltaTime[i] = _timeScale[i] * Time.deltaTime
      else:
        _deltaTime[i] = _timeScale[i] * _timeScale[Layer.ALL] * Time.deltaTime

  def Awake():
    ResetScale()
  def Start():
    pass
  def Update():
    update_scale()
