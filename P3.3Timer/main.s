
; ========================================================================================
; | Modulname:   main.s                                   | Prozessor:  STM32G474        |
; |--------------------------------------------------------------------------------------|
; | Ersteller:   P. Raab                                  | Datum: 20.12.2023            |
; |--------------------------------------------------------------------------------------|
; | Version:   4.0              | Projekt: Stoppuhr 	  | Assembler:  ARM-ASM          |
; |--------------------------------------------------------------------------------------|
; | Aufgabe:                                                                             |
; |    Stoppuhr                 |
; |                                                                                      |
; |--------------------------------------------------------------------------------------|
; | Bemerkungen:                                                                         |
; |                        		|
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
    ;EXPORT  EXTI0_IRQHandler
    EXPORT  TIM6_IRQHandler
	EXPORT	TIM7_IRQHandler
		
; ------------------------------- importierte Funktionen -----------------------------------
    IMPORT  up_delay

; ------------------------------- symbolische Konstanten ------------------------------------
;ZAEHLERSTAND RN R1 ; nicht nötig?
ZEHNER 		RN R2
EINER 		RN R3

; ------------------------------ Datensection / Variablen -----------------------------------		

	AREA	daten,	data
COUNTER 	DCB	0
	
; ------------------------------- Codesection / Programm ------------------------------------
	AREA	main_s, code
	

	
; ------------------------------- Einsprungpunkt --------------------------------------------		
main  PROC
	
	bl initialisiere
	
	bl loop

; --------------------- Initialisierung ------------------------------------------------------

initialisiere PROC

; --------------------- Konfiguration der Portpins PA[7:0] fuer LEDs -------------------------
    ldr R0, =RCC_AHB2ENR
    ldr R1, =5              ; Aktivieren von Port A+C  (Bit 0 und 2)
    str R1, [R0]

    ldr R0, =GPIOA_MODER
    ldr R1, [R0]            ; Reset Value for Port A =0xABFFFFFF (Alternate Functions for JTAG /SWD)
    ldr R2, =0xFFFF0000     ; Maskierung der Pins [7:0]
    and R1, R1, R2
    ldr R2, =0x00005555     ; 01: General Output Mode
    orr R1, R2
    str R1, [R0]

; ---------------------- Konfiguration des Portpins PC[0], PC[1] und PC[2] fuer Button---------
    ldr R0, =GPIOC_MODER
    ldr R1, [R0]            
    ldr R2, =0xFFFFFFC0     ; Maskierung der Bits [5:0] für die Tasten PC[0], PC[1] und PC[2]
    and R1, R1, R2          ; Bits [0:5] = 00 => Input Mode
    str R1, [R0]	
	
	ldr	R0, =COUNTER		; Initialisierung der Variable counter
	mov R1, #0
	ldr	R1, [R0]
	
	; Konfiguration des externen Interrupts
    ; Clock enable
    ;ldr R0, =RCC_APB2ENR 
    ;ldr R1, [R0] 
    ;orr R1, #0x01      ; Bit 0 -> SysCfg
    ;str R1, [R0]
	
    ; Pin mapping
    ;ldr R0, =SYSCFG_EXTICR1
    ;mov R1, #2        ; PC[3] -> EXTI_LINE0
    ;str R1, [R0]       
	
    ; Triggerflanken
    ;ldr R0, =EXTI_FTSR1
    ;mov R1, #1        ; Bit 0 -> EXTI_LINE0
    ;str R1, [R0] 

    ; NVIC: EXTI Line0 Interrupt = ID 6 => ICPR0/ISER0
    ldr R0, =NVIC_ICPR0 
    mov R1, #0x40      ; -> 0100:0000 -> 0x40
    str R1, [R0]       ; clear pending bit
	
    ldr R0, =NVIC_ISER0 
    mov R1, #0x40      ; -> 0100:0000 -> 0x40
    str R1, [R0]       ; set enable bit

    ; EXTI Line0 Interrupt freigeben
    ldr R0, =EXTI_IMR1 
    mov R1, #1         ; bit0 -> EXTI Line 0
    str R1, [R0]       
	
; ------------------ Konfiguration der Timer 6 und 7 ---------------------
    ; Clock enable
    ldr R0, =RCC_APB1ENR1 
    ldr R1, [R0] 
    orr R1, #0x30      ; Bit 4 -> Timer 6 und Bit 5 -> Timer 7
    str R1, [R0]
	
	; Prescale Register
    ldr  R0, =TIM6_PSC
    mov  R1, #(16000-1)   ; -> TC_CLK = 1 ms = 1000hz
    strh R1, [R0]	
	
	; Prescale Register
    ldr  R0, =TIM7_PSC
    mov  R1, #(16000-1)   ; -> TC_CLK = 1 ms = 1000hz
    strh R1, [R0]
	
    ; Auto-Reload Register
    ldr R0, =TIM6_ARR
    mov R1, #99   ; -> T = 100 ms
    str R1, [R0]  	
	
	; Auto-Reload Register
    ldr R0, =TIM7_ARR
    mov R1, #9   ; -> T = 10 ms
    str R1, [R0]
	
	; Timer control register
	ldr R0, =TIM6_CR1
    mov R1, #1   ; -> counter enable 
    str R1, [R0]
	
	; Timer control register
	ldr R0, =TIM7_CR1
    mov R1, #1   ; -> counter enable 
    str R1, [R0] 	
	
