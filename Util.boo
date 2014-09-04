namespace ore.util

import UnityEngine

/*
 */
static def Log(obj as object):
  if Debug.isDebugBuild:
    Debug.Log(obj)
static def LogWarning(obj as object):
  if Debug.isDebugBuild:
    Debug.LogWarning(obj)
static def LogError(obj as object):
  if Debug.isDebugBuild:
    Debug.LogError(obj)

// シーン中の全てのGameObjectにSendMessageする
static public def BroadcastMessage(methodname as string, value as Object):
  Log("Broadcast ${methodname}")
  for obj in Object.FindObjectsOfType(typeof(GameObject)):
    (obj as GameObject).SendMessage(methodname, value, SendMessageOptions.DontRequireReceiver)
static public def BroadcastMessage(methodname as string):
  BroadcastMessage(methodname, null)

// km/hからm/sに変換する
static public def ConvertKMHToMS(kmh as single):
  return (kmh * 1000.0f) * (1.0f/(60.0f*60.0f))

// [[https://gist.github.com/fum1h1ro/9223212]] 参照
public class GameObjectAccessor[of T(MonoBehaviour)]:
  _name as string
  _obj as GameObject = null
  _mono as T = null as T
  public def constructor(name as string):
    _name = name
  public obj:
    get:
      _obj = GameObject.Find(_name) if _obj == null
      return _obj
  public mono:
    get:
      _mono = obj.GetComponent[of T]() if _mono == null
      return _mono


static public def ObjectClone[of T](src as T) as T:
  r as T
  b = System.Runtime.Serialization.Formatters.Binary.BinaryFormatter()
  m = System.IO.MemoryStream()
  try:
    b.Serialize(m, src)
    m.Position = 0
    r = b.Deserialize(m) as T
  ensure:
    m.Close()
  return r

static public def FindChild(obj as GameObject, suffix as string) as GameObject:
  if obj.name.EndsWith(suffix):
    return obj
  for t as Transform in obj.transform:
    o = FindChild(t.gameObject, suffix)
    if o != null:
      return o
  return null


[System.Reflection.DefaultMember("h")]
public class UnorderedArray [of T(class)] ():
  _table as (T)
  _size = 0
  _insertPos = 0
  size:
    get:
      return _size
  h[index as int]:
    get:
      rawArrayIndexing:
        return _table[index]
    set:
      rawArrayIndexing:
        _table[index] = value
  def constructor():
    Reserve(4)
  def constructor(sz as int):
    Reserve(sz)
  def Clear():
    for i in range(_table.Length):
      _table[i] = null
    _insertPos = 0
  def Reserve(sz as int):
    if _size < sz:
      _size = sz
    if _table == null:
      _table = array(typeof(T), _size)
    else:
      System.Array.Resize[of T](_table, _size)
  def Jam(v as T):
    if _insertPos >= _size or _table[_insertPos] == null:
      for i in range(_table.Length):
        if _table[i] == null:
          _table[i] = v
          _insertPos = i+1
          break
      then:
        Reserve(_size * 2)
        Jam(v)
    else:
      _table[_insertPos++] = v
  def Erase(v as T):
    idx = IndexOf(v)
    _table[idx] = null if idx >= 0
  def IndexOf(v as T):
    return System.Array.IndexOf(_table, v)
  def CopyTo(dst as UnorderedArray[of T]):
    if dst.size < size:
      dst.Reserve(size)
    dst.Clear()
    for i in range(_table.Length):
      dst[i] = _table[i]

