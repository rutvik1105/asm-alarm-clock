#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

jmp st1 
db 125 dup(0)

;IVT entry for 20h-00140h
         
         dw t_inc
         dw 0000
         
;IVT entry for 21h-00144h
         
         dw t_conv
         dw 0000 
      
;IVT entry for 22h-00148h 
           
         dw t_set
         dw 0000
         db 4 dup(0)
                    
         
st1:cli 
;initialize ds,es,ss to start of RAM

mov ax,0100h
mov ds,ax
mov es,ax
mov ax,0111h
mov ss,ax
mov sp,0FFFEH



STI

;
; initializing data at memory locations
;
slash equ 01000h
colon equ 01001h
hr1   equ   01002h
hr2   equ  01003h
min   equ   01004h
sec   equ   01005h
date  equ   01006h
month equ   01007h
year  equ   01008h  
day1  equ      01009h   ;monday
day2  equ  0100Fh		;Tuesday
day3  equ  01016h		;Wednesday 
day4  equ 0101Fh		;Thursday
day5  equ  01027h		;Friday
day6  equ  0102Dh		;Saturday
day7  equ  01035h		;sunday
a     equ  0103Bh
am    equ   0103Ch
pm    equ   0103Eh
alarmmin equ 01040h
alarmhr1 equ 01041h
alarmhr2 equ 01042h
form equ 01043h
displayday equ 01044h

; Initializing the Clock

CNT0   EQU 40H
CNT1   EQU 42H
CNT2   EQU 44H
CREG   EQU 46H
MOV   AL , 00110100b
MOV dx,CREG
OUT dx , AL
MOV   AL,10H
mov dx,CNT0
OUT dx,AL
MOV   AL , 27H
OUT dx, AL
				
;Initialising 8259

mov al,00010011b
mov dx,50h
out DX,al
mov al,00100000b
out 52h,al
mov al,00000111b
out 52h,al
mov al,11111000b
out 52h,al
			
;initializing 8255(2)

portA equ 80h
portB equ 82h
portC equ 84h
creg2 equ 86h
mov al,10010010b
mov dx,creg2
out dx,al
		
; Initializing the LCD Screen

PORT_A   EQU 60H                                           	; set port addresses 
PORT_B   EQU 62H
PORT_C   EQU 64H
COMMAND_ADDRESS EQU 66H

;Sending a command or data to the LCD Display

MOV AL, 38H   ;initialize LCD for 2 lines & 5*7 matrix
CALL COMNDWRT ;write the command to LCD
CALL ms_delay ;wait before issuing the next command
CALL ms_delay ;this command needs lots of delay
CALL ms_delay
MOV AL, 0EH   ;send command for LCD on, cursor on
CALL COMNDWRT
CALL ms_delay
MOV AL, 01    ;clear LCD
CALL COMNDWRT
CALL ms_delay
MOV AL, 06    ;command for shifting cursor right
CALL COMNDWRT
CALL ms_delay

COMNDWRT PROC NEAR ;this procedure writes commands to LCD
CALL LCDREADY
PUSH DX           ;save DX
MOV DX, PORT_A
OUT DX, AL        ;send the code to Port A
MOV DX, PORT_B 
MOV AL, 00000100b ;RS=0,R/W=0,E=1 for H-To-L pulse
OUT DX, AL
NOP
NOP
MOV AL, 00000000b ;RS=0,R/W=0,E=0 for H-To-L pulse
OUT DX, AL
POP DX
RET
COMNDWRT ENDP       		   

LCDREADY PROC NEAR
PUSH AX
PUSH DX
MOV AL, 90H
MOV DX, COMMAND_ADDRESS
OUT DX, AL
MOV AL, 00000110B
MOV DX, PORT_B
OUT DX, AL
MOV DX, PORT_A
AGAIN: IN AL,DX
ROL AL,1
JC AGAIN
MOV AL,80H
MOV DX,COMMAND_ADDRESS
OUT DX, AL
POP DX
POP AX
RET
LCDREADY ENDP	   
													   
; ALP for procedure write

WRITE PROC NEAR

CALL LCDREADY
PUSH DX ;save DX
MOV DX,PORT_A ;DX=port A address
OUT DX,AL ;issue the char to LCD
MOV AL,00000101B ;RS=1,R/W=0, E=1 for H-to-L pulse
MOV DX, PORT_B ;port B address
OUT DX, AL ;make enable high
NOP
NOP
MOV AL, 00000001B ;RS=1,R/W=0 and E=0 for H-to-L pulse
OUT DX, AL
POP DX
RET

WRITE ENDP


;
; ALP for Clear Screen
;
CLS PROC NEAR				
	MOV AL, 01  ;clear LCD
    CALL COMNDWRT
	RET
CLS ENDP
;
; ALP for delay 
;
ms_delay proc NEAR 

MOV CX, 1325  ;1325*15.085 usec = 20 msec
PUSH AX
s1: IN AL, 61H
AND AL, 00010000B
CMP AL, AH
JE W1
MOV AH, AL
LOOP s1
POP AX
RET

ms_delay endp
;
; ALP for key debounce
;
DEBOUNCE PROC NEAR	
Z0:	IN   AL ,64h
AND   AL , 0Fh
CMP   AL , 0Fh
JZ   Z0
Mov bl,20
CALL   ms_DELAY
Z1:
IN   AL , 64h
AND   AL , 0Fh
CMP   AL , 0fh
JZ   Z1
Mov bl,20
Call ms_delay
IN   AL , 64h
AND   AL , 0Fh
CMP   AL , 0fh
JZ   Z1
RET
DEBOUNCE ENDP
 
