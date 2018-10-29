

Public lRow As Long
Public lCol As Long
Public dsn As String

'this vba code loops through listed sheets to copy cells from old template to new template
'handles label changes of replaced, addc to r_deriv,a_deriv
'handles conversion of type to xmltype
'populates significant digits column based on displayformat
'populates source and sourcederivation columns based on origin column in old format
'populates methodtype column based on origin column
'caution: amateur version of vba code


Sub LoopThroughSheets()

    Dim sheets As Variant
    
    
    Windows("old.xlsx").Activate
    
'"AMH","AAE","ACM","ACMANA","AAQAVIS","AEX","AIE","ADV","AAB","APQ","AVS","ALBSAF","ALBBNSP","AQSBPI","ASI","ASLEFF","ASLBASE","ADPC","ALS","ADFDS","ADFCB"
    
    'sheets = Array("AMH", "AAE", "ACM", "ACMANA", "AAQAVIS", "AEX", "AIE", "ADV", "AAB", "APQ", "AVS", "ALBSAF", "ALBBNSP", "AQSBPI", "ASI", "ASLEFF", "ASLBASE", "ADPC", "ALS", "ADFDS", "ADFCB")
    sheets = Array("AAE", "AMH")
    
For Number = LBound(sheets) To UBound(sheets)
    Windows("old.xlsx").Activate
    dsn = sheets(Number)
    With Worksheets(sheets(Number))
        Worksheets(sheets(Number)).Select
        

        'Macro calls go here
        
        'Actual code goes here
        Call Copycolumns
        'MsgBox dsn
        
        
    End With
Next Number

Windows("new.xlsm").Activate
ActiveWorkbook.Save
End Sub


























'Method to identify the last non-filled row and column in a sheet


Sub Range_End_Method()

Dim sheetrange As Range
Dim mystring As String
'Finds the last non-blank cell in a single row or column

    
    'Find the last non-blank cell in column A(1)
    lRow = Cells(Rows.Count, 1).End(xlUp).Row
    
    'Find the last non-blank cell in row 1
    lCol = Cells(1, Columns.Count).End(xlToLeft).Column
           
    'MsgBox "last row: " & lRow & ", last column" & lCol
    
End Sub




Sub replacestrings()

Call Range_End_Method

Do While n <= lRow

    n = n + 1

'Set Methodtype column based on origin value in old format
    mystring = Trim(UCase(ActiveSheet.Range("C" & n).Value))


    If InStr(mystring, "DERIVE") Then ActiveSheet.Range("D" & n).Value = "Computation"
    
'Convert type to xmltype based on decimal precision
    If Trim(UCase(ActiveSheet.Range("I" & n).Value)) = "CHAR" Then ActiveSheet.Range("I" & n).Value = "text"

'Change replacec values to r_deriv

    ActiveSheet.Range("N" & n).Value = Replace(ActiveSheet.Range("N" & n).Value, "[replacec]", "[r_deriv]")
    ActiveSheet.Range("N" & n).Value = Replace(ActiveSheet.Range("N" & n).Value, "[addc]", "[a_deriv]")
       
       
'Check integer/float type
    tempval = UCase(Range("L" & n))
    If InStr(tempval, "DATE") Then datepresent = 1 Else: datepresent = 0
    
    decimalpresent = InStr(tempval, ".")
    lengthpostdec = Len(Mid(tempval, decimalpresent + 1))
    If lengthpostdec > 0 Then signficantdigit = Mid(tempval, decimalpresent + 1) Else: signficantdigit = ""
       
    'Range("I" & n).Value = decimalpresent
    'Range("J" & n).Value = lengthpostdec
    Range("K" & n).Value = signficantdigit
    
    If lengthpostdec > 0 Then Range("I" & n).Value = "float"
   
    If (decimalpresent > 0 And lengthpostdec = 0) Or (datepresent = 1) Then Range("I" & n).Value = "integer"
    
   
