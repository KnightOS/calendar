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
    
    ; get the current time as in Tue 2014-11-11 15:04:32
    ;                             A   IX  L  H  B  C  D
    pcall(getTime)
    
    ; to test the code path for calculators with no clocks:
    ; ld a, errUnsupported
    cp errUnsupported
    kjp(z, unsupported)
    
    kld((selected_year), ix)
    ld a, l
    kld((selected_month), a)
    ld a, h
    kld((selected_day), a)
    
    ; determine the weekday the month starts with
    kcall(updateMonthData)

.drawEverything:
    pcall(clearBuffer)
    
    kld(hl, window_title)
    xor a
    corelib(drawWindow)
    
    kcall(normalizeSelectedDate)
    
    ; draw the month name
    ld de, 0x4101
    kld(hl, month_names)
    kld(a, (selected_month))
    add a, a ; 2x
    add a, a ; 4x
    ld b, 0
    ld c, a
    add hl, bc
    pcall(drawStrXOR)
    
    ; draw the year
    ld e, 0x4f
    ld l, 0
    ld c, 16
    ld b, 8
    pcall(rectXOR)
    
    ld de, 0x4f01
    kld(hl, (selected_year))
    kcall(drawYear)
    
    ld e, 0x4f
    ld l, 0
    ld c, 16
    ld b, 8
    pcall(rectXOR)
    
    ; determine the length of the month
    kld(a, (selected_month))
    ld e, a
    kld(a, (is_leap_year))
    kcall(monthLength)
    kld((selected_month_length), a)
    ld e, a
    
    ; draw the actual calendar
    kld(a, (start_weekday))
    ld b, a
    
    ; TODO dec b if the user wants Monday to be the first day of the week
    
    kld(a, (is_leap_year))
    ld c, a
    
    kcall(drawCalendar)

.waitForKey:
    ; update the screen
    pcall(fastCopy)
    
    ; wait for a key
    corelib(appWaitKey)
    pcall(flushKeys)
    
    ; arrow keys (move selected day)
    cp kRight
    jr nz, +_
    kld(a, (selected_day))
    inc a
    kld((selected_day), a)
    kjp(.drawEverything)
_:  cp kLeft
    jr nz, +_
    kld(a, (selected_day))
    dec a
    kld((selected_day), a)
    kjp(.drawEverything)
_:  cp kUp
    jr nz, +_
    kld(a, (selected_day))
    sub a, 7
    kld((selected_day), a)
    kjp(.drawEverything)
_:  cp kDown
    jr nz, +_
    kld(a, (selected_day))
    add a, 7
    kld((selected_day), a)
    kjp(.drawEverything)
_:  
    ; F2, F4 (previous / next year)
    cp kF2
    jr nz, +_
    kld(a, (selected_day))
    ld d, a
    kld(a, (selected_month))
    ld e, a
    kld(hl, (selected_year))
    dec hl
    kcall(updateMonthData)
    kld((selected_year), hl)
    kjp(.drawEverything)
_:  
    cp kF4
    jr nz, +_
    kld(a, (selected_day))
    ld d, a
    kld(a, (selected_month))
    ld e, a
    kld(hl, (selected_year))
    inc hl
    kcall(updateMonthData)
    kld((selected_year), hl)
    kjp(.drawEverything)
_:  
    ; MODE (quit)
    cp kMode
    jr nz, +_
    ret
_:  
    kjp(.waitForKey)


unsupported:
    
    kld(hl, window_title)
    xor a
    corelib(drawWindow)
    
    kld(hl, clock_unsupported_message)
    kld(de, clock_unsupported_options)
    ld a, 0
    ld b, 0
    corelib(showMessage)
    
    ret


#include "graphics.asm"
#include "dates.asm"


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

clock_unsupported_message:
    .db "Clock isn't sup-\nported on this\ncalculator.", 0
clock_unsupported_options:
    .db 1
    .db "Quit program", 0

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
