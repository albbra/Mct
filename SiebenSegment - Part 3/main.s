
; ========================================================================================
; | Modulname:   main.s                                   | Prozessor:  STM32G474        |
; |--------------------------------------------------------------------------------------|
; | Ersteller:   P. Raab                                  | Datum: 02.11.2021            |
; |--------------------------------------------------------------------------------------|
; | Version:   4.0               | Projekt:  Lauflicht  V4| Assembler:  ARM-ASM          |
; |--------------------------------------------------------------------------------------|
; | Aufgabe:                                                                             |
; |    Es soll ein einfaches Lauflicht (8x LEDs der MCT-Lehrplattform) mit einer         |
; |    Umschaltfrequenz von 500 ms  realisiert werden.                                   |
; |    Die Wartezeit bzw. der Trigger zum Weiterschalten soll über einen Timer realisiert|
; |    werden.                                                                           |
; |    Das Lauflicht soll laufen, solange der Taster an Pin PC0 kurz gedrueckt wird.     |
; |    Bei erneuten Drücken des Tasters soll das Lauflicht stoppen.                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Bemerkungen:                                                                         |
; |    Die Tastendruckerkennung soll mittels EXTI Interrupt erfolgen.                    |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Aenderungen:                                                                         |
; |     17.09.2020        P. Raab              Initialversion                            |
; |     29.07.2021        P. Raab              Portierung auf STM32G474                  |
; |     15.10.2021        P. Raab              Erweiterung auf Version V3 (Interrupts)   |
; |     02.11.2021        P. Raab              Erweiterung auf Version V4 (Timer)        |
; |                                                                                      |
; ========================================================================================

; ------------------------------- includierte Dateien ------------------------------------
    INCLUDE STM32G4xx_REG_ASM.inc
	
	
; ------------------------------- exportierte Variablen ------------------------------------


; ------------------------------- importierte Variablen ------------------------------------		
		

; ------------------------------- exportierte Funktionen -----------------------------------		
	EXPORT  main
    EXPORT  EXTI0_IRQHandler
    EXPORT  TIM6_IRQHandler
		
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
    ; Konfiguration des Portpins PC[0], PC[1] und PC[2] fuer Button
    ldr R0, =GPIOC_MODER
    ldr R1, [R0]            
    ldr R2, =0xFFFFFFC0     ; Maskierung der Bits [5:0]
    and R1, R1, R2          ; Bits [0:5] = 00 => Input Mode
    str R1, [R0]	
	
	
	;###################################################
	; Konfiguration des externen Interrupts
    ; Clock enable
    ldr  R0, =RCC_APB2ENR 
    ldr  R1, [R0] 
    orr  R1, #0x01      ; Bit 0 -> SysCfg
    str  R1, [R0]
	
    ; Pin mapping
    ldr   R0, =SYSCFG_EXTICR1
    mov   R1, #2        ; PC[3] -> EXTI_LINE0
    str   R1, [R0]       
	
    ; Triggerflanken
    ldr   R0, =EXTI_FTSR1
    mov   R1, #1        ; Bit 0 -> EXTI_LINE0
    str   R1, [R0] 

    ; NVIC: EXTI Line0 Interrupt = ID 6 => ICPR0/ISER0
    ldr   R0, =NVIC_ICPR0 
    mov   R1, #0x40      ; -> 0100:0000 -> 0x40
    str   R1, [R0]       ; clear pending bit
	
    ldr   R0, =NVIC_ISER0 
    mov   R1, #0x40      ; -> 0100:0000 -> 0x40
    str   R1, [R0]       ; set enable bit

    ; EXTI Line0 Interrupt freigeben
    ldr   R0, =EXTI_IMR1 
    mov   R1, #1         ; bit0 -> EXTI Line 0
    str   R1, [R0]       
	

	;###################################################
	; Konfiguration des Timers 6
    ; Clock enable
    ldr  R0, =RCC_APB1ENR1 
    ldr  R1, [R0] 
    orr  R1, #0x10      ; Bit 4 -> Timer 6
    str  R1, [R0]
	; Prescale Register
    ldr  R0, =TIM6_PSC
    mov  R1, #(16000-1)   ; -> TC_CLK = 1 ms
    str  R1, [R0]	
    ; Auto-Reload Register
    ldr  R0, =TIM6_ARR
    mov  R1, #499   ; -> T = 500 ms
    str  R1, [R0] 
	; Timer control register
	ldr  R0, =TIM6_CR1
    mov  R1, #1   ; -> counter enable 
    str  R1, [R0] 	
	
	; Timer 6: NVIC
    ldr   R0, =NVIC_ICPR1 ; clear pending bit 
    mov   R1, #(1<<22)	
    str   R1, [R0]   
    ldr   R0, =NVIC_ISER1 ; set enable bit
    mov   R1, #(1<<22)    
    str   R1, [R0] 
  
	MOV ZAEHLERSTAND, #0x3F ;nicht nötig ?
	MOV EINER, #0x3F
	MOV ZEHNER, #0xBF  
  
  	; Timer 6 Interrupt
	PUSH {R8,R0,R14}
	ldr  R0, =TIM6_DIER
    mov  R1, #1   ; -> update interrupt enable 
	
    str  R1, [R0]
	POP  {R8,R0,R14}
    mov  R11, #0x01   ; Initialwert der LEDs