;
; moving initial values into data 
;

DISPLAY PROC near
      display11 :
                Mov si,form
                Mov al,[si]
                CMP   al , 00       ; comparing CS for 24 hr or 12 hr clock format        	
                JNZ   display22
            	MOV   SI ,  hr1     ; displaying hours in 24 hr clock format
            	MOV   AX , [SI]
            	MOV DI, alarmhr1
            	MOV BL,[di]
            	CMP AL,BL
                JZ COMPMIN1

						
     back11: 
            MOV   SI , hr1           ; displaying hours in 24 hr clock format
           	MOV   AX , [SI]
  		    MOV   Bl , 10
           	DIV   Bl
           	ADD   AL , 30H
           	ADD   AH , 30H
           	MOV   BL , AL
           	CALL   WRITE
           	MOV   BL , AH
           	CALL   WRITE
            MOV   BL , 3AH 	          ; displaying colon                              	
           	CALL   WRITE
         	MOV   SI ,  min           ; displaying minutes in 24 hr clock format
           	MOV   AX , [SI]
            MOV   Bl , 10
           	DIV   Bl
           	ADD   AL , 30H
           	ADD   AH , 30H
           	MOV   BL , AL
           	CALL   WRITE
           	MOV   BL , AH
           	CALL   WRITE
           	MOV   BL , 3AH 	           ; displaying colon                             
           	CALL   WRITE
                MOV   SI,   sec        ; displaying seconds in 24 hr clock format
           		MOV   AX , [SI]
           		MOV   Bl , 10
           		DIV   Bl
           		ADD   AL , 30H
           		ADD   AH , 30H
           		MOV   BL , AL
           		CALL   WRITE
           		MOV   BL , AH
           		CALL   WRITE
           		MOV   CX , 12   	
           		x1234:      	
                        MOV   BL , 20H          ; spaces to jump to the next line   	
                        CALL   WRITE
                       	DEC  CX
                        CMP   CX , 0
                        JNZ   x1234
           	          	MOV   SI ,01038h                ; displaying day1
           	   	        MOV   BL , [SI]

day1:    	CALL   WRITE
          	INC   SI
            mov al,'$'
           	Cmp al,bl              
            JNZ   day1
         	MOV   SI ,  date                    ; displaying date
           	MOV   AX , [SI]
           	ADD   AH , 30H
           	MOV   BL , AL
           	CALL   WRITE
           	MOV   BL , AH
           	CALL   WRITE
           	MOV   BL , 2FH    	             	; displaying slash after date         	
            CALL   WRITE
           	MOV   SI ,  month                   ; displaying month
           	MOV   AX , [SI]
           	MOV   Bl , 10
           	DIV   Bl
           	ADD   AL , 30H
           	ADD    AH , 30H
           	MOV    BL , AL
           	CALL   WRITE
           	MOV    BL , AH
           	CALL   WRITE
           	MOV   BL , 2FH    	            	; displaying slash after month           
	        CALL   WRITE
           	MOV BL,32H
            CALL WRITE
            MOV BL,30H
            CALL WRITE                      ; displaying year                                                            	
            MOV SI, YEAR			        ;displaying first two digits of year
           	CALL   WRITE
           	MOV   AX , [SI]                     ; displaying last two digits of year
           	MOV   BL , 10
           	DIV   BL
           	ADD   AL , 30H
           	ADD   AH , 30H
           	MOV   BL , AL
           	CALL   WRITE
           	MOV   BL , AH
           	CALL   WRITE
;
; Display for 12 hr clock format
;


display22:   
            mov si,form 
            mov al,01
            CMP   al,[si]                         ; comparing CS for 24 hr or 12 hr clock format     	
            JNZ   display11
            MOV   SI ,  hr2                     ; displaying hours in 12 hr clock format
           	MOV   AX , [SI]
          	MOV DI,alarmhr2
           	MOV BL,[di]
           	CMP AL,BL
            JZ COMPMIN2
           	back22:
            MOV   SI ,  hr2                     ; displaying hours in 12 hr clock format
           	MOV   AX , [SI]
           	MOV   BL, 10
           	DIV   BL
           	ADD   AL , 30H
           	ADD   AH , 30H
           	MOV   BL , AL
           	CALL   WRITE
           	MOV   BL , AH
           	CALL   WRITE
           	MOV   BL , 3AH 	         	        ; displaying colon            
            CALL   WRITE
           	MOV   SI ,  min                     ; displaying minutes in 12 hr clock format
           	MOV   AX , [SI]
           	MOV   BL , 10
           	DIV   BL
           	ADD   AL , 30H
           	ADD   AH , 30H
           	MOV   BL , AL
           	CALL   WRITE
           	MOV   BL , AH
           	CALL   WRITE
           	MOV   BL , 3AH 	                 	; displaying colon                                                           
           	CALL   WRITE 
                MOV   SI ,  sec                 ; displaying seconds in 12 hr clock format
           		MOV   AX , [SI]
           		MOV   BL , 10
           		DIV   BL
           		ADD   AL , 30H
           		ADD   AH , 30H
           		MOV   BL , AL
           		CALL   WRITE
           		MOV   BL , AH
           		CALL   WRITE
           	                                        
           		MOV   SI ,  A			        ;displaying am after the set time
		        MOV   BL , [SI]
		        CALL   WRITE
           		INC   SI
	           	MOV BL,[SI]
                CALL WRITE
           	    MOV   CX , 10
           	    JMP   x1234

