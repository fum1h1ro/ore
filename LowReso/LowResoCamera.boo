import UnityEngine

//[ExecuteInEditMode()]
class LowResoCamera (MonoBehaviour): 
  static final VERTEX_COUNT = 4
  public _mainCamera as Camera
  public _shader as Shader
  public _width = 160
  public _height = 284
  _oldWidth = -1
  _oldHeight = -1
  _widthPow2 = 0
  _heightPow2 = 0
  _renderTexture as RenderTexture
  _material as Material
  _camera as Camera
  _mesh as Mesh
  _vertices as (Vector3)
  _colors as (Color)
  _uvs as (Vector2)
  _indices as (int)
  _support as LowResoCameraSupport

  def Awake():
    _camera = GetComponent[of Camera]()
    _mainCamera = Camera.main if _mainCamera == null
    create_buffer()
    create_mesh()
    override_main()
  def OnDestroy():
    delete_buffer()
  def Start():
    pass
  def Update():
    update_mesh()
    _camera.orthographicSize = _height * 0.5f
    Graphics.DrawMesh(_mesh, Vector3(0, 0, 0), Quaternion.identity, _material, gameObject.layer, _camera)



  def override_main():
    _support = _mainCamera.gameObject.AddComponent[of LowResoCameraSupport]()
    _support.width = _width
    _support.height = _height
    _mainCamera.targetTexture = _renderTexture
    _camera.enabled = true


    //rc = _mainCamera.pixelRect
    //rc.width = _width
    //rc.height = _height
    //_mainCamera.pixelRect = rc
    //Debug.Log(_mainCamera.pixelRect)

  def create_buffer():
    _widthPow2 = Mathf.NextPowerOfTwo(_width)
    _heightPow2 = Mathf.NextPowerOfTwo(_height)
    _renderTexture = RenderTexture(_widthPow2, _heightPow2, 24, RenderTextureFormat.ARGB32)
    _renderTexture.antiAliasing = 1
    _renderTexture.generateMips = false
    _renderTexture.useMipMap = false
    _renderTexture.filterMode = FilterMode.Point
    _material = Material(_shader)
    _material.mainTexture = _renderTexture
  def delete_buffer():
    Destroy(_renderTexture)
    Destroy(_material)

  def create_mesh():
    _mesh = Mesh()
    _mesh.vertices = _vertices = array(Vector3, VERTEX_COUNT)
    _mesh.colors = _colors = array(Color, VERTEX_COUNT)
    _mesh.uv = _uvs = array(Vector2, VERTEX_COUNT)
    _indices = array(int, VERTEX_COUNT)
    for i in range(VERTEX_COUNT):
      _indices[i] = i
    _mesh.SetIndices(_indices, MeshTopology.Quads, 0)
  //
  def update_mesh():
    if _width != _oldWidth or _height != _oldHeight:
      tw = _material.mainTexture.width cast single
      th = _material.mainTexture.height cast single
      hw = _width * 0.5f
      hh = _height * 0.5f
      _vertices[0] = Vector3(-hw, -hh, 0.0f)
      _vertices[1] = Vector3(-hw, hh, 0.0f)
      _vertices[2] = Vector3(hw, hh, 0.0f)
      _vertices[3] = Vector3(hw, -hh, 0.0f)
      _colors[0] = Color.white
      _colors[1] = Color.white
      _colors[2] = Color.white
      _colors[3] = Color.white
      _uvs[0] = Vector2(0.0f, 0.0f)
      _uvs[1] = Vector2(0.0f, _height / th)
      _uvs[2] = Vector2(_width / tw, _height / th)
      _uvs[3] = Vector2(_width / tw, 0.0f)
      //_uvs[0] = Vector2(0.0f, 0.0f)
      //_uvs[1] = Vector2(0.0f, 1.0f)
      //_uvs[2] = Vector2(1.0f, 1.0f)
      //_uvs[3] = Vector2(1.0f, 0.0f)
      _mesh.vertices = _vertices
      _mesh.colors = _colors
      _mesh.uv = _uvs
      _oldWidth = _width
      _oldHeight = _height
