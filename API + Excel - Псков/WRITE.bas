Attribute VB_Name = "Module3"

Sub Calculate_Скругленныйпрямоугольник1_Щелчок()
'

Dim step As Long
Dim i As Integer

Dim ID_SETS As String
Dim ID As String
Dim dt As Date
Dim szdt As String
Dim szdtU As String
Dim response As Variant

Dim szConnect As String
Dim cnt As Long
Dim ws As Object
Dim szSQL As String
Dim szData As Variant
Dim db As Object
Dim rsData As Object
Dim dtU As Object



' 1. Получаем ID суточного графика и dt-дату установки из Листа
' 2. Проверка на существование суточного графика : SELECT COUNT(*) FROM RSDUADMIN.HG_LIST WHERE ID=?ID?
' 3. получаем ID_SETS записи графика  SELECT ID FROM RSDUADMIN.HG_ANFTR WHERE ID_PARAM=?ID?
'      должен быть ID_FUNC = 2  ID_TARGET = 1
' 4. RSDUADMIN.HG_ANVAL - график суточный по умолчанию
'    RSDUADMIN.HG_ANVAL_DATE - график суточный по датам
' 5. Преобразовываем dt в UTC
' 6. Преобразовываем dt в unix-формат
' 7. проверяем, есть ли уже установленный график в таблице: SELECT COUNT(*) FROM RSDUADMIN.HG_ANVAL_DATE WHERE ID_SETS = ?ID_SETS? and R_DATE=?dt?
'    Если да - удаляем DELETE FROM RSDUADMIN.HG_ANVAL_DATE WHERE ID_SETS = ?ID_SETS? and R_DATE=?dt?
' 8. Вставляем в цикле INSERT INTO RSDUADMIN.HG_ANVAL_DATE (ID_SETS,SECONDS,VALUE,STATE,R_DATE) VALUES (ID_SETS,SECONDS,VALUE,0,dt)
'


'Build connection string
szConnect = "DSN=rsdupg; UID=rsduadmin;PWD=passme;database=rsdu" ' for pg
'szConnect = "Driver={PostgreSQL UNICODE}" _
'              & ";Server=" & Server _
'              & ";Port=" & Port _
'              & ";Database=" & DBName _
'              & ";Uid=" & UserId _
'              & ";Pwd=" & PWord & ";"

'szConnect = "DSN=rsdu2; UID=rsduadmin;PWD=passme " ' for oracle



' Set the worksheet where data will be written
Set ws = ThisWorkbook.Sheets("Calculate") ' Change to your sheet name

ID = ws.Cells(5, 2).Value ' 5 строка 2 (B) колонка     - id графика суточного
dt = ws.Cells(19, 2).Value ' 19 строка 2 (B) колонка  - дата

szdt = Format(dt, "dd.mm.yyyy")

response = MsgBox("Записать суточный график [" & ID & "] на дату " & szdt, vbOKCancel + vbExclamation + vbDefaultButton1)
Select Case response
  Case vbCancel
  Exit Sub
