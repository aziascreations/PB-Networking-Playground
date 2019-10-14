#DHCP_DEFAULT_SIZE = 240

; Structure from https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol
Structure DHCP_PACKET
	OP.b    ; 0x01
	HTYPE.b	; 0x01
	HLEN.b	; 0x06
	HOPS.b	; 0x00
	
	XID.l ; 0x3903F326
	
	SECS.w  ; 0x0000
	FLAGS.w	; 0x0000
	
	CIADDR.l ; 0x00000000
	YIADDR.l ; 0x00000000
	SIADDR.l ; 0x00000000
	GIADDR.l ; 0x00000000
	
	CHADDR1.q ; MAC
	CHADDR2.q ; Remnants of BOOTP
	
	;(192 octets of 0s)
	BOOTPDATA.b[192]
	
	MAGICCOOKIE.l ; 0x63825363
	
	; Options (just a buffer, we will use an offset to poke stuff into it and get the final size)
	; Some servers don't seem to respond if there is too much shit at the end.
	OPTIONS.b[2048 - #DHCP_DEFAULT_SIZE]
EndStructure

If InitNetwork() = 0
	MessageRequester("Error", "Can't initialize the network !", 0)
	End
EndIf

Port = 68
*Buffer.DHCP_PACKET = AllocateMemory(2048)

If CreateNetworkServer(0, Port, #PB_Network_UDP, "0.0.0.0")
	
	Debug "Server created (Port "+Str(Port)+")."
	
	Repeat
		SEvent = NetworkServerEvent()
		
		If SEvent
			ClientID = EventClient()
			
			Select SEvent
				Case #PB_NetworkEvent_Data
					Debug "We got data !"
					ReceiveNetworkData(ClientID, *Buffer, MemorySize(*Buffer))
					ShowMemoryViewer(*Buffer, MemorySize(*Buffer))
					
					
			EndSelect
		EndIf
		
	ForEver
	
	CloseNetworkServer(0)
Else
	MessageRequester("Error", "Can't create the server (port in use ?).", 0)
EndIf

End   

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 68
; FirstLine = 7
; EnableXP