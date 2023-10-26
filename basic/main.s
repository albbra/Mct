; ========================================================================================
; | Modulname:   main.s                                   | Prozessor:  STM32G474        |
; |--------------------------------------------------------------------------------------|
; | Ersteller:   Peter Raab                               | Datum:  03.09.2021           |
; |--------------------------------------------------------------------------------------|
; | Version:     V1.0            | Projekt:               | Assembler:  ARM-ASM          |
; |--------------------------------------------------------------------------------------|
; | Aufgabe:     Basisprojekt                                                            |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Bemerkungen:                                                                         |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Aenderungen:                                                                         |
; |     03.09.2021     Peter Raab        Initial version                                 |
; |                                                                                      |
; ========================================================================================

; ------------------------------- includierte Dateien ------------------------------------
    INCLUDE STM32G4xx_REG_ASM.inc

; ------------------------------- exportierte Variablen ------------------------------------


; ------------------------------- importierte Variablen ------------------------------------		
		

; ------------------------------- exportierte Funktionen -----------------------------------		
	EXPORT  main

			
; ------------------------------- importierte Funktionen -----------------------------------


; ------------------------------- symbolische Konstanten ------------------------------------


; ------------------------------ Datensection / Variablen -----------------------------------


; ------------------------------- Codesection / Programm ------------------------------------
	AREA	main_s,code
	


			
; -----------------------------------  Einsprungpunkt - --------------------------------------

main PROC

   ; Initialisierungen
		
loop	

	;ldr R8, =0x54 ; Lade 54h in Register
	;add R8, #1 ; Inkrementiere Register
	;lsl R8, #1 ; Logisches Schieben um ein Bit nach links
	;and R8, #0x0F ; binaeres UND mit 0Fh
	;orr R8, #0x05 ; binaeres ODER mit 05h
	;add R8, #2 ; Increment

    mov R9, #0 ; Clear Register
    ldr R10, =0x80000000
	adds R11, R10, R9 ; Addiere 8000:0000h zum Register
	adds R11, R11, R10 ; Addiere 8000:0000h zum Register
	adcs R11, R11, R10 ; Addiere 8000:0000h zum Register
	adcs R11, R11, R10 ; Addiere 8000:0000h zum Register
	adds R11, R11, R10 ; Addiere 8000:0000h zum Register

   ; wiederholter Anwendungscode

   B	loop	
  
   ENDP

   END
		