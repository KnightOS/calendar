#include "kernel.inc"
#include "corelib.inc"

    .db "KEXC"
    .db KEXC_ENTRY_POINT
    .dw start
    .db KEXC_STACK_SIZE
    .dw 20
    .db KEXC_NAME
    .dw name
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
    ;                             A   IX  L  H  B  C  H
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


;; drawCalendar
;;   Draws the calendar of the given month.
;; Inputs:
;;    B: day of the week of the first day (0-6); alternatively, the number of
;;       grid cells to leave blank in the beginning of the month
;;    E: number of days in the month
;; Destroys:
;;    everything
drawCalendar:
    
    ; first figure out if we need a 5-row or a 6-row grid
    ; 6-row grid iff a + e >= 36
    ld a, b
    add a, e
    cp 36
    jr nc, +_
    ; 5-row grid
    ld l, 12 ; y-coordinate of top of vertical lines
    ld c, 39 ; height of vertical lines
    jr ++_
_:  ; 6-row grid
    ld l, 8
    ld c, 47
_:
    ; draw vertical lines
    ld a, 23
    
.verticalLineLoop:
    pcall(drawVLine)
    add a, 10
    cp 74
    jr c, .verticalLineLoop
    
    ; draw horizontal lines
    ; (save l, since we need it later for the text)
    push hl
        
        ld a, l
        add a, 7
        ld l, a
      
.horizontalLineLoop:
        ; TODO rewrite this if/when a kernel function drawHLine is available
        ld a, 8
        
        push hl
            pcall(getPixel)
            ld (hl), 0b00000011
            inc hl \ ld (hl), 0xff
            inc hl \ ld (hl), 0xff
            inc hl \ ld (hl), 0xff
            inc hl \ ld (hl), 0xff
            inc hl \ ld (hl), 0xff
            inc hl \ ld (hl), 0xff
            inc hl \ ld (hl), 0xff
            inc hl \ ld (hl), 0xff
            inc hl \ ld (hl), 0b11100000
        pop hl
        
        ld a, l
        add a, 8
        ld l, a
        cp 48
        jr c, .horizontalLineLoop
    
    pop hl
    
    ; draw the labels
    ; x-position of the first one is 10 b + 15
    xor a
    add a, b     ;  1 b
    add a, a     ;  2 b
    add a, a     ;  4 b
    add a, b     ;  5 b
    add a, a     ; 10 b
    add a, 15    ; 10 b + 15
    ld d, a
    
    ; rescue e (number of days in the month)
    ld h, e
    inc h
    
    ; y-coordinate of the first label
    ld e, l
    inc e
    
    ld a, 1
    
.labelLoop:
    push af \ push de \ push bc
        
        ; draw the number
        push af \ push de
            kcall(drawDecAPadded)
        pop de \ pop af
        
        ; if this is the selected day, invert colors
        ld b, a
        kld(a, (selected_day))
        inc a  ; selected_day is 0-based
        cp b
        jr nz, .notSelected
        push bc \ push hl
            ld l, e
            dec l
            ld e, d
            dec e
            ld c, 9
            ld b, 7
            pcall(rectXOR)
        pop hl \ pop bc
.notSelected:
        ld a, b
    pop bc \ pop de \ pop af
    
    push af
        ld a, d
        add a, 10
        
        ; if x-coordinate > 75, we need to move to the next line
        cp 76
        jr c, .notToNextLine
        
        ld a, 15
        push af
            ld a, e
            add a, 8
            ld e, a
        pop af
        
.notToNextLine:
        ld d, a
    pop af
    
    inc a
    cp h
    jr c, .labelLoop
    
    ret


