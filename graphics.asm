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