DISPLAY endp


Mov  si, 0
Mov al,'/'
Mov [si],al
Inc si

Mov al,'/'
Mov [si],al
Inc si

Mov al,0
Mov [si],al
Inc si

Mov al,0
Mov [si],al
Inc si

Mov al,0
Mov [si],al
Inc si

Mov al,0
Mov [si],al
Inc si

Mov al,0
Mov [si],al
Inc si

Mov al,0
Mov [si],al
Inc si

Mov al,0
Mov [si],al
Inc si

Mov al,'m'
Mov [si],al
Inc si

Mov al,'o'
Mov [si],al
Inc si

Mov al,'n'
Mov [si],al
Inc si

Mov al,'d'
Mov [si],al
Inc si

Mov al,'a'
Mov [si],al
Inc si

Mov al,'y'
Mov [si],al
Inc si

Mov al,'t'
Mov [si],al
Inc si

Mov al,'u'
Mov [si],al
Inc si

Mov al,'e'
Mov [si],al
Inc si

Mov al,'s'
Mov [si],al
Inc si

Mov al,'d'
Mov [si],al
Inc si

Mov al,'a'
Mov [si],al
Inc si

Mov al,'y'
Mov [si],al
Inc si

Mov al,'w'
Mov [si],al
Inc si

Mov al,'e'
Mov [si],al
Inc si

Mov al,'d'
Mov [si],al
Inc si

Mov al,'n'
Mov [si],al
Inc si

Mov al,'e'
Mov [si],al
Inc si

Mov al,'s'
Mov [si],al
Inc si

Mov al,'d'
Mov [si],al
Inc si

Mov al,'a'
Mov [si],al
Inc si

Mov al,'y'
Mov [si],al
Inc si

Mov al,'t'
Mov [si],al
Inc si

Mov al,'h'
Mov [si],al
Inc si

Mov al,'u'
Mov [si],al
Inc si

Mov al,'r'
Mov [si],al
Inc si

Mov al,'s'
Mov [si],al
Inc si

Mov al,'d'
Mov [si],al
Inc si

Mov al,'a'
Mov [si],al
Inc si

Mov al,'y'
Mov [si],al
Inc si

Mov al,'f'
Mov [si],al
Inc si

Mov al,'r'
Mov [si],al
Inc si

Mov al,'i'
Mov [si],al
Inc si

Mov al,'d'
Mov [si],al
Inc si

Mov al,'a'
Mov [si],al
Inc si

Mov al,'y'
Mov [si],al
Inc si

Mov al,'s'
Mov [si],al
Inc si

Mov al,'a'
Mov [si],al
Inc si

Mov al,'t'
Mov [si],al
Inc si

Mov al,'u'
Mov [si],al
Inc si

Mov al,'r'
Mov [si],al
Inc si

Mov al,'d'
Mov [si],al
Inc si

Mov al,'a'
Mov [si],al
Inc si

Mov al,'y'
Mov [si],al
Inc si

Mov al,'s'
Mov [si],al
Inc si

Mov al,'u'
Mov [si],al
Inc si

Mov al,'n'
Mov [si],al
Inc si

Mov al,'d'
Mov [si],al
Inc si

Mov al,'a'
Mov [si],al
Inc si

Mov al,'y'
Mov [si],al
Inc si

Mov al,'a'
Mov [si],al
Inc si

Mov al,'a'
Mov [si],al
Inc si

Mov al,'m'
Mov [si],al
Inc si

Mov al,'p'
Mov [si],al
Inc si

Mov al,'m'
Mov [si],al
Inc si

Mov al,0
Mov [si],al
Inc si

Mov al,0
Mov [si],al
Inc si

Mov al,0
Mov [si],al
Inc si 

Mov al,0
Mov [si],al
Inc si

Mov al,'m'
Mov [si],al
Inc si

Mov al,'o'
Mov [si],al
Inc si

Mov al,'n'
Mov [si],al
Inc si

Mov al,'d'
Mov [si],al
Inc si

Mov al,'a'
Mov [si],al
Inc si

Mov al,'y'
Mov [si],al
Inc si

Mov al,'$'	
Mov [si],al
Inc si

Mov al,'$'
Mov [si],al
Inc si

Mov al,'$'
Mov [si],al
XOR AH,AH


      display1 :
                Mov si,form
                Mov al,[si]
                CMP   al , 00       ; comparing CS for 24 hr or 12 hr clock format        	
                JNZ   display2
            	MOV   SI ,  hr1     ; displaying hours in 24 hr clock format
            	MOV   AX , [SI]
            	MOV DI, alarmhr1
            	MOV BL,[di]
            	CMP AL,BL
                JZ COMPMIN1

						
     BACK1: 
            MOV   SI , hr1           ; displaying hours in 24 hr clock format
           	MOV   AX , [SI]
  		    MOV   Bl , 10
           	DIV   Bl
           	ADD   AL , 30H
           	ADD   AH , 30H
           	MOV   BL , AL
           	CALL   WRITE
           	MOV   BL , AH
           	CALL   WRITE
            MOV   BL , 3AH 	          ; displaying colon                              	
           	CALL   WRITE
         	MOV   SI ,  min           ; displaying minutes in 24 hr clock format
           	MOV   AX , [SI]
            MOV   Bl , 10
           	DIV   Bl
           	ADD   AL , 30H
           	ADD   AH , 30H
           	MOV   BL , AL
           	CALL   WRITE
           	MOV   BL , AH
           	CALL   WRITE
           	MOV   BL , 3AH 	           ; displaying colon                             
           	CALL   WRITE
                MOV   SI,   sec        ; displaying seconds in 24 hr clock format
           		MOV   AX , [SI]
           		MOV   Bl , 10
           		DIV   Bl
           		ADD   AL , 30H
           		ADD   AH , 30H
           		MOV   BL , AL
           		CALL   WRITE
           		MOV   BL , AH
           		CALL   WRITE
           		MOV   CX , 12   	
           		X1:      	
                        MOV   BL , 20H          ; spaces to jump to the next line   	
                        CALL   WRITE
                       	DEC  CX
                        CMP   CX , 0
                        JNZ   X1
           	          	MOV   SI ,01038h                ; displaying day
           	   	        MOV   BL , [SI]

