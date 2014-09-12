namespace ore.GoogleDrive
import UnityEngine

//
class Spreadsheet ():
  _worksheets = Dictionary[of string, Worksheet]()
  //
  def constructor():
    pass
  //
  def DecodeFromMsgPack(bin as (byte)):
    _worksheets.Clear()
    packer = MsgPack.BoxingPacker()
    list = packer.Unpack(bin) as IDictionary
    for itm in list:
      dic = itm cast DictionaryEntry
      //name = System.Text.Encoding.UTF8.GetString(dic.Key as (byte))
      name = encode(dic.Key)
      if (cols = dic.Value as (System.Object)) != null:
        _worksheets[name] = Matrix(name, cols)
      if (params = dic.Value as Dictionary[of System.Object, System.Object]) != null:
        _worksheets[name] = Tables(name, params)
  //
  private static def encode(b as (byte)) as string:
    return System.Text.Encoding.UTF8.GetString(b)
  //
  def Dump():
    for conf in _worksheets:
      if (tbl = conf.Value as Tables) != null:
        Debug.Log(tbl.keys)
        for k in tbl.keys:
          Debug.Log(k)
      Debug.Log(conf.Key)
//
class Worksheet ():
  _name as string
  name:
    get:
      return _name
  //
  def constructor(n as string):
    _name = n
  //
  protected static def encode(b as (byte)) as string:
    return System.Text.Encoding.UTF8.GetString(b)
//
class Tables (Worksheet):
  _values = Dictionary[of string, (string)]()
  values:
    get:
      return _values
  keys:
    get:
      return _values.Keys
  def constructor(n as string, src as Dictionary[of System.Object, System.Object]):
    super(n)
    for kv in src:
      header = System.Text.Encoding.UTF8.GetString(kv.Key)
      params = kv.Value as (System.Object)
      _values[header] = array(string, params.Length)
      //Debug.Log(header)
      for i in range(params.Length):
        _values[header][i] = encode(params[i])
        //Debug.Log(_values[header][i])
// 二次元配列
class Matrix (Worksheet):
  _values as (string, 2)
  _width as int
  _height as int
  values:
    get:
      return _values
  width:
    get:
      return _width
  height:
    get:
      return _height
  def constructor(n as string, cols as (System.Object)):
    super(n)
    _width = cols.Length
    _height = (cols[0] as (System.Object)).Length
    _values = matrix(string, _width, _height)
    for x in range(cols.Length):
      rows = cols[x] as (System.Object)
      for y in range(rows.Length):
        _values[x, y] = encode(rows[y])
        //Debug.Log("HOGE ${_values[x, y]}")
