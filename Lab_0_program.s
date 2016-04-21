;*----------------------------------------------------------------------------
;* Name:    Lab_0_program.s 
;* Purpose: Teaching students how to work with the uVision software 
;* Author: 	Rasoul Keshavarzi 
;*----------------------------------------------------------------------------
		THUMB 			; Thumb instruction set 
		AREA 		My_code, CODE, READONLY
		EXPORT 	__MAIN
		ENTRY 
__MAIN 	; This name should not be changed. It matches with the startup_LPC17xx.s file. 

; Store 0x1234,5678 into memory address 0x1000,0000 in order to see how the little-endian 
; approach writes data into memory 
		MOV 		R0, #0x5678 	; Load the lower half of R0 and erase the upper half
		MOVT 		R0, #0x1234 	; Load the upper half of R0 
		MOV 		R1, #0x0 	; Load the lower half of R1 with zeros 
		MOVT 		R1, #0x1000 	; 0x1000,0000 is now stored in R1 
		STR 		R0, [R1] 	; Store Register R0 in the memory address pointed to by R1 (0x1000,0000)

; Look at memory address 0x1000,0000 after the STore Register command runs

; Now Import values to registers - the values could be addresses or data
		MOV 		R0, #0x123 	; Loading 123 into R0 
		MOV 		R1, #0x456 	; Loading 456 into R1 
		MOV 		R2, #0x789 	; Loading 789 into R2 
		MOV 		R3, #0xABC 	; Loading ABC into R3 
		MOV 		R4, #0xDEF 	; Loading DEF into R4 
		MOV 		R5, #0x0 	; Loading R5 with zeros 

; Swapping the values in R0 and R1 (R5 is used as temporary buffer) 
		MOV 		R5, R0 		; R5 <-- R0 (content of R0 is stored in R5) 
		MOV 		R0, R1 		; R0 <-- R1 (content of R1 is stored in R0) 
		MOV 		R1, R5 		; R1 <-- R5 (content of R5 is stored in R1) 

; Adding five values together R5 <-- R0+R1+R2+R3+R4 
		ADD 		R5, R0, R1 	; R5 <-- R0 + R1 
		ADD 		R5, R2 		; R5 <-- R5 + R2 
		ADD 		R5, R3 		; R5 <-- R5 + R3 
		ADD 		R5, R4 		; R5 <-- R5 + R4 

LOOP 		B 		LOOP 		; Branch back to this line - an infinite loop

		END      
