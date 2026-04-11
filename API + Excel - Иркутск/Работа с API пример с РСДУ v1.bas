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

Dim JsonObject As Object

Dim shell As Object
Set shell = CreateObject("WScript.Shell")

' Set the worksheet where data will be written
Set ws = ThisWorkbook.Sheets("Source") ' Change to your sheet name

Dim curlCommand As String

dtBegin = "2026-02-17%2000%3A00%3A00"
dtEnd = "2026-02-17%2023%3A59%3A59"

' Initialize row and column counters
Row = 2 ' value вывод
For i = 2 To 2
    
    ' из колонки A читаем id
    colA = 1
    ID = ws.Cells(i, colA).Value
    
    curlCommand = "curl -X GET ""http://172.12.0.110:8080/rsdu/archives/api/v1.0/Values?"
    ' формируем строку запроса
    curlCommand = curlCommand + "tableId=29" ' 29 электрический режим
    curlCommand = curlCommand + "&paramId=" + ID
    curlCommand = curlCommand + "&typeAlias=GLT_ANALOG_OPT_AVG5MIN"  ' тип получаемого архива
    curlCommand = curlCommand + "&dtBegin=" + dtBegin
    curlCommand = curlCommand + "&dtEnd=" + dtEnd + """ "
    curlCommand = curlCommand + " -H  ""accept: text/plain"" -H  ""Authorization: Basic YWRtaW46cGFzc21l"" "

    response = shell.Exec(curlCommand).StdOut.ReadAll()
    Set shell = Nothing
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
    
    Row = Row + 1
Next















End Sub
