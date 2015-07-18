monthView:
    pcall(clearBuffer)
    
    kld(hl, window_title)
    ld a, 0b0100 ; draw the menu graphic
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
    kcall(monthLength2)
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
    kld(hl, menu_main)
    ld c, 70
    corelib(showMenu)
    
    ; option 0: quit
    cp 0
    jr nz, +_
    ret
_:
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
