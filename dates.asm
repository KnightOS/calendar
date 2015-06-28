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
    push bc
        kcall(weekdayMonthStart)
        ld a, b
        kld((start_weekday), a)
        ld a, c
        kld((is_leap_year), a)
        
        kcall(monthLength2)
        kld((selected_month_length), a)
    pop bc
    
    ret


;; monthLength2
;;   Determines the number of days in the given month.
;; Inputs:
;;    E: the month (0-11)
;;    A: indicates whether the year is a leap year or not (1 if leap; 0 if
;;       non-leap)
;; Outputs:
;;    A: the length of the month
monthLength2:
    push hl \ push bc
        cp 1
        jr z, +_
        kld(hl, month_length_non_leap)
        jr ++_
    _:  kld(hl, month_length_leap)
    _:  ld b, 0
        ld c, e
        add hl, bc
        ld a, (hl)
    pop bc \ pop hl
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