'Remove hyperlinks  - not working - will check later
    'ActiveSheet.Range("G" & n).Select
    'Selection.Hyperlinks.Delete
    

'Create new origin column based source values
'if length of source origin is 2 or source contain text contains 'SUPP' then origin will be set to 'SDTM'
'else if length of source origin is greater than 2 and value ne "CRF" or "Derived" then origin will be set to "ADaM"

    origsourcelength = Len(Range("Q" & n))
    origsourcevalue = UCase(Range("Q" & n))
    'Range("S" & n).Value = origsourcelength
    'Range("T" & n).Value = origsourcevalue
    
    
    If origsourcelength = 2 Or InStr(origsourcevalue, "SUPP") Then
        Range("C" & n).Value = "SDTM"
        Range("E" & n).Value = "SDTM." & Range("Q" & n)
        
    ElseIf origsourcelength > 2 And (Trim(origsourcevalue) <> "CRF" And Trim(origsourcevalue) <> "DERIVED") Then
        Range("C" & n).Value = "ADaM"
        Range("E" & n).Value = "ADaM." & Range("Q" & n)
        
    Else: Range("c" & n).Value = Range("q" & n).Value
    End If
    
 'Set Methodtype column based on origin value in old format

    If UCase(ActiveSheet.Range("C" & n).Value) = "DERIVED" Then ActiveSheet.Range("D" & n).Value = "Computation"
    
Loop

'Set column names and formatting in new workbook

    ActiveSheet.Range("A1").Value = "VariableName"
    ActiveSheet.Range("B1").Value = "VariableLabel"
    ActiveSheet.Range("C1").Value = "Origin"
    ActiveSheet.Range("D1").Value = "MethodType"
    ActiveSheet.Range("E1").Value = "SourceDerivation"
    ActiveSheet.Range("F1").Value = "ImplementationNotes"
    ActiveSheet.Range("G1").Value = "CodeListRef"
    ActiveSheet.Range("H1").Value = "NeedVLM"
    ActiveSheet.Range("I1").Value = "XMLDataType"
    ActiveSheet.Range("J1").Value = "Length"
    ActiveSheet.Range("K1").Value = "SignificantDigits"
    ActiveSheet.Range("L1").Value = "DisplayFormat"
    ActiveSheet.Range("M1").Value = "Mandatory"
    ActiveSheet.Range("N1").Value = "AMG162_20062004"
    ActiveSheet.Range("O1").Value = "Role"
    ActiveSheet.Range("P1").Value = "Xinrong comments"
    ActiveSheet.Range("Q1").Value = "Source_Origin"

    ActiveSheet.Range(Cells(1, 1), Cells(lRow, lCol)).Font.Name = "Arial"
    ActiveSheet.Range(Cells(1, 1), Cells(lRow, lCol)).Font.Size = 8
    ActiveSheet.Range(Cells(1, 1), Cells(lRow, lCol)).VerticalAlignment = xlTop
    ActiveSheet.Range(Cells(1, 1), Cells(lRow, lCol)).HorizontalAlignment = xlLeft
    ActiveSheet.Range(Cells(1, 1), Cells(lRow, lCol)).WrapText = True
    
    ActiveSheet.Range(Cells(1, 1), Cells(1, lCol)).Font.Bold = True
    
    ActiveSheet.Range(Cells(1, 1), Cells(lRow, lCol)).Borders.LineStyle = xlContinuous
    ActiveSheet.Range(Cells(1, 1), Cells(lRow, lCol)).Borders.Weight = xlThin
    
    If ActiveSheet.AutoFilterMode = True Then
    'Do Nothing
    Else
    ActiveSheet.Range(Cells(1, 1), Cells(1, lCol)).AutoFilter
    End If
    
End Sub


Sub Copycolumns()
'
' Macro3 Macro
'

'Delete the sheet in new workbook if it already exisits
'
Windows("new.xlsm").Activate
For Each delsheet In Worksheets
    If delsheet.Name = dsn Then
        Application.DisplayAlerts = False
        sheets(dsn).Delete
        Application.DisplayAlerts = True
    End If
