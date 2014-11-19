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
