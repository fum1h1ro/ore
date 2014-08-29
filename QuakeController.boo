namespace ore
import UnityEngine

class QuakeController (MonoBehaviour):
  _transform as Transform
  _width as Vector2
  _count as Vector2
  _tick as single
  _time as single
  _offset as Vector3
  _backup as Vector3
  //
  def Awake():
    _transform = transform
    _width.Set(0.0f, 0.0f)
  // Use this for initialization
  def Start():
    pass
  // Update is called once per frame
  def Update():
    if _time > 0.0f:
      process_quake()
  static ii = 0
  def OnPreRender():
    pos = _backup = _transform.localPosition
    pos += _transform.up * _offset.y
    pos += _transform.right * _offset.x
    _transform.localPosition = pos
  def OnPostRender():
    _transform.localPosition = _backup
  def process_quake():
    t = Mathf.Min(_tick / _time, 1.0f)
    wx = util.Math.EaseOut(_width.x, 0.0f, t)
    wy = util.Math.EaseOut(_width.y, 0.0f, t)
    rx = Mathf.Sin(t * _count.x * Mathf.PI) * wx
    ry = Mathf.Sin(t * _count.y * Mathf.PI) * wy
    _offset.Set(rx, ry, 0.0f)
    if _tick >= _time:
      _time = 0.0f
    else:
      _tick += Time.deltaTime
  def Start(x as single, y as single, cx as single, cy as single, time as single):
    _width.Set(x, y)
    _count.Set(cx, cy)
    _time = time
    _tick = 0.0f
  def Cancel():
    _time = 0.0f
    _offset.Set(0.0f, 0.0f, 0.0f)
  isQuaking:
    get:
      return _time > 0.0f
  isFinished:
    get:
      return not isQuaking


//static class Quaker ():
//  _instance as QuakeController = null
//  def instance():
//    if _instance == null:
//      obj = Object.FindObjectOfType(typeof(QuakeController))
//      if obj != null:
//        _instance = obj as QuakeController
//    return _instance
//  public def Start(x as single, y as single, cx as single, cy as single, time as single):
//    instance().Start(x, y, cx, cy, time)
//  public isQuaking:
//    get:
//      return instance().isQuaking
//  public isFinished:
//    get:
//      return instance().isFinished

