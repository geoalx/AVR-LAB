;
; AssemblerApplication3.asm
;
; Created: 22/11/2021 10:57:05 μμ
; Author : ageor
;
.include "m16def.inc" 

; Replace with your application code

.DEF a=r27
.DEF b=r26
;.DEF temp=r15
;.DEF temp=r21
;.DEF temp2=r20
;.DEF temp1=r19

.DSEG
_tmp_: .byte 2

.CSEG
.org 0
jmp main
.org 0x10
rjmp ISR_TIMER1_OVF //interrupt when timer ends
.org 0x1c
rjmp ADC_INT      // interrupt for adc


wait_usec:
	sbiw r24, 1 	; 2 κύκλοι (0.250 μsec)
	nop 			; 1 κύκλος (0.125 μsec)
	nop 			; 1 κύκλος (0.125 μsec)
	nop 			; 1 κύκλος (0.125 μsec)
	nop 			; 1 κύκλος (0.125 μsec)
	brne wait_usec 	; 1 ή 2 κύκλοι (0.125 ή 0.250 μsec)
	ret 			; 4 κύκλοι (0.500 μsec)

wait_msec:
	push r24 		; 2 κύκλοι (0.250 μsec)
	push r25 		; 2 κύκλοι
	/*ldi r24 , 0xe6	; φόρτωσε τον καταχ. r25:r24 με 998 (1 κύκλος - 0.125 μsec)
	ldi r25 , 0x03	; 1 κύκλος (0.125 μsec)*/
	ldi r24 , low(998) ; φόρτωσε τον καταχ. r25:r24 με 998 (1 κύκλος - 0.125 μsec)
	ldi r25 , high(998) ; 1 κύκλος (0.125 μsec)
	rcall wait_usec ; 3 κύκλοι (0.375 μsec), προκαλεί συνολικά καθυστέρηση 998.375 μsec
	pop r25 		; 2 κύκλοι (0.250 μsec)
	pop r24	 		; 2 κύκλοι
	sbiw r24 , 1 	; 2 κύκλοι
	brne wait_msec 	; 1 ή 2 κύκλοι (0.125 ή 0.250 μsec)
	ret 			; 4 κύκλοι (0.500 μsec)

scan_row_sim:
	out PORTC,r25	;r25 value from scan_keypad_sim
	push r24
	push r25
	ldi r24,low(500)
	ldi r25,high(500)
	rcall wait_usec
	pop r25
	pop r24
	nop
	nop
	in r24,PINC		; r24 takes value of 
	andi r24,0x0f	; r24 with mask keeping 4lsb's
	
	ret


scan_keypad_sim:
	
	push b			;r26
	push a			;r27
	ldi r25,0x10	; check first line
	rcall scan_row_sim
	swap r24		; 4 left shifts
	mov a,r24		; result to 4 msb's of a

	ldi r25,0x20	; check second line
	rcall scan_row_sim
	add a,r24		; result to 4 lsb's of a
	
	; second 8bits
	ldi r25,0x40	; check third line
	rcall scan_row_sim
	swap r24		; 4 left shifts
	mov b,r24		; result to 4 msb's of b

	ldi r25,0x80	; check second line
	rcall scan_row_sim
	add b,r24		; result to 4 lsb's of b

	movw r25:r24, a:b	; mov result to registers r25 r24

	clr b
	out PORTC,b		; clear PORTC

	pop a
	pop b	
	
	ret


