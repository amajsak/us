/*
* AssemblerApplication1.asm
*
*  Created: 2013-11-06 18:16:47
*   Author: Aleksander Majsak
*/ 

.include "m32def.inc"

// makro do opoznienia
// wzor na przyblizona ilosc cykli k*4*249*16 + k*8 + 4*8 + k*BREQ + 4*BREQ + 249*BREQ, gdzie:
// k - parametr
// BREQ - przyjmuje wartosc 0 lub 1 w roznych przebiegach petli
// 1 ms = 16011 cykli
// 5 ms = 80007 cykli
// 10 ms = 160002 cykli
// 50 ms = 799962 cykli
// 255 ms = 4079757 cykli
.MACRO SLP
	LDI R16, 0	
	LDI R18, @0
	LDI R19, 0
	LDI R21, 0
	LDI R20, 0xF9 //249
	LDI R22, 0x04 //4

	LOOP1: // dopoki mniejsze od parametru
		CP R16, R18		// 1 cykl
		BREQ LOOP1END	// 1/2 cykle		
		INC R16			// 1 cykl
		LOOP3:			// 4 obiegi petli
			CP R21, R22		// 1 cykl
			BREQ LOOP3END	// 1/2 cykle			
			INC R21			// 1 cykl
			LOOP2:			// 249 obiegow, ~16 cykli	
				CP R19, R20		//1 cykl
				BREQ LOOP2END	// 1/2 cykle
				NOP
				NOP
				NOP
				NOP
				NOP
				NOP
				NOP
				NOP
				NOP
				NOP		
				NOP				// 11 cykli			
				INC R19			//	1 cykl
				RJMP LOOP2		// 2 cykle
			LOOP2END:
			NOP
			NOP
			NOP
			LDI R19, 0	// zerowanie licznika, 1 cykl
			JMP LOOP3	// 3 cykle
		LOOP3END:
		NOP		
		LDI R21, 0	// zerowanie licznika, 1 cykl
		JMP LOOP1	// 3 cykle
	LOOP1END:	
.ENDM

	//zarezerwiwanie pamieci w SRAM
	.DSEG
		DEST: .byte 16
	//wczytanie NAPISU do FLASH:
	.CSEG
	.ORG 1000
	NAPIS: .DB "ABCDE", 0
	.ORG 0
	JMP start

START:
	slp 10 //makro 10ms

	//inicjalizacja stosu
	LDI R16, LOW(RAMEND)
	OUT SPL, R16
	LDI R16, HIGH(RAMEND)
	OUT SPH, R16
	//wywolanie procedury odwracajacej napis
	call rev 
JMP START

//Procedura odwracajaca napis
REV:
	//wkladanie uzywanych przez procedure rejestrow na stos
	PUSH ZH
	PUSH ZL
	PUSH XH
	PUSH XL
	PUSH R17
	PUSH R24
	PUSH R25

	//ustawienie wskaznika na poczatek napisu
	LDI     ZH, HIGH(NAPIS*2)  
    LDI     ZL, LOW(NAPIS*2)    
    CALL   length      //wywolanie procedury obliczajacej dlugosc napisu
    LDI     XH, HIGH(DEST)   
    LDI     XL, LOW(DEST)      
	
	//wkladanie na stos rejestrow uzytych przy kopiowaniu napisu z FLASH DO SRAM
    PUSH ZH
	PUSH ZL
	PUSH XH
	PUSH XL
	PUSH R17
	PUSH R24	

	//skopiowanie z FLASH do SRAM
	LOOP:			
		LPM     R24, Z+ // R24=Z, Z++
		ST      X, R24  // X=R24
		INC     XL		// XL++
		DEC     R17		// R17--, w R17 trzymana jest dlugosc napisu
		BRGE    LOOP
	//zdjecie ze stosu rejestrow uzytych powyzej
	POP     R24
	POP     R17
	POP     XL
	POP		XH
	POP     ZL
    POP     ZH

	//odwracanie napisu
	LOOP2:
		LD R24, X		// wczytanie do R24 znaku wskazywanego przez X
		DEC R17			// zmniejszenie dlugosci fragmentu na ktorym operujemy
		ADD XL, R17     // dodanie dlugosci fragmentu do XL - "przesuniecie wskaznika"
		LD R25, X		// TMP, tymczasowe zapamietanie aktualnie wskazywanego znaku  
		ST X, R24		// ustawienie znaku z R24 na aktualnie wskazywanej pozycji (przeniesienie z poczatku napisu na koniec)
		SUB XL, R17		// odjecie dlugosci fragmentu od XL - "cofniecie wskaznika"
		ST X, R25		// ustawienie znaku zapamietanego w TMP(R25) na aktualnie wskazywanej pozycji (przeniesienie z konca na poczatek)
		DEC R17			// zmniejszenie fragmentu na ktorym operujemy
		INC XL			// przesuniecie wskaznika aktualnego znaku o 1 w prawo
		CPI R17, 0		// sprawdzenie czy zostal jakis fragment do przestawienia (dla napisow o parzystej ilosci znakow)
		BREQ LOOP2END
		CPI R17, 0		// to samo co wyzej, ale dla napisow o nieparzystej dlugosci (R17 < 0)
		BRLT LOOP2END
		JMP LOOP2
	LOOP2END:

	//zdejmowanie rejestrow ze stosu
	POP		R25
	POP     R24
	POP     R17
	POP     XL
	POP		XH
	POP     ZL
    POP     ZH
RET	

//Procedura obliczajaca dlugosc napisu
LENGTH:
	PUSH    ZH
    PUSH    ZL
    LDI     R17, 0 //dlugosc napisu
	
	LOOP1:
		LPM     R24, Z+
		CPI     R24, 0 //sprawdzanie czy koniec napisu - "0"
		BREQ    LOOP1END
		INC     R17 //dlugosc + 1
		RJMP    LOOP1
	LOOP1END:
    POP     ZL
    POP     ZH
  
RET

//ZADANIE - Procedura do odwracanie napisow
//wczytanie do FLASH:
//.CSEG
//.ORG 1000
//NAPIS: .DB "ABC", 0
//.ORG 0
//1. inicjowanie stosu
//a) wczytanie z FLASH do SRAM
//b) zamiana znakow
//przed zmiana rejestrow w procedurze odlozyc je na stos a na koncu zdjac w odwr. kolejnosci
//Z - wskaznik na poczatek napisu (LDI ZL, LOW(NAPIS*2); LDI ZH, HIGH(NAPIS*2))
//X - wskaznik na poczatek gdzie napis ma sie przenisc
//LPM R16, Z
//mail z linkiem do repozytorium GIT (ujworkshop@gmail.com) - razem z tym macro (10ms)