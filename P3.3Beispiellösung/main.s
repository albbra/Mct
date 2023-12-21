; ========================================================================================
; | Modulname:   main.s                                   | Prozessor:  STM32G474        |
; |--------------------------------------------------------------------------------------|
; | Ersteller:   								          | Datum:  20.12.2023           |
; |--------------------------------------------------------------------------------------|
; | Version:     V2.3            | Projekt:    Stoppuhr   | Assembler:  ARM-ASM          |
; |--------------------------------------------------------------------------------------|
; | Aufgabe:     Stoppuhr                                                            	 |
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
	EXPORT main
	EXPORT TIM6_IRQHandler
	EXPORT TIM7_IRQHandler

			
; ------------------------------- importierte Funktionen -----------------------------------


; ------------------------------- symbolische Konstanten ------------------------------------


; ------------------------------ Datensection / Variablen -----------------------------------
	AREA daten, data
array DCB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
counter DCB 0
side DCB 0
number DCB 0
stop DCB 0
resetpressed DCB 0

; ------------------------------- Codesection / Programm ------------------------------------
	AREA	main_s,code

; ------------------------------------  Timer 6 interupt ---------------------------------------

TIM6_IRQHandler PROC				; 100ms
	
	ldr R1, =TIM6_SR			; reseten des interrupt flags
	mov R3, #0
	str R3, [R1]
	
	ldr R0, =counter			; counter += 1 -> 100 ms sind vergangen -> auf display + 0.1
	ldrb R1, [R0]
	add R1, #1
	str R1, [R0]
	
	bx LR
	
	ENDP
		
; ------------------------------------  Timer 7 interupt ---------------------------------------

TIM7_IRQHandler PROC			; 10ms
	
	ldr R1, =TIM7_SR			; reseten des interrupt flags
	mov R3, #0
	str R3, [R1]
	
	
	ldr R0, =side			; wir holen den wert aus der variable side
	ldrb R1, [r0]
	
	cmp R1, #1
	beq Tim_isone
	
	mov R1, #1				; if side = 1:  side = 0 
	str R1, [R0]
	b 	skip_side
	
Tim_isone

	mov R1, #0				; if side = 0:  side = 1 
	
	str R1, [R0]
	
skip_side
	

	push {lr}
	
	bl switch
	
	bl up_display
	
	pop {lr}
	
	bx lr
	
	ENDP
		
			
; ---------------------------------------  up_delay -----------------------------------------



up_delay PROC
	
	PUSH {R0, R1}
	
	mov R0, #10				; wieviele ms das delay sein soll
	mov R1, #3600			; wieviele durchläufe 1 ms ist
	mul R0, R0, R1			; wir rechnen die summe von durchläufen aus die wir machen müssen
		
loop_delay

	sub R0, R0, #1
	cmp R0, #0
	bne	loop_delay			; wir laufen durch den loop bis r0 = 0
	
	pop {R0, R1}
	
	bx lr
	
	ENDP
		

; ---------------------------------------  up_display ----------------------------------------


up_display PROC
	
	; r0 = zahl
	; r1 = welches display
	
	PUSH {R0, R1, R2, R5, R6}
	
	ldr R6, =number
	ldrb R0, [R6]
	
	ldr R6, =side
	ldrb R1, [R6]
	
	ldr R2, =GPIOA_ODR
	ldr R5, =array
	ldrb R5, [R5, R0]		; wir holen den wert im array mit einem ofset von r0 
	cmp R1, #1				; wenn r1 = 1 dann ändern wir das 8te bit zu 1 damit wir links ausgeben
	
	beq rechts
	
	add R5, #0x80
	
rechts

	str R5, [R2]			; wenn r1 = 0 überspringen wir das addieren
	
	pop {R0, R1, R2, R5, R6}
	
	bx lr
	ENDP
		
		
; -----------------------------------------  switch ------------------------------------------


switch PROC
	
	ldr r0, =counter		; wir holen den wert aus counter
	ldrb r2, [r0]
	
	ldr r0, =side			; wir holen den wert aus side
	ldrb r1, [r0]
	
	ldr r10, =10
	udiv r0, r2, r10		; wir dividieren r2 durch 10 um die 10er stelle zu bekommen
	cmp r1, #1	
	beq r1is1				; wenn r1 = 1 dann wird es auf der rechten seite ausgegeben
					
	b continue				; ansonsten haben wir die 10er stelle bereits und sind fertig

r1is1

	mul r0, r10				; wir berechnen die einzerstelle da r1 = 1
	sub r0, r2, r0

continue
	
	ldr r3, =number			; wir speichern die berechnete "numer"
	str r0, [r3]
	
	bx lr
	
	ENDP

		
; -----------------------------------  Einsprungpunkt - --------------------------------------


main PROC

	bl initialize

	
	bl stop_loop

startpol

	ldr r0, =resetpressed	; wir setzen resetpressed wieder auf 0
	ldr r1, =0
	str r1, [r0]
	
	ldr r0, =stop			; wir setzen sopt auf 0
	ldr r1, =1
	str r1, [r0]
	ldr r7, =TIM6_DIER
	mov r8, #1
	str r8, [r7]
	
loop						; wiederholter Anwendungscode
	
	ldr r4, =GPIOC_IDR
	ldr r5, [r4]
	and r6, r5, #0x2
	cmp r6, #0x2			; if px1 pressed -> stop -> gehe zum stop_loop
	bne stop_loop
	
	push {r0, r1}
	
	ldr r0, =counter
	ldrb r1, [r0]			; wir reseten den counter wenn wir bei 100 ankommen
	cmp r1, #100
	beq reset
	
	pop {r0, r1}

   B	loop	
  
	
