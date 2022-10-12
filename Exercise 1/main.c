#define F_CPU 8000000

#include <avr/io.h>
#include "keyboard.h"
#include "display.h"
#include <util/delay.h>
#include <avr/interrupt.h>
#include <stdio.h>
#include <stdlib.h>

char dig;
uint16_t temp;
int duty=0,TOP = 255;
float step = 500.0/1024.0, result = 0.0, pwm_qu = 0.0;
char output[4];
char str_duty[3];
char temp_str[4];

ISR(TIMER0_OVF_vect){
	ADCSRA |= (1<<ADSC); //ADC conversion is Enabled (ADSC=1)
}

//OC0 is connected to pin PB3
//OC1A is connected to pin PD5
//OC2 is connected to pin PD7
void PWM_init()
{
	//set TMR0 in fast PWM mode WGM01,WGM00 = 11 with non-inverted output, Prescale=8 (CS02,CS01,CS00) = 010

	TCCR0 = (1<<WGM00) | (1<<WGM01) | (1<<COM01) | (1<<CS01);
	TIMSK = (1<<TOIE0); //enable interrupt in overflow
	DDRB|=(1<<PB3); //set PB3 pin as output
	//set TMR1A in fast PWM 8 bit mode with non-inverted output
	//Prescale=8
}

void ADC_enable(){
	ADMUX = 1<<REFS0;  //Vref: Vcc 5V
	ADCSRA = (1<<ADEN)| (1<<ADSC) |(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0);
	//ADC is Enabled (ADEN=1)
	//ADC conversion is Enabled (ADSC=1)
	//Set Prescaler CK/128 = 62.5Khz (ADPS2:0=111)
}

void print_res(int result){
			
	//print_str("DUTY : ");
	//sprintf(str_duty,"%d",duty);	
	//print_str(str_duty);
	//print('\n');
	
	print_str("Vo1\n");
	
	int dig2 = result / 100;
	int dig1 = (result % 100) / 10;
	int dig0 = result % 10;
	print(dig2 + 48);
	print('.');
	print(dig1 + 48);
	print(dig0 + 48);	
		
}

int main ()
{

	DDRC = 0xf0; // half 4 lower bits as input and 4 upper bits as output
	DDRD = 0xff; //	output
	
	PWM_init();
	ADC_enable();
	lcd_init_sim();
	
	sei();
	
	while(1){
		_delay_ms(100);
		lcd_init_sim();
	
		if ((temp = scan_keypad_rising_edge_sim()) != 0){
			dig = keypad_to_ascii_sim(temp);
			if(dig=='1' && duty<TOP) OCR0 = ++duty;
			else if(dig == '2' && duty>0) OCR0 = --duty;
		}
		_delay_ms(8);
	
		while((ADCSRA&(1<<ADIF))==0);
		_delay_us(10);
		pwm_qu = ADC&0x3ff;
		result = pwm_qu*step;
		
		print_res((int) result);		
		
		//print(' ');
		//sprintf(temp_str,"%d",ADC);		
		//print_str(temp_str);
	}
}