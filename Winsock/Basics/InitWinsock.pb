; https://docs.microsoft.com/en-us/windows/win32/api/winsock/nf-winsock-wsastartup
; https://docs.microsoft.com/en-us/windows/win32/api/winsock/ns-winsock-wsadata

EnableExplicit


;- Code

Define wVersionRequested = $0202
Define wsaData.WSAData
Define iResult.i

; The version number doesn't seem to matter that much
iResult = WSAStartup_(wVersionRequested, @wsaData)

If iResult
	Debug "WSAStartup failed: "+Str(iResult)
	End iResult
EndIf

; Tell the user that we could not find a usable WinSock DLL.
If wsaData\wVersion <> wVersionRequested
	Debug "Unsupported Winsock DLL version:"
	Debug "  Requested: 0x" + RSet(Hex(wVersionRequested), 4, "0") + #TAB$ + "Got: 0x"+RSet(Hex(wsaData\wVersion), 4, "0")
    WSACleanup_()
    End 1
EndIf

; The WinSock DLL is acceptable, we can proceed.


; TODO: Should you clean up with "WSACleanup_()" at the end ?

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 31
; EnableXP