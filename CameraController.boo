namespace ore
import UnityEngine

class CameraController (MonoBehaviour): 
  class CameraPosture ():
    _pos as Vector3
    _rot as Quaternion
    _fovy as single
    public def constructor(cam as Camera):
      _pos = cam.transform.position
      _rot = cam.transform.rotation
      _fovy = cam.fieldOfView
    public def apply(cam as Camera):
      cam.transform.position = _pos
      cam.transform.rotation = _rot
      cam.fieldOfView = _fovy
  static _campos as CameraPosture = null

  enum Mode:
    Free // カメラ位置とカメラ回転で決まる
    LookAt // カメラ位置と注視点位置で決まる
    Relative // 注視点位置とそこからの相対回転で決まる(未サポート)
  enum Element:
    Position // カメラ位置(Mode.Free時に有効。Mode.LookAt/Mode.Relative時は算出される
    Relation // カメラのターゲットからの相対位置(Mode.Relative時に有効
    Rotation // カメラ回転(Mode.Free時に有効
    Target // ターゲット位置(Mode.LookAt/Mode.Relative時に有効
    FieldOfView
    Max
  enum Value:
    Begin
    Now
    End
    Max
  class Param ():
    public position as Vector3
    public relation as Vector3
    public rotation as Quaternion
    public target as Vector3
    public fieldOfView as single
    public mode = Mode.Free
    def Dump():
      ifdef UNITY_EDITOR:
        Debug.Log("${mode}: ${position} / ${rotation}")


  //_imode as InterpolateMode = InterpolateMode.Linear
  _itor = array(typeof(util.Math.Interpolator), Element.Max)
  _params = array(typeof(Param), Value.Max)
  _camera as Camera = null
  _upVector = Vector3(0, 1, 0)

  def Awake():
    initialize()
  def Start():
    pass
  def Update():
    update_interpolator()
  def ForceUpdate():
    update_interpolator()
  def reset():
    if _campos != null:
      _campos.apply(Camera.main)
    initialize()
  def initialize():
    _camera = self.GetComponent[of Camera]()
    //if _campos == null:
    //  _campos = CameraPosture(Camera.main)
    for i in range(Element.Max):
      _itor[i] = util.Math.Interpolator()
    for i in range(Value.Max):
      _params[i] = Param()
      _params[i].fieldOfView = _camera.fieldOfView
    SetPosition(transform.position, 0.0f)
    SetRotation(transform.rotation, 0.0f)
    SetFieldOfView(_camera.fieldOfView, 0.0f)

  isFinished:
    get:
      return isPositionFinished and isRotationFinished and isFieldOfViewFinished and isTargetFinished
  isPositionFinished:
    get:
      return _itor[Element.Position].isFinished
  isRotationFinished:
    get:
      return _itor[Element.Rotation].isFinished
  isFieldOfViewFinished:
    get:
      return _itor[Element.FieldOfView].isFinished
  isTargetFinished:
    get:
      if _params[Value.Now].mode != Mode.Free:
        return _itor[Element.Target].isFinished
      return true
  def SetInterpolateMode(mode as util.Math.Interpolator.Mode):
    for i in range(Element.Max):
      _itor[i].mode = mode
  def Save() as Param:
    return util.ObjectClone(_params[Value.Now])
  def Restore(param as Param):
    pass

  private def calc_rotation(param as Param):
    if param.mode == Mode.Free:
      return param.rotation
    elif param.mode == Mode.LookAt:
      return Quaternion.LookRotation(param.target - param.position, _upVector)
    elif param.mode == Mode.Relative:
      return Quaternion.LookRotation(param.target - param.position, _upVector)
  static public def CalculateRelativePosition(pos as Vector3, xrot as single, yrot as single, dist as single):
    v = Vector3()
    v.x = Mathf.Cos(xrot * Mathf.Deg2Rad) * dist
    v.y = Mathf.Sin(xrot * Mathf.Deg2Rad) * dist
    v.z = 0.0f
    dist2 = v.x
    v.x = Mathf.Cos(-yrot * Mathf.Deg2Rad) * dist2
    v.z = Mathf.Sin(-yrot * Mathf.Deg2Rad) * dist2
    return v + pos
  private def calc_relative_pos(xrot as single, yrot as single, dist as single):
    return CalculateRelativePosition(Vector3.zero, xrot, yrot, dist)
  private def update_interpolator():
    update_target(Time.deltaTime)
    update_position(Time.deltaTime)
    update_rotation(Time.deltaTime)
    update_field_of_view(Time.deltaTime)
    apply()
  private def apply():
    //b = _params[Value.Begin]
    n = _params[Value.Now]
    //e = _params[Value.End]
    transform.position = n.position
    if n.mode != Mode.Free:
      n.rotation = calc_rotation(n)
    transform.rotation = n.rotation
    _camera.fieldOfView = n.fieldOfView
  //
  private def update_target(dt as single):
    _itor[Element.Target].Update(dt)
    b = _params[Value.Begin]
    n = _params[Value.Now]
    e = _params[Value.End]
    // オブジェクト追跡なら随時更新
    //if e.targetMode == kTARGET_OBJECT:
    //  e.target = e.obj_->GetCameraTargetPosition()
    if _itor[Element.Target].isFinished:
      //n.target += (e.target - n.target) * chase_speed_ * (2.0f / dt)
      pass
    else:
      x = _itor[Element.Target].value
      n.target = Vector3.Lerp(b.target, e.target, x)
    //_camera.SetTargetPosition(tgt);
  //
  private def update_position(dt as single):
    b = _params[Value.Begin]
    n = _params[Value.Now]
    e = _params[Value.End]
    //if e.mode == Mode.Relative:
    //  e.position = e.target + calc_relative_pos(e.relation.x, e.relation.y, e.relation.z)
    //if b.mode == Mode.Relative:
    //  b.position = b.target + calc_relative_pos(b.relation.x, b.relation.y, b.relation.z)
    // Relative同士なら角度で補間する
    if b.mode == Mode.Relative and e.mode == Mode.Relative:
      _itor[Element.Relation].Update(dt)
      x = _itor[Element.Relation].value
      n.relation.z = Mathf.Lerp(b.relation.z, e.relation.z, x)
      n.relation.x = util.Math.LerpAngleDeg(b.relation.x, e.relation.x, x)
      n.relation.y = util.Math.LerpAngleDeg(b.relation.y, e.relation.y, x)
      n.mode = Mode.Relative
    else:
      _itor[Element.Position].Update(dt)
      x = _itor[Element.Position].value
      n.position = Vector3.Lerp(b.position, e.position, x)
      if _itor[Element.Position].isFinished:
        n.mode = e.mode
      else:
        n.mode = Mode.Free
    if n.mode == Mode.Relative:
      n.position = n.target + calc_relative_pos(n.relation.x, n.relation.y, n.relation.z)

  private def update_rotation(dt as single):
    b = _params[Value.Begin]
    n = _params[Value.Now]
    e = _params[Value.End]
    // Free同士なら角度で補間する
    if b.mode == Mode.Free and e.mode == Mode.Free:
      _itor[Element.Rotation].Update(dt)
      x = _itor[Element.Rotation].value
      n.rotation = Quaternion.Slerp(b.rotation, e.rotation, x)
      n.mode = Mode.Free
    else:
      b.rotation = calc_rotation(b)
      e.rotation = calc_rotation(e)
      _itor[Element.Rotation].Update(dt)
      x = _itor[Element.Rotation].value
      n.rotation = Quaternion.Slerp(b.rotation, e.rotation, x)
      n.mode = e.mode

  private def update_field_of_view(dt as single):
    b = _params[Value.Begin]
    n = _params[Value.Now]
    e = _params[Value.End]
    _itor[Element.FieldOfView].Update(dt)
    x = _itor[Element.FieldOfView].value
    n.fieldOfView = Mathf.Lerp(b.fieldOfView, e.fieldOfView, x)


  // カメラ位置を設定します
  // Free/LookAt時はモードを維持するが、Relative時は強制的にLookAtになる
  def SetPosition(pos as Vector3, time as single):
    b = _params[Value.Begin]
    n = _params[Value.Now]
    e = _params[Value.End]
    restart_position()
    if time <= 0.0f:
      b.mode = e.mode = n.mode // 現在のモードを尊重する
      b.position = e.position = n.position = pos
      _itor[Element.Position].Reset()
    else:
      e.mode = n.mode // 現在のモードを継承する
      e.position = pos
      _itor[Element.Position].Start(time)
  position:
    get:
      return _params[Value.Now].position
    set:
      SetPosition(value, 0.0f)
  // カメラの回転を設定します
  // 強制的にFreeモードになります
  def SetRotation(rot as Quaternion, time as single):
    b = _params[Value.Begin]
    n = _params[Value.Now]
    e = _params[Value.End]
    if time <= 0.0f:
      b.mode = n.mode = e.mode = Mode.Free
      b.rotation = n.rotation = e.rotation = rot
      _itor[Element.Rotation].Reset()
    else:
      restart_rotation()
      e.mode = Mode.Free
      e.rotation = rot
      _itor[Element.Rotation].Start(time)
  rotation:
    get:
      return _params[Value.Now].rotation
    set:
      SetRotation(value, 0.0f)
  // 現在の位置から指定の位置へ注視点を移動させる
  // Free時は、強制的にLookAtになります
  def SetTarget(pos as Vector3, time as single):
    b = _params[Value.Begin]
    n = _params[Value.Now]
    e = _params[Value.End]
    restart_target()
    if time <= 0.0f:
      b.mode = e.mode = n.mode // 現在のモードを尊重する
      b.target = e.target = n.target = pos
      _itor[Element.Target].Reset()
    else:
      e.mode = n.mode
      e.target = pos
      _itor[Element.Target].Start(time)
  target:
    get:
      return _params[Value.Now].target
    set:
      SetTarget(value, 0.0f)
  // カメラ位置をターゲット位置からの相対指定にします
  // 強制的にRelativeになります
  def SetRelation(xrot as single, yrot as single, dist as single, time as single):
    b = _params[Value.Begin]
    n = _params[Value.Now]
    e = _params[Value.End]
    restart_relation(dist)
    if time <= 0.0f:
      b.mode = n.mode = e.mode = Mode.Relative
      b.relation = e.relation = n.relation = Vector3(xrot, yrot, dist)
      _itor[Element.Relation].Reset();
      //b.position = n.position = e.position = n.target + calc_relative_pos(n.relation.x, n.relation.y, n.relation.z)
    else:
      e.mode = Mode.Relative
      e.relation = Vector3(xrot, yrot, dist)
      _itor[Element.Relation].Start(time)
  // 
  def SetLookAt(pos as Vector3, tgt as Vector3, time as single):
    b = _params[Value.Begin]
    n = _params[Value.Now]
    e = _params[Value.End]
    if time <= 0.0f:
      b.mode = n.mode = e.mode = Mode.LookAt
      b.position = n.position = e.position = pos
      b.target = n.target = e.target = tgt
      _itor[Element.Position].Reset()
      _itor[Element.Target].Reset()
    else:
      restart_position();
      e.mode = Mode.LookAt
      e.position = pos
      e.target = tgt
      _itor[Element.Position].Start(time)
      _itor[Element.Target].Start(time)
  // 画角をセットする
  def SetFieldOfView(degree as single, time as single):
    b = _params[Value.Begin]
    n = _params[Value.Now]
    e = _params[Value.End]
    if time <= 0.0f:
      b.fieldOfView = n.fieldOfView = e.fieldOfView = degree
      _itor[Element.FieldOfView].Reset()
    else:
      restart_field_of_view()
      b.fieldOfView = n.fieldOfView
      e.fieldOfView = degree
      _itor[Element.FieldOfView].Start(time)
  fieldOfView:
    get:
      return _params[Value.Now].fieldOfView
    set:
      SetFieldOfView(value, 0.0f)





  // 現在のカメラ位置から再スタートをきるようにする
  private def restart_position():
    b = _params[Value.Begin]
    n = _params[Value.Now]
    //e = _params[Value.End]
    if n.mode == Mode.Free:
      pass
    elif n.mode == Mode.LookAt:
      pass
    elif n.mode == Mode.Relative:
      // @todo
      pass
    b.mode = n.mode
    b.position = n.position
  private def restart_rotation():
    b = _params[Value.Begin]
    n = _params[Value.Now]
    //e = _params[Value.End]
    if n.mode == Mode.Free:
      pass
    elif n.mode == Mode.LookAt:
      n.mode = Mode.Free
      n.rotation = Quaternion.LookRotation(n.target - n.position)
    elif n.mode == Mode.Relative:
      // @todo
      pass
    b.mode = n.mode
    b.rotation = n.rotation
  private def restart_target():
    b = _params[Value.Begin]
    n = _params[Value.Now]
    //e = _params[Value.End]
    if n.mode == Mode.Free:
      n.mode = Mode.LookAt
      n.target = n.position + n.rotation * Vector3(0, 0, 100) // @bug 距離適当過ぎるかも
    elif n.mode == Mode.LookAt:
      pass
    elif n.mode == Mode.Relative:
      pass
    b.mode = n.mode
    b.target = n.target
  private def restart_relation(d as single):
    b = _params[Value.Begin]
    n = _params[Value.Now]
    //e = _params[Value.End]
    if n.mode == Mode.Free:
      n.mode = Mode.Relative
      n.target = n.position + n.rotation * Vector3(0, 0, d)
      rel = Quaternion.LookRotation(n.position - n.target).eulerAngles
      n.relation = Vector3(rel.x, rel.y, d)
    elif n.mode == Mode.LookAt:
      n.mode = Mode.Relative
      d = Vector3.Distance(n.target, n.position)
      rel = Quaternion.LookRotation(n.position - n.target).eulerAngles
      n.relation = Vector3(rel.x, rel.y, d)
    elif n.mode == Mode.Relative:
      pass
    b.mode = n.mode
    b.relation = n.relation
  private def restart_field_of_view():
    b = _params[Value.Begin]
    n = _params[Value.Now]
    //e = _params[Value.End]
    b.fieldOfView = n.fieldOfView



