
; ========================================================================================
; | Modulname:   main.s                                   | Prozessor:  STM32G474        |
; |--------------------------------------------------------------------------------------|
; | Ersteller:   P. Raab                                  | Datum: 17.09.2020            |
; |--------------------------------------------------------------------------------------|
; | Version:   2.0               | Projekt:  Lauflicht    | Assembler:  ARM-ASM          |
; |--------------------------------------------------------------------------------------|
; | Aufgabe:                                                                             |
; |    Es soll ein einfaches Lauflicht (8x LEDs der MCT-Lehrplattform) mit einer         |
; |    Umschaltfrequenz von 500 ms  realisiert werden.                                   |
; |    Das Lauflicht soll nur laufen, solange der Taster an Pin PC0 gedrueckt ist.       |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Bemerkungen:                                                                         |
; |    Die Tastendruckerkennung soll mittels Polling erfolgen.                           |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Aenderungen:                                                                         |
; |     17.09.2020        P. Raab              Initialversion                            |
; |     29.07.2021        P. Raab              Portierung auf STM32G474                  |
; |                                                                                      |
; ========================================================================================

; ------------------------------- includierte Dateien ------------------------------------
    INCLUDE STM32G4xx_REG_ASM.inc
	
	
; ------------------------------- exportierte Variablen ------------------------------------


; ------------------------------- importierte Variablen ------------------------------------		
		

; ------------------------------- exportierte Funktionen -----------------------------------		
	EXPORT  main

; ------------------------------- importierte Funktionen -----------------------------------
    IMPORT  up_delay

; ------------------------------- symbolische Konstanten ------------------------------------
LEDS RN R4
LEDS2 RN R5
LEDS3 RN R6

; ------------------------------ Datensection / Variablen -----------------------------------		

	
; ------------------------------- Codesection / Programm ------------------------------------
	AREA	main_s, code
	

	
; Einsprungpunkt		
main  PROC
	;#################################
    ; Konfiguration der Portpins PA[7:0] fuer LEDs	
    ldr R0, =RCC_AHB2ENR
    ldr R1, =5              ; enable Port A+C  (Bit 0 und 2)
    str R1, [R0]

    ldr R0, =GPIOA_MODER
    ldr R1, [R0]            ; Reset Value for Port A =0xABFFFFFF (Alternate Functions for JTAG /SWD)
    ldr R2, =0xFFFF0000     ; Maskierung der Pins [7:0]
    and R1, R1, R2
    ldr R2, =0x00005555     ; 01: General Output Mode
    orr R1, R2
    str R1, [R0]


	;#################################
    ; Konfiguration des Portpins PC[0] and PC[1] fuer Button
    ldr R0, =GPIOC_MODER
    ldr R1, [R0]            
    ldr R2, =0xFFFFFFFC     ; Maskierung der Bits [1:0] fuer Pin 0
    and R1, R1, R2          ; Bits [0:1] = 00 => Input Mode
    str R1, [R0]	
	
    mov  LEDS, #0x01   ; Initialwert der LEDs 00000001
	mov  LEDS2, #0x80  ; 10000000
	mov	 LEDS3, #0x18  ; 00011000

;#################################
; Endlosschleife
loop 

    LDR R0, =GPIOC_IDR ; Lesen des Ports C
    LDR R1, [R0]
    AND R1, R1, #0x1   ; Maskierung des Bits 0
    CMP R1, #0x1       ; Ist Bit PC0 gesetzt?
    BEQ button1_pressed
	
	LDR R0, =GPIOC_IDR
    LDR R1, [R0]
    AND R1, R1, #0x2   ; Masking bit 1 (PC1)
    CMP R1, #0x2       ; Is bit PC1 set?
    BEQ button2_pressed
	
	LDR R0, =GPIOC_IDR
    LDR R1, [R0]
    AND R1, R1, #0x3   ; Maskierung der Bits 0 und 1 (PC0 und PC1)
    CMP R1, #0x3       ; Sind beide Bits gesetzt?
    BEQ both_buttons_pressed
	
	; wenn wir hier ankommen, wissen wir, dass
    ; kein Button gedrückt ist
	B	loop

;#################################
; Buttons wurden gedrückt
button1_pressed ; Taster 1 ist gedrückt
	; Schalten der LEDs
	ldr  R0, =GPIOA_ODR
	orr  LEDS, LEDS, #1
	str  LEDS, [R0]

	; Schieben der LEDs
	lsl  LEDS, LEDS, #1
	cmp  LEDS, #0x100
	bne  weiter1
	mov  LEDS, #0x01  ; und wieder von vorne

	ADD R3, R3, #1      
    CMP R3, #5          
    BNE button1_pressed 

	B	loop
	
weiter1	
    mov r0, #500
	bl  up_delay

    B	button1_pressed
	
	
button2_pressed ; Taster 2 ist gedrückt
; Schalten der LEDs
	ldr  R0, =GPIOA_ODR
	orr  LEDS2, LEDS2, #0x80
	str  LEDS2, [R0]

	; Schieben der LEDs
	lsr  LEDS2, LEDS2, #1
	cmp  LEDS2, #0x00
	bne  weiter2
	mov  LEDS2, #0x80  ; und wieder von vorne

	ADD R3, R3, #1      
    CMP R3, #5          
    BNE button2_pressed 

	B	loop
	
weiter2	
    mov r0, #500
	bl  up_delay

    B	button2_pressed

both_buttons_pressed ; Taster 1 und 2 ist gedrückt
; Schalten der LEDs
	ldr  R0, =GPIOA_ODR
	orr  LEDS3, LEDS3, #0x18
	str  LEDS3, [R0]
	
	; Schieben zum spiegeln
	LSL LEDS3, LEDS3, #1

	cmp  LEDS3, #0xF1    
    beq  wiederholen   

	; Spiegeln 
    MOV R7, LEDS3  
	LSL R7, R7, #4 
	LSR LEDS3, LEDS3, #4 
	ORR LEDS3, LEDS3, R7 
	
	mov r0, #500
	bl  up_delay

	ADD R3, R3, #1      
    CMP R3, #5          
    BNE both_buttons_pressed 

	B	loop
	
wiederholen
	mov  LEDS3, #0x18  ; und wieder von vorne
	B both_buttons_pressed

	ENDP				
    END




; ========================================================================================
; | UP-Name:                                              | Modul:                       |
; |--------------------------------------------------------------------------------------|
; | Ersteller:                                            | Datum:                       |
; |--------------------------------------------------------------------------------------|
; |  Projekt:                                             | Prozessor:  LPC1778          |
; |--------------------------------------------------------------------------------------|
; | Funktion:                                                                            |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Eingangsgroessen:  (Parameter)                                                       |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Ausgangsgroessen:                                                                    |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Nebeneffekte:                                                                        |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Bemerkungen:                                                                         |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Aenderungen:                                                                         |
; |     tt.mm.yyyy        Name              Beschreibung                                 |
; |                                                                                      |
; ========================================================================================