End Select


    On Error GoTo ErrorHandler
    
    Set db = CreateObject("ADODB.Connection")

    db.ConnectionTimeout = 15
    db.CommandTimeout = 45
    db.ConnectionTimeout = 15
    db.Mode = adModeReadWrite
    
    db.Open szConnect
    
    'creating rsData object
    Set rsData = CreateObject("ADODB.Recordset")
    szSQL = "SELECT COUNT(*) FROM RSDUADMIN.HG_LIST WHERE ID=" & ID
    'opening and reading data according to szSQL and db
    rsData.Open szSQL, db, 0
    'Outputing some data for more clarification
    szData = rsData.Fields(0).Value
    'cleaning the connection and data
    rsData.Close
    Set rsData = Nothing
  
    
    If szData = 0 Then
      MsgBox "Суточный график = [" & ID & "] не задан в БД"
    Else
      
      Set rsData = CreateObject("ADODB.Recordset")
      szSQL = "SELECT ID FROM RSDUADMIN.HG_ANFTR WHERE ID_PARAM=" & ID
      rsData.Open szSQL, db, 0, 1, 1
      ID_SETS = rsData.Fields(0).Value
      rsData.Close
      Set rsData = Nothing
      
      ' to UTC
      Set dtU = CreateObject("WbemScripting.SWbemDateTime")
      dtU.SetVarDate szdt ' Sets local time
      szdtU = dtU.GetVarDate(False) ' Returns as UTC (False = UTC, True = Local)
      'Example for EST (UTC-3): szdt = szdt + TimeSerial(3, 0, 0)
      'Example for CEST (UTC+3): szdt = szdt - TimeSerial(3, 0, 0)
      MsgBox "UTC=" & szdtU
      
      ' to unixtime
      'szdt = DateDiff("s", Now, dt)
      'szdt = (Format(dt, "dd/mm/yyyy") - #1/1/1970#) * 86400
      'szdt = DateDiff("s", #1/1/1970#, Format(DateAdd("d", -1, szdt), "dd/mm/yyyy"))
      szdtU = DateDiff("s", #1/1/1970#, Format(szdtU, "dd/mm/yyyy"))
      MsgBox "unixtime=" & szdtU

      Set rsData = CreateObject("ADODB.Recordset")
      szSQL = "SELECT COUNT(*) FROM RSDUADMIN.HG_ANVAL_DATE WHERE ID_SETS=" & ID_SETS & " AND R_DATE>=" & szdtU & " AND R_DATE<" & szdtU & "+(86400-3600+1)"
      rsData.Open szSQL, db, 0, 1, 1
      szData = rsData.Fields(0).Value
      rsData.Close
      Set rsData = Nothing

      If szData > 0 Then
        response = MsgBox("Суточный график [" & ID & "] на дату " & szdt & " уже задан. Задать новый?", vbOKCancel + vbExclamation + vbDefaultButton1)
        Select Case response
          Case vbCancel
           db.Close
           Set db = Nothing
          Exit Sub
        End Select
        Set rsData = CreateObject("ADODB.Recordset")
        szSQL = "DELETE FROM RSDUADMIN.HG_ANVAL_DATE WHERE ID_SETS=" & ID_SETS & " AND R_DATE>=" & szdtU & " AND R_DATE<" & szdtU & "+(86400-3600+1)"
        Set rsData = db.Execute(szSQL)
        Set rsData = Nothing
      End If
 
      cnt = 0
      step = 0 ' SECONDS
      For i = 0 To 23 Step 1
        
        ' 00:00
        Value = ws.Cells(6, 6 + i).Value ' начинаем с F
        Value = Replace(Value, ",", ".") ' меняем , на .
        Set rsData = CreateObject("ADODB.Recordset")
        szSQL = "INSERT INTO RSDUADMIN.HG_ANVAL_DATE (ID_SETS,SECONDS,VALUE,STATE,R_DATE) VALUES (" & ID_SETS & "," & step & "," & Value & ",0," & szdtU & ")"
        Set rsData = db.Execute(szSQL)
        Set rsData = Nothing
        cnt = cnt + 1
        
        ' 00:30
        step = step + 1800
        Value = ws.Cells(5, 6 + i).Value ' начинаем с F
        Value = Replace(Value, ",", ".") ' меняем , на .
        Set rsData = CreateObject("ADODB.Recordset")
        szSQL = "INSERT INTO RSDUADMIN.HG_ANVAL_DATE (ID_SETS,SECONDS,VALUE,STATE,R_DATE) VALUES (" & ID_SETS & "," & step & "," & Value & ",0," & szdtU & ")"
        Set rsData = db.Execute(szSQL)
        Set rsData = Nothing
        cnt = cnt + 1
      
        step = step + 1800
      Next i

      MsgBox "Установили значения суточного графика = [" & ID & "]- " & cnt & " значениями."
    End If
    

    db.Close
    Set db = Nothing
    
    Exit Sub
ErrorHandler:
    MsgBox (Err.Number & " " & Err.Description)
    
End Sub
