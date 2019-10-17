;{- Code Header
; ==- Basic Info -================================
;         Name: SimpleWOLSender.pb
;      Version: N/A
;      Authors: Herwin Bozet
;  Create date: 2 September ‎2019, 00:06:59
; 
;  Description: A simple WOL packet sender.
;               It broadcasts 10 packets over a period of 10 secs for a given MAC address.
; 
; ==- Requirements -=============================
;  Endianness.pbi:
;    Version: 1.0.2
;       Link: https://github.com/aziascreations/PB-Utils
;    License: WTFPL (Compatible with the project's license)
; 
; ==- Compatibility -=============================
;  Compiler version: PureBasic 5.70 (x64) (Other versions untested)
;  Operating system: Windows 10 (Other platforms untested)
; 
; ==- Links & License -===========================
;   Github: https://github.com/aziascreations/PB-Networking-Playground
;  License: Unlicense
;  
;}

;
;- Compiler directives & imports
;{

EnableExplicit

XIncludeFile "../../Includes/PB-Utils/Includes/Endianness.pbi"

;}

;
;- Code
;{

If Not InitNetwork()
	Debug "Can't initialize the network library !"
	End 1
EndIf

Define ConnectionID, *Buffer, TargetMAC.q, i.i

Define ConnectionID = OpenNetworkConnection("192.168.10.255", 9, #PB_Network_UDP)
If ConnectionID
	Debug "Client connected to server..."
	
	; Preparing the packet in a buffer...
	*Buffer = AllocateMemory(6+(6*16)+2) ; The +2 is used to poke quads in the buffer, but isn't transmitted.
	
	; Setting the destination MAC to broadcast
	PokeQ(*Buffer, $FFFFFFFFFFFFFFFF)
	
	TargetMAC.q = EndianSwapQ($000F1FDE394CFFFF) ; Dell Optiplex sx280
	
	For i.i = 0 To 15
		PokeQ(*Buffer+6+(i*6), TargetMAC)
	Next
	
	
	; Sending the packets
	For i=0 To 10
		SendNetworkData(ConnectionID, *Buffer, MemorySize(*Buffer)-2)
		Delay(1000)
	Next
	
	
	; Finishing
	Debug "Packets sent !"
	
	FreeMemory(*Buffer)
	CloseNetworkConnection(ConnectionID)
Else
	Debug "Cannot find the server."
EndIf

End 0

;}

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 47
; Folding = +
; EnableXP