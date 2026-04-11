Attribute VB_Name = "Module1"
Sub Скругленныйпрямоугольник1_Щелчок()

Dim Key As Variant
Dim Item As Object
Dim Row As Long
Dim col As Long
Dim colA As Long
Dim ID As String
Dim dtBegin As String
Dim dtEnd As String
Dim response As Variant
Dim ds As String
Dim cnt As Long

Dim JsonObject As Object

Dim shell As Object
Set shell = CreateObject("WScript.Shell")

' Set the worksheet where data will be written
Set ws = ThisWorkbook.Sheets("Source") ' Change to your sheet name

Dim curlCommand As String

dt0 = Now ' yyyy-mm-dd

dt0 = ws.Cells(20, 2).Value ' 20 строка 2 колонка  - задаваемое время суток

'dt_1 = DateAdd("d", -1, dt0)
dt_1 = dt0

t2 = Format(dt_1, "yyyy-mm-dd%2023%3A59%3A59") ' yyyy-mm-(dd-1) 23:59:59
'MsgBox t2
t1 = Format(dt_1, "yyyy-mm-dd%2000%3A00%3A00") ' yyyy-mm-(dd-1) 00:00:00
'MsgBox t1

dtBegin = t1
dtEnd = t2

' Initialize row and column counters
cnt = 0
Row = 2 ' value вывод
For i = 2 To 2
    
    ' из колонки A читаем id
    colA = 1
    ID = ws.Cells(i, colA).Value
    
    curlCommand = "http://172.12.0.110:8080/rsdu/archives/api/v1.0/Values?"
    
    ' формируем строку запроса
    curlCommand = curlCommand + "tableId=29" ' 29 электрический режим
    curlCommand = curlCommand + "&paramId=" + ID
    curlCommand = curlCommand + "&typeAlias=GLT_ANALOG_OPT_AVGHOUR"  ' тип получаемого архива
    curlCommand = curlCommand + "&dtBegin=" + dtBegin
    curlCommand = curlCommand + "&dtEnd=" + dtEnd

    Set xhttp = CreateObject("WinHttp.WinHttpRequest.5.1")
    xhttp.Open "GET", curlCommand, False
    xhttp.SetRequestHeader "accept", "text/plain"
    xhttp.SetRequestHeader "Authorization", "Basic YWRtaW46cGFzc21l"
    xhttp.Send
     
    If xhttp.Status = 200 Then
      
      response = xhttp.ResponseText
      'MsgBox response
    
      ' Parse JSON
      Set JsonObject = JsonConverter.ParseJson(response)
    
      ' Write data to Excel sheet
      ' Row = 1
      col = 3 ' вывод value делаем из C
      For Each Item In JsonObject
        ds = Item("time")
        If InStr(ds, ":00:00Z") > 0 Then
          ws.Cells(Row, col).Value = Item("value")
          col = col + 1
        End If
      Next Item
      
      cnt = cnt + 1
    
    End If
    
    Row = Row + 1
Next i

If cnt > 0 Then
  MsgBox "Успешно получены данные для " & cnt & " параметров."
Else
  MsgBox "Данные из РСДУ не загружены"
End If


End Sub
