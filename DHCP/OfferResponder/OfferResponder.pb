
;- Compiler directives

XIncludeFile "../../Includes/PB-Utils/Includes/Endianness.pbi"
XIncludeFile "../../Includes/IPv4Helper.pbi"

EnableExplicit


;- Notes

; We could keep track of the transaction ids to avoid taking 2 in 1 transaction.
; Try out if the server will refuse to give a new ip to the same mac.

;- Constants, enums & constants

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

Enumeration DHCP_OPTIONS
	
EndEnumeration

#DHCP_PORT_SERVER = 67
#DHCP_PORT_CLIENT = 68

#DHCP_MAGIC_COOKIE = $63538263


;- Code

If InitNetwork() = 0
	Debug "Error: Can't initialize the network !"
	End 1
EndIf


Define ConnectionID, ServerID, ServerEvent, ClientID
Define ServerIP$ = "192.168.10.1"
Define BindedIP$ = "0.0.0.0"
Define InterfaceMAC.q = $00D86155C710 ; Don't bother about the padding or endianness here, just copy and paste.

ConnectionID = OpenNetworkConnection(ServerIP$, #DHCP_PORT_SERVER, #PB_Network_UDP)
If Not ConnectionID
	Debug "Error: Can't initialize the client !"
	End 2
EndIf

ServerID = CreateNetworkServer(#PB_Any, #DHCP_PORT_CLIENT, #PB_Network_UDP, BindedIP$)
If Not ServerID
	Debug "Error: Can't initialize the server !"
	CloseNetworkConnection(ConnectionID)
	End 2
EndIf

Debug "Everything is started up !"

Define DiscoverPacket.DHCP_PACKET, DiscoverPacketOptionsSize.i = 0
Define InboundPacket.DHCP_PACKET ; Kinda like a buffer
Define IsInboundPacketDirty.b = #False, PacketOptionsOffset.i = 0
Define RequestPacket.DHCP_PACKET, RequestPacketOptionsSize.i = 0

Define LeasesGotten.i = 0
Define TimeSinceLastDiscover.q = ElapsedMilliseconds()
Define TimeBetweendiscovers.q = 5*1000


; DiscoverPacket.DHCP_PACKET init
;{
With DiscoverPacket
	\OP = $01
	\HTYPE = $01
	\HLEN = $06
	\HOPS = $00
	\XID = Random($FFFFFFFF, 0)
	\SECS = $0000
	\FLAGS = EndianSwapW(%1000000000000000)
	\CIADDR = $00000000
	\YIADDR = $00000000
	\SIADDR = $00000000
	\GIADDR = $00000000
	\CHADDR1 = EndianSwapQ(InterfaceMAC) >> 16
	\CHADDR2 = 0
	\MAGICCOOKIE = EndianSwapL($63825363)
EndWith

; It's a discovery message
PokeL(@DiscoverPacket\OPTIONS + DiscoverPacketOptionsSize, EndianSwapL($35010100))
DiscoverPacketOptionsSize + 3

; End of options
PokeB(@DiscoverPacket\OPTIONS + DiscoverPacketOptionsSize, $FF)
DiscoverPacketOptionsSize + 1
;}

; RequestPacket.DHCP_PACKET init
;{
With RequestPacket
	\OP = $01
	\HTYPE = $01
	\HLEN = $06
	\HOPS = $00
	\XID = 0
	\SECS = $0000
	\FLAGS = EndianSwapW(%1000000000000000)
	\CIADDR = $00000000
	\YIADDR = $00000000
	\SIADDR = $00000000
	\GIADDR = $00000000
	\CHADDR1 = EndianSwapQ(InterfaceMAC) >> 16
	\CHADDR2 = 0
	\MAGICCOOKIE = EndianSwapL($63825363)
EndWith

; It's a request message
PokeL(@RequestPacket\OPTIONS + RequestPacketOptionsSize, EndianSwapL($35010300))
RequestPacketOptionsSize + 3

; The requested IP address
PokeL(@RequestPacket\OPTIONS + RequestPacketOptionsSize, EndianSwapQ($3204000000000000))
RequestPacketOptionsSize + 6

; The server IP address
PokeL(@RequestPacket\OPTIONS + RequestPacketOptionsSize, EndianSwapQ($3204000000000000))
RequestPacketOptionsSize + 6

; End of options
PokeB(@RequestPacket\OPTIONS + RequestPacketOptionsSize, $FF)
RequestPacketOptionsSize + 1
;}


Repeat
	If IsInboundPacketDirty
		FillMemory(@InboundPacket, SizeOf(DHCP_PACKET))
		IsInboundPacketDirty = #False
	EndIf
	
	If ElapsedMilliseconds() - TimeSinceLastDiscover > TimeBetweendiscovers
		Debug "Sending a discovery packet"
		DiscoverPacket\XID = Random($FFFFFFFF, 0)
		SendNetworkData(ConnectionID, @DiscoverPacket, #DHCP_DEFAULT_SIZE + DiscoverPacketOptionsSize)
		TimeSinceLastDiscover = ElapsedMilliseconds()
	EndIf
	
	
	ServerEvent = NetworkServerEvent()
	
	If ServerEvent
		ClientID = EventClient()
		
		Select ServerEvent
			Case #PB_NetworkEvent_Data
				Debug "Data was received"
				
				IsInboundPacketDirty = #True
				
				If ReceiveNetworkData(ClientID, @InboundPacket, SizeOf(DHCP_PACKET)) = -1
					Debug "An error occurred while receiving the data !"
					Continue
				EndIf
				
				If InboundPacket\MAGICCOOKIE <> #DHCP_MAGIC_COOKIE
					Debug "Magic cookie was incorrect !"
					Continue
				EndIf
				
				; This loop goes over all the options in the packet to check which type of message we got.
				Debug "Searching for the message type..."
				PacketOptionsOffset = 0
				Define MessageType = -1
				
				While #DHCP_DEFAULT_SIZE + PacketOptionsOffset < SizeOf(DHCP_PACKET) - 2
					Define OptionID.a = PeekA(@InboundPacket\OPTIONS + PacketOptionsOffset)
					Define OptionLength.a = PeekA(@InboundPacket\OPTIONS + PacketOptionsOffset + 1)
					PacketOptionsOffset + 2
					
					If OptionLength And #DHCP_DEFAULT_SIZE + PacketOptionsOffset + 2 > SizeOf(DHCP_PACKET)
						Debug "Potential out of buffer operation, stopping current loop !!!"
						Break
					EndIf
					
					;Debug OptionID
					
					Select OptionID
						Case 53 ; Message type
							MessageType = PeekA(@InboundPacket\OPTIONS + PacketOptionsOffset)
							Break
							
						Case 255 ; Exit
							Break
					EndSelect
					
					PacketOptionsOffset + OptionLength
				Wend
				
				; Some checks before continuing
				If MessageType = -1
					Debug "Unable to find the message type, packet will be ignored !"
					Continue
				EndIf
				
				; Choosing what to do now
				Select MessageType
					Case 1
						Debug "Got a discovery, this should NOT happen !"
						Continue
					Case 2
						Debug "Got an offer" ; our time to shine
						Debug "The server offered us: " + IPv4String(InboundPacket\YIADDR)
						
						RequestPacket\XID = InboundPacket\XID
						RequestPacket\SIADDR = InboundPacket\SIADDR
						
						; Poking the IP addresses in the options
						PokeL(@RequestPacket\OPTIONS + 3 + 2, InboundPacket\YIADDR)
						PokeL(@RequestPacket\OPTIONS + 3 + 6 + 2, RequestPacket\SIADDR)
						
						SendNetworkData(ConnectionID, @RequestPacket, #DHCP_DEFAULT_SIZE + RequestPacketOptionsSize)
						Debug "Sent the request"
						Continue
					Case 3
						Debug "Got a request, this should NOT happen, what are you doing !"
						Continue
					Case 5
						Debug "Got a acknowledgement for " + IPv4String(InboundPacket\YIADDR)
						LeasesGotten + 1
					Case 6
						Debug "Got a non-acknowledgement for " + IPv4String(InboundPacket\YIADDR) + " !"
					Default
						Debug "Got an unknown message type: "+MessageType
						Continue
				EndSelect
				
		EndSelect
	EndIf
	
Until LeasesGotten = 1


Debug "Got enough leases, now quitting..."

CloseNetworkConnection(ConnectionID)
CloseNetworkServer(ServerID)

End

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 13
; FirstLine = 140
; Folding = 9
; EnableXP