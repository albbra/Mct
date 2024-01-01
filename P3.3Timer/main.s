
; ========================================================================================
; | Modulname:   main.s                                   | Prozessor:  STM32G474        |
; |--------------------------------------------------------------------------------------|
; | Ersteller:   Egor Bernhardt, Albert Brandt            | Datum: 26.12.2023            |
; |--------------------------------------------------------------------------------------|
; | Version:   4.0              | Projekt: Stoppuhr 	  | Assembler:  ARM-ASM          |
; |--------------------------------------------------------------------------------------|
; | Aufgabe:                                                                             |
; |    Stoppuhr   2.3              |
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
ARRAY		DCB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x27, 0x7F, 0x6F
	
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
	ldr R0, =GPIOA_ODR
	str EINER, [R0]
	
	; 5ms warten -> 0.005s
	mov R8, #5
	bl up_delay
	
	ldr R0, =GPIOA_ODR
	str ZEHNER, [R0]
	
	; 5ms warten -> 0.005s
	mov R8, #5
	bl up_delay
	
	ldr	R0, =GPIOC_IDR 	; Lesen des Ports C
	ldr R1, [R0]	
	
	cmp R1, #6          ; Ist Bit PC0 gesetzt? -> Start/Weiter
	bne default
	
	
; --------------------- Endlosschleife ------------------------------

loop 
	ldr R0, =GPIOA_ODR
	str EINER, [R0]
	
	; 5ms warten -> 0.005s
	mov R8, #5
	bl  up_delay
	
	ldr R0, =GPIOA_ODR
	str ZEHNER, [R0]
	
	; 5ms warten -> 0.005s
	mov R8, #5
	bl  up_delay
	
	ldr R0, =GPIOC_IDR 	; Lesen des Ports C
	ldr R1, [R0]	
	
	cmp R1, #6           ; Ist Bit PC0 gesetzt? -> Start/Weiter
	beq zaehler
	
	cmp R1, #3           ; Ist Bit PC2 gesetzt? -> Reset
	beq nullen
	
	b	loop	

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
	ldr R0, =GPIOA_ODR
	str EINER, [R0]
	
	; 5ms warten -> 0.005s
	mov R8, #5
	bl  up_delay
	
	ldr R0, =GPIOA_ODR
	str ZEHNER, [R0]
	
	; 5ms warten -> 0.005s
	mov R8, #5
	bl  up_delay
	
	add R6,R6,#1
	cmp R6, #10
	bne schleife

	ldr R0, =GPIOC_IDR 	 ; Lesen des Ports C
	ldr R1, [R0]
	cmp R1, #5           ; Ist Bit PC1 gesetzt? -> Stop
	beq loop
	
	ldr R0, =GPIOA_ODR
	ldr R1, [R0]
	
	cmp EINER, #0x6F     ; 9 ? wenn ja -> 0
	bne nicht_neun
	mov EINER, #0x3F	
	b	nicht_null
nicht_neun

	cmp EINER, #0x7F     ; 8 ? wenn ja -> 9
	bne nicht_acht
	mov EINER, #0x6F
nicht_acht

	cmp EINER, #0x27     ; 7 ? wenn ja -> 8
	bne nicht_sieben
	mov EINER, #0x7F
nicht_sieben

	cmp EINER, #0x7D     ; 6 ? wenn ja -> 7
	bne nicht_sechs
	mov EINER, #0x27
nicht_sechs

	cmp EINER, #0x6D     ; 5 ? wenn ja -> 6
	bne nicht_fuenf
	mov EINER, #0x7D
nicht_fuenf

	cmp EINER, #0x66     ; 4 ? wenn ja -> 5
	bne nicht_vier
	mov EINER, #0x6D
nicht_vier

	cmp EINER, #0x4F     ; 3 ? wenn ja -> 4
	bne nicht_drei
	mov EINER, #0x66
nicht_drei

	cmp EINER, #0x5B     ; 2 ? wenn ja -> 3
	bne nicht_zwei
	mov EINER, #0x4F
nicht_zwei

	cmp EINER, #0x06     ; 1 ? wenn ja -> 2
	bne nicht_eins
	mov EINER, #0x5B
nicht_eins

	cmp EINER, #0x3F     ; 0 ? wenn ja -> 9
	bne nicht_null
	mov EINER, #0x06
	str EINER, [R0]
						 ;Zehnerstelle+1
	b 	zeta 
	
nicht_null

	str EINER, [R0]

	b 	z_nicht_null
	
; --------------------- Zehnerstelle ----------------------------
zeta ;Zehnerstelle 

	cmp ZEHNER, #0xEF     ; 9 ? wenn ja -> 0
	bne z_nicht_neun
	mov ZEHNER, #0xBF	
	b 	z_nicht_null
z_nicht_neun

	cmp ZEHNER, #0xFF     ; 8 ? wenn ja -> 9
	bne z_nicht_acht
	mov ZEHNER, #0xEF
z_nicht_acht

	cmp ZEHNER, #0xA7     ; 7 ? wenn ja -> 8
	bne z_nicht_sieben
	mov ZEHNER, #0xFF
z_nicht_sieben

	cmp ZEHNER, #0xFD     ; 6 ? wenn ja -> 7
	bne z_nicht_sechs
	mov ZEHNER, #0xA7
z_nicht_sechs

	cmp ZEHNER, #0xED     ; 5 ? wenn ja -> 6
	bne z_nicht_fuenf
	mov ZEHNER, #0xFD
z_nicht_fuenf

	cmp ZEHNER, #0xE6     ; 4 ? wenn ja -> 5
	bne z_nicht_vier
	mov ZEHNER, #0xED
z_nicht_vier

	cmp ZEHNER, #0xCF     ; 3 ? wenn ja -> 4
	bne z_nicht_drei
	mov ZEHNER, #0xE6
z_nicht_drei

	cmp ZEHNER, #0xDB     ; 2 ? wenn ja -> 3
	bne z_nicht_zwei
	mov ZEHNER, #0xCF
z_nicht_zwei

	cmp ZEHNER, #0x86     ; 1 ? wenn ja -> 2
	bne z_nicht_eins
	mov ZEHNER, #0xDB
z_nicht_eins

	cmp ZEHNER, #0xBF     ; 0 ? wenn ja -> 1
	bne z_nicht_null
	mov ZEHNER, #0x86
	
z_nicht_null

	str ZEHNER, [R0]
	
	b	zaehler

	ENDP				
END