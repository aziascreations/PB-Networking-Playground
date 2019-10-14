
XIncludeFile "../../Includes/PB-Utils/Includes/Endianness.pbi"

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

Port = 67

; I can't open a connection on 255.255.255.255 (Could be the firewall, it threw a fit after a couple of tries...)
;Ip$ = "255.255.255.255"
Ip$ = "192.168.10.255"

; 67 should be the DHCP server and 68 the client

ConnectionID = OpenNetworkConnection(Ip$, Port, #PB_Network_UDP);, 5000, "0.0.0.0", 68)
If ConnectionID
	Debug "Network connection created !"
	
	Define Packet.DHCP_PACKET
	
	Packet\OP = $01
	Packet\HTYPE = $01
	Packet\HLEN = $06
	Packet\HOPS = $00
	Packet\XID = Random($FFFFFFFF, 0)
	Packet\SECS = $0000
	Packet\FLAGS = EndianSwapW(%1000000000000000)
	Packet\CIADDR = $00000000
	Packet\YIADDR = $00000000
	Packet\SIADDR = $00000000
	Packet\GIADDR = $00000000
	Packet\CHADDR1 = EndianSwapQ($00D86155C710) >> 16
	Packet\CHADDR2 = 0
	Packet\MAGICCOOKIE = EndianSwapL($63825363)
	
	Define OptionsSize.l = 0
	
	; 53 ($35) message type
	; 01 arg len
	; 01 discover
	; 00 padding
	PokeL(@Packet\OPTIONS + OptionsSize, EndianSwapL($35010100))
	OptionsSize + 3
	
	; End of options
	PokeB(@Packet\OPTIONS + OptionsSize, $FF)
	OptionsSize + 1
	
	;SendNetworkData(ConnectionID, @Packet, #DHCP_DEFAULT_SIZE + OptionsSize)
	
	For i.i = 0 To 10
		SendNetworkData(ConnectionID, @Packet, #DHCP_DEFAULT_SIZE + OptionsSize)
		Packet\XID = Random($FFFFFFFF, 0)
		Delay(1000)
	Next
	
	CloseNetworkConnection(ConnectionID)
Else
	; Shouldn't happen since it is broadcasting.
	MessageRequester("PureBasic - Client", "Can't find the server (Is it launched ?).", 0)
EndIf

End

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 97
; FirstLine = 54
; EnableXP