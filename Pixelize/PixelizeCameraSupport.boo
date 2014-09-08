import UnityEngine

class PixelizeCameraSupport (MonoBehaviour): 
  _width = 0
  _height = 0
  _camera as PixelizeCamera
  width:
    set:
      _width = value
  height:
    set:
      _height = value
  def SetCamera(cam as PixelizeCamera):
    _camera = cam
  def OnPreRender():
    _camera.DelegateOnPreRender(self)
  def OnPostRender():
    _camera.DelegateOnPostRender(self)
