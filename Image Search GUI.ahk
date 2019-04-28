#SingleInstance Force
CoordMode, Mouse
CoordMode, Pixel

ClientEXE := "client.exe"
interval := 100
offsetX := 2
offsetY := 2
shades := 2

Gui, +ToolWindow +AlwaysOnTop +HwndMainHWND
Gui, Font, S8 CDefault, Verdana

Gui, Add, Tab3, hwndTabHWND, Search|Options|On Find Actions
Gui, Tab, 1

Gui, Add, GroupBox, section h110 w100, Image
Gui, Add, Picture, hwndPicHWND xp+10 yp+20 h80 w80
Gui, Add, DDL, Disabled y+17 xp-10  w100 Choose1 vimageFile gImageChange, % Images
Gui, Add, Button, Disabled wp+1 hp gSubmit hwndStartStop, Start
Gui, Add, Edit, vLogEdit ys+6 h158 w260 ReadOnly

Gui, Tab, 2
Gui, Add, Text, , Image Folder
Gui, Add, Edit, section r1 Disabled w220 vimgDirectory, 
Gui, Add, Button, ys-1 gSelectImageFolder, Browse...

;Refresh Images
Gui, Add, Button, ys-1 wp gRefreshImages, Refresh

;Search Interval
Gui, Add, Text, x21 yp+30 Section ,Search Interval [ms]
Gui, Add, Edit, number wp vInterval gIntervalChange center, % interval

;Shades
Gui, Add, Text, ys wp x+20, Variation
Gui, Add, Edit, limit3 w100 number center gVariationChange
Gui, Add, UpDown, Range0-255 vShades gVariationChange, % shades

;Killswitch
Gui, Add, Text, ys x+20, Killswitch
Gui, Add, Hotkey, w113 vKillswitch, F7

;Client EXE
Gui, Add, Text, xs Section y+10, Client EXE Name
Gui, Add, Edit, w120 center vClientEXE disabled, % ClientEXE

;SearchScreen
Gui, Add, CheckBox,  ys+23 center vSearchScreen gSearchEntireScreen checked, Search Entire Screen Instead of EXE?

Gui, Tab, 3

;OnFound
Gui, Add, Text, xs Section y+10, Action when image is found:
Gui, Add, DDL, w200 center vFoundAction altsubmit gUpdateVars, Mouse Click Image||Mouse Move to Image|Log Only

;StopIfFound
Gui, Add, Text, xs Section y+10, Keep searching if image is found?
Gui, Add, DDL, w200 center vStopIfFound altsubmit gUpdateVars, Stop if the image is found||Continue Searching at Interval

;Show
Gui, Show, Autosize , Image Search

Log("Ready")

return

SearchEntireScreen:
	Gui, Submit, Nohide
	GuiControl, % (SearchScreen ? "Disable" : "Enable"), ClientEXE
Return

ImageChange:
	Gui, Submit, Nohide
	GuiControl,, % picHWND, % imgDirectory "\" imageFile ".png"
	GuiControl, Move, Static1,  h80 w80
Return

IntervalChange:
	Gui, Submit, Nohide
	If !Interval{
	Interval := 1
	GuiControl,,Interval, % Interval
	}
Return

UpdateVars:
	Gui, Submit, Nohide
Return

VariationChange:
	Gui, Submit, Nohide
	GuiControl,,Shades, % Shades
Return

Search:
	;Search a specific window or just a client area?
	If !(SearchScreen){
		WinActivate, % "ahk_exe " ClientEXE
		WinGetPos, cliX, cliY, cliW, cliH, % "ahk_exe " ClientEXE
		ImageSearch, foundX, foundY, % cliX, % cliY, % cliX + cliW, % cliY + cliH, % "*" shades A_Space imgDirectory "\" imageFile ".png"
	} else { 
		ImageSearch, foundX, foundY, 0, 0, % A_ScreenHeight, % A_ScreenWidth, % "*" shades A_Space imgDirectory "\" imageFile ".png"
	}

    If !(ErrorLevel) {
		If (FoundAction = 1)
			MouseClick, Left, % foundX + offsetX, % foundY + offsetY, 1, 0
		If (FoundAction = 2)
			MouseMove, % FoundX, % FoundY, 0
				
        Log("Found " imageFile " at x:" foundX " y:" foundY)
		
		If (StopIfFound = 1)
			GoSub, Submit
    }
Return

Submit:
	Gui, Submit, Nohide
	Toggle := !Toggle
	If (Killswitch <> "")
		Hotkey, % KillSwitch, Submit, % (Toggle ? "ON" : "OFF")
	GuiControl, % Toggle ? "Disable" : "Enable", imageFile
	GuiControl,, % StartStop, % Toggle ? "Stop" : "Start" 
    SetTimer, Search, % (Toggle) ? interval : "Off"
	Log("Search " (Toggle ? "Started" : "Stopped") " - " imageFile)
Return

Log(txt){
	Global LogEdit
	Gui, Submit, Nohide
	FormatTime, time,, H:MM
	GuiControl,, LogEdit, % time " - " txt "`n" LogEdit
}

GuiClose:
GuiEscape:
	ExitApp
Return

SelectImageFolder:
	Gui, -AlwaysOnTop +Disabled
	FileSelectFolder, Folder, % A_Desktop,,Select Image Folder
	Gui, +AlwaysOnTop -Disabled
	Gui, Show
	If ErrorLevel
		Return
	GuiControl,,imgDirectory, % Folder
	Gui, Submit, Nohide
RefreshImages:
	Gosub, Loadimages
	GuiControl,, imageFile , % "|" Images	
	GuiControl, Choose, % TabHWND, 1
	GoSub ImageChange
Return

LoadImages:
	Images := ""
	Loop, Files, % imgDirectory "\*.png"
		Images .= Format("{:Ts}", StrReplace(A_LoopFileName, "." A_LoopFileExt)) "|" (A_Index = 1 ? "|" : "")
	If (Images <> ""){
		GuiControl, Enable, Start
		GuiControl, Enable, ImageFile
		Log("Image List Updated")
	} else {
		GuiControl, Disable, Start
		GuiControl, Disable, ImageFile
		Log("Folder contains no images")
	}
Return

^Esc::Reload