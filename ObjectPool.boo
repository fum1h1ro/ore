import UnityEngine
import System.Collections
import System.Collections.Generic

class ObjectPool (MonoBehaviour):
  // プール本体
  class Pool ():
    _prefab as GameObject = null
    _maxCount = 10
    _prepareCount = 0
    _objs = List[of GameObject]()
    _transform as Transform = null
    def constructor(obj as GameObject, trs as Transform):
      _prefab = obj
      _transform = trs
    prefab:
      get:
        return _prefab
    count:
      get:
        return _objs.Count
    maxCount:
      get:
        return _maxCount
      set:
        _maxCount = value
    prepareCount:
      get:
        return _prepareCount
      set:
        _prepareCount = Mathf.Min(value, _maxCount)
    private def destroy(obj as Object) as bool:
      Destroy(obj)
      return true
    internal def TruncateObjects():
      removecount = _objs.Count - _prepareCount
      _objs.RemoveAll({o|o == null})
      _objs.RemoveAll({o|not o.activeSelf and removecount-- > 0 and destroy(o)})
    def GetInstance() as GameObject:
      return GetInstance(_transform)
    def GetInstance(trs as Transform) as GameObject:
      _objs.RemoveAll({o|o == null})
      for obj in _objs:
        if obj.activeSelf == false:
          obj.SetActive(true)
          obj.transform.parent = trs
          return obj
      obj = create_instance()
      if obj != null:
        obj.SetActive(true)
        obj.transform.parent = trs
        return obj
      return null
    private def create_instance() as GameObject:
      if _objs.Count < _maxCount:
        obj = GameObject.Instantiate(_prefab) as GameObject
        obj.SetActive(false)
        _objs.Add(obj)
        return obj
      return null
    def PreWarm():
      if self.count < _prepareCount:
        for i in range(_prepareCount - self.count):
          create_instance()
    def OnDestroy():
      _objs.RemoveAll({o|destroy(o)})
      // @todo プールが消える時に、ここ出身のやつを全部殺すかどうかは判断しどころ

  private _pools = List[of Pool]()
  private _interval = 1.0f
  private static _instanceGameObject as GameObject = null
  private static _instance as ObjectPool = null
  private static final _objectName = '$$$ObjectPool'


  def OnEnable():
    if _interval > 0:
      StartCoroutine(remove_object_check())
  def OnDisable():
    StopAllCoroutines()
  def OnDestroy():
    return if _instanceGameObject == null
    for pool in _pools:
      pool.OnDestroy()

  public interval:
    get:
      return _interval
    set:
      if _interval != value:
        _interval = value
        StopAllCoroutines()
        if  _interval > 0:
          StartCoroutine(remove_object_check())
  private def remove_object_check() as IEnumerator:
    while true:
      for pool in _pools:
        pool.TruncateObjects()
      yield WaitForSeconds(_interval)
  private static def create_instance():
    _instanceGameObject = GameObject.Find(_objectName) if _instanceGameObject == null
    _instanceGameObject = GameObject(_objectName) if _instanceGameObject == null
    _instance = _instanceGameObject.AddComponent[of ObjectPool]() if _instance == null
  public static def GetPool(obj as GameObject) as Pool:
    create_instance()
    for pool in _instance._pools:
      if pool.prefab == obj:
        return pool
    newpool = Pool(obj, _instance.transform)
    _instance._pools.Add(newpool)
    return newpool
  public static def DestroyPool(pool as Pool):
    create_instance()
    _instance._pools.RemoveAll({p|p.prefab == pool.prefab})
