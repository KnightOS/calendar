;; monthView
;;   Displays the month view.
monthView:
    
    kcall(normalizeSelectedDate)
    
    pcall(clearBuffer)
    
    kld(hl, window_title)
    ld a, 0b0100 ; draw the menu graphic
    corelib(drawWindow)
    
    ; draw the month name
    ld de, 0x4001
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
    kld(hl, (selected_year))
    pcall(monthLength)
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
    kjp(monthView)
_:  cp kLeft
    jr nz, +_
    kld(a, (selected_day))
    dec a
    kld((selected_day), a)
    kjp(monthView)
_:  cp kUp
    jr nz, +_
    kld(a, (selected_day))
    sub a, 7
    kld((selected_day), a)
    kjp(monthView)
_:  cp kDown
    jr nz, +_
    kld(a, (selected_day))
    add a, 7
    kld((selected_day), a)
    kjp(monthView)
_:  
    
    ; F2, F4 (previous / next year)
    cp kF2
    jr nz, .no_f2
    kld(a, (selected_day))
    ld d, a
    kld(a, (selected_month))
    ld e, a
    kld(hl, (selected_year))
    dec hl
    kcall(updateMonthData)
    kld((selected_year), hl)
    kjp(monthView)
.no_f2:
    
    cp kF4
    jr nz, .no_f4
    kld(a, (selected_day))
    ld d, a
    kld(a, (selected_month))
    ld e, a
    kld(hl, (selected_year))
    inc hl
    kcall(updateMonthData)
    kld((selected_year), hl)
    kjp(monthView)
.no_f4:
    
    ; F3 (show menu)
    cp kF3
    jr nz, .no_f3
    kld(hl, menu_monthview)
    ld c, 40
    corelib(showMenu)
    pcall(flushKeys)
    
    ; option 0: quit
    cp 0
    jr nz, +_
    ret
_:
    ; no option chosen
    kjp(monthView)
.no_f3:
    
    ; Enter (day view)
    cp kEnter
    jr nz, .no_enter
    kjp(dayView)
.no_enter:
    
    ; MODE (quit)
    cp kMode
    jr nz, +_
    ret
_:  
    kjp(.waitForKey)


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
