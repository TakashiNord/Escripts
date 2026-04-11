Attribute VB_Name = "Module2"
Sub Прямоугольниксдвумяскругленнымипротиволежащимиуглами1_Щелчок()


Dim Row As Long
Dim RowK0 As Long
Dim col As Long
Dim cnt As Long
Dim ID As String
Dim K0 As String
Dim IPV As String
Dim IP1 As String
Dim IP2 As String
Dim IP0 As String
Dim strPath As String
Dim p As String
Dim pema As String
Dim response As Variant

Dim fs As Object
Set fs = CreateObject("Scripting.FileSystemObject")

Dim objShell As Object
Set objShell = CreateObject("WScript.Shell")

' Set the worksheet where data will be written
Set ws = ThisWorkbook.Sheets("Result") ' Change to your sheet name

pema = "R:\RSDU\ema.exe"
IPV = "172.12.0.29" ' виртуальный ip = ip1+ip2
IP1 = "172.12.0.30"
IP2 = "172.12.0.31"
p = "R:\RSDU\edmset.exe"


If (fs.FileExists(p) = False) Then
  MsgBox "Файл " & p & " для установки ручного ввода не доступен"
  Exit Sub
End If

' определяем IP мастера
IP0 = IP1
If (fs.FileExists(pema) = True) Then
  strPath = pema & " " & IP0
  response = objShell.Exec(strPath).StdOut.ReadAll()
  If (response = "SLAVE") Then
    IP0 = IP2
  End If
End If
'MsgBox "IP Основного ОИК-а = " & IP0

cnt = 0 ' количество установленных коэф
For i = 3 To 26
    
  ID = ""
  Row = 3 ' строка коэф
  K0 = ws.Cells(Row, i).Value
  K0 = Replace(K0, ",", ".") ' меняем , на .

  RowK0 = 1 ' если id K0 заданы в листе
  ID = ws.Cells(RowK0, i).Value
  
  'If i = 3 Then ID = "5215987"
  'If i = 4 Then ID = "5215989"
  ' и так далее
  'If i = 26 Then ID="xxxxxxxxx"

  If ID <> "" And K0 <> "" Then
    ' формируем строку для запуска
    strPath = "" & p & " " & IP0 & " 2132 " & ID & " admin passme " & K0 & ""
    'MsgBox strPath
    
    response = objShell.Exec(strPath).StdOut.ReadAll()
    If (response = "-7") Then
      lRetVal = MsgBox("Для параметра " & ID & " значение не установлено.", vbOKCancel + vbExclamation + vbDefaultButton1)
      Select Case lRetVal
        Case vbCancel
        Exit Sub
      End Select
    Else
      cnt = cnt + 1
    End If

  End If
    
Next i

Set objShell = Nothing

MsgBox "Установили значения ручного ввода для " & cnt & " коэффициентов."


End Sub