day:    	CALL   WRITE
          	INC   SI
            mov al,'$'
           	Cmp al,bl              
            JNZ   DAY
         	MOV   SI ,  date                    ; displaying date
           	MOV   AX , [SI]
           	ADD   AH , 30H
           	MOV   BL , AL
           	CALL   WRITE
           	MOV   BL , AH
           	CALL   WRITE
           	MOV   BL , 2FH    	             	; displaying slash after date         	
            CALL   WRITE
           	MOV   SI ,  month                   ; displaying month
           	MOV   AX , [SI]
           	MOV   Bl , 10
           	DIV   Bl
           	ADD   AL , 30H
           	ADD    AH , 30H
           	MOV    BL , AL
           	CALL   WRITE
           	MOV    BL , AH
           	CALL   WRITE
           	MOV   BL , 2FH    	            	; displaying slash after month           
	        CALL   WRITE
           	MOV BL,32H
            CALL WRITE
            MOV BL,30H
            CALL WRITE                      ; displaying year                                                            	
            MOV SI, YEAR			        ;displaying first two digits of year
           	CALL   WRITE
           	MOV   AX , [SI]                     ; displaying last two digits of year
           	MOV   BL , 10
           	DIV   BL
           	ADD   AL , 30H
           	ADD   AH , 30H
           	MOV   BL , AL
           	CALL   WRITE
           	MOV   BL , AH
           	CALL   WRITE
;
; Display for 12 hr clock format
;


display2:   
            mov si,form 
            mov al,01
           	CMP   al,[si]                         ; comparing CS for 24 hr or 12 hr clock format     	
           	JNZ   DISPLAY1
            MOV   SI ,  hr2                     ; displaying hours in 12 hr clock format
           	MOV   AX , [SI]
          	MOV DI,alarmhr2
           	MOV BL,[di]
           	CMP AL,BL
            JZ COMPMIN2
           	BACK2:
            MOV   SI ,  hr2                     ; displaying hours in 12 hr clock format
           	MOV   AX , [SI]
           	MOV   BL, 10
           	DIV   BL
           	ADD   AL , 30H
           	ADD   AH , 30H
           	MOV   BL , AL
           	CALL   WRITE
           	MOV   BL , AH
           	CALL   WRITE
           	MOV   BL , 3AH 	         	        ; displaying colon            
            CALL   WRITE
           	MOV   SI ,  min                     ; displaying minutes in 12 hr clock format
           	MOV   AX , [SI]
           	MOV   BL , 10
           	DIV   BL
           	ADD   AL , 30H
           	ADD   AH , 30H
           	MOV   BL , AL
           	CALL   WRITE
           	MOV   BL , AH
           	CALL   WRITE
           	MOV   BL , 3AH 	                 	; displaying colon                                                           
           	CALL   WRITE 
                MOV   SI ,  sec                 ; displaying seconds in 12 hr clock format
           		MOV   AX , [SI]
           		MOV   BL , 10
           		DIV   BL
           		ADD   AL , 30H
           		ADD   AH , 30H
           		MOV   BL , AL
           		CALL   WRITE
           		MOV   BL , AH
           		CALL   WRITE
           	                                        
           		MOV   SI ,  A			        ;displaying am after the set time
		        MOV   BL , [SI]
		        CALL   WRITE
           		INC   SI
	           	MOV BL,[SI]
                CALL WRITE
           	    MOV   CX , 10
           	    JMP   X1


