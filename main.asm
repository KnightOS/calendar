#include "kernel.inc"
#include "corelib.inc"

    .db "KEXC"
    .db KEXC_ENTRY_POINT
    .dw start
    .db KEXC_STACK_SIZE
    .dw 20
    .db KEXC_NAME
    .dw window_title
    .db KEXC_DESCRIPTION
    .dw description
    .db KEXC_HEADER_END

name:
    .db "calendar", 0
description:
    .db "An application to view a calendar", 0

start:
    kld(de, corelib_path)
    pcall(loadLibrary)
    
    pcall(getLcdLock)
    pcall(getKeypadLock)
    
    pcall(allocScreenBuffer)
    
    ; if the RTC is supported, use that time as the default,
    ; otherwise default to 2015-01-01 00:00
    pcall(clockSupported)
    ; to test the code path for calculators with no clocks:
    ; jr .notSupported
    jr nz, .notSupported
    
    ; get the current time as in Tue 2014-11-11 15:04:32
    ;                             A   IX  L  H  B  C  D
    pcall(getTime)
    jr .setTimeVariables
    
.notSupported:
    ld ix, 2015
    ld hl, 0
    
.setTimeVariables:
    kld((selected_year), ix)
    ld a, l
    kld((selected_month), a)
    ld a, h
    kld((selected_day), a)
    
    ; determine the weekday the month starts with
    kcall(updateMonthData)
    
    ; and start with the month view
    kjp(monthView)


#include "graphics.asm"
#include "dates.asm"
#include "monthview.asm"
#include "dayview.asm"


; variables
selected_year:
    .db 0, 0
selected_month:
    .db 0
selected_day:
    .db 0
start_weekday:
    .db 0
is_leap_year:
    .db 0
selected_month_length:
    .db 0

; strings

window_title:
    .db "Calendar", 0
corelib_path:
    .db "/lib/core", 0

; lengths of the months
month_length_non_leap:
    .db 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
month_length_leap:
    .db 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31

; weekday data for the months: this contains the weekday that starts a month in
; a year that starts on a Sunday (0)
month_start_weekday_non_leap:
    .db 0, 3, 3, 6, 1, 4, 6, 2, 5, 0, 3, 5
month_start_weekday_leap:
    .db 0, 3, 4, 0, 2, 5, 0, 3, 6, 1, 4, 6

; names of the months
month_names:
    .db "Jan", 0
    .db "Feb", 0
    .db "Mar", 0
    .db "Apr", 0
    .db "May", 0
    .db "Jun", 0
    .db "Jul", 0
    .db "Aug", 0
    .db "Sep", 0
    .db "Oct", 0
    .db "Nov", 0
    .db "Dec", 0

; menu strings
menu_monthview:
    .db 1
    .db "Quit", 0
menu_dayview:
    .db 3
    .db "New appointment", 0
    .db "Month view", 0
    .db "Quit", 0

; appointment data
; TODO this is temporary until reading from the file system is implemented
appointment_data:
    .db 3 ; number of appointments
    
    ; appointment 1
    .dw 1997 ; year
    .db 0    ; month
    .db 0    ; day
    .db 14   ; hour
    .db 15   ; minute
    .db "Dentist", 0 \ .block 32 - 8 ; description
    .db "42 Random St, Los Angeles", 0 \ .block 32 - 26 ; place
    
    ; appointment 2
    .dw 1997 ; year
    .db 0    ; month
    .db 0    ; day
    .db 12   ; hour
    .db 00   ; minute
    .db "Business presentation", 0 \ .block 32 - 22 ; description
    .db "Main Building room 3.14", 0 \ .block 32 - 24 ; place
    
    ; appointment 3
    .dw 1997 ; year
    .db 0    ; month
    .db 2    ; day
    .db 16   ; hour
    .db 00   ; minute
    .db "Team meeting", 0 \ .block 32 - 13 ; description
    .db "Main Building room 1.17", 0 \ .block 32 - 24 ; place