Next

'    dsn = "AAE"
    
    Dim ws As Worksheet
    Set ws = ThisWorkbook.sheets.Add(After:= _
             ThisWorkbook.sheets(ThisWorkbook.sheets.Count))
    ws.Name = dsn
    
    Windows("old.xlsx").Activate
    sheets(dsn).Select
    
    On Error Resume Next
    sheets(dsn).ShowAllData
    On Error GoTo 0
    
    
    Windows("new.xlsm").Activate

    sheets(dsn).Select
    
    Windows("old.xlsx").Activate
    Columns("A:A").Select
    Selection.Copy
    
    Windows("new.xlsm").Activate
    Columns("A:A").Select
    Selection.PasteSpecial Paste:=xlPasteAllUsingSourceTheme
    
    
    Windows("old.xlsx").Activate
    Columns("B:B").Select
    Selection.Copy
    
    Windows("new.xlsm").Activate
    Columns("B:B").Select
    Selection.PasteSpecial Paste:=xlPasteAllUsingSourceTheme


    Windows("old.xlsx").Activate
    Columns("G:G").Select
    Selection.Copy
    
    Windows("new.xlsm").Activate
    Columns("Q:Q").Select
    Selection.PasteSpecial Paste:=xlPasteAllUsingSourceTheme
    
    
    Windows("old.xlsx").Activate
    Columns("C:C").Select
    Selection.Copy
    
    Windows("new.xlsm").Activate
    Columns("E:E").Select
    Selection.PasteSpecial Paste:=xlPasteAllUsingSourceTheme
    
    Windows("old.xlsx").Activate
    Columns("D:D").Select
    Selection.Copy
    
    Windows("new.xlsm").Activate
    Columns("G:G").Select
    Selection.PasteSpecial Paste:=xlPasteAllUsingSourceTheme
    
    Windows("old.xlsx").Activate
    Columns("E:E").Select
    Selection.Copy
    
    Windows("new.xlsm").Activate
    Columns("I:I").Select
    Selection.PasteSpecial Paste:=xlPasteAllUsingSourceTheme
    
    Windows("old.xlsx").Activate
    Columns("H:H").Select
    Selection.Copy
    
    Windows("new.xlsm").Activate
    Columns("J:J").Select
    Selection.PasteSpecial Paste:=xlPasteAllUsingSourceTheme
    
    Windows("old.xlsx").Activate
    Columns("I:I").Select
    Selection.Copy
    
    Windows("new.xlsm").Activate
    Columns("L:L").Select
    Selection.PasteSpecial Paste:=xlPasteAllUsingSourceTheme
    
    Windows("old.xlsx").Activate
    Columns("J:J").Select
    Selection.Copy
    
    Windows("new.xlsm").Activate
    Columns("N:N").Select
    Selection.PasteSpecial Paste:=xlPasteAllUsingSourceTheme
    
    Windows("old.xlsx").Activate
    Columns("F:F").Select
    Selection.Copy
    
    Windows("new.xlsm").Activate
    Columns("O:O").Select
    Selection.PasteSpecial Paste:=xlPasteAllUsingSourceTheme
    
    Windows("old.xlsx").Activate
    Columns("K:K").Select
    Selection.Copy
    
    Windows("new.xlsm").Activate
    Columns("P:P").Select
    Selection.PasteSpecial Paste:=xlPasteAllUsingSourceTheme
    

    Call replacestrings
    
    Range("A1").Select
    

   
End Sub





Sub scan_test()

Dim list As Variant
Dim fromsheet As String
Dim tosheet As String
Dim tempval As String

list = Array("A~B", "C~D")
For i = LBound(list) To UBound(list)
    tempval = list(i)
    fromsheet = Split(tempval, "~")(0)
    tosheet = Split(tempval, "~")(1)
    MsgBox "From: " & fromsheet
    MsgBox "To: " & tosheet
    

Next i


End Sub
