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
    
    ; Get a lock on the devices we intend to use
    pcall(getLcdLock)
    pcall(getKeypadLock)
    
    ; Allocate and clear a buffer to store the contents of the screen
    pcall(allocScreenBuffer)


.loop:
    pcall(clearBuffer)
    
    kld(hl, window_title)
    xor a
    corelib(drawWindow)
    
    ; get the current time as in Tue 2014-11-11 15:04:32
    ;                             A   IX  L  H  B  C  H
    pcall(getTime)
    
    cp errUnsupported
    kjp(z, unsupported)
    
    ld b, 6
    ld e, 31
    kcall(drawCalendar)

.waitForKey:
    ; update the screen
    pcall(fastCopy)
    
    ; wait for a key
    corelib(appWaitKey)
    pcall(flushKeys)
    
    ; if it is not MODE, draw everything again
    cp kMode
    kjp(nz, .loop)
    
    ; otherwise, exit
    ret

unsupported:
    kld(hl, clock_unsupported_1)
    ld de, 0x0208
    pcall(drawStr)
    kld(hl, clock_unsupported_2)
    ld de, 0x0210
    pcall(drawStr)
    
    ; update the screen
    pcall(fastCopy)
    
    ; wait for a key
    corelib(appWaitKey)
    pcall(flushKeys)
    
    cp kMODE
    jr nz, unsupported
    
    ret


;; drawCalendar
;;   Draws the calendar of the given month.
;; Inputs:
;;    B: day of the week of the first day (0-6); alternatively, the number of
;;       grid cells to leave blank in the beginning of the month
;;    E: number of days in the month
;;    F: selected day
;; Destroys:
;;    A, C, D, F, H, L, ...
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


; strings
window_title:
    .db "Calendar  -  Nov 2014", 0 ; TODO remove month suffix
corelib_path:
    .db "/lib/core", 0

clock_unsupported_1:
    .db "Clock is not supported", 0
clock_unsupported_2:
    .db "on this calculator :(", 0

; names of the months
months:
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