;; weekdayYearStart
;;   Computes the weekday of 1 January of a given year in the Gregorian
;;   calendar. Also checks whether the year is a leap year or not.
;; Inputs:
;;   HL: the year
;; Outputs:
;;    B: the weekday (0-6, 0 = Sunday, 6 = Saturday) of 1 January of the year
;;    C: indicates whether the year is a leap year or not (1 if leap; 0 if
;;       non-leap)
;; Destroys:
;;   A
;; Notes:
;;   This uses a formula proposed by Gauss. See
;;   http://en.wikipedia.org/wiki/Determination_of_the_day_of_the_week#Gauss.27_algorithm
;;   Interleaved with this calculation, it is determined whether we are dealing
;;   with a leap year or not.
weekdayYearStart:
    push de \ push hl
        
        ; c will be zero if it is a leap year; non-zero otherwise
        ld c, 0
        
        dec hl
        
        ; (1 + 5 (hl % 4) + 4 (hl % 100) + 6 (hl % 400)) % 7
        
        ; 6 (hl % 400)
        ld de, -400
_:      add hl, de
        jr c, -_
        ld de, 400
        add hl, de
        
        ; if hl = 399, the year was divisible by 400, so increase c
        ld a, h
        cp 1
        jr nz, +_
        ld a, l
        cp 399-256
        jr nz, +_
        inc c
_:      
        push hl
            ld d, h
            ld e, l
            add hl, hl ; 2x
            add hl, de ; 3x
            add hl, hl ; 6x
            push bc
                ld c, 7
                pcall(divHLByC)
            pop bc
            ld b, a ; store intermediate result in b
        pop hl
        
        ; 4 (hl % 100)
        ld de, -100
_:      add hl, de
        jr c, -_
        ld de, 100
        add hl, de
        
        ; if hl = 99, the year was divisible by 100, so decrease c
        ld a, h
        cp 0
        jr nz, +_
        ld a, l
        cp 99
        jr nz, +_
        dec c
_:      
        push hl
            add hl, hl ; 2x
            add hl, hl ; 4x
            push bc
                ld c, 7
                pcall(divHLByC)
            pop bc
            add a, b
            ld b, a
        pop hl
        
        ; 5 (hl % 4)
        ld a, l
        and 0b00000011
        ; if a = 3, the year was divisible by 4, so increase c
        cp 3
        jr nz, +_
        inc c
_:      
        ld l, a
        add a, a ; 2x
        add a, a ; 4x
        add a, l ; 5x
        add a, b
        
        ; the +1, and divide by 7
        inc a
_:      sub a, 7
        jr nc, -_
        add a, 7
        
        ld b, a
        
    pop hl \ pop de
    
    ret


;; weekdayMonthStart
;;   Computes the weekday of 1 January of a given year in the Gregorian
;;   calendar. Also checks whether the year is a leap year or not.
;; Inputs:
;;   HL: the year
;;    E: the month
;; Outputs:
;;    B: the weekday (0-6, 0 = Sunday, 6 = Saturday) of 1 January of the year
;;    C: indicates whether the year is a leap year or not (1 if leap; 0 if
;;       non-leap)
;; Destroys:
;;   A
;; Notes:
;;   This simply uses [weekdayYearStart], plus some offsets for the months.
weekdayMonthStart:
    kcall(weekdayYearStart)
    
    push hl \ push de
        ld a, c
        cp 0
        jr z, +_
        kld(hl, month_start_weekday_leap)
        jr ++_
_:      kld(hl, month_start_weekday_non_leap)
_:      ld d, 0
        add hl, de
        ld a, (hl)
        add a, b
        cp 7
        jr c, +_
        sub a, 7
_:      ld b, a
    pop de \ pop hl
    
    ret


; Draws A (assumed < 100) as a decimal number, padded with leading whitespace
; if it is < 10.
drawDecAPadded:
    
    cp 10
    jr nc, .noPadding
    
    ; do padding
    push af
        ld a, d
        add a, 4
        ld d, a
    pop af

.noPadding:
    pcall(drawDecA)
    ret


; Draws A (assumed < 100) as a decimal number, padded with a single zero ('0')
; if it is < 10.
drawDecAPaddedZero:
    
    cp 10
    jr nc, .noPadding
    
    ; do padding
    push af
        ld a, '0'
        pcall(drawChar)
    pop af

.noPadding:
    pcall(drawDecA)
    ret