; ALP for incrementing displayed values 

                    
              t_inc:CALL CLS 
                    mov   al,00
                    mov   si,form
                    CMP   [si],al
                    JNZ   INC2
               INC1:
	                MOV   SI ,  sec			; for incrementing seconds
	                MOV   AL , [SI]
	                CMP   AL ,59    	
	                JZ  x2				; if seconds=59 move on to inc min
	                INC   [si]
	                IRET
	                X2:	MOV   AL , 00
		            MOV   DI ,  sec
		            MOV   [DI] , AL		; making sec=00 and then incrementing min
		            MOV   SI ,  min
		            MOV   AL , [SI]
                    CMP   AL , 59
		         	JZ   X3
		        	INC [si]
                    IRET
                    X3:	MOV   AL , 00
		            MOV   DI ,  min		; making min=00 and then incrementing hr
	             	MOV   [DI] , AL
                    MOV   SI ,  hr1
                  	MOV AL,[SI]
                    CMP   AL , 23		; checking for hr=23, jump to inc day if yes
	                JZ   X4
	                INC   [si]
		         	IRET			; else incrementing hr
	            	X4: MOV AL, 00
                    MOV   SI ,  hr1		; making hr=00 and inc day and date
			        MOV   [SI] , AL
					
              label:MOV DI,displayday		; incrementing day
		            MOV   SI ,  day1
                    Mov cx,6
                    cld
                    Rep  CMPSB
                    JZ   X5
                    MOV   DI ,  displayday 
                    MOV   SI ,  day2
                    Mov cx,7
                    cld
                    REP CMPSB
                    JZ   X6
                    MOV   DI ,  displayday  
                    MOV   SI ,  day3
                    Mov cx,9
                    cld
                    REP CMPSB
                    JZ   X7 
                    MOV   DI ,  displayday 
                    MOV   SI ,  day4
                    Mov cx,8
                    cld
                    REP CMPSB
                    JZ   X8
                    MOV   DI,displayday 
                    MOV   SI ,  day5
                    cld
                    mov cx,6
                    REP CMPSB
                    JZ   X9
                    MOV   DI ,  displayday 
                    MOV   SI ,  day6
                    cld
                    mov cx,8
                    REP CMPSB
                    JZ   X10
                    MOV   DI ,  displayday 
                    MOV SI,day7
                    Cld
                    Mov cx,6
                    REP CMPSB
                    JZ   X11
                 X5:MOV DI,displayday 
                    MOV SI,day2
                    cld
                    mov cx,7
	            	REP MOVSB
	             	JMP X12
                 X6:MOV DI,displayday 
                    MOV   SI ,  day3
                    cld
                    mov cx,9
		            REP MOVSB
		            JMP X12
                 X7:MOV DI,displayday 
                    MOV SI,day4
                    cld
                    mov cx,8
		            REP MOVSB
		            JMP X12
                 X8:MOV DI,displayday 
                    MOV SI,day5
                    cld
                    mov cx,6
		            REP MOVSB
		            JMP X12
                 X9:MOV DI,displayday 
                    MOV SI,day6
                    cld
                    mov cx,8		
                    REP MOVSB
	            	JMP X12
                X10:MOV DI,displayday 
                    MOV SI,day7
                    cld
                    mov cx,6
	            	REP MOVSB
		            JMP X12
	            X11:MOV DI,displayday 
                    MOV SI,day1
                    cld
                    mov cx,6
		            REP MOVSB
		            JMP X12
					
                X12:MOV SI,year
		            MOV AL,[SI]
                    MOV   BL , 4			; checking for leap year
		            DIV   BL
		            CMP   AH , 0			; if AH(remainder)=0, leap yr
		            JZ   X13
					
	X14:MOV SI,month		                ; incrementing for non leap years
		MOV   AL , [SI]
		CMP   AL , 01
		JZ   X16
		CMP   AL , 02
		JZ   X18
		CMP   AL , 03
		JZ   X16
		CMP   AL , 04
		JZ   X17
		CMP   AL , 05
		JZ   X16
		CMP   AL , 06
		JZ   X17
		CMP   AL , 07
		JZ   X16
		CMP   AL , 08
		JZ   X16
		CMP   AL , 09
		JZ   X17
		CMP   AL , 10
		JZ   X16
		CMP   AL , 11
		JZ   X17
		MOV   SI ,  date		; incrementing for december	
		MOV   AL , [SI]
		CMP   AL , 31
		JZ   X19
		INC [si]
		IRET
		
	X16:MOV SI,date		        ; incrementing for months with 31 days	
		MOV AL,[SI]
		CMP AL,31
		JZ   X15
		INC [si]
		IRET
	X17:MOV SI,date	            ; incrementing for months with 30 days				
	    MOV AL,[SI]
		CMP AL,30
		JZ   X15
		INC [si]
		IRET
	X18:MOV SI,date	            ; incrementing for february non leap yr	
		MOV AL ,[SI]
		CMP AL,28
		JZ   X15
		INC [si]
		IRET
	X19:MOV AL,01		        ; for year incrementation
        MOV   SI ,  date
		MOV   [SI] , AL
		MOV   SI ,  month
		MOV   [SI] , AL
		Mov si,year
		Inc [si]
		IRET
    X13:MOV   SI ,  month	    ; inc when leap yr
		MOV   AL , [SI]
		CMP   AL , 02		    ; checking if month is feb
		JNZ   X14		        ; jumping to normal year inc if month not feb
		MOV   SI ,  date		; inc for leap yr , feb
		MOV   AL , [SI]
		CMP   AL , 29
		JZ   X15
		INC [si]
		IRET
	X15:MOV AL , 01		       ; month incrementation
		MOV SI,date
		MOV [SI] , AL
		Mov si,month
		Inc [si]
		IRET
		
; incrementing for 12 hour format clock
   INC2:
	    MOV   SI ,  sec				; for incrementing seconds
	    MOV   AL , [SI]
	    CMP   AL ,59
	    JZ   X20					; if seconds=59 move on to inc min
	    INC   [si]
	    IRET
	X20:MOV AL,00
		MOV   SI ,  sec
		MOV   [SI] , AL		        ; making sec=00 and then incrementing min
		MOV   SI ,  min
		MOV   AL , [SI]
        CMP   AL , 59
		JZ   X21
		INC [si]
		IRET
	X21:MOV   AL , 00
		MOV   SI ,  min
		MOV   [SI] , AL
		MOV   SI,hr2
		MOV   AL,[SI]
		CMP   AL,12
		JZ   X22
		CMP   AL , 11
		JZ   X23
		INC   [si]
	    IRET
	X22:MOV   AL , 01
        MOV SI,hr2
        MOV [SI],AL
        IRET
    X23:INC [si]
        MOV dI,a  
        MOV si,am
        Mov al,[si]
	    Cmp al,[di]
        JZ X24
      	MOV SI,am
	    MOV DI,a
        cld
	    mov cx,2
    	REP MOVSB
        JMP LABEL
	X24:MOV di ,a
		MOV si, PM
        Cld
        Mov cx,2
	    REP MOVSB
        IRET

				
