import UnityEngine

class LowResoCameraSupport (MonoBehaviour): 
  _width = 0
  _height = 0
  width:
    set:
      _width = value
  height:
    set:
      _height = value
  def OnPreRender():
    GL.Viewport(Rect(0, 0, _width, _height))

