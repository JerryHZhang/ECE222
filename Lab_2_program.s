;*----------------------------------------------------------------------------
;* Name:    Lab_2_program.s 
;* Purpose: This code template is for Lab 2
;* Author: Eric Praetzel and Rasoul Keshavarzi 
;*----------------------------------------------------------------------------*/
		THUMB 		; Declare THUMB instruction set 
                AREA 		My_code, CODE, READONLY 	; 
                EXPORT 		__MAIN 		; Label __MAIN is used externally q
		ENTRY 
__MAIN
; The following lines are similar to Lab-1 but use an address, in r4, to make it easier.
; Note that one still needs to use the offsets of 0x20 and 0x40 to access the ports
;
; Turn off all LEDs 
		MOV 	R2, #0xC000
		MOV 	R3, #0xB0000000	
		MOV 	R4, #0x0
		MOVT 	R4, #0x2009
		ADD 	R4, R4, R2 		; 0x2009C000 - the base address for dealing with the ports
		STR 	R3, [R4, #0x20]	; Turn off the three LEDs on port 1
		MOV 	R3, #0x0000007C
		STR 	R3, [R4, #0x40] ; Turn off five LEDs on port 2 
		
ResetLUT
		LDR     R5, =InputLUT            ; assign R5 to the address at label LUT

NextChar
        LDRB    R0, [R5]		; Read a character to convert to Morse
        ADD     R5, #1          ; point to next value for number of delays, jump by 1 byte
		TEQ     R0, #0          ; If we hit 0 (null at end of the string) then reset to the start of lookup table
		BNE		ProcessChar		; If we have a character process it

		MOV		R0, #4			; delay 4 extra spaces (7 total) between words
		BL		DELAY			; call DELAY subroutine to delay for 4*500 ms
		BEQ     ResetLUT		; If R0 is 0, then restart the word from the beginning

ProcessChar	BL		CHAR2MORSE	; convert ASCII to Morse pattern in R1		

;	This is a different way to read the bits in the Morse Code LUT than is in the lab manual.
; 	Choose whichever one you like.
; 
;	First - loop until we have a 1 bit to send  (no code provided)
;
;	This is confusing as we're shifting a 32-bit value left, but the data is ONLY in the lowest 16 bits, so test starting at bit 15 for 1 or 0
;	Then loop thru all of the data bits:
;
		MOV		R6, #0x80000000	; Init R6 with the value for the bit, 15th, which we wish to test
		LSL		R1, R1, #16		; shift R1 left by 16, only need the lowest 16 bits of 32

SkipZeroes	;	skipping zeroes padded in front of binary
		LSL		R1, R1, #1		; shift R1 left by 1, store in R1
		ANDS	R7, R1, R6		; R7 gets R1 AND R6, Zero bit gets set telling us if the bit is 0 or 1	
		BEQ		SkipZeroes		; branch to SkipZeroes to continue looping
		LSR		R1, R1, #1		; if it was not zero, then shift R1 right to restore the
								; previous bit, or else it would have skipped a non-zero
		
Main		; main function
		LSL		R1, R1, #1		; shift R1 left by 1, store in R1
		TEQ		R1,#0			; test R1 = 0
		BEQ		Pause			; if R1 = 0, then branch to Pause
		ANDS	R7, R1, R6		; R7 gets R1 AND R6, Zero bit gets set telling us if the bit is 0 or 1	
		BEQ		MorseSpace		; branch somewhere it's zero
		BNE		MorseDot		; branch somewhere - it's not zero
		
MorseDot	; light ON
		BL 		LED_ON			; call LED_ON subroutine, to turn LED ON
		MOV		R0, #1			; initiate R0 with value a of 1, for delay
		BL		DELAY			; call DELAY subroutine to delay for 1*500 ms (one dot)
		B		Main			; branch back to Main
		
MorseSpace	; light OFF
		BL 		LED_OFF			; call LED_OFF subroutine
		MOV		R0, #1			; initiate R0 with a value of 1, for delay
		BL 		DELAY			; call DELAY subroutine to delay for 1*500 ms (space between dashes and dots)
		B		Main			; branch back to Main
		
Pause		; set 1.5 seconds of wait time, and go to process the next character
		BL		LED_OFF			; turn LED OFF, in case it was ON for the last bit
		MOV		R0, #3			; set R0 as 3, for default delay between two morse characters
		BL 		DELAY			; call DELAY subroutine to delay for 3*500 ms (3 dots)
		B 		NextChar 		; get next character in word, or reset the word

; Subroutines
;
;			convert ASCII character to Morse pattern
;			pass ASCII character in R0, output in R1
;			index into MorseLuT must be by steps of 2 bytes
CHAR2MORSE	STMFD	R13!,{R0, R3, R14}	; push Link Register (return address) on stack
		;
		; add code here to convert the ASCII to an index (subtract 41)
		; and lookup the Morse patter in the Lookup Table
		
		SUBS  	R0, #0x41		; subtract 41 from ASCII to get index
		LDR		R3, =MorseLUT 	; load look up table address of character
		
loopMorse
		LDRH	R9, [R3]		; load R9 with the halfword of R3
		ADD		R3, #2			; add 2 to R3 to get next index of LUT
		TEQ		R0, #0			; test R0 = 0
		BEQ		ExitMorse		; if R0 is 0, then branch to ExitMorse
		SUBS	R0, #1			; subtract 1 from R0, to decrement until 0 for correct LUT index
		B		loopMorse		; branch to loopMorse
		
ExitMorse
		MOV		R1, R9			; move the value of R9 into R1
		LDMFD	R13!,{R0, R3, R15}	; restore LR to R15 the Program Counter to return


; Turn the LED on, but deal with the stack in a simpler way
; NOTE: This method of returning from subroutine (BX  LR) does NOT work if subroutines are nested!!
;
LED_ON		push	{r3-r4}		; preserve R3 and R4 on the R13 stack
		MOV 	R3, #0xA0000000	; move "0xA0000000" into R3 to turn ON the LED
		STR 	R3, [R4, #0x20]	; write R3 to address in R4, offset by 0x20
		pop 	{r3-r4}			; restore original R3 and R4 from stack
		BX 		LR		; branch to the address in the Link Register - return to the caller

; Turn the LED off, but deal with the stack in the proper way
; the Link register gets pushed onto the stack so that subroutines can be nested
;
LED_OFF		STMFD	R13!,{R3, R14}	; push R3 and Link Register (return address) on stack
		MOV 	R3, #0xB0000000	; move "0xB0000000" into R3 to turn OFF the LED
		STR 	R3, [R4, #0x20]	; write R3 to address in R4, offset by 0x20
		LDMFD	R13!,{R3, R15}	; restore R3 and LR to R15 the Program Counter to return

;	Delay 500ms * R0 times
;	Use the delay loop from Lab-1 but loop R0 times around

DELAY		STMFD		R13!,{R2, R14}
MultipleDelay
		TEQ		R0, #0			; test R0 to see if it's 0
		BEQ		exitDelay		; branch to exitDelay if R0 is 0, since no more iterations left
		
		MOV		R2, #0x80000	; initialize a value in R2 for counting down

loopDelay
		SUBS 	R2, #1			; subtract 1 from the counter R2
		BNE		loopDelay		; loop until R2 is 0
		SUBS	R0, #1			; after R2 is 0, subtract 1 from R0
		B		MultipleDelay	; branch to MultipleDelay to re-evaluate R0 and reset R2 counter

exitDelay	LDMFD	R13!,{R2, R15}	; restore R3 and LR to R15 the Program Counter to return

;
; Data used in the program
; DCB is Define Constant Byte size
; DCW is Define Constant Word (16-bit) size
; EQU is EQUate or assign a value.  This takes no memory but instead of typing the same address in many places one can just use an EQU
;
		ALIGN				; make sure things fall on word addresses

; One way to provide a data to convert to Morse code is to use a string in memory.
; Simply read bytes of the string until the NULL or "0" is hit.  This makes it very easy to loop until done.
;
InputLUT	DCB		"ZHANG", 0	; --../..../.-/-./--.

		ALIGN				; make sure things fall on word addresses
MorseLUT 
		DCW 	0x17, 0x1D5, 0x75D, 0x75 	; A, B, C, D
		DCW 	0x1, 0x15D, 0x1DD, 0x55 	; E, F, G, H
		DCW 	0x5, 0x1777, 0x1D7, 0x175 	; I, J, K, L
		DCW 	0x77, 0x1D, 0x777, 0x5DD 	; M, N, O, P
		DCW 	0x1DD7, 0x5D, 0x15, 0x7 	; Q, R, S, T
		DCW 	0x57, 0x157, 0x177, 0x757 	; U, V, W, X
		DCW 	0x1D77, 0x775 				; Y, Z

; One can also define an address using the EQUate directive
;
LED_PORT_ADR	EQU	0x2009c000	; Base address of the memory that controls I/O like LEDs

		END 

;
; From ProcessChar at the top, moved down here to view code better
;
;	Alternate Method #2
; Shifting the data left - makes you walk thru it to the right.  You may find this confusing!
; Instead of shifting data - shift the masking pattern.  Consider this and you may find that
;   there is a much easier way to detect that all data has been dealt with.

;		LSR		R6, #1		; shift the mask 1 bit to the right
;		ANDS		R7, R1, R6	; R7 gets R1 AND R6, Zero bit gets set telling us if the bit is 0 or 1


;	Alternate Method #3
; All of the above methods do not use the shift operation properly.
; In the shift operation the bit which is being lost, or pushed off of the register,
; "falls" into the C flag - then one can BCC (Branch Carry Clear) or BCS (Branch Carry Set)
; This method works very well when coupled with an instruction which counts the number 
;  of leading zeros (CLZ) and a shift left operation to remove those leading zeros.


;	Alternate Method #4
;
; Ok - you are a hot coder and you've got time to burn and want to shorten your code.  Try this:
; Reverse the Morse Code LUT and encode the bits as follows (01 = short, 11 = 3 delay long, 00 = done)
; By doing this one could just shift right and peel off 2 bits at a time, without the need to count to know when you're
; done or peel off a bunch of empty 0's.  This method means that the encoded information ALTERNATES between on and off!
; The first 01 or 11 count is LED on, and the following one is off, then the next is on ....  till you hit 00

;
;	Additional Work
; 
; Are you still bored?  You want to make sweet Morse Code Music?
; Well - lets get the speaker humming.
;
; Note: If you do use this then decrease the delay to 50 to 100ms so that one can both "read" the LED and audio pattern
;
; By modifying your 500ms delay loop to be two loops - an inner loop of 0x200 that toggles the speaker when done
;  and an outer loop to ensure that the total delay is 500ms
;
; The speaker is on Port 0 ping 26 and by toggling it's at an audible frequency one can make a sound
;
; A simple hack to this code is to modify the EOR line to use another register.  If the register is
; 0x4000000 then the speaker will sound; but if it's 0x0 then the speaker stays silent
;
;		LDR	R4, =LED_PORT_ADR	; setup speaker address
;		MOV	R5, #0x4000000		; This is bit 26 which goes to the speaker
;Again		MOV	R3, #0x200
;loopBuzz	MOV	R2, #0x200		; aprox 1kHz since looping 0x10000 times is ~ 10Hz
;loopMore	SUBS	R2, #1			; decreament inner loop to make a sound;
;		BNE	loopMore
;		EOR	R5, #0x4000000		; toggle speaker output
;		STR	R5, [R4]		; write to speaker output
;		SUBS	R3, #1
;		B	Again