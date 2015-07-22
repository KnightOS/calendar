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
    
    kcall(drawAppointments)
    
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
    kld(de, only_dismiss_option)
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


;; findAppointments
;;   Finds all appointments of the current day. This method allocates space for
;;   the list. It is the caller's responsibility to call the function free on
;;   the list when it is not needed anymore. If the malloc call fails due to an
;;   out-of-memory condition, a message is shown and B is set to zero.
;; Outputs:
;;    B: The number of appointments
;;   IX: Address of the first byte of the list of appointments. The list
;;       contains addresses of appointment data structures
findAppointments:
    
    ; idea:
    ; 1. figure out how many appointments there are
    ; 2. allocate memory for that amount of appointments
    ; 3. fill the list
    ld c, 0
    kld(hl, appointment_data)
    ld a, (hl)
    ld b, a
    inc hl
    
.findLoop:
    ; TODO if appointment is of today, increase c
    ld a, (hl)
    ld e, a
    kld(a, (selected_year))
    cp e
    jr nz, .notToday
    
    inc hl
    ld a, (hl)
    ld e, a
    kld(a, (selected_year + 1))
    cp e
    jr nz, .notToday
    
    
    
.notToday:
    add hl, 70 ; size of an appointment data structure
    djnz .findLoop
    
    ; multiply bc by 2, since addresses take 2 bytes
    ex hl, bc
    add hl, hl
    ex hl, bc
    pcall(malloc)
    jr z, .noFailure
    ld b, 0
    kld(hl, out_of_memory_message)
    kld(de, only_dismiss_option)
    ld a, 0
    ld b, 0
    corelib(showMessage)
    ret
    
.noFailure:
    ; TODO put appointments in list
    ret




;     kld(hl, no_appointments)
;     ld de, 0x0208
;     pcall(drawStr)
;     ret

; strings
no_appointments:
    .db "No appointments.", 0
appointments_not_supported_message:
    .db "Creating ap-\npointments is\nnot supported.", 0
out_of_memory_message:
    .db "Out of memory!\nClose other\nprograms...", 0
only_dismiss_option:
    .db 1
    .db "Dismiss", 0
