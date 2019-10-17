;{- Code Header
; ==- Basic Info -================================
;         Name: IPv4Helper.pbi
;      Version: 0.0.1
;       Author: Herwin Bozet
;  Create date: 21 ‎June ‎2019, 19:24:33
; 
;  Description: A basic set of utility procedures and macros to help with IPv4 addresses.
; 
; ==- Compatibility -=============================
;  Compiler version: PureBasic 5.62 & 5.70 (x64) (Other versions untested)
;  Operating system: Windows (Other platforms untested)
; 
; ==- Links & License -===========================
;   Github: https://github.com/aziascreations/PB-Networking-Playground
;  License: Unlicense
; 
;}

;
;- Compiler directives
;{

;EnableExplicit

;}

;
;- Constants
;{

#IPv4_IP_ERROR = $00000000 ; 0.0.0.0
#IPv4_BITMASK_ERROR = $00000000 ; 0.0.0.0
#IPv4_CIDRMASK_ERROR = 0		; /0

; TODO: D & E classes
#IPv4_BITMASK_CLASS_A = $000000FF ; 255.0.0.0
#IPv4_BITMASK_CLASS_B = $0000FFFF ; 255.255.0.0
#IPv4_BITMASK_CLASS_C = $00FFFFFF ; 255.255.255.0

#IPv4_CIDRMASK_CLASS_A = 8
#IPv4_CIDRMASK_CLASS_B = 16
#IPv4_CIDRMASK_CLASS_C = 24

;}

