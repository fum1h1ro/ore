namespace ore
import UnityEngine

class App (MonoBehaviour): 
  static private _instance as App = null
  //
  class State ():
    _app as App
    _name as string
    _frameCount = 0
    _timer = 0.0f
    def constructor(n as string):
      _name = n
    def App[of T]():
      return _app as T
    app:
      get:
        return _app
      internal set:
        _app = value
    internal def _initialize():
      TLog.Output("${_name}.Initialize")
      Initialize()
    internal def _finalize():
      Finalize()
      TLog.Output("${_name}.Finalize")
    internal def _update():
      Update()
    virtual def Initialize():
      pass
    virtual def Finalize():
      pass
    virtual def Update():
      pass
  //
  _requestFile = List[of string]()
  _loadedFile = Dictionary[of string, (byte)]()
  _states = Dictionary[of string, callable]()
  _state as State = null
  _stateNext as string = null
  stateNext:
    get:
      return _stateNext
    set:
      _stateNext = value
  instance:
    get:
      return _instance
  static public def LoadFile(filename as string):
    _instance._requestFile.Add(filename)
  static public def UnloadFile(filename as string):
    _instance._loadedFile.Remove(filename)
  static public def IsFileLoaded(filename as string):
    return _instance._loadedFile.ContainsKey(filename)
  static public def GetFile(filename as string):
    return _instance._loadedFile[filename]
  //
  def Awake():
    assert _instance == null
    _instance = self
    ifdef UNITY_EDITOR:
      QualitySettings.vSyncCount = 0
    ifdef not UNITY_EDITOR:
      QualitySettings.vSyncCount = 1
      Application.targetFrameRate = 60
      TLog.Output('START')
    StartCoroutine(proc_loader())
  //
  def OnDestroy():
    assert _instance != null
    _instance = null
  //
  def Start():
    pass
  //
  def Update():
    proc_state()
  //
  def Register(name as string, factory as callable):
    _states[name] = factory
  //
  def proc_state():
    if _state == null and not string.IsNullOrEmpty(_stateNext):
      _state = _states[_stateNext]()
      _stateNext = null
      _state.app = self
      _state._initialize()
    if _state != null:
      _state._update()
    if not string.IsNullOrEmpty(_stateNext):
      if _state != null:
        _state._finalize()
        _state = null
  def proc_loader() as IEnumerator:
    while true:
      if _requestFile.Count > 0:
        filename = _requestFile[0]
        _requestFile.RemoveAt(0)
        util.Log("LOADFILE: ${filename}")
        www as WWW = null
        if DebugMenu.isAlive and DebugMenu.instance.connected:
          ifdef UNITY_EDITOR:
            www = WWW("http://127.0.0.1:${DebugMenu.PORT}/${filename}")
          ifdef not UNITY_EDITOR:
            www = WWW("http://192.168.0.${_addr}:${DebugMenu.PORT}/${filename}")
        else:
          www = WWW("file://${Application.streamingAssetsPath}/${filename}")
        yield www
        if string.IsNullOrEmpty(www.error):
          util.Log("LOADED: ${filename}")
          _loadedFile[filename] = www.bytes
        else:
          util.Log(www.error)
      yield WaitForSeconds(1)