COMPMIN1:MOV DI,alarmmin
         MOV BL,[DI]
         MOV SI, min
         MOV AL,[SI]
         CMP AL,BL
         JNZ abc
		 mov al,00000001b
	     mov dx,creg2
	     out dx,al	
		 mov dx,portB
	  q1:in al,dx
		 and al,80h
		 cmp al,80h
		 jnz q1      
    abc: JMP BACK1
		 
COMPMIN2:MOV DI,alarmmin
        MOV BL,[DI]
        MOV SI, min
        MOV AL,[SI]
        CMP AL,BL
        JNZ abc2
		 mov al,00000001b
	     mov dx,creg2
	     out dx,al	
		 mov dx,portB
	  q2:in al,dx
		 and al,80h
		 cmp al,80h
		 jnz q2    
    abc2:JMP BACK2
		
;
; ALP for conversion between 12 hr and 24 hr clock format
;
        
  t_conv:	
        CALL   debounce
        mov  si,form
        mov al,01 
        CMP  [si],al
        JZ   XX
        JMP   XY
                                   ; Conversion from 12 hr format to 24 hr format
    XX:	MOV   SI , a
	    MOV   AL , [SI]
	    CMP   AL ,'a'
	    JZ   XX1
	    MOV   SI , hr2
	    MOV   aL , [SI]
	    MOV   bL , aL
	    CMP   bL ,12
	    Jz  XX2
	    ADD   BL , 12
	    JMP   XX2
   XX2:	MOV   SI , hr2
		MOV   [SI] , BL
        IRET
	XX1:MOV   SI , hr2
		MOV   AL , [SI]
		MOV   BL , AL
		CMP   AL , 12
		JNZ   XX2
		MOV   BL , 00
		JMP   XX2
                                   ; Conversion from 24 hr format to 12 hr format
    XY:	MOV   SI , hr1
	    MOV   AL , [SI]
	    MOV    BL , AL
	    CMP   AL  , 00
	    JZ   XY1
	    CMP   AL , 12
	    JB   XY2
	    JZ   XY3
	    MOV   SI , hr2
	    SUB   BL , 12
	    MOV   [SI] , BL
	    MOV   SI , pm
	    MOV   DI , a
        Cld
        Mov cx,2
	    REP MOVSB
	    IRET
	XY1:MOV   AL , 12
		MOV   SI , hr2
		MOV   [SI] , AL
		MOV   SI , am
		MOV   DI , a
		Mov cx,2
		cld
		REP MOVSB
		IRET
	XY2:MOV   SI , hr2
		MOV   [SI] , BL
		MOV   SI , am
		MOV   DI , a
		Cld
		Mov cx,2
		REP MOVSB
		IRET
	XY3:MOV   SI , hr2
		MOV   [SI] , BL
        MOV   SI , pm
		MOV   DI , a
		Cld
		Mov cx,2
		REP MOVSB
		IRET
;
; ALP for setting time, day , date , month and year
 
  
   t_set:
    	MOV   dx , PORT_C
        IN   AL ,dx
        CMP   AL , 80h
        JZ   sec_set  
        CMP   AL , 40h
        JZ   min_set
        CMP   AL , 20h
        JZ   hr_set
        CMP   AL , 10h
        JZ   date_set
        CMP   AL , 08h
        JZ   month_set
        CMP   AL , 04h
        JZ   year_set
        CMP   AL , 02h
        JZ   alarm_hr_set
        CMP   AL , 01h
        JZ   alarm_min_set
        IRET
		
sec_set:mov dx,portA
     w1:in al,dx
		and al,11h
		CMP AL,01h
		JZ   IN1
		CMP   AL ,10h
		JZ   IN2
		jnz w1
		IRET
		
	IN1:CALL DEBOUNCE
		MOV  SI , sec
		MOV  AL , [SI]
		CMP  AL , 59
		JZ   IN3
		INC  [si]
		mov dx,PORT_C
		in al,dx
		cmp al,80h
		jz w1
		CALL DISPLAY
 		IRET
 		
		
	IN3:MOV   AL , 00
		MOV   DI , sec
		MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,80h
		jz w1
		mov si,form
		mov al,00
		Cmp [si],al
 		CALL DISPLAY
 		IRET
 		
		
	IN2:CALL   DEBOUNCE
		MOV   SI , sec
		MOV   AL , [SI]
		CMP   AL , 00
		JZ   IN4
		DEC   [si]
		mov dx,PORT_C
		in al,dx
		cmp al,80h
		jz w1
		CALL DISPLAY
 		IRET
 		
		
    IN4:MOV   AL , 59
		MOV   DI , sec
		MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,80h
		jz w1
		CALL DISPLAY
 		IRET
 		
		
