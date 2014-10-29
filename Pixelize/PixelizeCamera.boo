import UnityEngine

//[ExecuteInEditMode()]
class PixelizeCamera (MonoBehaviour): 
  enum Layer:
    PIXEL
    NORMAL
    MAX
  enum UniformID:
    PIXEL_COLOR
    PIXEL_DEPTH
    NORMAL_COLOR
    NORMAL_DEPTH
    COLOR_REDUCTION_LEVEL
    MAX
  [System.Flags]
  enum Flag:
    NONE = 0
    RECREATE_MESH = (1<<0)
  static final VERTEX_COUNT = 4
  _pixelCamera as Camera
  _normalCamera as Camera
  _uniteCamera as Camera
  public _shader as Shader
  public _pixelWidth = 4
  public _pixelHeight = 4
  public _pixelizeLayer = 0
  public _uniteLayer = 31
  public _colorReductionLevel = 8
  _pixelSize as Vector2
  _normalSize as Vector2
  _flags = Flag.NONE
  _colorTextures = array(RenderTexture, Layer.MAX)
  _depthTextures = array(RenderTexture, Layer.MAX)
  _material as Material
  _transform as Transform
  _camera as Camera
  _mesh as Mesh
  _vertices as (Vector3)
  _colors as (Color)
  _uvs as (Vector2)
  _uvs2 as (Vector2)
  _indices as (int)
  _layerBak as int
  _clearFlagsBak as CameraClearFlags
  //
  _uniformID = array(int, UniformID.MAX)
  final _uniformTexts = (of string:
    "_PixelColor",
    "_PixelDepth",
    "_NormalColor",
    "_NormalDepth",
    "_ColorReductionLevel",
  )


  pixelWidth:
    get:
      return _pixelWidth
    set:
      _pixelWidth = value
  pixelHeight:
    get:
      return _pixelHeight
    set:
      _pixelHeight = value
  pixelizeLayer:
    get:
      return _pixelizeLayer
    set:
      _pixelizeLayer = value
  uniteLayer:
    get:
      return _uniteLayer
    set:
      _uniteLayer = value
  colorReductionLevel:
    get:
      return _colorReductionLevel
    set:
      _colorReductionLevel = value

  def Awake():
    initialize()
  def OnDestroy():
    finalize()
  def Start():
    pass
  def OnGUI():
    //return
    //if (!showBuffers) { return; }
    size = Vector2(Screen.width, Screen.height) / 2.0f
    y = 0.0f;
    for i in range(Layer.MAX cast int):
      if _colorTextures[i] != null:
        size = Vector2(_colorTextures[i].width * 0.25f, _colorTextures[i].height * 0.25f)
        GUI.DrawTexture(Rect(0, y, size.x, size.y), _colorTextures[i], ScaleMode.StretchToFill, false)
        //GUI.DrawTexture(Rect(size.x, y, size.x, size.y), _depthTextures[i], ScaleMode.ScaleToFit, false)
        y += size.y + 0.0f

  def Update():
    _flags |= Flag.RECREATE_MESH
    if _flags & Flag.RECREATE_MESH:
      update_mesh(_pixelSize, _normalSize, _colorTextures[0], _colorTextures[1])
      _flags &= ~Flag.RECREATE_MESH
    cl = (_colorReductionLevel if _colorReductionLevel >= 2 else 2) cast single
    _material.SetVector(_uniformID[UniformID.COLOR_REDUCTION_LEVEL cast int], Vector3(cl, 1.0f / cl, 0.0f))
    Graphics.DrawMesh(_mesh, Vector3(0, 0, 0), Quaternion.identity, _material, _uniteLayer, _uniteCamera)
    //_material.SetPass(0)
    //DrawFullscreenQuad(1.0f)

  def OnPreCull():
    _layerBak = _camera.cullingMask
    _camera.cullingMask = 0
    _uniteCamera.cullingMask = (1<<_uniteLayer)
  def OnPreRender():
    adjust_size()
    create_buffers()
    render_scene(_pixelCamera, Layer.PIXEL cast int, (1<<_pixelizeLayer), _pixelSize, true)
    render_scene(_normalCamera, Layer.NORMAL cast int, ~(1<<_pixelizeLayer), _normalSize, false)
    render_scene_normal(_uniteCamera, (1<<_uniteLayer))
    _clearFlagsBak = _camera.clearFlags
    _camera.clearFlags = CameraClearFlags.Nothing
  def OnPostRender():
    _camera.cullingMask = _layerBak
    _camera.clearFlags = _clearFlagsBak

  def render_scene(cam as Camera, layer as int, mask as int, sz as Vector2, scale as bool):
    cam.CopyFrom(_camera)
    cam.SetTargetBuffers(_colorTextures[layer].colorBuffer, _depthTextures[layer].depthBuffer)
    cam.cullingMask = mask
    cam.ResetAspect()
    cam.ResetProjectionMatrix()
    if scale:
      sca = _pixelWidth cast single / _pixelHeight cast single
      cam.pixelRect = Rect(0, 0, sz.x * sca, sz.y * (1.0f/sca))
    else:
      cam.pixelRect = Rect(0, 0, sz.x, sz.y)
    cam.Render()


  def render_scene_normal(cam as Camera, mask as int):
    cam.cullingMask = mask
    cam.backgroundColor = _camera.backgroundColor
    cam.Render()



  def initialize():
    _transform = transform
    _camera = GetComponent[of Camera]()
    create_material()
    setup_pixel_camera()
    setup_normal_camera()
    setup_unite_camera()
    create_mesh()
    adjust_size()
    _camera.enabled = true
  def finalize():
    delete_buffers()
  def setup_pixel_camera():
    _pixelCamera = create_camera("Pixel Camera", _transform)
    _pixelCamera.depth = _camera.depth - 4
  def setup_normal_camera():
    _normalCamera = create_camera("Normal Camera", _transform)
    _normalCamera.depth = _camera.depth - 1
  def setup_unite_camera():
    _uniteCamera = create_camera("Unite Camera", null)
    _uniteCamera.depth = _camera.depth + 100
    _uniteCamera.orthographic = true
    _uniteCamera.orthographicSize = 1
    _uniteCamera.transform.parent = null
    _uniteCamera.transform.position = Vector3(0, 0, -10)
    _uniteCamera.transform.rotation = Quaternion.identity

  def create_camera(name as string, parent as Transform):
    obj = GameObject(name)
    obj.transform.parent = parent
    cam = obj.AddComponent[of Camera]()
    cam.enabled = false
    //obj.hideFlags = HideFlags.HideAndDontSave
    return cam



  def create_material():
    _material = Material(_shader)
    for i in range(UniformID.MAX):
      _uniformID[i] = Shader.PropertyToID(_uniformTexts[i])

  def create_buffers():
    for i in range(Layer.MAX cast int):
      if _colorTextures[i] != null:
        RenderTexture.ReleaseTemporary(_colorTextures[i])
        _colorTextures[i] = null
      if _depthTextures[i] != null:
        RenderTexture.ReleaseTemporary(_depthTextures[i])
        _depthTextures[i] = null
    _colorTextures[Layer.PIXEL] = create_buffer(_pixelSize.x, _pixelSize.y, RenderTextureFormat.ARGB32)
    _colorTextures[Layer.NORMAL] = create_buffer(_normalSize.x, _normalSize.y, RenderTextureFormat.ARGB32)
    _depthTextures[Layer.PIXEL] = create_buffer(_pixelSize.x, _pixelSize.y, RenderTextureFormat.Depth)
    _depthTextures[Layer.NORMAL] = create_buffer(_normalSize.x, _normalSize.y, RenderTextureFormat.Depth)
    _material.SetTexture(_uniformID[UniformID.PIXEL_COLOR], _colorTextures[Layer.PIXEL])
    _material.SetTexture(_uniformID[UniformID.PIXEL_DEPTH] , _depthTextures[Layer.PIXEL])
    _material.SetTexture(_uniformID[UniformID.NORMAL_COLOR], _colorTextures[Layer.NORMAL])
    _material.SetTexture(_uniformID[UniformID.NORMAL_DEPTH], _depthTextures[Layer.NORMAL])

  def create_buffer(w as int, h as int, fmt as RenderTextureFormat):
    tex = RenderTexture.GetTemporary(w, h, 0, fmt, RenderTextureReadWrite.Default, 1)
    tex.generateMips = false
    tex.useMipMap = false
    tex.filterMode = FilterMode.Point
    return tex
  def delete_buffers():
    for i in range(Layer.MAX cast int):
      if _colorTextures[i] != null:
        RenderTexture.ReleaseTemporary(_colorTextures[i])
        _colorTextures[i] = null
      if _depthTextures[i] != null:
        RenderTexture.ReleaseTemporary(_depthTextures[i])
        _depthTextures[i] = null
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
  def adjust_size():
    pw = (_pixelWidth if _pixelWidth > 0 else 1)
    ph = (_pixelHeight if _pixelHeight > 0 else 1)
    _pixelSize.x = Screen.width / pw cast int
    _pixelSize.y = Screen.height / ph cast int
    _normalSize.x = Screen.width
    _normalSize.y = Screen.height
  //
  def update_mesh(size0 as Vector2, size1 as Vector2, tex0 as Texture, tex1 as Texture):
    //tw0 = tex0.width cast single
    //th0 = tex0.height cast single
    //tw1 = tex1.width cast single
    //th1 = tex1.height cast single
    //Debug.Log("${size0} / ${tw0},${th0}")
    //Debug.Log("${size1} / ${tw1},${th1}")
    vh = _uniteCamera.orthographicSize * 2.0f
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
    _uvs[1] = Vector2(0.0f, 1.0f)
    _uvs[2] = Vector2(1.0f, 1.0f)
    _uvs[3] = Vector2(1.0f, 0.0f)
    _uvs2[0] = Vector2(0.0f, 0.0f)
    _uvs2[1] = Vector2(0.0f, 1.0f)
    _uvs2[2] = Vector2(1.0f, 1.0f)
    _uvs2[3] = Vector2(1.0f, 0.0f)
    //_uvs[0] = Vector2(0.0f, 0.0f)
    //_uvs[1] = Vector2(0.0f, size0.y / th0)
    //_uvs[2] = Vector2(size0.x / tw0, size0.y / th0)
    //_uvs[3] = Vector2(size0.x / tw0, 0.0f)
    //_uvs2[0] = Vector2(0.0f, 0.0f)
    //_uvs2[1] = Vector2(0.0f, size1.y / th1)
    //_uvs2[2] = Vector2(size1.x / tw1, size1.y / th1)
    //_uvs2[3] = Vector2(size1.x / tw1, 0.0f)
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
    GL.Color(Color.red)
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








