﻿; ####################################################################################################
; # This script merges PoE-ItemInfo and AdditionalMacros into one script and executes it.
; # We also have to set some global variables and pass them to the ItemInfo script. 
; # This is to support using ItemInfo as dependancy for other tools.
; ####################################################################################################
#Include, %A_ScriptDir%\resources\Version.txt

MsgWrongAHKVersion := "AutoHotkey v" . AHKVersionRequired . " or later is needed to run this script. `n`nYou are using AutoHotkey v" . A_AhkVersion . " (installed at: " . A_AhkPath . ")`n`nPlease go to http://ahkscript.org to download the most recent version."
If (A_AhkVersion < AHKVersionRequired)
{
    MsgBox, 16, Wrong AutoHotkey Version, % MsgWrongAHKVersion
    ExitApp
}

RunAsAdmin()
If (!PoEScripts_CreateTempFolder(A_ScriptDir, "PoE-ItemInfo")) {
	ExitApp	
}

/*	 
	Set ProjectName to create user settings folder in A_MyDocuments
*/
projectName				:= "PoE-ItemInfo"
FilesToCopyToUserFolder	:= ["\resources\config\default_config.ini", "\resources\ahk\default_AdditionalMacros.txt", "\resources\ahk\default_MapModWarnings.txt"]
overwrittenFiles 		:= PoEScripts_HandleUserSettings(projectName, A_MyDocuments, "", FilesToCopyToUserFolder, A_ScriptDir)
isDevelopmentVersion	:= PoEScripts_isDevelopmentVersion()
userDirectory			:= A_MyDocuments . "\" . projectName . isDevelopmentVersion

PoEScripts_CompareUserFolderWithScriptFolder(userDirectory, A_ScriptDir, projectName)

/*
	merge all scripts into `_ItemInfoMain.ahk` and execute it.
*/
info		:= ReadFileToMerge(A_ScriptDir "\resources\ahk\POE-ItemInfo.ahk")
addMacros := ReadFileToMerge(userDirectory "\AdditionalMacros.txt")

info		:= info . "`n`r`n`r"
addMacros	:= "#IfWinActive Path of Exile ahk_class POEWindowClass ahk_group PoEexe" . "`n`r`n`r" . addMacros
addMacros   .= AppendCustomMacros(userDirectory)

CloseScript("ItemInfoMain.ahk")
FileDelete, %A_ScriptDir%\_ItemInfoMain.ahk
FileCopy,   %A_ScriptDir%\resources\ahk\POE-ItemInfo.ahk, %A_ScriptDir%\_ItemInfoMain.ahk

FileAppend, %addMacros%	, %A_ScriptDir%\_ItemInfoMain.ahk

; set script hidden
FileSetAttrib, +H, %A_ScriptDir%\_ItemInfoMain.ahk
; pass some parameters to ItemInfo
Run "%A_AhkPath%" "%A_ScriptDir%\_ItemInfoMain.ahk" "%projectName%" "%userDirectory%" "%isDevelopmentVersion%" "%overwrittenFiles%"

ExitApp 


; ####################################################################################################
; # functions
; ####################################################################################################

CloseScript(Name)
{
	DetectHiddenWindows On
	SetTitleMatchMode RegEx
	IfWinExist, i)%Name%.* ahk_class AutoHotkey
		{
		WinClose
		WinWaitClose, i)%Name%.* ahk_class AutoHotkey, , 2
		If ErrorLevel
			Return "Unable to close " . Name
		Else
			Return "Closed " . Name
		}
	Else
		Return Name . " not found"
}

RunAsAdmin() 
{
    ShellExecute := A_IsUnicode ? "shell32\ShellExecute":"shell32\ShellExecuteA" 
    If Not A_IsAdmin 
    { 
		If A_IsCompiled 
			DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_ScriptFullPath, str, A_WorkingDir, int, 1) 
		Else 
			DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_AhkPath, str, """" . A_ScriptFullPath . """", str, A_WorkingDir, int, 1) 
		ExitApp 
    }
}

AppendCustomMacros(userDirectory)
{
	If(!InStr(FileExist(userDirectory "\CustomMacros"), "D")) {
		FileCreateDir, %userDirectory%\CustomMacros\
	}
	
	appendedMacros := "`n`n"
	extensions := "txt,ahk"
	Loop %userDirectory%\CustomMacros\*
	{
		If A_LoopFileExt in %extensions% 
		{
			FileRead, tmp, %A_LoopFileFullPath%
			appendedMacros .= "; appended custom macro file: " A_LoopFileName " ---------------------------------------------------"
			appendedMacros .= "`n" tmp "`n`n"
		}
	}
	
	Return appendedMacros
}

ReadFileToMerge(path) {
	If (FileExist(path)) {
		ErrorLevel := 0
		FileRead, file, %path%
		If (ErrorLevel = 1) {
			; file does not exist (should be caught already)
			Msgbox, 4096, Critical file read error, File "%path%" doesn't exist.`n`nClosing Script...
			ExitApp
		} Else If (ErrorLevel = 2) {
			; file is locked or inaccessible
			Msgbox, 4096, Critical file read error, File "%path%" is locked or inaccessible.`n`nClosing Script...
			ExitApp
		} Else If (ErrorLevel = 3) {
			; the system lacks sufficient memory to load the file
			Msgbox, 4096, Critical file read error, The system lacks sufficient memory to load the file "%path%".`n`nClosing Script...
			ExitApp
		} Else {
			Return file	
		}		
	} Else {
		Msgbox, 4096, Critical file read error, File "%path%" doesn't exist.`n`nClosing Script...
		ExitApp		
	}	
}