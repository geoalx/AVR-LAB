#include <avr/io.h>
#define  F_CPU 8000000UL
#include <util/delay.h>
#include <avr/interrupt.h>

uint8_t alarm_flag =0; // r17
uint16_t temp=0;		// r18
uint8_t wrong_psw_counter=0;// r16
uint8_t chars_readed=0;		// r31
uint16_t adc=0;				// r28-r29
uint8_t out=0;				// r30
uint8_t psw_bit=0;			// r26
uint8_t digA=0;				// r22
uint8_t digB=0;				// r23
uint8_t wrong_flag=0;		// r20
uint8_t rev_bit=0;			// r21 
uint16_t palio = 0;

uint16_t scan_keypad_rising_edge_sim();
char scan_row_sim(char load);
uint16_t scan_keypad_sim();
char scan_row_sim(char load);
char keypad_to_ascii_sim(uint16_t keyb);
void set_leds(uint16_t adc);
void check_psw();
void timer_int_init();
void ADC_init();

ISR (TIMER1_OVF_vect)    // Timer1 ISR
{
	ADCSRA = 0xef;
	if ((temp = scan_keypad_rising_edge_sim()) != 0){
		chars_readed++;
		digB = keypad_to_ascii_sim(temp);
	}
	if (wrong_flag){
		chars_readed = 0;
		if (wrong_psw_counter == 40){
			wrong_psw_counter = 0;
			wrong_flag = 0;
			chars_readed = 0;
			psw_bit = 0;
		}
		else if (wrong_psw_counter%5 == 0) {
			psw_bit ^= 0x80;
			//PORTB += psw_bit;
		}
		wrong_psw_counter++;
	}
	TCNT1 = 0xf3cb;   // for 1 sec at 16 MHz
}

ISR (ADC_vect){
	adc = ADC;		
}

char scan_row_sim(char load){
	PORTC = load;
	_delay_us(500);
	char temp = PINC;
	return (temp & 0x0f);
}

uint16_t scan_keypad_sim(){
	char temp, a, b;
	temp = scan_row_sim(0x10);
	PORTC = 0;
	temp <<= 4;
	a = temp;
	temp = scan_row_sim(0x20);
	PORTC = 0;
	a += temp;
	temp = scan_row_sim(0x40);
	PORTC = 0;
	temp <<= 4;
	b = temp;
	temp = scan_row_sim(0x80);
	PORTC = 0;
	b += temp;
	uint16_t asd = ((a << 8) & 0xff00) | b;
	return asd;
}

uint16_t scan_keypad_rising_edge_sim(){
	//debouncing
	uint16_t temp1 = scan_keypad_sim();
	_delay_ms(15);
	uint16_t temp2 = scan_keypad_sim();
	
	//check for new keys
	uint16_t ap_1 = temp1&temp2;
	uint16_t res = ap_1&(palio^0xffff);
	palio = ap_1;
	return res;
}

char keypad_to_ascii_sim(uint16_t keyb){
	char ascii[16] = {'A','3','2','1','B','6','5','4','C','9','8','7','D','#','0','*'};
	for(int i=0; i<=15; i++){
		if((keyb&(0x1)) == 0x1){
			return ascii[15-i];
		}
		keyb >>=1;
	}
	return 0;
}

void ADC_init(){
	ADMUX = 1<<REFS0;
	ADCSRA = (1<<ADEN)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0);
} 

void timer_int_init(){
	TIMSK = (1<<TOIE1);
	TCCR1B = (1<<CS12);
}

void check_psw(){
	if (digA == '1' && digB == '4'){
		// print("WELCOME")
		PORTB = 0x80;
		_delay_ms(4000);
		PORTB = 0x00;
	}
	else {
		wrong_flag = 0xff;
		wrong_psw_counter= 0;
	}
	chars_readed=0;
}

void alarm(){
	// print("GAS DETECTED");
	alarm_flag = 1;
	set_leds(adc);
	PORTB = (out & rev_bit & 0x7f)| psw_bit;
	_delay_ms(500);	
	
	rev_bit ^= 0xff;
}

void set_leds(uint16_t adc){
	if (adc > 614){
		out = 0x7f;
	}
	else if (adc > 527){
		out = 0x3f;
	}
	else if (adc > 439){
		out = 0x1f;
	}
	else if (adc > 351){
		out = 0x0f;
	}
	else if (adc > 263){
		out = 0x07;
	}
	else if (adc > 176){
		out = 0x03;
	}
	else if (adc > 88){
		out = 0x01;
	}
	else{
		out = 0;
	}
}

int main(void)
{
 	DDRB = 0xff;
	DDRD = 0xff;
	DDRC = 0xf0;
	//lcd_init_sim();
	//lcd_command_sim(1);
	timer_int_init();
	TCNT1 = 0xf3cb;
	sei();
	// clr r30
    while (1)
    {
		if (chars_readed == 1){
			digA = digB;
		}
		else if(chars_readed == 2){
			check_psw();
		}
		
		if (adc > 206){
			alarm();
		}
		else{
			alarm_flag = 0;
			set_leds(adc);
			PORTB = (out & 0x7f )| psw_bit;
		}
    }
}

