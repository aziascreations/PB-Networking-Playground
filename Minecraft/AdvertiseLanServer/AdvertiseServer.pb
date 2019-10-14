
If InitNetwork() = 0
	MessageRequester("Error", "Can't initialize the network !", 0)
	End
EndIf

Port = 4445
Ip$ = "192.168.10.255"

ConnectionID = OpenNetworkConnection(Ip$, Port, #PB_Network_UDP)
If ConnectionID
	MessageRequester("PureBasic - Client", "Client connected to server...", 0)
	
	Repeat
		; Note: be carefull about the string's length, MC only seems to parse up to 1024 chars. - Could be the compiler's unicode mode.
		SendNetworkString(ConnectionID, "[MOTD]Why are you still playing this game ?[/MOTD][AD]420[/AD][NAME]ASS[/NAME]", #PB_UTF8)
		Delay(1500)
	ForEver
Else
	; Shouldn't happen since it is broadcasting.
	MessageRequester("PureBasic - Client", "Can't find the server (Is it launched ?).", 0)
EndIf

End

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 11
; EnableXP