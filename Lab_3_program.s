; ECE-222 Lab ... Winter 2013 term 
; Lab 3 sample code 
			THUMB 		; Thumb instruction set 
            AREA 		My_code, CODE, READONLY
            EXPORT 		__MAIN
			ENTRY  
__MAIN
; The following lines are similar to Lab-1 but use a defined address to make it easier.
; They just turn off all LEDs 
				LDR			R10, =LED_BASE_ADR	; R10 is a permenant pointer to the base address for the LEDs, offset of 0x20 and 0x40 for the ports
				LDR			R9, =FIO2PIN		; Reads INT0 Push Button
				
				MOV 		R3, #0xB0000000		
				STR 		R3, [R10, #0x20]	; Turn off three LEDs on port 1  
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn off five LEDs on port 2 

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Block for testing Delay time, should be around 10 seconds per iteration of loop
;looptest		MOV 		R3, #0xA0000000
;				STR			R3, [R10, #0x20]	
;				MOV			R0, #0x86A0
;				MOVT		R0, #0x0001
;				BL			DELAY
;				MOV 		R3, #0xB0000000
;				STR			R3, [R10, #0x20]
;				MOV			R0, #0x86A0
;				MOVT		R0, #0x0001
;				BL			DELAY
;				B			looptest				
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;				BL				SimpleCounter	; Call SimpleCounter, displaying 0 to 255
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV			R11, #0xABCD		; Init the random number generator with a non-zero number
loop 			BL 			RandomNum 
				MOV			R0, R11
				LSL			R0, #24				; Shift R0 left 24 bits, keeping the 8 LSB, which are now the 8 MSB
				LSR			R0, #24				; Shift R0 right 24 bits, moving the 8 wanted bits back to their original position, keeping only the original 8 LSB of R0
				ADD			R0, R0, #34			; Arbitrary addition to the number in R0 in order to set-up the correct 2 to 10 second range, making the number between 34 to 289, or (0 + 34) to (255 + 34)
				MOV			R4, #350			; Arbitrary number 34, that when multiplied with numbers between (0 + 34) and (255 + 34) will give 11900 to 103200
				MUL			R0, R0, R4			; R0 is now roughly between 20000 and 100000, which will give a delay of 2s and 10s respectively when multiplied with 0.1 ms
				BL			DELAY				; Call delay, which will be between 2s and 10s given the R0 value set above
				
				BL			POLL				; After delay, call POLL, which will turn on the light and wait for the user to press the button
				
				BL			SEND_RESULT			; After user presses button, call SEND_RESULT to display their reaction time in units of 0.1 ms
				
				B 			loop				

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; Send the result of the user's reaction time to be displayed in four 8-bit patterns
SEND_RESULT		STMFD		R13!,{R7, R8, R12, R14}

				MOV			R8, R3				; Move the contents of R3 to R8, to preserve an unchanging record of them

Resend			MOV			R7, R8				; Move the contents of R8 to R7, to move and manipulate the data in R7 while not changing R8
				MOV			R12, #4				; Initialize the R12 as 4 to be the loop counter, as we want to send 8 bits of data 4 times, which is 32 in total

DisplayNext		MOV			R3, #0				; Clear R3
				BFI			R3, R7, #0, #8		; Insert the 8 LSB of R7 to R3
				BL			DISPLAY_NUM			; Call DISPLAY_NUM to the number stored in R3
				MOV			R0, #20000			; Initiliaze R0 to 20000, which will give a delay on 2 seconds (20000 * 0.1 ms)
				BL			DELAY				; Delay for 2 seconds
				LSR			R7,	#8				; Shift R7 right by 8 bits, meaning that the previous bits 15 to 8 are now bits 7 to 0
				SUBS		R12, R12, #1		; Subtract 1 from the loop counter, and set to Z flag
				BNE			DisplayNext			; If Z flag is not zero (ie, R12 is not zero), loop to display the next number
				
				MOV			R0, #30000			; Once loop ends, we want to delay for 5 seconds before restarting, so add 3 seconds onto the 2 seconds covered in the last iteration of the loop
				BL			DELAY				; Delay for 3 seconds
				
				B			Resend				; Restart the number sequence

				LDMFD		R13!,{R6, R8, R12, R15}

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; Poll for user input, and count until input is received
POLL			STMFD		R13!,{R5, R6, R14}

				MOV 		R3, #0x90000000		; Give R3 the equivalent of the bit pattern 1001...., meaning that the 29th bit is 0, which will turn on the LED at P1.29
				STR 		R3, [R10, #0x20]	; Write to P1 the contents of R3, turning on P1.29 while leaving the other two off
				MOV			R3, #0				; Clear R3 for use below
				
count			ADD			R3, R3, #1			; Increment R3 by 1
				MOV			R0, #1				; Set R0 as 1, which will give a delay of 0.1 ms
				BL			DELAY				; Delay for 0.1 ms
				
				LDR			R6,[R9]				; Load into R6 the information stored in R9, which is the memory location "FIO2PIN" corresponding to 0x2009c054 or P2 on the board
				LSR			R6, #10				; Shift R6 right by 10 bits, as the information we want is in the 10th bit
				MOV			R5, #0				; Clear R5, to make sure that it is 0
				BFI			R5, R6, #0, #1		; Take the 1 LSB of the contents of R6 and put them into R5
				ANDS		R5, R5, #0x1		; Check if the current LSB of R5 is 1, and set the status flag Z (ie, LSB of R5 is 1 -> Z = 1, LSB of R5 is 0 -> Z = 0)
				BNE			count				; If Z is not 0, then it means that the LSB of R5 is 1, which implies that the button is not pressed, so keep looping and counting the time
				
				MOV 		R6, #0xB0000000		; User has pushed button, so prepare to turn off all P1 LEDs
				STR 		R6, [R10, #0x20]	; Turn off three LEDs on port 1

				LDMFD		R13!,{R5, R6, R15}

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; Display the number in R3 onto the 8 LEDs
; Useful commaands:
; RBIT (reverse bits)
; BFC (bit field clear)
; LSR & LSL to shift bits left and right
; ORR & AND and EOR for bitwise operations
DISPLAY_NUM		STMFD		R13!,{R1, R2, R14}


; Adjusting bits for P1

				MOV			R1, R3				; Move the contents of R3, containing the number to be displayed, into R1 so that we can manipulate it
				LSR			R1, #5				; Cut to 3 MSB (leftmost), and the 3 MSB are now the 3 LSB (ie, abc... -> ...abc)
				RBIT		R1, R1				; Flip bit order, 3 MSB flipped from original (ie, ...abc -> cba...)
				
				MOV			R2, R1				; Move the modified content in R1 into R2
				LSR			R2, #31				; Shift right 31 bits in R2, leaving only the MSB, which is now the LSB (ie, abc... -> ...a)
				RBIT		R2, R2				; Flip bit order, making the LSB to the MSB again (ie, ...a -> a...)
				
				LSL			R1, #1				; Shift left one bit in R1, getting rid of the MSB (ie, abc... -> bc...)
				LSR			R1, #2				; Shift left two bits in R1, making the two MSB 0's (ie, bc... -> 00bc...)
				
				ADD			R1, R1, R2			; Add R1 and R2, and leave the result in R1 (ie, R2 + R1 = a... + 00bc... = a0bc...)
				
				EOR			R1, R1, #4294967295 ; R1 XOR 2^32 - 1, which is 32 bits of 1's, giving the result of each bit in R1 being flipped, as 0 turns the LED on and 1 turns of LED off
				STR			R1,	[R10, #0x20]	; Write R1 to P1
			
; Adjusting bits for P2

				MOV			R1, R3				; Move the contents of R3, containing the number to be displayed, into R1 so that we can manipulate it
				LSL			R1, #27				; Cut to 5 LSB (rightmost), and the 5 LSB are now the 5 MSB (ie, ...abcde -> abcde...)
				RBIT		R1, R1				; Flip bit order, 5 LSB flipped from original (ie, abcde... -> ...edcba)
				
				LSL			R1, #2				; Offset bits so they fit into their respective bits in P2 (ie, ...edcba -> ...edcba00)
				EOR			R1, R1, #4294967295	; R1 XOR 2^32 - 1, which is 32 bits of 1's, giving the result of each bit in R1 being flipped, as 0 turns the LED on and 1 turns of LED off
				STR			R1,	[R10, #0x40]	; Write R1 to P2

				LDMFD		R13!,{R1, R2, R15}

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; simple counter from 0 to 255
SimpleCounter	STMFD		R13!,{R2, R3, R14}
			
				MOV			R3, #0				; Initialize R3 as 0, which is the counter for the number being counted from 0 to 255
				MOV			R2, #255			; Initialize R2 as 255, which is the loop counter
			
counterLoop		BL			DISPLAY_NUM			; Call DISPLAY_NUM to display the current number in R3
				MOV			R0, #1000			; 1000 * 100 us = 0.1 s
				BL			DELAY				; Delay for 0.1 s
				ADD			R3, R3, #1			; Add 1 to R3
				SUBS		R2, R2, #1			; subtract 1 from R2, set Z flag
				
				BNE			counterLoop			; If Z is not 0, it means that R2 is not zero yet, so loop again
				
				BL			DISPLAY_NUM			; Display 255 in R3, or else it will be skipped
				MOV			R0, #1000			; 1000 * 100 us = 0.1 s
				BL			DELAY				; Delay for 0.1 s
				
				MOV			R3, #0				; Re-initialize R3 as 0, which is the counter for the number being counted from 0 to 255
				MOV			R2, #255			; Re-initialize R2 as 255, which is the loop counter
				
				B			counterLoop			; Restart entire loop
				
				LDMFD		R13!,{R2, R3, R15}
			
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; R11 holds a 16-bit random number via a pseudo-random sequence as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 holds a non-zero 16-bit number.  If a zero is fed in the pseudo-random sequence will stay stuck at 0
; Take as many bits of R11 as you need.  If you take the lowest 4 bits then you get a number between 1 and 15.
; If you take bits 5..1 you'll get a number between 0 and 15 (assuming you right shift by 1 bit).
;
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program OR ELSE!
; R11 can be read anywhere in the code but must only be written to by this subroutine
RandomNum		STMFD		R13!,{R1, R2, R3, R14}

				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1			; the new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				
				LDMFD		R13!,{R1, R2, R3, R15}
			
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

;		Delay 0.1ms (100us) * R0 times
; 		aim for better than 10% accuracy
DELAY			STMFD		R13!,{R2, R14}
MultipleDelay
				TEQ		R0, #0					; test R0 to see if it is 0
				BEQ		exitDelay				; branch to exitDelay if R0 is 0, since no more iterations left
			
				MOV		R2, #0x85				; initialize a value in R2 as 85, giving 0.1 ms per iteration of delay
			
loopDelay
				SUBS 	R2, #1					; subtract 1 from the counter R2
				BNE		loopDelay				; loop until R2 is 0
				SUBS	R0, #1					; after R2 is 0, subtract 1 from R0
				B		MultipleDelay			; branch to MultipleDelay to re-evaluate R0 and reset R2 counter

exitDelay		LDMFD	R13!,{R2, R15}

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

LED_BASE_ADR	EQU 	0x2009c000 				; Base address of the memory that controls the LEDs
FIO2PIN			EQU		0x2009c054				; Address of INT0 Push Button
PINSEL3			EQU 	0x4002c00c 				; Address of Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002c010 				; Address of Pin Select Register 4 for P2[15:0]
;	Usefull GPIO Registers
;	FIODIR  - register to set individual pins as input or output
;	FIOPIN  - register to read and write pins
;	FIOSET  - register to set I/O pins to 1 by writing a 1
;	FIOCLR  - register to clr I/O pins to 0 by writing a 1

				ALIGN 

				END 
				
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; LAB REPORT
;
; Q1
; The maximum number that can be encoded into each bit is:
; 8 bits - 255; 16 bits - 65 535; 24 bits - 16 777 215; 32 bits - 4 294 967 295
; Since each number represents 0.1 ms, the maximum time we can display is:
; 8 bits: 255 * 0.1 ms = 25.5 ms = 0.0255 s
; 16 bits: 6535 ms = 6.535 s
; 24 bits: 1677721.5 ms = 1677.7215 s = 27.962025 minutes
; 32 bits: 429496729.5 ms = 429496.7295 s = 7158.278825 minutes = 119.304647083 hours, almost 5 days
; 
; Q2
; The average human reaction time to a visual stimulus is 0.25 second or 250 ms.
; Given that 8 bits displays 25.5 seconds at maximum, it is too small to accurately display reaction time for an average person.
; Therefore, the best size would be 16 bits, as it can display up to 6.535 seconds, which is plenty of time for any human to react.
; 