reset 
	ldr r2, =0
	ldr r3, =counter		; wir reseten den counter 
	str r2, [r3]
	
	bx lr
	
	
stop_loop

	ldr r0, =stop			; wir speichern das wir der timer gestoppt ist
	ldr r1, =0
	str r1, [r0]
	
	ldr r7, =TIM6_DIER
	mov r8, #0
	str r8, [r7]
	
	
; --------------------  stop loop --------------------		für das pollen von px1 und px2 währendem timer gestopt ist

	
s_loop	

	ldr r4, =GPIOC_IDR		; wir holen die werte der taster
	ldr r5, [r4]
	and r6, r5, #0x1
	cmp r6, #0x1			; wenn px0 gedrückt wurde gehen wir wieder in den mainloop
	bne startpol
	
	
	ldr r0, =resetpressed	; wir skippen den reset wenn wir bereits reset gedrückt haben
	ldrb r1, [r0]
	cmp r1, #1
	beq s_loop
	
	ldr r4, =GPIOC_IDR		; wir holen hier die werte der taster
	ldr r5, [r4]
	and r6, r5, #0x4
	cmp r6, #0x4
	bne s_reset				; wenn px2 gedrückt wurde reseten wir
	
	b s_loop
	
s_reset						; wir reseten bei reset button press

	ldr r0, =resetpressed	; wir speichern das wir bereits geresettet haben
	ldr r1, =1
	str r1, [r0]
	
	ldr r2, =0				; wir setzen den counter zurück auf 0
	ldr r3, =counter		
	str r2, [r3]
	
	b s_loop
	
   ENDP
	   
	   
; ---------------------------------------  initialize ----------------------------------------
	   

initialize PROC
	
	ldr r0, =RCC_AHB2ENR
	ldr r1, =5
	str r1, [r0]			; wir speichern r1 in das register damit die clock für port-A aktiviert wird.	
	
	ldr r0, =GPIOA_MODER
	ldr r1, [r0]
	ldr r2, =0xABFF0000
	and r1, r2
	ldr r2, =0xABFF5555
	orr r1, r2
	str r1, [r0]			; wir setzten bei GPIOA_MODER die ersten 8 Pins auf ouput-mode
	
	ldr R0, =GPIOC_MODER
	ldr R1, [R0]
	ldr	R2, =0xFFFFFFC0		; Maskierung aller Pins außer dem ersten für die Tasten Px0, Px1 und Px2
	and R1, R1, r2
	ldr R2, =0xFFFFFFC0		; 1100 = C für den Inputmode in MODE0 0000 = 0 für Inputmode MODE0 & MODE1
	orr R1, R2
	str R1, [R0]
	
	ldr r0, =array			; wir initialisieren das array für die zahlen:
	ldr r1, =0x4F5B063F
	str r1, [r0, #0]
	ldr r1, =0x077D6D66
	str r1, [r0, #4]
	ldr r1, =0x6F7F
	str r1, [r0, #8]
	
	ldr r0, =counter			; wir initialisieren variablen
	mov r1, #0
	ldr r1, [r0]
	
	ldr r0, =side
	mov r1, #0
	ldr r1, [r0]
	
	ldr r0, =number
	mov r1, #0
	ldr r1, [r0]
	
	ldr r0, =stop
	mov r1, #0
	ldr r1, [r0]
	
	ldr r0, =resetpressed
	mov r1, #0
	ldr r1, [r0]
	
							; wir aktivieren timer 6 und 7		6 = 100ms; 7 = 10ms 
	ldr r0, =RCC_APB1ENR1
	ldr r1, =0x30
	str r1, [r0]
	
	ldr r0, =TIM6_PSC
	mov r1, #15999		; wir machen das hier 1000hz laufen
	str r1, [r0]
	
	ldr r0, =TIM6_ARR
	mov r1, #99			; es soll alle 100 ms auslösen also 10hz -> bei 99 stoppen da wir bei 0 anfangen
	str r1, [r0]
	
	ldr r0, =TIM7_PSC
	mov r1, #15999		; wir machen das hier 1000hz laufen  
	str r1, [r0]
	
	ldr r0, =TIM7_ARR
	mov r1, #9			; es soll alle 5 ms auslösen also 10hz -> bei 9 stoppen da wir bei 0 anfangen
	str r1, [r0]
	
	ldr r0, =TIM7_CR1
	mov r1, #1
	str r1, [r0]
	
	ldr r0, =TIM6_CR1
	mov r1, #1
	str r1, [r0]
	
	ldr r0, =NVIC_ICPR1
	mov r1, #(1<<22)
	str r1, [r0]
	
	ldr r0, =NVIC_ICPR1
	mov r1, #(1<<23)
	str r1, [r0]
	
	ldr r0, =NVIC_ISER1
	mov r1, #(1<<22)
	str r1, [r0]
	
	ldr r0, =NVIC_ISER1
	mov r1, #(1<<23)
	str r1, [r0]
	
	ldr r0, =TIM6_DIER
	mov r1, #0
	str r1, [r0]
	
	ldr r0, =TIM7_DIER
	mov r1, #1
	str r1, [r0]
	
	; finished timer init
	

	
							

	bx lr
	
	ENDP

   END