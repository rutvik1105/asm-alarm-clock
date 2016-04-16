;
; START of Data Declaration
;
time_format db 00; 00 = 24 hour format
time_suffix db 00; 00 = HR, 01 = AM, 02 = PM
time_second db 00
time_minute db 00
time_hour db 12
time_day db 01; Day 01 = 1st of Month X ...
time_month db 00; Month 00 = January ...
time_year db 00
db ?; An Overflow Byte. Refer to Macro "tinc".

alarm_hour db 07
alarm_minute db 00
alarm_switch db 00
alarm db 00

;Definitions
TRUE equ 01
FALSE equ 00
ON equ 01
OFF equ 00
FEB equ 01
APR equ 02
JUN equ 05
SEP equ 08
NOV equ 10
HR24 equ 00
HR12 equ 01
HR equ 00
AM equ 01
PM equ 02
;
; END of Data Declaration
;

;
;	START of Second Tick - Interupt Service Routine
;
;Turn OFF the alarm if it IS ON AND alarm_switch is OFF
; ijmp x,y,z :: if x is y, jump to z
ijne alarm, ON, alarm_no_change
ijne alarm_switch, OFF, alarm_no_change
mov alarm,OFF
;TODO: out OFF at the Piezo electric buzzer.
alarm_no_change:
;Behold the Power of Macros
; tinc x, y :: if x>=y, increment the value at address following x.
tinc time_second, 60
tinc time_minute, 60
tinc time_hour, 24
;Alarm
ijne alarm_switch, ON, no_alarm
ijne alarm_hour, time_hour, no_alarm
ijne alarm_minute, time_minute, no_alarm
mov alarm, ON
;TODO: out ON at the Piezo electric buzzer.
no_alarm:
;Check Day Counter w.r.t. Month and Leap Year Here
ijne time_month, FEB, not_feb
push time_year
and time_year, 03
ijne time_year, 00, not_leap
pop time_year
tinc time_day,29
jmp day_end
;check if leap year or not 
not_leap:
pop time_year
tinc time_day,28
jmp day_end
;check if 30 days months
not_feb:
ijne time_month, APR, month_31
ijne time_month, JUN, month_31
ijne time_month, SEP, month_31
ijne time_month, NOV, month_31
tinc time_day,30
jmp day_end
;incrementing the 31 day months 
month_31:
tinc time_day,31
;incrementing the month and year
day_end:
tinc time_month, 12
tinc time_year, 100
;
;	END of Second Tick - Interrupt Service Routine
;

;
;	START of Increment Button - Interupt Service Routine
;
; TODO: Analyse State and Increment That
binc time_second, 60
binc time_minute, 60
binc time_hour, 24
;Check Day Counter w.r.t. Month and Leap Year Here
ijne time_month, FEB, inc_not_feb
push time_year
and time_year, 03
ijne time_year, 00, inc_not_leap
pop time_year
binc time_day,29
jmp inc_day_end
;check if leap year or not 
inc_not_leap:
pop time_year
binc time_day,28
jmp inc_day_end
;check if 30 days months
inc_not_feb:
ijne time_month, APR, inc_month_31
ijne time_month, JUN, inc_month_31
ijne time_month, SEP, inc_month_31
ijne time_month, NOV, inc_month_31
binc time_day,30
jmp inc_day_end
;incrementing the 31 day months 
inc_month_31:
binc time_day,31
;incrementing the month and year
inc_day_end:
binc time_month, 12
binc time_year, 100
;
;	END of Increment Button - Interrupt Service Routine
;

;
;	START of Decrement Button - Interupt Service Routine
;
; TODO: Analyse State and Decrement That
bdec time_second, 59
bdec time_minute, 59
bdec time_hour, 23
;Check Day Counter w.r.t. Month and Leap Year Here
ijne time_day, 0ffh, dec_day_end
ijne time_month, FEB, dec_not_feb
push time_year
and time_year, 03
ijne time_year, 00, dec_not_leap
pop time_year
mov time_day,28
jmp dec_day_end
;check if leap year or not 
dec_not_leap:
pop time_year
mov time_day,27
jmp dec_day_end
;check if 30 days months
dec_not_feb:
ijne time_month, APR, dec_month_31
ijne time_month, JUN, dec_month_31
ijne time_month, SEP, dec_month_31
ijne time_month, NOV, dec_month_31
mov time_day,29
jmp dec_day_end
;incrementing the 31 day months 
dec_month_31:
mov time_day,30
;incrementing the month and year
dec_day_end:
bdec time_month, 11
bdec time_year, 99
;
;	END of Decrement Button - Interupt Service Routine
;

;
;Macro Definitions
;
ijne	macro var, state, jt
			cmp var, state
			jne jt
		endm
tinc 	macro var, limit
			local pass
			;For "local" directive, refer to : https://courses.engr.illinois.edu/ece390/books/artofasm/CH08/CH08-7.html#HEADING7-248
			cmp var, limit
			jl pass
			mov var, 00
			;push di
			lea di, var
			inc di
			inc [di]
			;pop di
		pass:
		endm
binc 	macro var, limit
			local pass
			cmp var, limit
			jl pass
			mov var, 00
		pass:
		endm
bdec 	macro var, limit
			local pass
			cmp var, 0ffh
			jle pass
			mov var, limit
		pass:
		endm