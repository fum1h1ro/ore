import UnityEngine
import UnityEditor

[CustomEditor(PixelizeCamera)]
class PixelizeCameraInspector (Editor): 
  _target as PixelizeCamera
  def OnEnable():
    _target = target as PixelizeCamera
  def OnInspectorGUI():
    DrawDefaultInspector()
    oldlayer = _target.pixelizeLayer
    _target.pixelizeLayer = EditorGUILayout.LayerField("PixelizeLayer", _target.pixelizeLayer)
    if oldlayer != _target.pixelizeLayer:
      EditorUtility.SetDirty(target)
      Debug.Log("DIRTY")
