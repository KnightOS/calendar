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
    .db "An application to view the current date and time", 0

start:
    kld(de, corelib_path)
    pcall(loadLibrary)
    
    ; Get a lock on the devices we intend to use
    pcall(getLcdLock)
    pcall(getKeypadLock)
    
    ; Allocate and clear a buffer to store the contents of the screen
    pcall(allocScreenBuffer)
    pcall(clearBuffer)
    
    kld(hl, window_title)
    xor a
    corelib(drawWindow)

.loop:
    ; get the current time as in Tue 2014-11-11 15:04:32
    ;                             A   IX  L  H  B  C  H
    pcall(getTime)
    
    cp errUnsupported
    kjp(z, .unsupported)

.drawDate:
    
    ; first, draw the year (that is actually pretty complicated since drawDecHL
    ; is not implemented yet)
    
    push hl
        ; get the year in hl
        push ix
        pop hl
        
        ; subtract 1900 from it and put the result in a
        ld de, -1900
        add hl, de
        ld a, l
        
        ; if a >= 100 we have year "20.."
        cp 100
        ld de, 0x0208
        jr nc, .drawYear2000

.drawYear1900:
        ld de, 0x0a08
        kcall(drawDecAPadded)
        
        ; "19"
        ld a, '1'
        ld de, 0x0208
        pcall(drawChar)
        ld a, '9'
        ld de, 0x0608
        pcall(drawChar)
        
        jr .endDrawYear

.drawYear2000:
        sub 100
        ld de, 0x0a08
        kcall(drawDecAPadded)
        
        ; "20"
        ld a, '2'
        ld de, 0x0208
        pcall(drawChar)
        ld a, '0'
        ld de, 0x0608
        pcall(drawChar)

.endDrawYear:
    pop hl
    
    ; now, draw the month and day
    ld a, l
    inc a
    ld de, 0x1608
    kcall(drawDecAPadded)
    ld a, h
    inc a
    ld de, 0x2208
    kcall(drawDecAPadded)
    
    ; the dashes
    ld a, '-'
    ld de, 0x1208
    pcall(drawChar)
    ld de, 0x1e08
    pcall(drawChar)

.drawTime:
    ld a, b
    ld de, 0x0210
    kcall(drawDecAPadded)
    ld a, c
    ld de, 0x0c10
    kcall(drawDecAPadded)
    ld a, h
    ld de, 0x1610
    kcall(drawDecAPadded)
    
    ; the colons
    ld a, ':'
    ld de, 0x0a10
    pcall(drawChar)
    ld de, 0x1410
    pcall(drawChar)

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

.unsupported:
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
    jr nz, .unsupported
    
    ret


; Draws A (assumed < 100) as a decimal number, padded with a leading zero if it
; is < 10.
drawDecAPadded:
    
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


window_title:
    .db "Calendar", 0
corelib_path:
    .db "/lib/core", 0

clock_unsupported_1:
    .db "Clock is not supported", 0
clock_unsupported_2:
    .db "on this calculator :(", 0

colon:
    .db ":", 0
