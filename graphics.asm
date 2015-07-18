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
