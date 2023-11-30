
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
ZAEHLERSTAND RN R1
ZEHNER 		 RN R2
EINER 		 RN R3

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
    LDR R2, =0xFFFFFFC0     ; Maskierung der Bits [1:0] fuer Pin 0 und Maskierung der Bits [3:2] fuer Pin 1
    AND R1, R1, R2          ; Bits [0:3] = 00 => Input Mode
    STR R1, [R0]	
	
	MOV ZAEHLERSTAND, #0x3F
	MOV EINER, #0x3F
	MOV ZEHNER, #0x80
	
	LDR  R0, =GPIOA_ODR
	STR  EINER, [R0]
	
;#################################
; Endlosschleife
loop 
	
	
	LDR R0, =GPIOC_IDR ; Lesen des Ports C
	LDR R1, [R0]	
	
	B	zaehler
	;CMP R1, #0           ; Sind beide Bits gesetzt?
	;BEQ both_buttons_pressed
	
	
	B	loop
	
;#################################
; Zaehler
zaehler
	
	LDR  R0, =GPIOA_ODR
	
	
	CMP EINER, #0x6F
	BNE nicht_neun
	MOV EINER, #0x3F	
	B nicht_null
nicht_neun

	CMP EINER, #0x7F
	BNE nicht_acht
	MOV EINER, #0x6F
nicht_acht

	CMP EINER, #0x27
	BNE nicht_sieben
	MOV EINER, #0x7F
nicht_sieben

	CMP EINER, #0x7D
	BNE nicht_sechs
	MOV EINER, #0x27
nicht_sechs

	CMP EINER, #0x6D
	BNE nicht_fuenf
	MOV EINER, #0x7D
nicht_fuenf

	CMP EINER, #0x66
	BNE nicht_vier
	MOV EINER, #0x6D
nicht_vier

	CMP EINER, #0x4F
	BNE nicht_drei
	MOV EINER, #0x66
nicht_drei

	CMP EINER, #0x5B
	BNE nicht_zwei
	MOV EINER, #0x4F
nicht_zwei

	CMP EINER, #0x06
	BNE nicht_eins
	MOV EINER, #0x5B
nicht_eins

	CMP EINER, #0x3F
	BNE nicht_null
	MOV EINER, #0x06
	;Zehnerstelle
	ADD Zehner
	
	B zeta 
	
nicht_null

	; 100ms warten
	MOV  R8, #1000
	BL   up_delay
	
	STR  EINER, [R0]
	
	b loop
	
zeta ;Zehner+1 



b loop



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