import UnityEngine

//[ExecuteInEditMode()]
class PixelizeCamera (MonoBehaviour): 
  enum Layer:
    PIXEL
    NORMAL
    MAX
  [System.Flags]
  enum Flag:
    NONE = 0
    RECREATE_MESH = (1<<0)
  static final VERTEX_COUNT = 4
  public _pixelCamera as Camera
  _normalCamera as Camera
  public _shader as Shader
  public _widthScale = 4
  public _heightScale = 4
  _pixelSize as Vector2
  _normalSize as Vector2
  _flags = Flag.NONE
  //_width = 160
  //_height = 284
  _oldWidth = -1
  _oldHeight = -1
  _widthPow2 = 0
  _heightPow2 = 0
  _colorTextures as (RenderTexture)
  _depthTextures as (RenderTexture)
  _material as Material
  _transform as Transform
  _camera as Camera
  _mesh as Mesh
  _vertices as (Vector3)
  _colors as (Color)
  _uvs as (Vector2)
  _uvs2 as (Vector2)
  _indices as (int)
  _supportPixel as PixelizeCameraSupport
  _supportNormal as PixelizeCameraSupport
  [SerializeField]
  _pixelizeLayer as int


  pixelizeLayer:
    get:
      return _pixelizeLayer
    set:
      _pixelizeLayer = value

  def Awake():
    initialize()
  def OnDestroy():
    finalize()
  def Start():
    pass
  def OnGUI():
    //return
    //if (!showBuffers) { return; }
    size = Vector2(Screen.width, Screen.height) / 3.0f
    y = 5.0f;
    for i in range(Layer.MAX cast int):
      GUI.DrawTexture(Rect(5, y, size.x, size.y), _colorTextures[i], ScaleMode.ScaleToFit, false)
      //GUI.DrawTexture(Rect(size.x, y, size.x, size.y), _depthTextures[i], ScaleMode.ScaleToFit, false)
      y += size.y + 5.0f
    //GUI.DrawTexture(new Rect(5, y, size.x, size.y), rtComposite, ScaleMode.ScaleToFit, false);
    //y += size.y + 5.0f

  def Update():
    adjust_mesh()
    if _flags & Flag.RECREATE_MESH:
      update_mesh(_pixelSize, _normalSize, _colorTextures[0], _colorTextures[1])
      _flags &= ~Flag.RECREATE_MESH
    Graphics.DrawMesh(_mesh, Vector3(0, 0, 0), Quaternion.identity, _material, gameObject.layer, _camera)
    //_material.SetPass(0)
    //DrawFullscreenQuad(1.0f)

  def DelegateOnPreRender(support as PixelizeCameraSupport):
    if support == _supportPixel:
      layer = Layer.PIXEL cast int
      _pixelCamera.SetTargetBuffers(_colorTextures[layer].colorBuffer, _depthTextures[layer].depthBuffer)
      _pixelCamera.cullingMask = (1<<27)
      GL.Viewport(Rect(0, 0, _pixelSize.x, _pixelSize.y))
    elif support == _supportNormal:
      _normalCamera.CopyFrom(_pixelCamera)
      layer = Layer.NORMAL cast int
      _normalCamera.SetTargetBuffers(_colorTextures[layer].colorBuffer, _depthTextures[layer].depthBuffer)
      _normalCamera.cullingMask = ~(1<<27)
      GL.Viewport(Rect(0, 0, _normalSize.x, _normalSize.y))
  def DelegateOnPostRender(support as PixelizeCameraSupport):
    if support == _supportPixel:
      _normalCamera.Render() // again
    elif support == _supportNormal:
      pass



  def initialize():
    _transform = transform
    _camera = camera
    _pixelCamera = Camera.main if _pixelCamera == null
    create_camera()
    create_mesh()
    adjust_mesh()
    create_buffers()
    _supportPixel = override_main(_pixelCamera, _pixelSize.x, _pixelSize.y)
    _supportNormal = override_main(_normalCamera, _normalSize.x, _normalSize.y)
    _camera.enabled = true
  def finalize():
    delete_buffers()
    
  def override_main(cam as Camera, w as int, h as int):
    support = cam.gameObject.AddComponent[of PixelizeCameraSupport]()
    support.width = w
    support.height = h
    support.SetCamera(self)
    cam.depthTextureMode |= DepthTextureMode.Depth
    return support

  def create_camera():
    obj = GameObject("DummyCamera")
    _normalCamera = obj.AddComponent[of Camera]()
    _normalCamera.enabled = false
    obj.hideFlags = HideFlags.HideAndDontSave

  def create_buffers():
    _colorTextures = array(RenderTexture, Layer.MAX)
    _depthTextures = array(RenderTexture, Layer.MAX)
    _colorTextures[Layer.PIXEL cast int] = create_buffer(_pixelSize.x, _pixelSize.y, RenderTextureFormat.ARGB32)
    _colorTextures[Layer.NORMAL cast int] = create_buffer(_normalSize.x, _normalSize.y, RenderTextureFormat.ARGB32)
    _depthTextures[Layer.PIXEL cast int] = create_buffer(_pixelSize.x, _pixelSize.y, RenderTextureFormat.Depth)
    _depthTextures[Layer.NORMAL cast int] = create_buffer(_normalSize.x, _normalSize.y, RenderTextureFormat.Depth)
    _material = Material(_shader)
    _material.SetTexture("_PixelColor", _colorTextures[0])
    _material.SetTexture("_PixelDepth", _depthTextures[0])
    _material.SetTexture("_NormalColor", _colorTextures[1])
    _material.SetTexture("_NormalDepth", _depthTextures[1])

  def create_buffer(w as int, h as int, fmt as RenderTextureFormat):
    wp2 = Mathf.NextPowerOfTwo(w)
    hp2 = Mathf.NextPowerOfTwo(h)
    tex = RenderTexture(wp2, hp2, 0, fmt)
    tex.antiAliasing = 1
    tex.generateMips = false
    tex.useMipMap = false
    tex.filterMode = FilterMode.Point
    return tex
  def delete_buffers():
    for tex in _colorTextures:
      Destroy(tex)
    for tex in _depthTextures:
      Destroy(tex)
    Destroy(_material)
  //
  def create_mesh():
    _mesh = Mesh()
    _mesh.vertices = _vertices = array(Vector3, VERTEX_COUNT)
    _mesh.colors = _colors = array(Color, VERTEX_COUNT)
    _mesh.uv = _uvs = array(Vector2, VERTEX_COUNT)
    _mesh.uv2 = _uvs2 = array(Vector2, VERTEX_COUNT)
    _indices = array(int, VERTEX_COUNT)
    for i in range(VERTEX_COUNT):
      _indices[i] = i
    _mesh.SetIndices(_indices, MeshTopology.Quads, 0)
  //
  def adjust_mesh():
    if _normalSize.x != Screen.width or _normalSize.y != Screen.height:
      _pixelSize.x = Screen.width / _widthScale cast int
      _pixelSize.y = Screen.height / _heightScale cast int
      _normalSize.x = Screen.width
      _normalSize.y = Screen.height
      _flags |= Flag.RECREATE_MESH
  //
  def update_mesh(size0 as Vector2, size1 as Vector2, tex0 as Texture, tex1 as Texture):
    tw0 = tex0.width cast single
    th0 = tex0.height cast single
    tw1 = tex1.width cast single
    th1 = tex1.height cast single

    Debug.Log("${size0} / ${tw0}")
    Debug.Log("${size1} / ${th0}")

    vh = _camera.orthographicSize * 2.0f
    vw = vh * _camera.aspect
    hw = vw * 0.5f
    hh = vh * 0.5f
    _vertices[0] = Vector3(-hw, -hh, 0.0f)
    _vertices[1] = Vector3(-hw, hh, 0.0f)
    _vertices[2] = Vector3(hw, hh, 0.0f)
    _vertices[3] = Vector3(hw, -hh, 0.0f)
    _colors[0] = Color.white
    _colors[1] = Color.white
    _colors[2] = Color.white
    _colors[3] = Color.white
    _uvs[0] = Vector2(0.0f, 0.0f)
    _uvs[1] = Vector2(0.0f, size0.y / th0)
    _uvs[2] = Vector2(size0.x / tw0, size0.y / th0)
    _uvs[3] = Vector2(size0.x / tw0, 0.0f)
    _uvs2[0] = Vector2(0.0f, 0.0f)
    _uvs2[1] = Vector2(0.0f, size1.y / th1)
    _uvs2[2] = Vector2(size1.x / tw1, size1.y / th1)
    _uvs2[3] = Vector2(size1.x / tw1, 0.0f)
    _mesh.vertices = _vertices
    _mesh.colors = _colors
    _mesh.uv = _uvs
    _mesh.uv2 = _uvs2
  //
  static public def DrawFullscreenQuad(z as single):
    GL.PushMatrix()
    GL.LoadIdentity()
    GL.LoadOrtho()
    GL.Begin(GL.QUADS)
    GL.Color(Color.white)
    GL.Vertex3(-1.0f, -1.0f, z)
    GL.Vertex3(1.0f, -1.0f, z)
    GL.Vertex3(1.0f, 1.0f, z)
    GL.Vertex3(-1.0f, 1.0f, z)

    //GL.Vertex3(-1.0f, 1.0f, z)
    //GL.Vertex3(1.0f, 1.0f, z)
    //GL.Vertex3(1.0f, -1.0f, z)
    //GL.Vertex3(-1.0f, -1.0f, z)
    GL.End()
    GL.PopMatrix()
