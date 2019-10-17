;{- Code Header
; ==- Basic Info -================================
;         Name: ThreadedSendARP.pb
;      Version: N/A
;      Authors: Herwin Bozet
;  Create date: 11 October ‎2019, 03:15:22
; 
;  Description: N/A
; 
; ==- Requirements -=============================
;  IPv4Helper.pbi:
;    Version: 0.0.1
;       Link: https://github.com/aziascreations/PB-Networking-Playground
;    License: Unlicense
; 
; ==- Compatibility -=============================
;  Compiler version: PureBasic 5.70 (x64) (Other versions untested)
;  Operating system: Windows 10 (Other platforms untested)
; 
; ==- Links & License -===========================
;   Github: https://github.com/aziascreations/PB-Networking-Playground
;  License: Unlicense
; 
; ==- Notes -=====================================
;  The main loop appears to go above 254 even when it shouldn't.
;  
;}

;
;- Compiler directives & imports
;{

EnableExplicit

XIncludeFile "../../Includes/IPv4Helper.pbi"

CompilerIf #PB_Compiler_Thread = 0
	CompilerError "Required: Thread-safe compiler flag."
CompilerEndIf

;}

;
;- Declarations
;{

;-> Structures & Globals

Structure NetworkDeviceInfo
	MACAddress.q
	IPv4Address.i
EndStructure

; Because you can only give 1 param to a thread...
Structure ARPThreadParameterStruct
	DestinationIPV4Address.i
	SourceIPV4Address.i
	DevicesListMutex.i ; Not sure about the type, don't care
EndStructure

; Couldn't find a way around that global...
Global NewList Devices.NetworkDeviceInfo()


;-> Procedures

Procedure ARPRequestIPV4WorkerThread(*Parameters.ARPThreadParameterStruct)
	Protected *MACAddressBuffer = AllocateMemory(8)
	
	If Not *MACAddressBuffer
		ProcedureReturn
	EndIf
	
	; The fuck is that supposed to mean ? - The 6 bytes a mac@48 takes...
	Protected MACAddressLength.l = 6
	Protected WasPresent.b = #False
	
	If SendARP_(*Parameters\DestinationIPV4Address, *Parameters\SourceIPV4Address, *MACAddressBuffer, @MACAddressLength) = #NO_ERROR
		LockMutex(*Parameters\DevicesListMutex)
		
		ForEach Devices()
			If Devices()\MACAddress = PeekL(*MACAddressBuffer)
				WasPresent = #True
				Break
			EndIf
		Next
		
		If Not WasPresent
			LastElement(Devices())
			
			If AddElement(Devices())
				Devices()\MACAddress = PeekQ(*MACAddressBuffer)
				Devices()\IPv4Address = *Parameters\DestinationIPV4Address
			Else
				DebuggerError("Failed to allocate list cell !")
			EndIf
		EndIf
		
		UnlockMutex(*Parameters\DevicesListMutex)
	EndIf
EndProcedure

;}

;
;- Code
;{

; The amount of threads allowed to run at the same time.
#WORKER_POOL_SIZE = 64 ; It helps to have a bigger one to not let the ones that are waiting for a timeout block the rest
#WORKER_POST_BIRTH_DELAY = 50 ; ms

; I could have used an array, but I don't want to deal with PB's bullshit around arrays.
NewList WorkerPoolThreadIDs.i()
NewList WorkerPoolThreadParams.i() ; Ptr list

; TODO: Pass the list as an arg to mutex it inside the thread ?
; Make it local
Define DevicesListMutex = CreateMutex()

Define Thread, SourceIPV4Address.i
Define *TemporaryParamsPtr.ARPThreadParameterStruct

Define IPV4AddressLSB.i = 1 ; This is used to simplify the main loop and to avoid making some annoying IP bit level shit.
Define i.i

; Init the worker pool list
For i = 0 To #WORKER_POOL_SIZE - 1
	InsertElement(WorkerPoolThreadIDs())
	WorkerPoolThreadIDs() = #Null
	
	InsertElement(WorkerPoolThreadParams())
	WorkerPoolThreadParams() = #Null
Next

While IPV4AddressLSB < 255 - 1
	ForEach WorkerPoolThreadIDs()
		If Not IsThread(WorkerPoolThreadIDs())
			
			; Cleaning up some garbage
			SelectElement(WorkerPoolThreadParams(), ListIndex(WorkerPoolThreadIDs()))
			If WorkerPoolThreadParams()
				FreeMemory(WorkerPoolThreadParams())
			EndIf
			
			WorkerPoolThreadParams() = AllocateMemory(SizeOf(ARPThreadParameterStruct))
			*TemporaryParamsPtr = WorkerPoolThreadParams()
			*TemporaryParamsPtr\DestinationIPV4Address = MakeIPAddress(192,168,10,IPV4AddressLSB)
			*TemporaryParamsPtr\SourceIPV4Address = MakeIPAddress(192,168,10,2)
			*TemporaryParamsPtr\DevicesListMutex = DevicesListMutex
			;*TemporaryParamsPtr\Devices() = Devices()
			
			WorkerPoolThreadIDs() = CreateThread(@ARPRequestIPV4WorkerThread(), *TemporaryParamsPtr)
			
			Debug IPV4AddressLSB
			IPV4AddressLSB = IPV4AddressLSB + 1
			Delay(#WORKER_POST_BIRTH_DELAY)
		EndIf
	Next
Wend

; Waiting for the threads to finish
ForEach WorkerPoolThreadIDs()
	If IsThread(WorkerPoolThreadIDs())
		WaitThread(WorkerPoolThreadIDs())
	EndIf
Next

; Last cleanup
ForEach WorkerPoolThreadParams()
	If WorkerPoolThreadParams()
		FreeMemory(WorkerPoolThreadParams())
	EndIf
Next

Debug "Done !"
Debug "Got "+Str(ListSize(Devices()))+" responses !"

ForEach Devices()
	Debug IPv4String(Devices()\IPv4Address)
	Debug "0x"+RSet(Hex(Devices()\MACAddress), 8*2, "0")
	Debug ""
Next

;}

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 24
; Folding = +-
; EnableThread
; EnableXP