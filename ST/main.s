
; ========================================================================================
; | Modulname:   main.s                                   | Prozessor:  STM32G474        |
; |--------------------------------------------------------------------------------------|
; | Ersteller:   P. Raab                                  | Datum: 17.09.2020            |
; |--------------------------------------------------------------------------------------|
; | Version:   1.0               | Projekt:  Lauflicht    | Assembler:  ARM-ASM          |
; |--------------------------------------------------------------------------------------|
; | Aufgabe:                                                                             |
; |    Es soll ein einfaches Lauflicht (8x LEDs der MCT-Lehrplattform) mit einer         |
; |    Umschaltfrequenz von 500 ms  realisiert werden.                                   |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Bemerkungen:                                                                         |
; |                                                                                      |
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

; ------------------------------ Datensection / Variablen -----------------------------------		

	
; ------------------------------- Codesection / Programm ------------------------------------
	AREA	main_s, code
	



		
		
		
	
; Einsprungpunkt		
main  PROC
	;#################################
    ; Konfiguration der Portpins PA[7:0] for LEDs	
    ldr R0, =RCC_AHB2ENR
    ldr R1, =1              ; enable Port A  (Bit 0)
    str R1, [R0]

    ldr R0, =GPIOA_MODER
    ldr R1, [R0]            ; Reset Value for Port A =0xABFFFFFF (Alternate Functions for JTAG /SWD)
    ldr R2, =0xFFFF0000     ; Maskierung der Pins [7:0]
    and R1, R1, R2
    ldr R2, =0x00005555     ; 01: General Output Mode
    orr R1, R2
    str R1, [R0]

    mov  LEDS, #0x01   ; Initialwert der LEDs

; Endlosschleife
loop 
    ; Schalten der LEDs
	ldr  R0, =GPIOA_ODR
	orr  LEDS, LEDS, #1
	str  LEDS, [R0]

	; Schieben der LEDs
    lsl  LEDS, LEDS, #1	
	cmp  LEDS, #0x100
	bne  weiter
	
	; und wieder von vorne
	mov  LEDS, #0x01
	
weiter	
    mov r0, #500
	bl  up_delay

    B	loop	
	
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