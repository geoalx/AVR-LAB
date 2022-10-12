#include <util/delay.h>

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

uint16_t palio = 0;

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