scan_keypad_rising_edge_sim:

	push r22 ; αποθήκευσε τους καταχωρητές r23:r22 και τους
	push r23 ; r26:r27 γιατι τους αλλάζουμε μέσα στην ρουτίνα
	push r26
	push r27

	rcall scan_keypad_sim ; έλεγξε το πληκτρολόγιο για πιεσμένους διακόπτες
	push r24 ; και αποθήκευσε το αποτέλεσμα
	push r25

	ldi r24 ,15 ; καθυστέρησε 15 ms (τυπικές τιμές 10-20 msec που καθορίζεται από τον
	ldi r25 ,0 ; κατασκευαστή του πληκτρολογίου – χρονοδιάρκεια σπινθηρισμών)
	rcall wait_msec
	rcall scan_keypad_sim ; έλεγξε το πληκτρολόγιο ξανά και απόρριψε
	pop r23 ; values of r24 r25 to r22 t23
	pop r22
	;debouncing
	and r24,  r22 ; and for checking debouncing
	and r25, r23

	;pressing button checker
	ldi r26, low(_tmp_) ; φόρτωσε την κατάσταση των διακοπτών στην
	ldi r27, high(_tmp_) ; προηγούμενη κλήση της ρουτίνας στους r27:r26
	ld r23, X+ ;load previous value of keys to r23 r22
	ld r22, X
	st X, r24 ; αποθήκευσε στη RAM τη νέα κατάσταση
	st -X, r25 ; των διακοπτών

	com r23
	com r22 ; βρες τους διακόπτες που έχουν «μόλις» πατηθεί
	and r24, r22
	and r25, r23
	pop r27 ; επανάφερε τους καταχωρητές r27:r26
	pop r26 ; και r23:r22
	pop r23
	pop r22
	ret 

keypad_to_ascii_sim:
	
	push b
	push a

	movw b,r24 ; λογικό ‘1’ στις θέσεις του καταχωρητή r26 δηλώνουν

	ldi r24,'*'
	; r26
	;C 9 8 7 D # 0 *
	sbrc b, 0
	rjmp return_ascii
	ldi r24, '0'
	sbrc b, 1
	rjmp return_ascii
	ldi r24, '#'
	sbrc b, 2
	rjmp return_ascii
	ldi r24, 'D'
	sbrc r26, 3 ; αν δεν είναι ‘1’παρακάμπτει την ret, αλλιώς (αν είναι ‘1’)
	rjmp return_ascii ; επιστρέφει με τον καταχωρητή r24 την ASCII τιμή του D.
	ldi r24, '7'
	sbrc r26, 4
	rjmp return_ascii
	ldi r24, '8'
	sbrc r26, 5
	rjmp return_ascii
	ldi r24, '9'
	sbrc r26, 6
	rjmp return_ascii 
	ldi r24, 'C'
	sbrc r26, 7
	rjmp return_ascii
	ldi r24, '4' ; λογικό ‘1’ στις θέσεις του καταχωρητή r27 δηλώνουν
	sbrc r27, 0 ; τα παρακάτω σύμβολα και αριθμούς
	rjmp return_ascii
	ldi r24, '5'
	;r27
	;Α 3 2 1 B 6 5 4
	sbrc r27, 1
	rjmp return_ascii
	ldi r24, '6'
	sbrc r27, 2
	rjmp return_ascii
	ldi r24, 'B'
	sbrc r27, 3
	rjmp return_ascii
	ldi r24, '1'
	sbrc r27, 4
	rjmp return_ascii 
	ldi r24, '2'
	sbrc r27, 5
	rjmp return_ascii
	ldi r24, '3' 
	sbrc r27, 6
	rjmp return_ascii
	ldi r24, 'A'
	sbrc r27, 7
	rjmp return_ascii
	clr r24
	return_ascii:
		pop a ; επανάφερε τους καταχωρητές r27:r26
		pop b
	ret 

	lcd_command_sim:
	push r24 ; αποθήκευσε τους καταχωρητές r25:r24 γιατί τους
	push r25 ; αλλάζουμε μέσα στη ρουτίνα
	cbi PORTD, PD2 ; επιλογή του καταχωρητή εντολών (PD2=0)
	rcall write_2_nibbles_sim ; αποστολή της εντολής και αναμονή 39μsec
	ldi r24, 39 ; για την ολοκλήρωση της εκτέλεσης της από τον ελεγκτή της lcd.
	ldi r25, 0 ; ΣΗΜ.: υπάρχουν δύο εντολές, οι clear display και return home,
	rcall wait_usec ; που απαιτούν σημαντικά μεγαλύτερο χρονικό διάστημα.
	pop r25 ; επανάφερε τους καταχωρητές r25:r24
	pop r24
	ret