;; drawYear
;;   Draws the number of the current year.
;; Inputs:
;;   HL: the year
;;    D: the x-position
;;    E: the y-position
drawYear:
    
    ld c, 100
    pcall(divHLByC)
    
    ld h, a
    ld a, l
    kcall(drawDecAPadded)
    ld a, h
    kcall(drawDecAPaddedZero)
    
    ret


; Normalizes the variables containing the selected date, and also updates
; selected_month_length, start_weekday and is_leap_year. That is, this
; subroutine for example changes "0 January 1997" to "31 December 1996".
; This should be called after every cursor movement.
normalizeSelectedDate:
    
    kld(a, (selected_day))
    ld d, a
    kld(a, (selected_month))
    ld e, a
    kld(hl, (selected_year))
    
    kld(a, (selected_month_length))
    ld b, a
    
    ; correct underflowed day
    ld a, d
    cp 128
    jr c, +_
    kcall(toPreviousMonth)
    jr .done
_:  
    ; correct overflowed day
    ld a, d
    cp b
    jr c, +_
    kcall(toNextMonth)
_:  
    
.done:
    ld a, d
    kld((selected_day), a)
    ld a, e
    kld((selected_month), a)
    kld((selected_year), hl)
    ret


;; toPreviousMonth
;;   Decreases selected_month and updates selected_month_length, start_weekday
;;   and is_leap_year.
;; Inputs:
;;    D: the day (0-30)
;;    E: the month (0-11)
;;   HL: the year
;; Outputs:
;;    D: updated day
;;    E: updated month
;;   HL: updated year
;; Destroys:
;;   A
toPreviousMonth:
    
    ; decrease the month
    dec e
    
    ; if the month is < 0, go to the previous year
    ld a, e
    cp 128
    jr c, +_
    add a, 12
    ld e, a
    dec hl
_:  
    ; update selected_month_length, start_weekday, is_leap_year
    kcall(updateMonthData)
    
    ; update the selected day
    kld(a, (selected_month_length))
    add a, d
    ld d, a
    
    ret


;; toNextMonth
;;   Increases selected_month and updates selected_month_length, start_weekday
;;   and is_leap_year.
;; Inputs:
;;    D: the day (0-30)
;;    E: the month (0-11)
;;   HL: the year
;; Outputs:
;;    D: updated day
;;    E: updated month
;;   HL: updated year
;; Destroys:
;;   A
toNextMonth:
    
    ; increase the month
    inc e
    
    ; update the selected day
    kld(a, (selected_month_length))
    sub a, d
    neg
    ld d, a
    
    ; if the month is >= 12, go to the next year
    ld a, e
    cp 12
    jr c, +_
    sub a, 12
    ld e, a
    inc hl
_:  
    ; update selected_month_length, start_weekday, is_leap_year
    kcall(updateMonthData)
    
    ret


;; updateMonthData
;;   Updates selected_month_length, start_weekday and is_leap_year.
;; Inputs:
;;    D: the day (0-30)
;;    E: the month (0-11)
;;   HL: the year
;; Outputs:
;;    D: updated day
;;    E: updated month
;;   HL: updated year
;; Destroys:
;;   A
updateMonthData:
    kcall(monthLength)
    kld((selected_month_length), a)
    
    push bc
        kcall(weekdayMonthStart)
        ld a, b
        kld((start_weekday), a)
        ld a, c
        kld((is_leap_year), a)
    pop bc
    
    ret


;; monthLength
;;   Determines the number of days in the given month.
;; Inputs:
;;    E: the month (0-11)
;;    A: indicates whether the year is a leap year or not (1 if leap; 0 if
;;       non-leap)
;; Outputs:
;;    A: the length of the month
monthLength:
    push hl \ push bc
        cp 1
        jr z, +_
        kld(hl, month_length_non_leap)
        jr ++_
    _:  kld(hl, month_length_leap)
    _:  ld a, e
        ld b, 0
        ld c, a
        add hl, bc
        ld a, (hl)
    pop bc \ pop hl
    ret


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
