;*-------------------------------------------------------------------
;* Name:    	lab_4_program.s 
;* Purpose: 	A sample style for lab-4
;* Term:		Winter 2016
;*-------------------------------------------------------------------
				THUMB 								; Declare THUMB instruction set 
				AREA 	My_code, CODE, READONLY 	; 
				EXPORT 		__MAIN 					; Label __MAIN is used externally 
				EXPORT 		EINT3_IRQHandler 		; without this the interupt routine will not be found

				ENTRY 

__MAIN

; The following lines are similar to previous labs.
; They just turn off all LEDs 
				LDR			R10, =LED_BASE_ADR		; R10 is a  pointer to the base address for the LEDs
				
				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [r10, #0x20]
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn off five LEDs on port 2 

; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV			R11, #0xABCD		; Init the random number generator with a non-zero number
				
				MOV			R7, #0
				LDR			R7, =ISER0			; Set-enable R0
				MOV			R8, #0x00200000		
				STR			R8, [R7]
				
				LDR			R7, =IO2IntEnf		; Set R7 to contain the address for Port 2 Falling Edge register
				MOV			R8, #0x400			; Move into R8 a value containing all 0's, except for a 1 at the bit 10
				STR			R8, [R7]			; Set up the falling edge for Port 2.10
						
LOOP 			BL 			RNG
				MOV			R4, #0				; Set R4 as 0 initially, which is the register we will check for a '1' to see if an interrupt has been done

count			TEQ			R4, #0				; Check if R4 is zero
				BNE			LOOP				; If R4 is not zero, then it must be 1 meaning that the interrupt has been requested, so restart loop and RNG

				MOV			R3, R6				; Move the RNG value in R6 into R3
				BL			DISPLAY_NUM			; Display the number in R3
				MOV			R0, #10				; Set R0 for DELAY
				BL			DELAY				; Delay for 1 second (10 * 100 ms)
				
				MOV			R3, #0				; Set R3 to 0 in case we go to flashLED
			
				SUBS		R6, #10				; Subtract 10 from R6, and set the Z and N flags
				BMI			flashLED			; If the result from above is negative, then branch to flash LED
				BNE			count				; If not equal to zero, keep counting down
												; or else, if not BNE and not BMI, then R6 must be equal to zero, so it will go to flashLED by default
				
flashLED		TEQ			R4, #0				; Check if R4 is zero
				BNE			LOOP				; If R4 is not zero, then it must be 1 meaning that the interrupt has been requested, so restart loop and RNG
				
				BL			DISPLAY_NUM			; Display R3, which was set to 0 initially, and will be XOR'd in DISPLAY_NUM to alternate between 0xff to 0x00 continuously
				MOV			R0, #5				; Set R0 for DELAY
				BL			DELAY				; Delay for 0.5s, since 0.5s ON and 0.5s OFF gives a 1Hz flash
				B 			flashLED			; Keep flashing

;*------------------------------------------------------------------- 
; Subroutine RNG ... Generates a pseudo-Random Number in R11 
;*------------------------------------------------------------------- 
; R11 holds a random number as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program
; R11 can be read anywhere in the code but must only be written to by this subroutine
RNG 			STMFD		R13!,{R1-R3, R14} 	; Random Number Generator 
				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1			; The new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				
				MOV			R6, R11
				LSL			R6, #28				; Take 4 LSB, giving a 4-bit number (0 to 15)
				LSR			R6, #28				; ---
				ADD			R6, #5				; Add 5 and multiply by 12
				MOV			R1,	#12				; This gives a range of 5*12 to 20*12, which is 60 to 240
				MUL			R6, R1				; ---
				
				LDMFD		R13!,{R1-R3, R15}

;*------------------------------------------------------------------- 
; Subroutine DISPLAY_NUM ... for displaying countdown
;*------------------------------------------------------------------- 

DISPLAY_NUM		STMFD		R13!,{R1, R2, R14}

; Adjusting bits for P1
				EOR			R3, R3, #4294967295 ;R1 XOR 2^32 - 1, which is 32 bits of 1's, giving the result of each bit in R1 being flipped, as 0 turns the LED on and 1 turns of LED off
				
				MOV			R1, R3				; Move the contents of R3, containing the number to be displayed, into R1 so that we can manipulate it
				LSR			R1, #5				; Cut to 3 MSB (leftmost), and the 3 MSB are now the 3 LSB (ie, abc... -> ...abc)
				RBIT		R1, R1				; Flip bit order, 3 MSB flipped from original (ie, ...abc -> cba...)
				
				MOV			R2, R1				; Move the modified content in R1 into R2
				LSR			R2, #31				; Shift right 31 bits in R2, leaving only the MSB, which is now the LSB (ie, abc... -> ...a)
				RBIT		R2, R2				; Flip bit order, making the LSB to the MSB again (ie, ...a -> a...)
				
				LSL			R1, #1				; Shift left one bit in R1, getting rid of the MSB (ie, abc... -> bc...)
				LSR			R1, #2				; Shift left two bits in R1, making the two MSB 0's (ie, bc... -> 00bc...)
				
				ADD			R1, R1, R2			; Add R1 and R2, and leave the result in R1 (ie, R2 + R1 = a... + 00bc... = a0bc...)
				
				STR			R1,	[R10, #0x20]	; Write R1 to P1
			
; Adjusting bits for P2

				MOV			R1, R3				; Move the contents of R3, containing the number to be displayed, into R1 so that we can manipulate it
				LSL			R1, #27				; Cut to 5 LSB (rightmost), and the 5 LSB are now the 5 MSB (ie, ...abcde -> abcde...)
				RBIT		R1, R1				; Flip bit order, 5 LSB flipped from original (ie, abcde... -> ...edcba)
				
				LSL			R1, #2				; Offset bits so they fit into their respective bits in P2 (ie, ...edcba -> ...edcba00)
				STR			R1,	[R10, #0x40]	; Write R1 to P2

				LDMFD		R13!,{R1, R2, R15}

;*------------------------------------------------------------------- 
; Subroutine DELAY ... Causes a delay of 100ms * R0 times
;*------------------------------------------------------------------- 

DELAY			STMFD		R13!,{R2, R14}
MultipleDelay
				TEQ			R0, #0				; test R0 to see if it is 0
				BEQ			exitDelay			; branch to exitDelay if R0 is 0, since no more iterations left

				MOV			R2, #0x23000		; initialize a value in R2 as 85000, giving 100 ms per iteration of delay
			
loopDelay
				SUBS 		R2, #1				; subtract 1 from the counter R2
				BNE			loopDelay			; loop until R2 is 0
				SUBS		R0, #1				; after R2 is 0, subtract 1 from R0
				B			MultipleDelay		; branch to MultipleDelay to re-evaluate R0 and reset R2 counter

exitDelay		LDMFD		R13!,{R2, R15}

; The Interrupt Service Routine MUST be in the startup file for simulation 
;   to work correctly.  Add it where there is the label "EINT3_IRQHandler
;
;*------------------------------------------------------------------- 
; Interrupt Service Routine (ISR) for EINT3_IRQHandler 
;*------------------------------------------------------------------- 
; This ISR handles the interrupt triggered when the INT0 push-button is pressed 
; with the assumption that the interrupt activation is done in the main program
EINT3_IRQHandler 	
				STMFD 		R13!,{R7, R8, R14} 
				
				LDR			R7, =IO2INTCLR		; Set R7 to contain the address for Port 2 Clear register
				MOV			R8, #0x400			; Move into R8 a value containing all 0's, except for a 1 at the bit 10
				STR			R8, [R7]			; Clear P2.10, which had the falling edge triggered
				
				LDR			R7, =IO2IntEnf		; Set R7 to contain the address for Port 2 Falling Edge register
				MOV			R8, #0x400			; Move into R8 a value containing all 0's, except for a 1 at the bit 10
				STR			R8, [R7]			; Set up the falling edge for Port 2.10
				
				MOV			R4, #1				; Set R4 to 1, which will be checked to restart the RNG in the main function
				
				LDMFD 		R13!,{R7, R8, R15} 


;*-------------------------------------------------------------------
; Below is a list of useful registers with their respective memory addresses.
;*------------------------------------------------------------------- 
LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002C00C 		; Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002C010 		; Pin Select Register 4 for P2[15:0]
FIO1DIR			EQU		0x2009C020 		; Fast Input Output Direction Register for Port 1 
FIO2DIR			EQU		0x2009C040 		; Fast Input Output Direction Register for Port 2 
FIO1SET			EQU		0x2009C038 		; Fast Input Output Set Register for Port 1 
FIO2SET			EQU		0x2009C058 		; Fast Input Output Set Register for Port 2 
FIO1CLR			EQU		0x2009C03C 		; Fast Input Output Clear Register for Port 1 
FIO2CLR			EQU		0x2009C05C 		; Fast Input Output Clear Register for Port 2 
IO2IntEnf		EQU		0x400280B4		; GPIO Interrupt Enable for port 2 Falling Edge 
ISER0			EQU		0xE000E100		; Interrupt Set-Enable Register 0 
IO2INTCLR		EQU		0x400280AC		; Interrupt Port 2 Clear Register

				ALIGN 

				END 