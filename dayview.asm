;; dayView
;;   Displays the day view.
dayView:
    
    pcall(clearBuffer)
    
    kld(hl, window_title)
    ld a, 0b0100 ; draw the menu graphic
    corelib(drawWindow)
    
    ; draw the day
    ld e, 0x34
    ld l, 0
    ld c, 8
    ld b, 8
    pcall(rectXOR)
    
    ld de, 0x3401
    kld(a, (selected_day))
    inc a ; days are zero-based
    kcall(drawDecAPadded)
    
    ld e, 0x34
    ld l, 0
    ld c, 8
    ld b, 8
    pcall(rectXOR)
    
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
    
.waitForKey:
    ; update the screen
    pcall(fastCopy)
    
    ; wait for a key
    corelib(appWaitKey)
    pcall(flushKeys)
    
    kjp(monthView)