write_2_nibbles_sim:

	push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
	push r25 ; λειτουργία του προγραμματος απομακρυσμένης
	ldi r24 ,low(6000) ; πρόσβασης
	ldi r25 ,high(6000)
	rcall wait_usec
	pop r25
	pop r24 ; τέλος τμήμα κώδικα
	push r24 ; στέλνει τα 4 MSB
	in r25, PIND ; διαβάζονται τα 4 LSB και τα ξαναστέλνουμε
	andi r25, 0x0f ; για να μην χαλάσουμε την όποια προηγούμενη κατάσταση
	andi r24, 0xf0 ; απομονώνονται τα 4 MSB και
	add r24, r25 ; συνδυάζονται με τα προϋπάρχοντα 4 LSB
	out PORTD, r24 ; και δίνονται στην έξοδο
	sbi PORTD, PD3 ; δημιουργείται παλμός Enable στον ακροδέκτη PD3
	cbi PORTD, PD3 ; PD3=1 και μετά PD3=0
	push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
	push r25 ; λειτουργία του προγραμματος απομακρυσμένης
	ldi r24 ,low(6000) ; πρόσβασης
	ldi r25 ,high(6000)
	rcall wait_usec
	pop r25
	pop r24 ; τέλος τμήμα κώδικα
	pop r24 ; στέλνει τα 4 LSB. Ανακτάται το byte.
	swap r24 ; εναλλάσσονται τα 4 MSB με τα 4 LSB
	andi r24 ,0xf0 ; που με την σειρά τους αποστέλλονται
	add r24, r25
	out PORTD, r24
	sbi PORTD, PD3 ; Νέος παλμός Enable
	cbi PORTD, PD3
	ret


lcd_data_sim:
	push r24 ; αποθήκευσε τους καταχωρητές r25:r24 γιατί τους
	push r25 ; αλλάζουμε μέσα στη ρουτίνα
	sbi PORTD, PD2 ; επιλογή του καταχωρητή δεδομένων (PD2=1)
	rcall write_2_nibbles_sim ; αποστολή του byte
	ldi r24 ,43 ; αναμονή 43μsec μέχρι να ολοκληρωθεί η λήψη
	ldi r25 ,0 ; των δεδομένων από τον ελεγκτή της lcd
	rcall wait_usec
	pop r25 ;επανάφερε τους καταχωρητές r25:r24
	pop r24
	ret 

lcd_init_sim:
	push r24 ; αποθήκευσε τους καταχωρητές r25:r24 γιατί τους
	push r25 ; αλλάζουμε μέσα στη ρουτίνα

	ldi r24, 40 ; Όταν ο ελεγκτής της lcd τροφοδοτείται με
	ldi r25, 0 ; ρεύμα εκτελεί την δική του αρχικοποίηση.

	rcall wait_msec ; Αναμονή 40 msec μέχρι αυτή να ολοκληρωθεί.
	ldi r24, 0x30 ; εντολή μετάβασης σε 8 bit mode
	out PORTD, r24 ; επειδή δεν μπορούμε να είμαστε βέβαιοι
	sbi PORTD, PD3 ; για τη διαμόρφωση εισόδου του ελεγκτή
	cbi PORTD, PD3 ; της οθόνης, η εντολή αποστέλλεται δύο φορές
	ldi r24, 39
	ldi r25, 0 ; εάν ο ελεγκτής της οθόνης βρίσκεται σε 8-bit mode

	rcall wait_usec ; δεν θα συμβεί τίποτα, αλλά αν ο ελεγκτής έχει διαμόρφωση
	; εισόδου 4 bit θα μεταβεί σε διαμόρφωση 8 bit
	push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
	push r25 ; λειτουργία του προγραμματος απομακρυσμένης
	ldi r24,low(1000) ; πρόσβασης
	ldi r25,high(1000)

	rcall wait_usec
	pop r25
	pop r24 ; τέλος τμήμα κώδικα
	ldi r24, 0x30
	out PORTD, r24
	sbi PORTD, PD3
	cbi PORTD, PD3
	ldi r24,39
	ldi r25,0

	rcall wait_usec 
	push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
	push r25 ; λειτουργία του προγραμματος απομακρυσμένης
	ldi r24 ,low(1000) ; πρόσβασης
	ldi r25 ,high(1000)

	rcall wait_usec
	pop r25
	pop r24 ; τέλος τμήμα κώδικα
	ldi r24,0x20 ; αλλαγή σε 4-bit mode
	out PORTD, r24
	sbi PORTD, PD3
	cbi PORTD, PD3
	ldi r24,39
	ldi r25,0

	rcall wait_usec
	push r24 ; τμήμα κώδικα που προστίθεται για τη σωστή
	push r25 ; λειτουργία του προγραμματος απομακρυσμένης
	ldi r24 ,low(1000) ; πρόσβασης
	ldi r25 ,high(1000)
	 
	rcall wait_usec
	pop r25
	pop r24 ; τέλος τμήμα κώδικα
	ldi r24,0x28 ; επιλογή χαρακτήρων μεγέθους 5x8 κουκίδων
	rcall lcd_command_sim ; και εμφάνιση δύο γραμμών στην οθόνη
	ldi r24,0x0c ; ενεργοποίηση της οθόνης, απόκρυψη του κέρσορα
	rcall lcd_command_sim
	ldi r24,0x01 ; καθαρισμός της οθόνης
	rcall lcd_command_sim
	ldi r24, low(1530)
	ldi r25, high(1530)
	rcall wait_usec
	ldi r24 ,0x06 ; ενεργοποίηση αυτόματης αύξησης κατά 1 της διεύθυνσης
	rcall lcd_command_sim ; που είναι αποθηκευμένη στον μετρητή διευθύνσεων και
	; απενεργοποίηση της ολίσθησης ολόκληρης της οθόνης
	pop r25 ; επανάφερε τους καταχωρητές r25:r24
	pop r24
	ret