; Endlosschleife
loop 

	LDR  R0, =GPIOA_ODR
	STR  EINER, [R0]
	
	; 5ms warten -> 0.05s
	MOV  R8, #2
	BL   up_delay
	
	LDR  R0, =GPIOA_ODR
	STR  ZEHNER, [R0]
	
	; 5ms warten -> 0.05s
	MOV  R8, #2
	BL   up_delay
	
    B	loop	

	


	ENDP				





; ========================================================================================
; | UP-Name:    EXTI0_IRQHandler                          | Modul:  main.s               |
; |--------------------------------------------------------------------------------------|
; | Ersteller:  Peter Raab                                | Datum:  15.10.2021           |
; |--------------------------------------------------------------------------------------|
; | Projekt:    Lauflicht V3                             | Prozessor:  STM32G474         |
; |--------------------------------------------------------------------------------------|
; | Funktion:   Interrupt Handler der EXTI Line 0                                        |
; |             Bei Betätigung des Tasters an PC[0] soll das Lauflicht aktiviert        |
; |             bzw. deaktiviert werden.                                                 | 
; |--------------------------------------------------------------------------------------|
; | Eingangsgroessen:  (Parameter)                                                       |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Ausgangsgroessen:                                                                    |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Nebeneffekte:    setzt Register R10 (= Zustand des Lauflichtes: 0: aus / 1: an)      |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Bemerkungen:                                                                         |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Aenderungen:                                                                         |
; |     tt.mm.yyyy        Name              Beschreibung                                 |
; |     15.10.2021        Peter Raab        initial version                              |
; |                                                                                      |
; ========================================================================================
EXTI0_IRQHandler PROC
	
	push {R4, R5, LR}

    ; 10 ms warten (Tasterprellen)
    mov R0, #10   ; nested UP-Aufruf
    bl  up_delay  ; -> LR sichern
	
    ; Zustand des Lauflichtes ändern
    ; 0(default): aus / 1 an
    eor  R10, #1 ; toggelt Bit 0

    ; Interrupt Flag zurücksetzen
    ldr  R4, =EXTI_PR1
    mov  R5, #1    ; clear by writing 1
    str  R5, [R4]

    pop {R4, R5, LR}

	bx lr

	ENDP


; ========================================================================================
; | UP-Name:    EXTI0_IRQHandler                          | Modul:  main.s               |
; |--------------------------------------------------------------------------------------|
; | Ersteller:  Peter Raab                                | Datum:  02.11.2021           |
; |--------------------------------------------------------------------------------------|
; | Projekt:    Lauflicht V4                             | Prozessor:  STM32G474         |
; |--------------------------------------------------------------------------------------|
; | Funktion:   Interrupt Handler des Timers 6                                           |
; |             Bei Überlauf des Timers soll alle 500 ms ein Interrupt erzeugt werden.   |
; |                                                               | 
; |--------------------------------------------------------------------------------------|
; | Eingangsgroessen:  (Parameter)                                                       |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Ausgangsgroessen:                                                                    |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Nebeneffekte:    wertet Register R10 (= Zustand des Lauflichtes: 0: aus / 1: an) aus |
; |                    -> wird in EXTI Interrupt gesetzt                                 |
; |                  speichert aktuellen Zustand der LEDs in Register R11                |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Bemerkungen:                                                                         |
; |                                                                                      |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Aenderungen:                                                                         |
; |     tt.mm.yyyy        Name              Beschreibung                                 |
; |     02.11.2021        Peter Raab        initial version                              |
; |                                                                                      |
; ========================================================================================
TIM6_IRQHandler PROC
	
	; zuruecksetzen des Timers
	ldr R0, =TIM6_SR
    mov R1, #0
    str R1, [R0]

    ; wenn LED aktiv
	cmp R10, #0     ; wenn =0
    beq norun       ; dann kein Weiterschalten

		; Schieben der LEDs
		lsl  R11, R11, #1
		cmp  R11, #0x100
		bne  weiter
		  mov  R11, #0x01  ; und wieder von vorne
weiter	

		; Schalten der LEDs
		ldr  R0, =GPIOA_ODR
		str  R11, [R0]
	
norun
	bx lr
	
	ENDP
		
    END