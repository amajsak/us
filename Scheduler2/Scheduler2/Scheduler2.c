/*
 * Scheduler.c
 *
 * Created: 2013-11-20 18:20:28
 *  Author: student
 */ 

#define F_CPU 16000000UL
#define MAX_TASKS 10

#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>

typedef void(*TASK_PTR) (void);

struct tsk{
	TASK_PTR t;
	uint16_t ToGo;
	uint16_t Interval;
	uint8_t ready;
};

struct tsk tasks[MAX_TASKS];
int tasks_num = 0;

void init(){
	for(int i = 0; i < MAX_TASKS; i++){
		tasks[i].Interval = 0;
		tasks[i].ready = 0;
		tasks[i].t = 0;
		tasks[i].ToGo = 0;
	}
}

void addTask(TASK_PTR task, uint16_t period){
	if(tasks_num < MAX_TASKS){
		tasks[tasks_num].Interval = period;
		tasks[tasks_num].ToGo = period;
		tasks[tasks_num].t = task;
		tasks_num++;		
	}
}

void addOneShot(TASK_PTR task, uint16_t period){
	if(tasks_num < MAX_TASKS){
		tasks[tasks_num].Interval = 0;
		tasks[tasks_num].ToGo = period;
		tasks[tasks_num].t = task;
		tasks_num++;
	}
}

//wykonywana w przerwaniu
void schedule(){
	//int i = 0;
	for(int i = 0; i < MAX_TASKS; i++){
		//jesli task nie jest pusty zmiejszamy ToGo
		if(tasks[i].t != 0){
			tasks[i].ToGo--;
			//jesli ToGo = 0 zwiekszamy ready (periodyczny)
			if(tasks[i].ToGo == 0 && tasks[i].Interval != 0){
				tasks[i].ready++;
				tasks[i].ToGo = tasks[i].Interval;
			}
			//(nie jest periodyczny)
			else if(tasks[i].ToGo == 0 && tasks[i].Interval == 0){
				tasks[i].ready++;
			}
		}			
	}		
}

void execute(){	
	for(int i=0; i < MAX_TASKS; i++){
		if(tasks[i].ready > 0){
			tasks[i].t();
			tasks[i].ready--;
			//usuwanie taska jesli zostal wykonany i nie jest periodyczny
			if(tasks[i].ready == 0 && tasks[i].Interval == 0){
				tasks[i].Interval = 0;
				tasks[i].ToGo = 0;
				tasks[i].t = 0;				
			}
		}			
	}
}  

ISR(TIMER0_OVF_vect){
	schedule();
}

void task1(){
	PORTA = 0xFF;	
}

void task2(){
	PORTA = 0x00;
}

int main(void)
{
	
	// prescaler na 64
	OCR0 = 250;
	TCCR0 |= (0 << WGM00) | (0 << WGM01) | (0 << CS02) | (1 << CS01) | (1 << CS00) | (0 << COM01) | (0 << COM00);
	TIMSK |= (1 << TOIE0);
	DDRA = 0xFF;
	
	init();
    addTask(task1, 2);
	addTask(task2, 4);
	sei();	
	while(1){
		execute();
	}
	return 0;
}