;
;- Procedures & Macros
;{

;
;-> Validity checkers
;{

; Returns non-zero if the bit mask is valid.
Procedure.b IsIPv4BitMaskValid(BitMask.l)
	ProcedureReturn #True
EndProcedure

; Avoids useless procedure calls inside other procedure inside this include.
Macro _IsIPv4CIDRMaskValid(CIDRMask)
	(CIDRMask >= 1 And CIDRMask<=31)
EndMacro

; Returns non-zero if the CIDR mask is valid.
Procedure.b IsIPv4CIDRMaskValid(CIDRMask.b)
	ProcedureReturn Bool(_IsIPv4CIDRMaskValid(CIDRMask))
EndProcedure

;}

;
;-> Mask transformers
;{

; Returns the bit mask associated with the given CIDR mask.
; If the CIDR mask is invalid, it returns zero. (0.0.0.0)
Procedure.l GetIPv4BitMaskFromCIDRMask(CIDRMask.b)
	Protected BitMask.l
	
	If Not _IsIPv4CIDRMaskValid(CIDRMask)
		ProcedureReturn #IPv4_BITMASK_ERROR
	EndIf
	
	; The endianness fucks it up without asm
	
	BitMask = ($80000000 >> (CIDRMask - 1))
	EnableASM
	MOV eax, BitMask
	BSWAP eax
	ProcedureReturn
	DisableASM
	
EndProcedure

; Returns the CIDR mask associated with the given bit mask.
; If the bit mask is invalid, it returns zero. (/0)
Procedure.l GetIPv4CIDRMaskFromBitMask(BitMask.l)
	If Not IsIPv4BitMaskValid(BitMask)
		ProcedureReturn #IPv4_CIDRMASK_ERROR
	EndIf
	
	; ...
	
EndProcedure

;}

;
;-> Net-ID resolvers
;{

Macro _GetIPv4NetworkIDByBitMask(IPv4Address, BitMask)
	(IPv4Address & BitMask)
EndMacro

Macro _GetIPv4NetworkIDByCIDRMask(IPv4Address, CIDRMask)
	(_GetIPv4NetworkIDByBitMask(IPv4Address, GetIPv4BitMaskFromCIDRMask(CIDRMask)))
EndMacro

Procedure.l GetIPv4NetworkIDByBitMask(IPv4Address.l, BitMask.l)
	If IsIPv4BitMaskValid(BitMask)
		ProcedureReturn _GetIPv4NetworkIDByBitMask(IPv4Address, BitMask)
	Else
		ProcedureReturn #IPv4_IP_ERROR
	EndIf
EndProcedure

Procedure.l GetIPv4NetworkIDByCIDRMask(IPv4Address.l, CIDRMask.b)
	If _IsIPv4CIDRMaskValid(CIDRMask)
		ProcedureReturn _GetIPv4NetworkIDByBitMask(IPv4Address, GetIPv4BitMaskFromCIDRMask(CIDRMask))
	Else
		ProcedureReturn #IPv4_IP_ERROR
	EndIf
EndProcedure

;}

;
;-> Host-ID resolvers
;{

Macro _GetIPv4HostIDByBitMask(IPv4Address, BitMask)
	(IPv4Address & (~BitMask))
EndMacro

Procedure.l GetIPv4HostIDByBitMask(IPv4Address.l, BitMask.l)
	If IsIPv4BitMaskValid(BitMask)
		ProcedureReturn _GetIPv4HostIDByBitMask(IPv4Address, BitMask)
	Else
		ProcedureReturn #IPv4_IP_ERROR
	EndIf
EndProcedure

Procedure.l GetIPv4HostIDByCIDRMask(IPv4Address.l, CIDRMask.b)
	If _IsIPv4CIDRMaskValid(CIDRMask)
		ProcedureReturn _GetIPv4HostIDByBitMask(IPv4Address, GetIPv4BitMaskFromCIDRMask(CIDRMask))
	Else
		ProcedureReturn #IPv4_IP_ERROR
	EndIf
EndProcedure

;}

;
;-> Host-ID utils
;{

Macro _GetIPv4RawHostCountFromBitMask(BitMask)
	(_GetIPv4HostIDByBitMask($FFFFFFFF, BitMask) - 1)
EndMacro

Macro _GetIPv4RawHostCountFromCIDRMask(CIDRMask)
	(Pow(2, 32-CIDRMask))
EndMacro

; Returns non-zero is no error occured.
; FIXME: Is the broadcast @ removed ???
Procedure GetIPv4MaxHostCountFromBitMask(BitMask.l)
	If IsIPv4BitMaskValid(BitMask)
		ProcedureReturn _GetIPv4RawHostCountFromBitMask(BitMask)
	Else
		ProcedureReturn #False ; 0
	EndIf
EndProcedure

Procedure GetIPv4MaxHostCountFromCIDRMask(CIDRMask.b)
	If _IsIPv4CIDRMaskValid(CIDRMask)
		ProcedureReturn _GetIPv4RawHostCountFromCIDRMask(CIDRMask)
	Else
		ProcedureReturn #False ; 0
	EndIf
EndProcedure

;}

;
;-> Misc
;{

; Same as IPString(IPv4Address.l, #PB_Network_IPv4), but it doesn't require you to use InitNetwork().
Procedure.s IPv4String(IPv4Address.l)
	ProcedureReturn Str(PeekA(@IPv4Address)) + "." + Str(PeekA(@IPv4Address+1)) + "." +
	                                           Str(PeekA(@IPv4Address+2)) + "." + Str(PeekA(@IPv4Address+3))
EndProcedure

;}

; Get nth client
; get next client(current, mask)
; Get broadcast
;Procedure.b IsIPv4MaskValid
; Get subnet mask

;}

;
;- Tests
;{

CompilerIf #PB_Compiler_IsMainFile
	;IP.l = GetIPv4BitMaskFromCIDRMask(24)
	;IP.l = MakeIPAddress(156,48,133,96)
	Define IP.l = MakeIPAddress(255, 255, 255, 255)
	Define CIDR.b = 24
	Debug IPv4String(IP)+"/"+CIDR
	
	Define BitMask.l = GetIPv4BitMaskFromCIDRMask(CIDR)
	Debug IPv4String(BitMask)
	
	Debug IPv4String(GetIPv4NetworkIDByBitMask(IP, BitMask))
	Debug IPv4String(GetIPv4HostIDByBitMask(IP, BitMask))
	Debug IPv4String(GetIPv4HostIDByCIDRMask(IP, CIDR))
CompilerEndIf

;}

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 1
; Folding = +----
; EnableXP