ADC_init:
	ldi r24,(1<<REFS0) // Vcc = Vref = 5V
	out ADMUX,r24
	ldi r24,(1<<ADEN)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0) //division factor of 128 and interrupt at the completion of the adc
	out ADCSRA,r24
	ret

timer_int_init:
	ldi r24,(1<<TOIE1)     //interrupt TCNT1
	out TIMSK,r24
	ldi r24,(1<<CS12)     //CLK/256
	out TCCR1B,r24 
	ret

set_100_ms:
	push r18
	ldi r18,0xf3
	out TCNT1H,r18
	ldi r18,0xcb
	out TCNT1L,r18
	pop r18
	ret

main:	
	ldi r18,high(RAMEND)
	out SPH,r18
	ldi r18,low(RAMEND)
	out SPL,r18
	rcall ADC_init
	clr r26
	clr r19
	clr r16
	clr r21
	ser r18
	out DDRD,r18
	out DDRB,r18
	ldi r18,0xf0
	out DDRC,r18
	clr r31 ;counter
	rcall lcd_init_sim
	ldi r24,1
	rcall lcd_command_sim
	rcall timer_int_init
	ldi r18,0xf3
	out TCNT1H,r18
	ldi r18,0xcb
	out TCNT1L,r18
	sei
	clr r30
	jmp loop1
	

clear:
	ldi r24,1
	rcall lcd_command_sim
	ldi r24,'C'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24,'L'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24,'E'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24,'A'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24,'R'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd

loop1:
	sbrc r31,0 ;skip if bit is cleared (skip if 2/0 are pressed) ; save first key to r22
	mov r22,r23 ;r22 has first key value
	cpi r31,2
	brne loop2

check_psw:
	nop
	clr r31		; clear r31->counter
	cpi r22, '1'
	brne wrong_psw
	cpi r23, '4'
	brne wrong_psw
    jmp rigth_psw
	;jmp loop2

wrong_psw:
	ser r20 ; flag for wrong password
	clr r19 ; counter for 5*100ms
	clr r16

;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
loop2:
	;add r30,r26
	;out PORTB,r30
	cpi r29,1
	brsh alarm
	cpi r28,206
	brsh alarm

no_alarm:
	clr r17
	rcall set_leds
	add r30,r26
	out PORTB,r30
	jmp loop1

set_leds:
	; clear reg for output
	clr r30
	;clr r30
	cpi r29,3
	brsh led6
	cpi r29,2
	breq big_led_2
	cpi r29,1
	breq big_led_1
	cpi r28,176
	brsh led1
	cpi r28,88
	brsh led0
	ret

big_led_2:
	cpi r28,102
	brsh led6
	rjmp led5

