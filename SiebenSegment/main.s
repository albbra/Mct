
; ========================================================================================
; | Modulname:   main.s                                   | Prozessor:  STM32G474        |
; |--------------------------------------------------------------------------------------|
; | Ersteller:   P. Raab                                  | Datum: 07.12.2023            |
; |--------------------------------------------------------------------------------------|
; | Version:   2.2              | Projekt:  Stopuhr       | Assembler:  ARM-ASM          |
; |--------------------------------------------------------------------------------------|
; | Aufgabe:                                                                             |
; |    Stopuhr                                                                           |
; |                                                                                      |
; |                                                                                      |
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
ZAEHLERSTAND RN R1 ; nicht nötig?
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
	
;#################################
; Startwerte
nullen
	MOV ZAEHLERSTAND, #0x3F ;nicht nötig ?
	MOV EINER, #0x3F
	MOV ZEHNER, #0xBF

;#################################
; Defaultzustand
default
	LDR  R0, =GPIOA_ODR
	STR  EINER, [R0]
	
	; 5ms warten -> 0.05s
	MOV  R8, #5
	BL   up_delay
	
	LDR  R0, =GPIOA_ODR
	STR  ZEHNER, [R0]
	
	; 5ms warten -> 0.05s
	MOV  R8, #5
	BL   up_delay
	
	LDR R0, =GPIOC_IDR ; Lesen des Ports C
	LDR R1, [R0]	
	
	CMP R1, #6           ; Ist Bit PC0 gesetzt? -> Start/Weiter
	BNE default 
	
;#################################
; Endlosschleife
loop 
	LDR  R0, =GPIOA_ODR
	STR  EINER, [R0]
	
	; 5ms warten -> 0.05s
	MOV  R8, #5
	BL   up_delay
	
	LDR  R0, =GPIOA_ODR
	STR  ZEHNER, [R0]
	
	; 0.5ms warten -> 0.05s
	MOV  R8, #5
	BL   up_delay
	
	LDR R0, =GPIOC_IDR ; Lesen des Ports C
	LDR R1, [R0]	
	
	CMP R1, #6           ; Ist Bit PC0 gesetzt? -> Start/Weiter
	BEQ zaehler
	
	CMP R1, #3           ; Ist Bit PC2 gesetzt? -> Reset
	BEQ nullen
	
	B	loop
	
;#################################
; Zaehler
zaehler
	
	MOV R6, #0
schleife	
	LDR  R0, =GPIOA_ODR
	STR  EINER, [R0]
	
	; 5ms warten -> 0.05s
	MOV  R8, #5
	BL   up_delay
	
	LDR  R0, =GPIOA_ODR
	STR  ZEHNER, [R0]
	
	; 0.5ms warten -> 0.05s
	MOV  R8, #5
	BL   up_delay
	
	ADD R6,R6,#1
	CMP R6, #10
	BNE schleife

	LDR R0, =GPIOC_IDR ; Lesen des Ports C
	LDR R1, [R0]
	CMP R1, #5           ; Ist Bit PC1 gesetzt? -> Stop
	BEQ loop
	
	LDR  R0, =GPIOA_ODR
	LDR R1, [R0]
	
	CMP EINER, #0x6F     ; 9 ? wenn ja -> 0
	BNE nicht_neun
	MOV EINER, #0x3F	
	B nicht_null
nicht_neun

	CMP EINER, #0x7F     ; 8 ? wenn ja -> 9
	BNE nicht_acht
	MOV EINER, #0x6F
nicht_acht

	CMP EINER, #0x27     ; 7 ? wenn ja -> 8
	BNE nicht_sieben
	MOV EINER, #0x7F
nicht_sieben

	CMP EINER, #0x7D     ; 6 ? wenn ja -> 7
	BNE nicht_sechs
	MOV EINER, #0x27
nicht_sechs

	CMP EINER, #0x6D     ; 5 ? wenn ja -> 6
	BNE nicht_fuenf
	MOV EINER, #0x7D
nicht_fuenf

	CMP EINER, #0x66     ; 4 ? wenn ja -> 5
	BNE nicht_vier
	MOV EINER, #0x6D
nicht_vier

	CMP EINER, #0x4F     ; 3 ? wenn ja -> 4
	BNE nicht_drei
	MOV EINER, #0x66
nicht_drei

	CMP EINER, #0x5B     ; 2 ? wenn ja -> 3
	BNE nicht_zwei
	MOV EINER, #0x4F
nicht_zwei

	CMP EINER, #0x06     ; 1 ? wenn ja -> 2
	BNE nicht_eins
	MOV EINER, #0x5B
nicht_eins

	CMP EINER, #0x3F     ; 0 ? wenn ja -> 9
	BNE nicht_null
	MOV EINER, #0x06
	STR  EINER, [R0]
	;Zehnerstelle+1
	B zeta 
	
nicht_null

	STR  EINER, [R0]

	b z_nicht_null
	
;#################################
zeta ;Zehnerstelle 

	CMP ZEHNER, #0xEF     ; 9 ? wenn ja -> 0
	BNE z_nicht_neun
	MOV ZEHNER, #0xBF	
	B z_nicht_null
z_nicht_neun

	CMP ZEHNER, #0xFF     ; 8 ? wenn ja -> 9
	BNE z_nicht_acht
	MOV ZEHNER, #0xEF
z_nicht_acht

	CMP ZEHNER, #0xA7     ; 7 ? wenn ja -> 8
	BNE z_nicht_sieben
	MOV ZEHNER, #0xFF
z_nicht_sieben

	CMP ZEHNER, #0xFD     ; 6 ? wenn ja -> 7
	BNE z_nicht_sechs
	MOV ZEHNER, #0xA7
z_nicht_sechs

	CMP ZEHNER, #0xED     ; 5 ? wenn ja -> 6
	BNE z_nicht_fuenf
	MOV ZEHNER, #0xFD
z_nicht_fuenf

	CMP ZEHNER, #0xE6     ; 4 ? wenn ja -> 5
	BNE z_nicht_vier
	MOV ZEHNER, #0xED
z_nicht_vier

	CMP ZEHNER, #0xCF     ; 3 ? wenn ja -> 4
	BNE z_nicht_drei
	MOV ZEHNER, #0xE6
z_nicht_drei

	CMP ZEHNER, #0xDB     ; 2 ? wenn ja -> 3
	BNE z_nicht_zwei
	MOV ZEHNER, #0xCF
z_nicht_zwei

	CMP ZEHNER, #0x86     ; 1 ? wenn ja -> 2
	BNE z_nicht_eins
	MOV ZEHNER, #0xDB
z_nicht_eins

	CMP ZEHNER, #0xBF     ; 0 ? wenn ja -> 1
	BNE z_nicht_null
	MOV ZEHNER, #0x86
	
z_nicht_null

	STR ZEHNER, [R0]
	
	B 	zaehler

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