import UnityEngine
import UnityEditor

[CustomEditor(PixelizeCamera)]
class PixelizeCameraInspector (Editor): 
  _target as PixelizeCamera
  def OnEnable():
    _target = target as PixelizeCamera
  def OnInspectorGUI():
    sobj = serializedObject
    //DrawDefaultInspector()
    EditorGUILayout.PropertyField(sobj.FindProperty('_shader'))
    EditorGUILayout.HelpBox("Please specify 'ore/PixelizeCameraShader'", MessageType.Info)
    _target.pixelWidth = EditorGUILayout.IntSlider('Pixel Width', _target.pixelWidth, 1, 16)
    _target.pixelHeight = EditorGUILayout.IntSlider('Pixel Height', _target.pixelHeight, 1, 16)
    _target.pixelizeLayer = EditorGUILayout.LayerField('Pixelize Layer', _target.pixelizeLayer)
    _target.uniteLayer = EditorGUILayout.LayerField('Unite Layer', _target.uniteLayer)
    _target.colorReductionLevel = EditorGUILayout.IntSlider('Color Reduction Level', _target.colorReductionLevel, 2, 256)
    if GUI.changed:
      EditorUtility.SetDirty(target)
      //Debug.Log("DIRTY")