big_led_1:
	cpi r28,183
	brsh led4
	cpi r28,95
	brsh led3
	jmp led2

led6:
	ori r30,(1<<6)

led5:
	ori r30,(1<<5)

led4:
	ori r30,(1<<4)

led3:
	ori r30,(1<<3)

led2:
	ori r30,(1<<2)

led1:
	ori r30,(1<<1)

led0:
	ori r30,1
	;out PORTB,r30
	/*ldi r24,low(10)
	ldi r25,high(10)
	call wait_usec*/
	ret

alarm:
	cpi r17,00
	brne alarm_loop	
	andi r30,0x80
	ldi r24,1
	rcall lcd_command_sim
	ldi r24,'G'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24,'A'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24,'S'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24,0x20
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24,'D'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24,'E'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24,'T'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24,'E'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24,'C'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24,'T'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24,'E'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24,'D'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ser r17


alarm_loop:
	rcall set_leds
	and r30,r21
	andi r30,0x7f
	add r30,r26
	out PORTB,r30
	ldi r25,high(500)
	ldi r24,low(500)
	com r21
	call wait_msec
	cpi r29,1
	brsh go_loop
	cpi r28,206
	brsh go_loop
	jmp clear

go_loop:
	jmp loop1

counter_inc:
	inc r31
	rcall keypad_to_ascii_sim	; returns value to r24
	mov r23, r24 ;ascii value
	ret

rigth_psw:
	clr r31
	clr r17 ;if we were in alarm mode
	ldi r24,1	
	rcall lcd_command_sim	
	ldi r24, 'W'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24, 'E'
	rcall lcd_data_sim
	ldi r24, 'L'
	rcall lcd_data_sim  
	ldi r24, 'C'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24, 'O'
	rcall lcd_data_sim
	ldi r24, 'M'
	rcall lcd_data_sim  
	ldi r24, 'E'
	rcall lcd_data_sim ; αποστολή ενός byte δεδομένων στον ελεγκτή της οθόνης lcd
	ldi r24, ' '
	rcall lcd_data_sim
	mov r24, r22
	rcall lcd_data_sim  
	mov r24, r23
	rcall lcd_data_sim  
	;clr r22
	;clr r23
	;cli
	ldi r24,0x80
	out PORTB,r24
	ldi r25,high(4000)
	ldi r24,low(4000)
	call wait_msec
	clr r24
	out PORTB,r24
	ldi r24,1
	rcall lcd_command_sim
	rcall set_100_ms
	;sei
	cpi r29,1
	brsh alarm_go
	cpi r28,206
	brsh alarm_go
	jmp clear

alarm_go:
	jmp alarm

;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
;************************************************
ISR_TIMER1_OVF:
	in r18,SREG
	push r18
	ldi r18,0xef
	out ADCSRA,r18	
	;cli
	;check keyboard
	push r25
	push r24
	push r26
	push r21
	ldi r26,00 ;for equal to 0 check with r21
	rcall scan_keypad_rising_edge_sim
	clr r21
	or r21,r24
	or r21,r25
	cpse r21,r26 ;compare, skip if equal (if r21==0 skip)
	rcall counter_inc
	pop r21
	pop r26
	;continue timer
	;sbi ADCSRA,ADSC //enabling adc interrupt
	;out ADCSRA,r18
	;wrong password
	cli
	sbrc r20,0 ;skip if bit in reg is clear
	call wrong_routine
	pop r24
	pop r25
	pop r18
	out SREG,r18
	rcall set_100_ms
	sei
	reti

wrong_routine:
	clr r31
	inc r19  ; counter 5
	inc r16 ;counter 4
	cpi r16,48;
	breq end_wrong_psw
	cpi r19,6
	breq change_leds
	ret
	
change_leds:
	com r26
	andi r26,0x80
	;or r30,r26
	;out PORTB,r30
	clr r19
	ret

end_wrong_psw:
	clr r31
	clr r16
	clr r20
	clr r19
	clr r26
	ret
ADC_INT:
	in r18,SREG
	push r18
	clr r28
	clr r29
	in r28, ADCL
	in r29, ADCH
	andi r29,0x3
	pop r18
	out SREG,r18
	reti