min_set:mov dx,portA
     w2:IN AL ,dx
		and al,11h
		CMP AL,01h
		JZ IN5
		CMP AL,10h
		JZ   IN6
		jnz w2
		IRET
		
	IN5:CALL   DEBOUNCE
		MOV   SI , min
		MOV   AL , [SI]
		CMP   AL , 59
		JZ   IN7
		INC   [si]
		mov dx,PORT_C
		in al,dx
		cmp al,40h
		jz w2
		CALL DISPLAY
 		IRET
 		
		
   		
	IN7:MOV   AL , 00
		MOV   DI , min
		MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,40h
		jz w2
		CALL DISPLAY
 		IRET
 		
		
	IN6:CALL   DEBOUNCE
		MOV   SI , min
		MOV   AL , [SI]
		CMP   AL , 00
		JZ   IN8
		DEC  [si]
		mov dx,PORT_C
		in al,dx
		cmp al,40h
		jz w2
		CALL DISPLAY
 		IRET
 		
		
	IN8:MOV   AL , 59
		MOV   DI , min
		MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,40h
		jz w2
		CALL DISPLAY
 		IRET
 		
		
hr_set:mov dx,portA
     w3:IN AL ,dx
		and al,11h
		CMP AL,01h
        JZ   IN9
        CMP AL ,10h
        JZ   IN10
		jnz w3
		IRET
		
	IN9:mov si,form
		mov al,00
		Cmp [si],al				;incrementing hrs 
		JZ   IN9_24hr
		JMP   IN9_12hr
   IN10:mov si,form
		mov al,00
		Cmp [si],al					;decrementing hrs
		JZ   IN10_24hr
		JMP   IN10_12hr
IN9_24hr:CALL   DEBOUNCE
        MOV   SI ,  hr1			; incrementing hrs for 24 hr format
		MOV  AL , [SI]
		CMP   AL , 23
		JZ   IN11
		INC   [si]
		mov dx,PORT_C
		in al,dx
		cmp al,20h
		jz w3
		CALL DISPLAY
 		IRET
 		
		
   IN11:MOV   AL , 00
        MOV   DI , hr1
        MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,20h
		jz w3
        CALL DISPLAY
 		IRET
 		
		
IN9_12hr:CALL   DEBOUNCE
        MOV   SI ,  hr2			; incrementing hrs for 12 hr format
		MOV  AL , [SI]
		CMP   AL , 12
		JZ   IN12
		INC   [si]
		mov dx,PORT_C
		in al,dx
		cmp al,20h
		jz w3
		CALL DISPLAY
 		IRET
 		
		
   IN12:MOV   AL , 01
       	MOV   DI , hr2
      	MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,20h
		jz w3
       	CALL DISPLAY
 		IRET
 		
		
IN10_24hr:CALL   DEBOUNCE
        MOV   SI ,  hr1			; decrementing hrs for 24 hr format
		MOV  AL , [SI]
		CMP   AL , 00
		JZ   IN13
		DEC   [si]
		mov dx,PORT_C
		in al,dx
		cmp al,20h
		jz w3
		CALL DISPLAY
 		IRET
 		
		
	IN13:MOV   AL , 23
        MOV   DI , hr1
        MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,20h
		jz w3
        CALL DISPLAY
 		IRET
 		
		
IN10_12hr:CALL   DEBOUNCE
        MOV   SI ,  hr2			; decrementing hrs for 12 hr format
		MOV  AL , [SI]
		CMP   AL , 01
		JZ   IN14
		DEC   [si]
		mov dx,PORT_C
		in al,dx
		cmp al,20h
		jz w3
		CALL DISPLAY
 		IRET
 		
		
	IN14:MOV   AL , 12
        MOV   DI , hr2
        MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,20h
		jz w3
        CALL DISPLAY
 		IRET
 		
		
date_set:mov dx,portA
      w4:IN AL,dx
		and al,11h
        CMP al,01h
        JZ   IN15
        CMP AL,10h
        JZ IN16
		jnz w4
        IRET
		
   IN15:CALL   DEBOUNCE
        MOV   SI , date
        MOV   AL , [SI]
        CMP   AL , 31
        JZ   IN17
        INC   [si]
		mov dx,PORT_C
		in al,dx
		cmp al,10h
		jz w4
        CALL DISPLAY
 		IRET
 		
		
   	IN17:MOV   AL , 01
        MOV   DI , date
        MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,10h
		jz w4
        CALL DISPLAY
 		IRET
 		
		
   IN16:CALL   DEBOUNCE
        MOV   SI , date
        MOV   AL , [SI]
        CMP   AL , 01
        JZ   IN18
        DEC  [si]
		mov dx,PORT_C
		in al,dx
		cmp al,10h
		jz w4
        CALL DISPLAY
 		IRET
 			
		
IN18:	MOV   AL , 31
        MOV   DI , date
        MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,10h
		jz w4
        CALL DISPLAY
 		IRET
 		

