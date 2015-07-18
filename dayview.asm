;; dayView
;;   Displays the day view.
dayView:
    
    kcall(normalizeSelectedDate)
    
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
    
.drawAppointments:
    kld(hl, no_appointments)
    ld de, 0x0208
    pcall(drawStr)
    
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
    kjp(dayView)
_:  cp kLeft
    jr nz, +_
    kld(a, (selected_day))
    dec a
    kld((selected_day), a)
    kjp(dayView)
_:  
    
    ; F3 (show menu)
    cp kF3
    jr nz, .no_f3
    kld(hl, menu_dayview)
    ld c, 70
    corelib(showMenu)
    pcall(flushKeys)
    
    ; option 0: new appointment
    cp 0
    jr nz, +_
    kld(hl, appointments_not_supported_message)
    kld(de, appointments_not_supported_options)
    ld a, 0
    ld b, 0
    corelib(showMessage)
    kjp(dayView)
_:  
    ; option 1: back to month view
    cp 1
    jr nz, +_
    kjp(monthView)
_:  
    ; option 2: quit
    cp 2
    jr nz, +_
    ret
_:  
    ; no option chosen
    kjp(dayView)
.no_f3:
    
    ; MODE (quit)
    cp kMode
    jr nz, +_
    ret
_:  
    kjp(.waitForKey)

; strings
no_appointments:
    .db "No appointments.", 0
appointments_not_supported_message:
    .db "Creating ap-\npointments is\nnot supported.", 0
appointments_not_supported_options:
    .db 1
    .db "Dismiss", 0