public class Math:
  static public def Loop(n as int, lo as int, hi as int) as int:
    while n < lo:
      n += (hi - lo)
    while n >= hi:
      n -= (hi - lo)
    return n


  // 一番近い2の乗数にする
  static public def round_up(n as int) as int:
    // corner case: x=0, x>2^63
    _N1 as int = n - 1
    _N2 as int = _N1 | (_N1 >>  1)
    _N3 as int = _N2 | (_N2 >>  2)
    _N4 as int = _N3 | (_N3 >>  4)
    _N5 as int = _N4 | (_N4 >>  8)
    _N6 as int = _N5 | (_N5 >> 16)
    _N7 as int = _N6 | (_N6 >> 32)
    return _N7 + 1
  static public def round_up(n as uint) as uint:
    // corner case: x=0, x>2^63
    _N1 as uint = n - 1
    _N2 as uint = _N1 | (_N1 >>  1)
    _N3 as uint = _N2 | (_N2 >>  2)
    _N4 as uint = _N3 | (_N3 >>  4)
    _N5 as uint = _N4 | (_N4 >>  8)
    _N6 as uint = _N5 | (_N5 >> 16)
    _N7 as uint = _N6 | (_N6 >> 32)
    return _N7 + 1


  // Xorshift128乱数
  public class Xorshift128:
    x as uint = 123456789
    y as uint = 362436069
    z as uint = 521288629
    w as uint = 88675123
    public def constructor():
      pass
    public def constructor(n as uint):
      SetSeed(n)
    public def SetSeed(n as uint):
      x = n = (1812433253 * (n ^ (n >> 30)) + 1) & 0x7fffffff
      y = n = (1812433253 * (n ^ (n >> 30)) + 2) & 0x7fffffff
      z = n = (1812433253 * (n ^ (n >> 30)) + 3) & 0x7fffffff
      w = n = (1812433253 * (n ^ (n >> 30)) + 4) & 0x7fffffff
    public def get_uint() as uint:
      t as uint = (x ^ (x<<11))
      x=y
      y=z
      z=w
      w=(w^(w>>19))^(t^(t>>8))
      return w
    public def get_ushort(max as ushort) as ushort:
      return (((get_uint() >> 16) * max) >> 16)
    public def get_int() as int:
      return get_uint() & 0x7fffffff
    /** generates a random number on [0,1]-real-interval */
    public def get_single() as single:
      /* divided by 2^32-1 */ 
      return get_uint() * (1.0f / 4294967295.0f) + 0.5f
    /** generates a random number on [0,1)-real-interval */
    public def get_real2() as single:
      /* divided by 2^32 */
      return get_uint() * (1.0f / 4294967296.0f)
    /** generates a random number on (0,1)-real-interval */
    public def get_real3() as single:
      /* divided by 2^32 */
      return (get_uint() cast single + 0.5f) * (1.0f / 4294967296.0f)
  static private _xorshift128 = Xorshift128()
  static public rand:
    get:
      return _xorshift128

  // 補間器
  public static def EaseInEaseOut(f as single, t as single, v as single) as single:
    v2 = v * v
    v3 = v2 * v
    iv = 3.0f * v2 - 2.0f * v3
    return f + (t - f) * iv
  public static def EaseIn(f as single, t as single, v as single) as single:
    v2 = v * v
    //float v3 = Mathf.Pow(v, 1.8f);
    return f + (t - f) * v2
  public static def EaseOut(f as single, t as single, v as single) as single:
    v2 = 1.0f - v
    v3 = 1.0f - v2 * v2// * v2;
    return f + (t - f) * v3
  public static def Parabola(v as single) as single:
      x = 1.0f - 2.0f * v
      return 1.0f - x * x
  public class Interpolator:
    public enum Mode:
      Linear
      EaseInEaseOut
      EaseIn
      EaseOut
    mode_ as Mode;
    from_ as single
    to_ as single
    value_ as single
    seconds_ as single
    //
    public static def Linear(f as single, t as single, sec as single):
      return Interpolator(Mode.Linear, f, t, sec)
    public static def EaseInEaseOut(f as single, t as single, sec as single):
      return Interpolator(Mode.EaseInEaseOut, f, t, sec)
    public static def EaseIn(f as single, t as single, sec as single):
      return Interpolator(Mode.EaseIn, f, t, sec)
    public static def EaseOut(f as single, t as single, sec as single):
      return Interpolator(Mode.EaseOut, f, t, sec)
    //
    public def constructor():
      mode_ = Mode.Linear
      from_ = 0.0f
      to_ = 1.0f
      value_ = 0.0f
      seconds_ = 0.0f
    private def constructor(mode as Mode, f as single, t as single, sec as single):
      mode_ = mode
      from_ = f
      to_ = t
      value_ = 0.0f
      seconds_ = 1.0f / sec
    public def Reset():
      value_ = 0.0f
    public def Start(sec as single):
      value_ = 0.0f
      seconds_ = 1.0f / sec
    public def Update(step as single):
      value_ = Mathf.Min(value_ + seconds_ * step, 1.0f)
    public isFinished:
      get:
        return value_ >= 1.0f
    public value as single:
      get:
        if mode_ == Mode.Linear:
          return Mathf.Lerp(from_, to_, value_)
        elif mode_ == Mode.EaseInEaseOut:
          return Math.EaseInEaseOut(from_, to_, value_)
        elif mode_ == Mode.EaseIn:
          return Math.EaseIn(from_, to_, value_)
        elif mode_ == Mode.EaseOut:
          return Math.EaseOut(from_, to_, value_)
        else:
          return 0.0f
    public normalizedValue as single:
      get:
        return value_
    public mode as Mode:
      get:
        return mode_
      set:
        mode_ = value
  // 角度正規化
  public static def NormalizeAngleRad(rad as single):
    while rad < 0.0f:
      rad += Mathf.PI * 2.0f
    while rad >= Mathf.PI * 2.0f:
      rad -= Mathf.PI * 2.0f
    return rad
  public static def NormalizeAngleDeg(deg as single):
    return NormalizeAngleRad(deg * Mathf.Deg2Rad) * Mathf.Rad2Deg
  // 角度補間
  public static def LerpAngleRad(l as single, h as single, a as single):
    ll = NormalizeAngleRad(l)
    hh = NormalizeAngleRad(h)
    d0 = ll - hh
    d1 = ll - (hh - Mathf.PI * 2.0f)
    d2 = ll - (hh + Mathf.PI * 2.0f)
    if Mathf.Abs(d0) <= Mathf.Abs(d1) and Mathf.Abs(d0) <= Mathf.Abs(d2):
      return Mathf.Lerp(ll, hh, a)
    else:
      if Mathf.Abs(d1) <= Mathf.Abs(d2):
        return Mathf.Lerp(ll, hh - Mathf.PI * 2.0f, a)
      else:
        return Mathf.Lerp(ll, hh + Mathf.PI * 2.0f, a)
  public static def LerpAngleDeg(l as single, h as single, a as single):
    return LerpAngleRad(l * Mathf.Deg2Rad, h * Mathf.Deg2Rad, a) * Mathf.Rad2Deg


  class EaseValue ():
    private _value as single = 0.0f
    private _target as single = 0.0f
    private _accel as single = 0.0f
    def constructor():
      pass
    def MoveTo(v as single, t as single):
      _target = v
      if t <= 0.0f:
        _value = _target
        _accel = 0.0f
      else:
        _accel = (_target - _value) / t
    def Update(dt as single):
      _value += _accel * dt
      if (_accel < 0.0f and _value <= _target) or (_accel > 0.0f and _value >= _target):
        _value = _target
        _accel = 0.0f
    value:
      get:
        return _value
    isFinished:
      get:
        return _accel == 0.0f

  class EaseAngle ():
    private _angle as single = 0.0f
    private _target as single = 0.0f
    private _accel as single = 0.0f
    private _tick as single = 0.0f
    def constructor():
      pass
    def RotateTo(v as single, t as single):
      _target = v
      if t <= 0.0f:
        _angle = _target
        _accel = 0.0f
        _tick = 1.0f
      else:
        _accel = 1.0f / t
        _tick = 0.0f
    def Update(dt as single):
      _tick = Mathf.Min(_tick + _accel * dt, 1.0f)
      if _tick >= 1.0f:
        _angle = _target
        _accel = 0.0f
        _tick = 1.0f
      else:
        _angle = Math.LerpAngleDeg(_angle, _target, _tick)
    angle:
      get:
        return _angle
    isFinished:
      get:
        return _accel == 0.0f


