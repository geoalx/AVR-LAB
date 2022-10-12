#include <string.h>
extern void lcd_init_sim();
extern void lcd_data_sim(char R24);
void print(char x){
	lcd_data_sim(x);
}

void print_str(char * str){
	for(int i=0; i<strlen(str); i++){
		print(str[i]);
	}
}