namespace ore
import UnityEngine
import System.Collections
import System.IO
import System.Runtime.Serialization
import System.Runtime.Serialization.Formatters.Binary

//namespace 
// デバッグメニュー基底
class DebugMenu (MonoBehaviour):
  public static final PORT = 6456
  static _instance as DebugMenu = null
  _silentMode as bool = false
  _buttonRect as Rect
  _touched as single
  _menuRect as Rect
  _boxStyle as GUIStyle = null
  _windowStyle as GUIStyle = null
  _valueStyle as GUIStyle = null
  _buttonStyle as GUIStyle = null
  _delegatefunction as GUI.WindowFunction
  _windowTitle as string
  _addr = 0
  _connected = false
  _confirmString as (string)
  _confirmFunction as (callable)
  static final kRETINA_W = 640.0f
  static final kRETINA_H = 1136.0f
  static final kBUTTON_SIZE = 96.0f
  static final kASPECT_RATIO = kRETINA_W / kRETINA_H
  _state as callable = null
  _stateNext as callable = null
  public stateNext:
    set:
      _stateNext = value
  _first as bool = false
  _interp as single
  _tabs = List[of Tab]()
  _selectTab = -1
  _bakScale = 1.0f
  _textures = array(Texture2D, 2)
  //
  public _permanent = false
  public _valueStyleFG as Color = Color(1, 1, 1, 1)
  public _valueStyleBG as Texture2D
  //
  buttonWidth:
    get:
      return _buttonRect.width
  buttonHeight:
    get:
      return _buttonRect.height
  halfButtonWidth:
    get:
      return _buttonRect.width * 0.5f
  halfButtonHeight:
    get:
      return _buttonRect.height * 0.5f
  menuWindowRect:
    get:
      return _menuRect
    set:
      _menuRect = value
  delegate as GUI.WindowFunction:
    set:
      _delegatefunction = value
  windowTitle:
    get:
      return _windowTitle
    set:
      _windowTitle = value
  addr:
    get:
      return _addr
    set:
      _addr = value
  connected:
    get:
      return _connected
    set:
      _connected = value
  isWakeup:
    get:
      return _state != state_button
  static public instance:
    get:
      return _instance
  static public isAlive:
    get:
      return _instance != null
  static public def Wakeup():
    _instance.stateNext = _instance.state_wakeup
  // タブ
  public abstract class Tab ():
    _menu as DebugMenu
    _name as string
    _priority as ushort = 1000
    _order as ushort = 0
    menu:
      get:
        return _menu
      internal set:
        _menu = value
    name:
      get:
        return _name
    priority:
      get:
        return _priority
      set:
        _priority = value
    order:
      get:
        return _order
      internal set:
        _order = value
    sortOrder:
      get:
        return (_priority cast uint << 16) | (_order cast uint)
    def constructor(n as string):
      _name = n
    public virtual def Init():
      pass
    public virtual def Start():
      pass
    public virtual def Stop():
      pass
    public virtual def Execute():
      GUILayout.Label(name)
  //
  def Awake():
    if _permanent:
      DontDestroyOnLoad(gameObject)
    if Debug.isDebugBuild and _instance == null:
      _instance = self
      w = Screen.width / 15.0f
      h = Screen.height / 15.0f
      sz = Mathf.Max(w, h)
      stateNext = state_button
      _buttonRect = Rect(0, 0, sz, sz)
      _touched = 0.0f
      _menuRect = Rect(0, 0, Screen.width, Screen.height * 0.9f)
      _delegatefunction = DefaultDelegate
      windowTitle = "DEBUG MENU"
      _addr = PlayerPrefs.GetInt('DebugMenu.IPADDR', 0)
      //DontDestroyOnLoad(gameObject)
      make_textures()
      default_tabs()
      StartCoroutine(proc_server())
    else:
      Destroy(gameObject);
  def OnDestroy():
    if _instance == self:
      PlayerPrefs.SetInt('DebugMenu.IPADDR', _addr)
      _instance = null
  def Start():
    util.Log("super.Start()")
  def default_tabs():
    AddTab(LogTab("LOG"))
    AddTab(ServerTab("SERVER"))
    AddTab(SystemTab("SYS"))
  def AddTab(t as Tab):
    t.order = _tabs.Count
    t.menu = self
    _tabs.Add(t)
    sort_tabs()
    t.Init()
  def sort_tabs():
    _tabs.Sort({a as Tab, b as Tab|(-1 if a.sortOrder < b.sortOrder else 1)})
  def DefaultDelegate(id as int):
    if _tabs.Count > 0:
      oldtab = _selectTab
      tabtitle = array(string, _tabs.Count)
      for i in range(_tabs.Count):
        t = _tabs[i]
        tabtitle[i] = t.name
      if tabtitle.Length > 4:
        _selectTab = GUILayout.SelectionGrid(_selectTab, tabtitle, 4, _boxStyle)
      else:
        _selectTab = GUILayout.Toolbar(_selectTab, tabtitle, _boxStyle)
      GUILayout.Space(Screen.height * 0.01f)
      if oldtab != _selectTab:
        _tabs[oldtab].Stop() if oldtab >= 0
        _tabs[_selectTab].Start() if _selectTab >= 0
      _tabs[_selectTab].Execute()
  def Shutdown():
    stateNext = state_shutdown
  def Confirm(lstr as string, lfunc as callable, rstr as string, rfunc as callable):
    stateNext = state_confirm
    _confirmString = array(string, 2)
    _confirmFunction = array(typeof(callable), 2)
    _confirmString[0] = (lstr if lstr != null else 'CANCEL')
    _confirmString[1] = (rstr if rstr != null else 'OK')
    _confirmFunction[0] = lfunc
    _confirmFunction[1] = rfunc





  def OnGUI():
    make_style()
    if _stateNext != null:
      _first = true
      _state = _stateNext
      _stateNext = null
    _state()
    _first = false
  def state_button():
    if _first:
      util.Log("BUTTON")
    e = Event.current
    //if (e.type != EventType.Used)
    if _touched == 0.0f:
      if e.type == EventType.MouseDown and _buttonRect.Contains(e.mousePosition):
        _touched += Time.deltaTime
        e.Use()
      else:
        AdjustRect()
    else:
      _touched += Time.deltaTime;
      if _touched < 0.5f:
        if e.type == EventType.MouseUp:
          if _buttonRect.Contains(e.mousePosition):
            stateNext = state_wakeup
          _touched = 0.0f
      else:
        // move
        _buttonRect.x = e.mousePosition.x - _buttonRect.width * 0.5f
        _buttonRect.y = e.mousePosition.y - _buttonRect.height * 0.5f
        if e.type == EventType.MouseUp:
          _touched = 0.0f
      if e.isMouse:
        e.Use()
    LimitRect()
    RenderButton() unless _silentMode
  def state_wakeup():
    if _first:
      util.Log("WAKEUP")
      _interp = 0.0f
      _bakScale = AppTime.GetScale(0)
      AppTime.SetScale(0, 0.0f)
    rc = LerpRect(_buttonRect, _menuRect, _interp)
    _interp += (1.0f / 0.25f) * Time.deltaTime
    if _interp >= 1.0f:
      stateNext = state_delegate
    rc = GUI.Window(0, rc, _delegatefunction/*DefaultDelegate*/, _windowTitle)
    //rc = GUI.Window(0, rc, DefaultDelegate, _windowTitle);
  def state_shutdown():
    if _first:
      util.Log("SHUTDOWN")
      _interp = 0.0f
      AppTime.SetScale(0, _bakScale)
    rc = LerpRect(_menuRect, _buttonRect, _interp)
    _interp += (1.0f / 0.25f) * Time.deltaTime
    if _interp >= 1.0f:
      stateNext = state_button
    rc = GUI.Window(0, rc, _delegatefunction/*DefaultDelegate*/, _windowTitle)
    //rc = GUI.Window(0, rc, DefaultDelegate, _windowTitle);
  def state_delegate():
    e = Event.current
    if e.type == EventType.MouseDown and not _menuRect.Contains(e.mousePosition):
      Shutdown()
      e.Use()
    _menuRect = GUI.Window(0, _menuRect, _delegatefunction, _windowTitle)//, _windowStyle)
  def state_confirm():
    buttonwidth = Screen.width / 2
    buttonheight = Screen.height / 15
    GUILayout.BeginHorizontal()
    if GUILayout.Button(_confirmString[0], GUILayout.Width(buttonwidth), GUILayout.Height(buttonheight)):
      (_confirmFunction[0])() if _confirmFunction[0] != null
      stateNext = state_delegate
    elif GUILayout.Button(_confirmString[1], GUILayout.Width(buttonwidth), GUILayout.Height(buttonheight)):
      (_confirmFunction[1])() if _confirmFunction[1] != null
      stateNext = state_delegate
    GUILayout.EndHorizontal()
  def LerpRect(fromrc as Rect, to as Rect, t as single):
    rc = Rect(0, 0, 0, 0)
    rc.x = Mathf.Lerp(fromrc.x, to.x, t)
    rc.y = Mathf.Lerp(fromrc.y, to.y, t)
    rc.width = Mathf.Lerp(fromrc.width, to.width, t)
    rc.height = Mathf.Lerp(fromrc.height, to.height, t)
    return rc
  def LimitRect():
    w = buttonWidth
    h = buttonHeight
    _buttonRect.x = Mathf.Clamp(_buttonRect.x, 0.0f, Screen.width - w)
    _buttonRect.y = Mathf.Clamp(_buttonRect.y, 0.0f, Screen.height - h)
  def AdjustRect():
    x = _buttonRect.x + halfButtonWidth
    y = _buttonRect.y
    nx = (0.0f if x < Screen.width * 0.5f else Screen.width)
    ny = y
    _buttonRect.x += (nx - x) * 0.07f
    _buttonRect.y += (ny - y) * 0.07f
  def RenderButton():
    GUI.Box(_buttonRect, "DEBUG")//, _boxStyle)
    rc = _buttonRect
    rc.width *= 0.2f
    rc.height *= 0.2f
    rc.x += rc.width
    rc.y += rc.height
    if _connected:
      GUI.DrawTexture(rc, _textures[1])
    else:
      GUI.DrawTexture(rc, _textures[0])
  def make_style():
    if _windowStyle == null:
      _windowStyle = GUIStyle()
      _windowStyle.fontSize = 20
      _windowStyle.alignment = TextAnchor.MiddleCenter
      _windowStyle.normal.textColor = Color.white
      //_windowStyle.normal.background = Resources.LoadAssetAtPath[of Texture2D]('Assets/Texture/black.png')
    //
    if _boxStyle == null or _boxStyle.name == "":
      //fnt = _boxStyle.font
      _boxStyle = GUIStyle("button")
      //_boxStyle.font = fnt
      util.Log("FONTSIZE: ${_boxStyle.fontSize}")
      _boxStyle.fontSize = (Screen.width * 1.0f / 20.0f)//CalcVerticalInRetina(48.0f);
      util.Log("FONTSIZE: ${_boxStyle.fontSize}")
    //
    if _valueStyle == null:
      _valueStyle = GUIStyle()
      _valueStyle.fontSize = 20
      _valueStyle.alignment = TextAnchor.MiddleCenter
      _valueStyle.normal.textColor = _valueStyleFG
      _valueStyle.normal.background = _valueStyleBG//Resources.LoadAssetAtPath[of Texture2D]('Assets/Texture/black.png')
    //
    if _buttonStyle == null:
      _buttonStyle = GUIStyle('button')
      _buttonStyle.fontSize = Screen.height / 32.0f
  def make_textures():
    _textures[0] = create_texture(8, 8, Color.red)
    _textures[1] = create_texture(8, 8, Color.green)
  def create_texture(w as int, h as int, col as Color):
    tex = Texture2D(w, h, TextureFormat.ARGB32, false, false)
    for y in range(h):
      for x in range(w):
        tex.SetPixel(x, y, col)
    tex.Apply()
    return tex
  def tenkey(v as int, lo as int, hi as int) as int:
    buttonheight = Screen.height / 10
    buttons = (('7', '8', '9'), ('4', '5', '6'), ('1', '2', '3'), ('C', '0', '<'))
    vs = v.ToString()
    for column in buttons:
      GUILayout.BeginHorizontal()
      for str in column:
        if str == 'C':
          if GUILayout.Button(str, _buttonStyle, GUILayout.Height(buttonheight)):
            vs = '0'
        elif str == '<':
          if GUILayout.Button(str, _buttonStyle, GUILayout.Height(buttonheight)):
            l = vs.Length
            if l > 0:
              vs = vs.Remove(l - 1, 1)
              if string.IsNullOrEmpty(vs):
                vs = '0'
        else:
          if GUILayout.Button(str, _buttonStyle, GUILayout.Height(buttonheight)):
            vs = string.Concat(vs, str)
      GUILayout.EndHorizontal()
    v = int.Parse(vs)
    return Mathf.Clamp(v, lo, hi)
  def proc_server() as IEnumerator:
    laddr = System.Net.IPAddress.Parse(Network.player.ipAddress).ToString().Split((of char: char('.')), 4)
    Array.Resize[of string](laddr, 3)
    baseaddr = string.Join('.', laddr)
    //Debug.Log("baseaddr = ${baseaddr}")
    while true:
      //addr = 0
      //addr = int.Parse(_ipaddr) unless string.IsNullOrEmpty(_ipaddr)
      //Util.Log(addr)
      if 0 < _addr and _addr < 255:
        //Util.Log(int.Parse(_ipaddr))
        ifdef UNITY_EDITOR:
          www = WWW("http://127.0.0.1:${PORT}/api?ping")
        ifdef not UNITY_EDITOR:
          www = WWW("http://${baseaddr}.${_addr}:${PORT}/api?ping")
        yield www
        _connected = false
        if string.IsNullOrEmpty(www.error):
          //Util.Log(www.text)
          //s = MessagePackSerializer.Create[of System.Collections.Generic.Dictionary[of string, string]]()
          //h = s.Unpack(MemoryStream(www.bytes))
          //if h['result'] == 'ok':
          //  _connected = true
          if www.text == 'ok':
            _connected = true
      else:
        _connected = false
      yield WaitForSeconds(3)
  /*
  private Stream CreatePersistentDataStream(FileMode mode) {
      Stream stream = new FileStream(Application.persistentDataPath + "/debugmenu.bin", mode);
      return stream;
  }
  protected void Save(System.Object obj) {
      using (Stream stream = CreatePersistentDataStream(FileMode.Create)) {
          BinaryFormatter fmt = new BinaryFormatter();
          fmt.Serialize(stream, obj);
          stream.Close();
      }
  }
  protected System.Object Load() {
      System.Object obj;
      try {
          using (Stream stream = CreatePersistentDataStream(FileMode.Open)) {
              BinaryFormatter fmt = new BinaryFormatter();
              obj = fmt.Deserialize(stream);
          }
      }
      catch (FileNotFoundException e) {
          obj = null;
      }
      catch (SerializationException e) {
          obj = null;
      }
      return obj;
  }
  */




  //
  public class SystemTab (Tab):
    def constructor(n as string):
      super(n)
    public override def Execute():
      buttonheight = Screen.height / 15
      if GUILayout.Button("RELOAD", GUILayout.Height(buttonheight)):
        _menu.Confirm(null, null, null, reload)
    def reload():
      _menu.Shutdown()
      Application.LoadLevel(Application.loadedLevelName)
  //
  public class LogTab (Tab):
    _logpos = Vector2.zero
    _logs = List[of string]()
    def constructor(n as string):
      super(n)
    public override def Execute():
      _logpos = GUILayout.BeginScrollView(_logpos)
      txt = ''
      for s in _logs:
        txt += "${s}\n"
      GUILayout.Label(txt)
      GUILayout.EndScrollView()
  //
  public class ServerTab (Tab):
    def constructor(n as string):
      super(n)
    public override def Execute():
      GUILayout.Label("STATUS: ${('CONNECTED' if _menu.connected else 'DISCONNECTED')}")
      GUILayout.Label("IP ADDRESS: ${_menu.addr}")
      _menu.addr = _menu.tenkey(_menu.addr, 0, 254)
