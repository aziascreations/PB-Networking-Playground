
; EndianSwapQ(Number.q)
; Had to be separated based on the CPU arch because x86 doesn't have an easy way of dealing with a 64bit variable
;  in its registers.
CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
	
	; Note: A version of this procedure that uses xmm registers and SSE2 instructions can be made to suit both
	;        x86 and x64, but the performances would likely take a hit. (~8 instructions with XMM regs.)
	
	; Note: The stack could have technically been used to leave EDX untouched, but when I used it,
	;        the "ProcedureReturn" kept throwing an "Invalid memory access" error.
	
	Procedure.q EndianSwapQ(Number.q)
		EnableASM
			MOV eax, dword [p.v_Number]
			MOV edx, dword [p.v_Number+4]
			
	 		BSWAP eax
	 		BSWAP edx
	 		
	 		MOV dword [p.v_Number+4], eax
	 		MOV dword [p.v_Number], edx
		DisableASM
		
		ProcedureReturn Number
	EndProcedure
	
CompilerElseIf #PB_Compiler_Processor = #PB_Processor_x64
	
	Procedure.q EndianSwapQ(Number.q)
		EnableASM
			MOV rdx, Number
			BSWAP rdx
			MOV Number, rdx
		DisableASM
		
		ProcedureReturn Number
	EndProcedure
	
CompilerElse
	CompilerWarning "Unsupported CPU Architecture in Endianness.pbi for EndianSwapQ(...) !"
CompilerEndIf


If Not InitNetwork()
	Debug "Can't initialize the network !"
	End 1
EndIf

;9/7
ConnectionID = OpenNetworkConnection("192.168.69.255", 9, #PB_Network_UDP)
If ConnectionID
	Debug "Client connected to server..."
	
	*Buffer = AllocateMemory(6+(6*16)+2) ; The +2 is used to poke quads in the buffer, but isn't transmitted.
	
	For i.i = 0 To 5
		PokeA(*Buffer + i, $FF)
	Next
	
	MAC.q = EndianSwapQ($C8CBB82603CBFFFF) ; HP Touch
	;MAC.q = EndianSwapQ($0800270B4364FFFF) ; VirtualBox VM
	;MAC.q = EndianSwapQ($001122334455FFFF)
	
	For i.i = 0 To 15
		PokeQ(*Buffer+6+(i*6), MAC)
	Next
	
	;ShowMemoryViewer(*Buffer, MemorySize(*Buffer))
	;Delay(10000)
	
	For i=0 To 10
		SendNetworkData(ConnectionID, *Buffer, MemorySize(*Buffer)-2)
		Delay(1000)
	Next

	FreeMemory(*Buffer)
	
	Debug "Packet sent !"
	CloseNetworkConnection(ConnectionID)
Else
	Debug "Can't find the server (Is it launched ?)."
EndIf

End 0

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 50
; FirstLine = 3
; Folding = +
; EnableXP