
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
	EXPORT  EXTI1_IRQHandler
	EXPORT  EXTI2_IRQHandler
    EXPORT  TIM6_IRQHandler
		
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
	
    ; Pin mapping for EXTI0 (PC[0])
    ldr   R0, =SYSCFG_EXTICR1
    mov   R1, #2        ; PC[0] -> EXTI_LINE0
    str   R1, [R0]       
    ; Pin mapping for EXTI1 (PC[1])
    mov   R1, #8        ; PC[1] -> EXTI_LINE1
    str   R1, [R0]       
    ; Pin mapping for EXTI2 (PC[2])
    mov   R1, #16       ; PC[2] -> EXTI_LINE2
    str   R1, [R0]      
	
    ; Triggerflanken for EXTI0
    ldr   R0, =EXTI_FTSR1
    mov   R1, #1        ; Bit 0 -> EXTI_LINE0
    str   R1, [R0] 
    ; Triggerflanken for EXTI1
    mov   R1, #2        ; Bit 1 -> EXTI_LINE1
    str   R1, [R0] 
    ; Triggerflanken for EXTI2
    mov   R1, #4        ; Bit 2 -> EXTI_LINE2
    str   R1, [R0] 

    ; NVIC: EXTI Line0-2 Interrupts = ID 6, 7, 8 => ICPR0/ISER0
    ldr   R0, =NVIC_ICPR0 
    mov   R1, #(1 << 6) | (1 << 7) | (1 << 8)
    str   R1, [R0]       ; clear pending bits
    
    ldr   R0, =NVIC_ISER0 
    mov   R1, #(1 << 6) | (1 << 7) | (1 << 8)
    str   R1, [R0]       ; set enable bits

    ; EXTI Line0-2 Interrupts freigeben
    ldr   R0, =EXTI_IMR1 
    mov   R1, #7         ; bit0-2 -> EXTI Line 0-2
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
  
	MOV ZAEHLERSTAND, #0x3F
	MOV EINER, #0x3F
	MOV ZEHNER, #0xBF  
  
	; Timer 6 Interrupt
    ldr  R0, =TIM6_DIER
    mov  R1, #1   ; -> update interrupt enable 
    str  R1, [R0]
	
	B loop

; Endlosschleife
loop 

  B	loop

;##########################################################
;Zahl um 1 erhöhen
zaehler
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
	
	B loop
	
	ENDP

; Timer 6 Interrupt Handler
TIM6_IRQHandler PROC
    ; Timer 6 abgelaufen
    ; Zurücksetzen des Timers
    ldr R0, =TIM6_SR
    mov R1, #0
    str R1, [R0]

    ; Zähler erhöhen
    BL zaehler

    ; Schalten der LEDs
    ldr R0, =GPIOA_ODR
    ldr R1, [R0]
    str R11, [R0]

    bx lr
    ENDP

; External Interrupt Handler for EXTI0 (Button connected to PC[0])
EXTI0_IRQHandler PROC
	push {R4, R5, LR}

    ; 10 ms warten (Tasterprellen)
    mov R0, #10   ; nested UP-Aufruf
    bl up_delay  ; -> LR sichern

    ; Zustand des Lauflichtes ändern
    ; 0(default): aus / 1 an
    eor  R10, #1 ; toggelt Bit 0

    ; Interrupt Flag zurücksetzen
    ldr  R4, =EXTI_PR1
    mov  R5, #1    ; clear by writing 1
    str  R5, [R4]

    ; Zähler erhöhen
    BL zaehler

    pop {R4, R5, LR}
    bx lr
    ENDP


; External Interrupt Handler for EXTI1 (Button connected to PC[1])
EXTI1_IRQHandler PROC
    push {R4, R5, LR}

    ; 10 ms warten (Tasterprellen)
    mov R0, #10   ; nested UP-Aufruf
    bl up_delay 

    ; Zustand des Lauflichtes ändern
    ; 0(default): aus / 1 an
    ldr R4, =GPIOC_IDR
    ldr R5, [R4]
    tst R5, #0x00000002   ; Test Zustand des PC[1]
    beq EXTI1_no_stop     ; Wenn Button 0 nicht gedrückt wurde -> Zustandswechsel

    ; Stop-Funktionalität: Wenn Button 0 gedrückt wurde -> Timer stop
    ldr R0, =TIM6_CR1
    ldr R1, [R0]
    bic R1, R1, #1    ; Clear Bit 0, um den Timer zu stoppen
    str R1, [R0]

EXTI1_no_stop
    ; Interrupt Flag zurücksetzen
    ldr R4, =EXTI_PR1
    mov R5, #2    ; clear by writing 1
    str R5, [R4]

    ; Zähler erhöhen
    BL zaehler

    pop {R4, R5, LR}
    bx lr
    ENDP

; External Interrupt Handler for EXTI2 (Button connected to PC[2])
EXTI2_IRQHandler PROC
    push {R4, R5, LR}

    ; 10 ms warten (Tasterprellen)
    mov R0, #10   ; nested UP-Aufruf
    bl up_delay  

    ; Zustand des Lauflichtes ändern
    ; 0(default): aus / 1 an
    ldr R4, =GPIOC_IDR
    ldr R5, [R4]
    tst R5, #0x00000004   ; Test Zustand des PC[2]
    beq EXTI2_no_reset    ; Wenn Button 1 nicht gedrückt wurde -> Zustandswechsel 

    ; Reset-Funktionalität: Wenn Button 1 gedrückt wurde -> Zähler zurücksetzen
    MOV EINER, #0x3F
    MOV ZEHNER, #0xBF

EXTI2_no_reset
    ; Interrupt Flag zurücksetzen
    ldr R4, =EXTI_PR1
    mov R5, #4    ; clear by writing 1
    str R5, [R4]

    ; Zähler erhöhen
    BL zaehler

    pop {R4, R5, LR}
    bx lr
    ENDP
		
    END


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