month_set:mov dx,portA
      w5:IN AL,dx
		and al,11h
        CMP al,01h
        JZ   IN50
        CMP AL,10h
        JZ IN60
		jnz w5
        IRET
		
   IN50:CALL   DEBOUNCE
        MOV   SI ,month
        MOV   AL , [SI]
        CMP AL,12
        JZ   IN51
        INC   [si]
		mov dx,PORT_C
		in al,dx
		cmp al,08h
		jz w5
        CALL DISPLAY
 		IRET
 		
		
   	IN51:MOV AL , 01
        MOV DI,month
        MOV [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,08h
		jz w5
        CALL DISPLAY
 		IRET
 		
   IN60:CALL DEBOUNCE
        MOV SI,month
        MOV AL,[SI]
        CMP AL , 01
        JZ IN61
        DEC  [si]
		mov dx,PORT_C
		in al,dx
		cmp al,08h
		jz w5
        CALL DISPLAY
 		IRET
 			
		
IN61:	MOV   AL , 12
        MOV   DI ,month
        MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,08h
		jz w5
        CALL DISPLAY
 		IRET
 		
		
year_set:mov dx,portA
     w6:IN al,dx
		and al,11h
		CMP AL,01h
        JZ   IN19
        CMP AL,10h
        JZ   IN20
		jnz w5
        IRET
		
   IN19:CALL DEBOUNCE
        mov si,year
        INC   [si]
		mov dx,PORT_C
		in al,dx
		cmp al,04h
		jz w6
        CALL DISPLAY
 		IRET
 		
		
   IN20:CALL DEBOUNCE
        mov si,year
        DEC [si]
		mov dx,PORT_C
		in al,dx
		cmp al,04h
		jz w6
        CALL DISPLAY
 		IRET
 		
        		
alarm_min_set:mov dx,portA
     w7:IN AL,dx
	    and al,11h
        CMP AL,01h
        JZ   IN21
        CMP   AL ,10h
        JZ   IN22
		jnz w7
        IRET
		
   IN21:CALL   DEBOUNCE
        MOV   SI , alarmmin
        MOV   AL , [SI]
        CMP   AL , 59
        JZ   IN23
        INC   [si]
		mov dx,PORT_C
		in al,dx
		cmp al,01h
		jz w7
        jmp alarmdisplay
		
   IN23:MOV   AL , 00
        MOV   DI ,alarmmin
        MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,01h
		jz w7
        jmp alarmdisplay
		
   IN22:CALL   DEBOUNCE
        MOV   SI , alarmmin
        MOV   AL , [SI]
        CMP   AL , 00
        JZ   IN24
        DEC  [si]
		mov dx,PORT_C
		in al,dx
		cmp al,01h
		jz w7
        jmp   alarmdisplay
		
   IN24:MOV   AL , 59
        MOV   DI , alarmmin
        MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,01h
		jz w7
        jmp alarmdisplay
		
alarm_hr_set:mov dx,portA
     w8:IN   AL , PORT_C
	    and al,11h
        CMP   AL , 01h
        JZ   IN25
        CMP   AL ,10h
        JZ   IN26
		jnz w8
		IRET
		
   IN25:mov si,form
		mov al,00
		Cmp [si],al			;incrementing hrs 
		JZ IN9_24hr_al
		JMP IN9_12hr_al
		
	IN26:mov si,form
		mov al,00
		Cmp [si],al					;decrementing hrs
		JZ IN10_24hr
		JMP IN10_12hr
		
IN9_24hr_al:CALL DEBOUNCE
        MOV SI,alarmhr1			; incrementing hrs for 24 hr format
		MOV  AL , [SI]
		CMP   AL , 23
		JZ   IN27
		INC  [si]
		mov dx,PORT_C
		in al,dx
		cmp al,02h
		jz w8
		jmp alarmdisplay
		
	IN27:MOV AL , 00
        MOV   DI , alarmhr1
        MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,02h
		jz w8
        jmp alarmdisplay
     	
IN9_12hr_al:CALL   DEBOUNCE
        MOV SI,alarmhr2			; incrementing hrs for 12 hr format
		MOV  AL , [SI]
		CMP   AL , 12
		JZ   IN28
		INC [si]
		mov dx,PORT_C
		in al,dx
		cmp al,02h
		jz w8
		jmp alarmdisplay
			
   IN28:MOV   AL , 01
        MOV   DI , alarmhr2
        MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,02h
		jz w8
        Jmp alarmdisplay
			
IN10_24hr_al:CALL DEBOUNCE
        MOV SI,alarmhr1		; decrementing hrs for 24 hr format
		MOV  AL , [SI]
		CMP   AL , 00	
		JZ   IN29
		DEC   [si]
		mov dx,PORT_C
		in al,dx
		cmp al,02h
		jz w8
		Jmp alarmdisplay
		
   IN29:MOV   AL , 23
        MOV   DI , alarmhr1
        MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,02h
		jz w8
        jmp alarmdisplay
		
IN10_12hr_al:CALL DEBOUNCE
        MOV SI,alarmhr2		; decrementing hrs for 12 hr format
		MOV  AL , [SI]
		CMP   AL , 01
		JZ   IN30
		DEC   [si]
		mov dx,PORT_C
		in al,dx
		cmp al,02h
		jz w8
		Jmp alarmdisplay
		
   IN30:MOV   AL , 12
        MOV   DI ,alarmhr2
        MOV   [DI] , AL
		mov dx,PORT_C
		in al,dx
		cmp al,02h
		jz w8
        Jmp alarmdisplay
		
Alarmdisplay:MOV SI,alarmhr1                                                   	
        MOV   AX , [SI]
  		MOV   Bl , 10
        DIV   Bl
        ADD   AL , 30H
        ADD   AH , 30H
        MOV   BL , AL
        CALL  WRITE
        MOV   BL,AH
        CALL  WRITE
        MOV   BL , 3AH 	                                                           	
        CALL  WRITE
        MOV   SI , alarmmin                                                  	
        MOV   AX , [SI]
        MOV   Bl , 10
        DIV   Bl
        ADD   AL , 30H
        ADD   AH , 30H
        MOV   BL , AL
        CALL  WRITE
        MOV   BL , AH
        CALL  WRITE
        Jmp t_set		






           