; ------------- Timer 6 und 7 Interrupt --------------------------------
    ldr R0, =NVIC_ICPR1 ; clear pending bit 
    mov R1, #(1<<22)	; IRQ54 -> Bitnummer
    str R1, [R0] 		; 54 - 32 = 22

	ldr R0, =NVIC_ICPR1 ; clear pending bit 
    mov R1, #(1<<23)	; IRQ55 -> Bitnummer
    str R1, [R0] 		; 55 - 32 = 23

	ldr R0, =NVIC_ISER1 ; set enable bit / ab IRQ32: ISER1
    mov R1, #(1<<22)    ; IRQ54 -> Bitnummer
    str R1, [R0] 		; 54 - 32 = 22
	
	ldr R0, =NVIC_ISER1 ; set enable bit / ab IRQ32: ISER1
    mov R1, #(1<<23)    ; IRQ55 -> Bitnummer
    str R1, [R0] 		; 55 - 32 = 23
  
	ldr R0, =TIM6_DIER
    mov R1, #0   
	str	R1, [R0]
	
	ldr R0, =TIM7_DIER
    mov R1, #1   
	str	R1, [R0]
	
	bx lr
	
	ENDP

; ------------------- Startwerte -----------------------------------
nullen
	;mov ZAEHLERSTAND, #0x3F ;nicht nötig ?
	mov EINER,	 #0x3F
	mov ZEHNER,  #0xBF 
	
; -------------------- Defaultzustand ------------------------------
default
	LDR R0, =GPIOA_ODR
	STR EINER, [R0]
	
	; 5ms warten -> 0.005s
	MOV R8, #5
	BL  up_delay
	
	LDR R0, =GPIOA_ODR
	STR ZEHNER, [R0]
	
	; 5ms warten -> 0.005s
	MOV R8, #5
	BL  up_delay
	
	LDR	R0, =GPIOC_IDR 	; Lesen des Ports C
	LDR R1, [R0]	
	
	CMP R1, #6          ; Ist Bit PC0 gesetzt? -> Start/Weiter
	BNE default
	
	
; --------------------- Endlosschleife ------------------------------

loop 
	LDR R0, =GPIOA_ODR
	STR EINER, [R0]
	
	; 5ms warten -> 0.005s
	MOV R8, #5
	BL  up_delay
	
	LDR R0, =GPIOA_ODR
	STR ZEHNER, [R0]
	
	; 5ms warten -> 0.005s
	MOV R8, #5
	BL  up_delay
	
	LDR R0, =GPIOC_IDR 	; Lesen des Ports C
	LDR R1, [R0]	
	
	CMP R1, #6           ; Ist Bit PC0 gesetzt? -> Start/Weiter
	BEQ zaehler
	
	CMP R1, #3           ; Ist Bit PC2 gesetzt? -> Reset
	BEQ nullen
	
	B	loop	

; ------------------------- Interrupt Handler -------------------------

TIM6_IRQHandler PROC			;100ms
	; zuruecksetzen des Timers
	ldr R1, =TIM6_SR
	mov R4, #0
	str R4, [R1]
	
	ldr R0, =COUNTER
	ldrb R1, [R0]
	add R1, #1			;COUNTER + 1
	str R1, [R0]
	
	bx 	LR
	
	ENDP
	
TIM7_IRQHandler PROC			;10ms
	; zuruecksetzen des Timers
	ldr R1, =TIM7_SR
	mov R4, #0
	str R4, [R1]
	
	ldr R0, =COUNTER
	ldrb R1, [R0]
	add R1, #1
	str R1, [R0]
	
	bx 	LR
	
	ENDP

; --------------------------- Zaehler -----------------------------------
zaehler
	MOV R6, #0
	
schleife	
	LDR R0, =GPIOA_ODR
	STR EINER, [R0]
	
	; 5ms warten -> 0.05s
	MOV R8, #5
	BL  up_delay
	
	LDR R0, =GPIOA_ODR
	STR ZEHNER, [R0]
	
	; 0.5ms warten -> 0.05s
	MOV R8, #5
	BL  up_delay
	
	ADD R6,R6,#1
	CMP R6, #10
	BNE schleife

	LDR R0, =GPIOC_IDR 	 ; Lesen des Ports C
	LDR R1, [R0]
	CMP R1, #5           ; Ist Bit PC1 gesetzt? -> Stop
	BEQ loop
	
	LDR R0, =GPIOA_ODR
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
	STR EINER, [R0]
						 ;Zehnerstelle+1
	B 	zeta 
	
nicht_null

	STR EINER, [R0]

	b 	z_nicht_null
	
; --------------------- Zehnerstelle ----------------------------
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