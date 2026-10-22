
Option Explicit

Dim args, expected, shell, fso, scriptDir, ps1Path, cmd

Set args = WScript.Arguments
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

expected = "execute terminalv2.ps1"

' Get current folder
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
ps1Path = scriptDir & "\v2\terminalv2.ps1"

' Validate argument
If args.Count <> 1 Then
    ShowError
    WScript.Quit
End If

If LCase(args(0)) <> expected Then
    ShowError
    WScript.Quit
End If

' Check that the PowerShell terminal exists
If Not fso.FileExists(ps1Path) Then
    MsgBox "Script not found: " & ps1Path, 16, "Script Error"
    WScript.Quit
End If

' Launch PowerShell terminal
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File """ & ps1Path & """"

shell.Run cmd, 1, False

WScript.Quit

' Error message
Sub ShowError()
    MsgBox "Invalid command." & vbCrLf & _
           "Use:" & vbCrLf & _
           "    execute terminalv2.ps1", 16, "Terminal"
End Sub

