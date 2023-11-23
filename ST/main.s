
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
LEDS  RN R4
LEDS2 RN R5
LEDS3 RN R6

; ------------------------------ Datensection / Variablen -----------------------------------		

	
; ------------------------------- Codesection / Programm ------------------------------------
	AREA	main_s, code
	

	
; Einsprungpunkt		
main  PROC
	;#################################
    ; Aktivieren der I/O-Ports
    LDR R0, =RCC_AHB2ENR
    LDR R1, =5              ; enable Port A+C  (Bit 0 und 2)
	LDR R2, =0x00000005		; Maskierung der I/O-Ports 
	AND R1, R1, R2
    STR R1, [R0]

	; Konfiguration der Portpins PA[7:0] fuer LEDs
    LDR R0, =GPIOA_MODER
    LDR R1, [R0]            ; Reset Value for Port A =0xABFFFFFF (Alternate Functions for JTAG /SWD)
    LDR R2, =0xFFFF0000     ; Maskierung der Pins [7:0]
    AND R1, R1, R2
    LDR R2, =0x00005555     ; 01: General Output Mode
    ORR R1, R2
    STR R1, [R0]


	;#################################
    ; Konfiguration des Portpins PC[0] and PC[1] fuer Button
    LDR R0, =GPIOC_MODER
    LDR R1, [R0]            
    LDR R2, =0xFFFFFFF0     ; Maskierung der Bits [1:0] fuer Pin 0 und Maskierung der Bits [3:2] fuer Pin 1
    AND R1, R1, R2          ; Bits [0:3] = 00 => Input Mode
    STR R1, [R0]	
	
	; Initialwert der LEDs
    MOV LEDS , #0x01  ; 00000001
	MOV LEDS2, #0x80  ; 10000000
	MOV	LEDS3, #0x18  ; 00011000 
	
	; Wert zum Vergleichen
	LDR R9 , =0x1FE
	LDR R10, =0x1FF
	

;#################################
; Endlosschleife
loop 
	
	
	LDR R0, =GPIOC_IDR ; Lesen des Ports C
	LDR R1, [R0]	
	
	CMP R1, #0           ; Sind beide Bits gesetzt?
	BEQ both_buttons_pressed
	
	CMP R1, #2           ; Ist Bit PC0 gesetzt?
	BEQ button1_pressed

	CMP R1, #1           ; Ist Bit PC1 gesetzt?
	BEQ button2_pressed
	
	LDR  R0, =GPIOA_ODR
	STR  R12, [R0]
	
	B	loop
	

;#################################
; Buttons wurden gedrueckt
button1_pressed ; Taster 1 ist gedrückt
	; Schalten der LEDs
	LDR  R0, =GPIOA_ODR
	
	ORR  LEDS, LEDS, #1
	STR  LEDS, [R0]

	; 100ms warten
	MOV  R8, #100
	BL   up_delay

	; Schieben der LEDs
	LSLS LEDS, LEDS, #1
	
	CMP  LEDS, R9 ; R9 = 0x1FE
	BNE  button1_pressed

	MOV  R8, #100 ; 100ms warten
	BL   up_delay
	
	MOV  LEDS, #0x00
	STR  LEDS, [R0]
	
	MOV  R8, #100 ; 100ms warten
	BL   up_delay
	
	MOV  LEDS, #0x01  ; und wieder von vorne

	ADD  R3, R3, #1 ; Wiederholungszaehler
    CMP  R3, #5          
    BNE  button1_pressed 

	MOV  R3, #0 

	B	 loop
	
;#################################
button2_pressed ; Taster 2 ist gedrueckt
	; Schalten der LEDs
	LDR  R0, =GPIOA_ODR
	
	ORR  LEDS2, LEDS2, #0x80
	STR  LEDS2, [R0]

	; 100ms warten
	MOV  R8, #100
	BL   up_delay

	; Schieben der LEDs
	LSR  LEDS2, LEDS2, #1
	
	CMP  LEDS2, #0x7F
	BNE  button2_pressed 
	
	LDR  R0, =GPIOA_ODR
	
	ORR  LEDS2, LEDS2, #0x80
	STR  LEDS2, [R0]
	
	MOV  R8, #200 ; 100ms warten
	BL   up_delay
	
	MOV  LEDS, #0x00
	STR  LEDS, [R0]
	
	MOV  R8, #100 ; 100ms warten
	BL   up_delay
	
	MOV  LEDS2, #0x80  ; und wieder von vorne

	ADD  R3, R3, #1  ; Wiederholungszaehler
    CMP  R3, #5          
    BNE  button2_pressed 

	MOV  R3, #0 
	
	B	 loop

;#################################
both_buttons_pressed ; Taster 1 und 2 ist gedrueckt
; Schalten der LEDs
	LDR  R0, =GPIOA_ODR
	
	ORR  LEDS3, LEDS3, #0x18
	STR  LEDS3, [R0]
	
	; 200ms warten
	MOV  R8, #200
	BL   up_delay
	
	; Spiegeln 
    MOV  R7, LEDS3  
	LSL  R7, R7, #1 
	LSR  LEDS3, LEDS3, #1 
	ORR  LEDS3, LEDS3, R7 
	
	CMP  LEDS3, R10
	BNE  both_buttons_pressed
	
	MOV  R8, #100 ; 100ms warten
	BL   up_delay
	
	MOV  LEDS, #0x00
	STR  LEDS, [R0]
	
	MOV  R8, #100 ; 100ms warten
	BL   up_delay
	
	MOV  LEDS3, #0x18  ; und wieder von vorne

	ADD  R3, R3, #1 ; Wiederholungszaehler
    CMP  R3, #5          
    BNE  both_buttons_pressed

	MOV  R3, #0 

	B	 loop

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