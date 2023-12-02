
SECTION "Day2Vars", WRAM0
d2v::
.redMax
        ds 1
.greenMax
        ds 1
.blueMax
        ds 1
.gameID
        ds 1
.part1sum
        ds 2
.part2sum
        ds 4


SECTION "Day2", ROMX

; IN A * DE
; OUT A:DE
Day2_Mult_A_DE::
        push hl
        push bc

        ld hl, 0
        ld c, 0

        ; z80bits <3
	add	a,a		; optimised 1st iteration
	jr	nc,:+
	ld	h,d
	ld	l,e
:

	add	hl,hl		; unroll 7 times
	rla			; ...
	jr	nc,:+		; ...
	add	hl,de		; ...
	adc	a,c		; ...
:
	add	hl,hl		; unroll 7 times
	rla			; ...
	jr	nc,:+		; ...
	add	hl,de		; ...
	adc	a,c		; ...
:
	add	hl,hl		; unroll 7 times
	rla			; ...
	jr	nc,:+		; ...
	add	hl,de		; ...
	adc	a,c		; ...
:
	add	hl,hl		; unroll 7 times
	rla			; ...
	jr	nc,:+		; ...
	add	hl,de		; ...
	adc	a,c		; ...
:
	add	hl,hl		; unroll 7 times
	rla			; ...
	jr	nc,:+		; ...
	add	hl,de		; ...
	adc	a,c		; ...
:
	add	hl,hl		; unroll 7 times
	rla			; ...
	jr	nc,:+		; ...
	add	hl,de		; ...
	adc	a,c		; ...
:
	add	hl,hl		; unroll 7 times
	rla			; ...
	jr	nc,:+		; ...
	add	hl,de		; ...
	adc	a,c		; ...
:
        ld d,h
        ld e,l

        pop bc
        pop hl
        ret

Day2::
        ; yay this one fits in one page!!

        ; Part1 - Determine which games would have been possible if the bag had been loaded with only 12 red cubes, 13 green cubes, and 14 blue cubes. What is the sum of the IDs of those games?

        ; so we need to, for each game,
        ; - get max(r), max(g), max(b)
        ; - check that r <= 12, g <= 13, b <= 14
        ; - if so, add game ID to our sum

        ; Part2 - Compute max(r), max(g), max(b) for each game. 
        ; Calculate sum(max(r) * max(g) * max(b)) across all games

        ; Zero out sums
        xor a
        ld [d2v.part1sum], a
        ld [d2v.part1sum + 1], a
        ld [d2v.part2sum], a
        ld [d2v.part2sum + 1], a
        ld [d2v.part2sum + 2], a
        ld [d2v.part2sum + 3], a

        ; Data pointer. hl will be the data pointer for the rest of the code
        ld hl, Day2Input

.p1ProcessLine
        ; clear maximums
        xor a
        ld [d2v.redMax], a
        ld [d2v.greenMax], a
        ld [d2v.blueMax], a

        ; Skip "Game "
        ld de, 5
        add hl, de

        ; Read ID - read until ':'. ':' == 3A
        ; Store ID in C
        ld c, 0
.p1ReadID
        ld a, [hl]
        inc hl
        cp $3A
        jr z, .p1ReadIDDone

        ; Parse digit
        sub $30

        ; Store current digit in e
        ld e, a

        ; Load prev digit, mult by 10
        ld a, c

        ; *2, store
        add a, a
        ld d, a
        ; *4, *8
        add a, a
        add a, a
        ; + *2 = *10
        add a, d

        ; Add current digit
        add a, e

        ; Store back in c
        ld c, a
        jr .p1ReadID
.p1ReadIDDone
        ; store ID
        ld a, c
        ld [d2v.gameID], a
        
        ; At this point, HL is pointing to the space after the :
        ;
        ; All entries will then take the format `` [0-9]+ (red|green|blue)[,;\0]``
.p1ReadEntries
        ; Skip space
        inc hl

        ; Parse number
        ld c, 0
.p1ReadCount
        ld a, [hl]
        inc hl
        cp $20 ; space
        jr z, .p1ReadCountDone

        ; Parse digit
        sub $30

        ; Store current digit in e
        ld e, a

        ; Load prev digit, mult by 10
        ld a, c

        ; *2, store
        add a, a
        ld d, a
        ; *4, *8
        add a, a
        add a, a
        ; + *2 = *10
        add a, d

        ; Add current digit
        add a, e

        ; Store back in c
        ld c, a
        jr .p1ReadCount

.p1ReadCountDone

        ; c = count, HL is pointing to first letter of color. Given the colors
        ; are red/green/blue, we can just compare against r/g/b to determine the
        ; color, and then skip accordingly
        ld a, [hl]
        cp $72 ; 'r'
        jr z, .p1CountRed
        cp $67 ; 'g'
        jr z, .p1CountGreen
        cp $62 ; 'b'
        jr z, .p1CountBlue

.p1CountRed
        ; c = count, [hl] = 'r'
        ld a, 12
        cp c
        ; if carry, count > 12, discard game for part1
        jr nc, .p1KeepGameRed

        ; Discard by setting game ID to 0
        xor a
        ld [d2v.gameID], a
        
.p1KeepGameRed
        ; Compute maximum
        ld a, [d2v.redMax]
        cp c
        ; If carry, c > a, so store new maximum
        jr nc, .p1SkipRedMax
        ld a, c
        ld [d2v.redMax], a
.p1SkipRedMax

        ; skip "red" and move [hl] to terminator
        ld de, 3
        add hl, de
        jr .p1ProcessTerminator

.p1CountGreen
        ; c = count, [hl] = 'g'
        ld a, 13
        cp c
        ; if carry, count > 13, discard game
        jr nc, .p1KeepGameGreen

        ; Discard by setting game ID to 0
        xor a
        ld [d2v.gameID], a

.p1KeepGameGreen
        ; Compute minimum
        ld a, [d2v.greenMax]
        cp c
        ; If carry, c > a, so store new minimum
        jr nc, .p1SkipGreenMax
        ld a, c
        ld [d2v.greenMax], a
.p1SkipGreenMax

        ; skip "green" and move [hl] to terminator
        ld de, 5
        add hl, de
        jr .p1ProcessTerminator

.p1CountBlue
        ; c = count, [hl] = 'b'
        ld a, 14
        cp c
        ; if carry, count > 14, discard game
        jr nc, .p1KeepGameBlue

        ; Discard by setting game ID to 0
        xor a
        ld [d2v.gameID], a

.p1KeepGameBlue
        ; Compute minimum
        ld a, [d2v.blueMax]
        cp c
        ; If carry, c > a, so store new minimum
        jr nc, .p1SkipBlueMax
        ld a, c
        ld [d2v.blueMax], a
.p1SkipBlueMax

        ; skip "blue" and move [hl] to terminator
        ld de, 4
        add hl, de
        jr .p1ProcessTerminator

.p1ProcessTerminator
        ; Load terminator
        ld a, [hl]
        ; Move hl past terminator
        inc hl

        ; If terminator is 0, then we're done with the line and we kept it in,
        ; so add the ID to our running total, and move on to the next line!
        ;
        ; If terminator is not 0, then we have more entries to process. Loop!
        or a
        jr nz, .p1ReadEntries


; End of line processing!

; Part 1
        ; load ID sum into DE
        ld a, [d2v.part1sum]
        ld e, a
        ld a, [d2v.part1sum + 1]
        ld d, a

        ; load ID
        ld a, [d2v.gameID]

        ; Add ID to sum, store sum
        add a, e
        jr nc, .p1ProcessTerminatorNoCarry
        inc d
.p1ProcessTerminatorNoCarry
        ld [d2v.part1sum], a
        ld a, d
        ld [d2v.part1sum + 1], a

; Part 2
        ; R * G

        ; R in DE
        ld d, 0
        ld a, [d2v.redMax]
        ld e, a

        ; G in A
        ld a, [d2v.greenMax]


        ; Mult r * g! Result in A:DE, but A will be 0 for this first mult
        call Day2_Mult_A_DE

        ld a, [d2v.blueMax]
        ; Mult rg * b! Result in A:DE
        call Day2_Mult_A_DE

        ; Now result is C:DE
        ld c, a

        ; 32-bit sum (im paranoid about the result max)
        ld a, [d2v.part2sum]
        add a, e
        ld [d2v.part2sum], a
        ld a, [d2v.part2sum + 1]
        adc a, d
        ld [d2v.part2sum + 1], a
        ld a, [d2v.part2sum + 2]
        adc a, c
        ld [d2v.part2sum + 2], a
        ld a, [d2v.part2sum + 3]
        adc a, 0
        ld [d2v.part2sum + 3], a
        
        

        ; Process the next line!
.p1NextLine
        ; [hl] should be positioned at the start of the next line. If it's 
        ; pointer to zero, that means we hit the end of the input
        ld a, [hl]
        or a
        jp nz, .p1ProcessLine

        ; Ok its done
.p1Done
        ; Load p1sum into DE
        ld a, [d2v.part1sum]
        ld e, a
        ld a, [d2v.part1sum + 1]
        ld d, a 

        ; load p2sum into BC:HL
        ld a, [d2v.part2sum]
        ld l, a
        ld a, [d2v.part2sum + 1]
        ld h, a
        ld a, [d2v.part2sum + 2]
        ld c, a
        ld a, [d2v.part2sum + 3]
        ld b, a

        ; "Print" with the error screen
        rst $38

Day2Input::

db "Game 1: 13 green, 3 red; 4 red, 9 green, 4 blue; 9 green, 10 red, 2 blue", 0
db "Game 2: 3 red, 8 green, 1 blue; 4 green, 11 blue, 2 red; 3 blue, 2 red, 6 green; 5 green, 15 blue, 1 red; 2 blue, 2 red, 5 green; 12 blue, 7 green, 2 red", 0
db "Game 3: 1 red, 9 green, 3 blue; 8 green, 4 red, 11 blue; 6 red, 10 blue; 6 green, 6 red, 12 blue; 2 blue, 11 green, 7 red; 12 blue, 9 green, 8 red", 0
db "Game 4: 7 red, 2 green, 1 blue; 12 green; 12 green", 0
db "Game 5: 15 red, 3 green, 1 blue; 6 red, 2 blue, 2 green; 3 green, 3 red, 1 blue; 2 blue, 13 red, 5 green; 2 green, 15 red, 2 blue", 0
db "Game 6: 3 blue, 15 red, 1 green; 8 green, 5 red, 6 blue; 9 green, 5 blue, 6 red; 9 green, 3 blue, 9 red; 10 green, 14 red, 2 blue", 0
db "Game 7: 6 green, 1 red, 11 blue; 6 green, 1 red, 3 blue; 4 green, 20 blue; 2 red, 5 blue, 4 green; 10 green, 17 blue", 0
db "Game 8: 10 blue, 9 green, 10 red; 9 green, 1 red; 8 red, 9 green, 9 blue; 5 green, 3 red, 7 blue", 0
db "Game 9: 7 blue, 1 red; 5 red, 4 green; 4 green, 6 red, 5 blue; 2 green, 4 blue; 3 green, 6 blue, 4 red; 1 green, 3 red, 3 blue", 0
db "Game 10: 2 red, 2 green, 2 blue; 10 blue, 2 red, 1 green; 2 green, 9 blue, 3 red", 0
db "Game 11: 8 red, 4 blue, 1 green; 3 red; 1 green; 2 green, 3 blue", 0
db "Game 12: 10 red, 2 green, 4 blue; 4 red, 2 green; 1 blue, 1 red, 1 green; 10 red, 1 green, 5 blue", 0
db "Game 13: 20 blue, 9 green, 7 red; 13 red, 13 blue, 16 green; 17 blue, 6 red, 6 green; 1 red, 1 blue, 9 green; 9 blue, 18 green, 7 red", 0
db "Game 14: 6 blue, 14 red; 9 red, 8 blue; 2 red, 1 green, 8 blue; 3 blue, 1 green, 9 red; 8 blue, 2 green, 1 red", 0
db "Game 15: 3 red, 1 blue, 5 green; 2 red, 3 green; 5 red, 5 green, 1 blue; 2 green, 6 red; 4 red, 1 blue; 6 red, 1 blue, 1 green", 0
db "Game 16: 5 blue, 7 red, 2 green; 7 red, 12 blue; 10 blue, 11 green, 5 red; 11 red, 11 blue, 10 green", 0
db "Game 17: 3 red, 7 blue; 1 blue, 14 green, 4 red; 11 blue, 4 red, 11 green; 18 blue, 5 red, 11 green; 18 blue, 1 red, 8 green", 0
db "Game 18: 8 green, 2 red, 6 blue; 8 blue, 11 green; 2 red, 11 blue, 9 green", 0
db "Game 19: 11 red, 9 green, 3 blue; 19 green, 9 red, 2 blue; 19 green, 4 blue, 4 red; 1 green, 11 red; 10 red, 2 green, 4 blue", 0
db "Game 20: 2 blue, 3 red, 1 green; 1 red, 3 green; 7 blue, 1 green, 4 red; 1 red, 8 blue, 7 green; 6 blue, 3 red; 5 red, 3 blue, 7 green", 0
db "Game 21: 1 green, 1 blue, 10 red; 1 green, 5 red, 8 blue; 11 red, 4 blue; 6 blue, 6 red", 0
db "Game 22: 6 blue, 6 green; 8 green, 15 blue; 8 green, 3 blue, 1 red; 11 blue, 2 red, 7 green", 0
db "Game 23: 1 green, 3 blue, 7 red; 4 red, 1 green, 2 blue; 3 red, 2 blue, 2 green", 0
db "Game 24: 4 green, 8 blue, 4 red; 2 green, 9 blue; 4 green, 1 red; 2 green, 5 blue, 1 red; 2 blue, 3 red, 3 green; 6 blue", 0
db "Game 25: 7 blue; 15 blue, 5 red; 6 blue, 12 red; 1 green, 17 red; 13 blue, 5 red; 17 red", 0
db "Game 26: 1 blue, 3 green, 7 red; 9 red, 4 green, 1 blue; 1 red, 2 green, 1 blue; 11 red, 3 green; 10 red, 4 green, 2 blue; 6 red, 4 green", 0
db "Game 27: 4 blue, 6 red; 2 blue, 8 red, 1 green; 3 blue, 3 red; 2 red, 1 blue; 1 green, 3 blue, 6 red", 0
db "Game 28: 1 red, 7 blue, 7 green; 2 green, 1 red, 4 blue; 8 green, 2 red; 2 red, 7 blue, 5 green; 12 green, 5 blue, 2 red; 1 red, 1 green, 2 blue", 0
db "Game 29: 10 green, 3 red, 6 blue; 9 green, 6 blue, 4 red; 3 red, 2 blue, 17 green", 0
db "Game 30: 8 blue; 15 blue, 1 red; 10 green, 2 red, 13 blue", 0
db "Game 31: 10 green, 2 blue, 7 red; 2 green, 1 blue; 1 blue, 15 green, 2 red; 7 green, 2 blue; 3 blue, 6 green, 8 red; 6 red, 1 blue", 0
db "Game 32: 2 blue, 2 red, 11 green; 10 green, 2 red, 1 blue; 1 green, 2 blue; 2 red, 9 green, 2 blue; 2 blue, 1 green; 5 green, 1 blue, 2 red", 0
db "Game 33: 8 red, 6 blue; 2 green, 3 red, 2 blue; 1 green, 13 red, 18 blue", 0
db "Game 34: 7 blue, 5 green; 5 green, 8 blue; 13 blue, 15 red, 2 green", 0
db "Game 35: 1 blue, 2 green; 9 green; 4 red, 14 green; 1 red, 1 blue, 17 green", 0
db "Game 36: 2 red, 14 green, 4 blue; 13 green, 3 blue; 1 blue, 7 green, 2 red; 4 blue, 9 green; 1 green, 3 blue, 1 red; 2 red, 4 blue, 10 green", 0
db "Game 37: 2 blue, 7 green, 5 red; 5 green, 2 blue; 6 blue, 11 red", 0
db "Game 38: 6 green, 6 red; 9 red, 10 green; 2 blue, 8 green, 8 red", 0
db "Game 39: 10 red, 3 blue; 5 green, 3 red; 5 red, 7 green", 0
db "Game 40: 5 red, 14 green, 2 blue; 5 red, 7 blue, 12 green; 2 green, 4 red; 1 red, 16 green, 3 blue; 16 green, 4 red, 7 blue; 9 green, 2 red", 0
db "Game 41: 4 red, 3 green, 2 blue; 13 green, 6 blue; 2 red, 14 green, 1 blue; 7 blue, 2 red, 14 green", 0
db "Game 42: 4 red; 1 blue, 5 red; 1 green, 6 red; 1 red, 1 blue; 3 blue, 8 red", 0
db "Game 43: 7 blue, 16 red, 1 green; 2 red, 6 green, 1 blue; 5 green, 3 red; 5 green, 9 blue, 2 red; 3 red, 9 blue, 4 green; 7 red, 9 blue", 0
db "Game 44: 2 red, 2 green; 5 red, 1 blue, 8 green; 7 green, 3 blue, 5 red", 0
db "Game 45: 8 blue, 16 red; 8 blue; 4 blue, 1 green, 8 red", 0
db "Game 46: 11 green, 9 blue, 1 red; 8 green, 7 blue; 10 blue, 1 red, 1 green; 12 green, 10 blue", 0
db "Game 47: 3 green, 6 red, 1 blue; 2 blue, 2 green, 12 red; 3 red, 2 green, 1 blue", 0
db "Game 48: 3 red, 3 green, 3 blue; 3 red, 4 green, 2 blue; 2 green, 7 red, 1 blue; 2 red, 3 blue, 5 green", 0
db "Game 49: 5 red, 7 blue, 5 green; 10 red, 4 green, 7 blue; 9 red, 17 green; 6 green, 1 red, 2 blue; 7 green, 8 blue, 5 red", 0
db "Game 50: 2 red, 4 green, 16 blue; 4 blue, 3 red, 8 green; 4 blue, 2 red, 6 green", 0
db "Game 51: 16 green, 10 red, 14 blue; 8 red, 4 blue, 12 green; 14 green, 7 blue; 6 red, 20 green, 3 blue", 0
db "Game 52: 1 red, 1 blue, 1 green; 9 green, 9 red; 4 green, 13 red; 7 red, 11 green; 4 red, 1 blue; 8 green, 3 red, 1 blue", 0
db "Game 53: 4 green, 11 blue; 9 green, 2 red; 6 red, 18 green, 13 blue; 6 red, 2 blue, 14 green", 0
db "Game 54: 1 green, 1 red, 1 blue; 2 green, 4 blue; 4 blue, 5 green; 3 blue, 1 red, 10 green", 0
db "Game 55: 8 blue, 2 red, 3 green; 9 red, 11 blue; 1 green, 12 blue, 4 red; 3 green, 17 red; 3 red, 3 green, 15 blue; 7 blue, 7 red, 2 green", 0
db "Game 56: 3 blue, 13 green; 9 green, 2 blue; 1 red, 2 blue, 16 green", 0
db "Game 57: 6 blue, 4 red; 3 green, 6 red; 2 red, 3 blue, 3 green; 8 red, 5 blue", 0
db "Game 58: 4 red, 15 green, 5 blue; 1 red, 16 blue, 14 green; 2 green, 17 blue, 6 red; 20 blue, 3 red, 7 green; 17 green, 1 red, 12 blue", 0
db "Game 59: 3 blue, 14 red; 5 green, 10 red, 2 blue; 2 blue, 5 red, 6 green", 0
db "Game 60: 4 red, 1 blue, 1 green; 15 blue; 8 green, 14 blue, 4 red; 9 blue, 3 green, 4 red; 4 green, 2 red, 11 blue; 4 blue, 7 green", 0
db "Game 61: 5 green, 9 blue, 16 red; 4 blue, 12 green, 4 red; 17 red, 7 green, 5 blue; 19 blue, 12 red, 17 green; 8 green, 13 red", 0
db "Game 62: 13 green, 1 red, 7 blue; 9 blue, 1 red, 4 green; 14 green, 2 red, 2 blue; 3 green", 0
db "Game 63: 6 green; 7 red, 3 blue, 8 green; 5 blue, 1 green, 6 red; 6 green, 6 red, 2 blue; 8 green, 2 blue", 0
db "Game 64: 16 blue, 1 red, 2 green; 4 green, 1 blue, 6 red; 6 green, 2 blue, 2 red; 17 blue; 1 red; 13 blue, 6 green, 1 red", 0
db "Game 65: 8 red, 3 green, 7 blue; 6 blue, 8 red, 2 green; 2 blue, 3 green, 17 red", 0
db "Game 66: 2 blue, 3 green, 3 red; 3 red, 2 blue; 5 red, 4 green, 3 blue; 1 blue, 3 green; 2 red, 1 green, 1 blue; 2 blue, 4 green", 0
db "Game 67: 2 red, 3 blue, 15 green; 2 blue, 2 red, 17 green; 4 blue, 3 red, 2 green; 6 red; 3 red, 8 green", 0
db "Game 68: 7 red, 1 blue, 12 green; 17 red, 1 green; 10 red, 8 green; 16 red, 5 green, 2 blue; 4 red, 1 blue, 8 green; 8 green, 7 red, 2 blue", 0
db "Game 69: 17 green, 9 red, 2 blue; 1 blue, 14 green, 3 red; 9 red, 12 green, 2 blue; 11 green, 2 blue, 7 red", 0
db "Game 70: 1 green, 8 blue, 2 red; 2 red, 10 green, 1 blue; 1 red, 12 green, 6 blue; 9 green, 4 blue, 4 red; 2 red, 6 green; 3 red, 8 green, 6 blue", 0
db "Game 71: 1 red, 5 blue; 12 blue, 3 red; 3 red, 2 green, 4 blue; 5 blue, 3 green, 1 red", 0
db "Game 72: 11 red, 6 blue; 1 red, 1 blue, 1 green; 2 blue, 7 red; 18 blue, 3 red; 1 green, 1 blue, 12 red", 0
db "Game 73: 4 red, 2 blue, 1 green; 3 red; 5 red, 1 blue; 4 blue, 6 red", 0
db "Game 74: 2 red; 2 red, 5 green; 4 green, 1 red, 1 blue; 1 blue, 5 green, 5 red; 7 red, 1 blue, 3 green; 8 red, 1 blue, 6 green", 0
db "Game 75: 13 blue, 2 red, 2 green; 2 red, 9 blue; 2 red, 9 blue, 5 green", 0
db "Game 76: 2 red, 3 green, 18 blue; 2 red, 11 green, 5 blue; 6 green, 8 blue, 2 red; 4 blue; 7 green, 14 blue", 0
db "Game 77: 5 blue, 8 red, 1 green; 2 blue, 5 green, 12 red; 3 red, 4 blue", 0
db "Game 78: 1 blue, 2 green, 16 red; 2 red, 3 green; 1 red, 4 green, 2 blue; 11 red; 2 green, 12 red, 2 blue; 11 red, 5 green, 3 blue", 0
db "Game 79: 10 green, 3 blue, 2 red; 8 red, 3 blue, 8 green; 5 green, 3 red, 11 blue; 9 green, 16 blue", 0
db "Game 80: 1 red, 4 blue; 6 green, 1 red; 6 green, 3 blue, 1 red; 6 green, 2 red; 7 green, 1 blue; 2 red, 2 blue, 2 green", 0
db "Game 81: 10 blue, 4 red, 4 green; 5 green, 1 red, 7 blue; 11 blue, 8 green, 2 red; 8 green, 2 red", 0
db "Game 82: 12 green, 1 red, 3 blue; 6 red, 1 blue; 16 green, 3 red, 4 blue; 8 blue; 7 blue, 7 green, 2 red; 4 red, 19 green", 0
db "Game 83: 4 red, 4 blue, 3 green; 8 blue, 4 green, 6 red; 6 green, 7 blue, 6 red; 11 red, 6 green, 7 blue", 0
db "Game 84: 11 red, 2 green, 2 blue; 20 green, 2 blue, 13 red; 15 red, 6 green, 3 blue; 17 green, 7 red", 0
db "Game 85: 3 blue, 5 green, 2 red; 12 green, 2 blue, 1 red; 7 blue, 6 green, 5 red; 11 red, 2 blue, 17 green; 11 blue, 11 red, 17 green; 18 green, 9 red, 13 blue", 0
db "Game 86: 1 blue, 14 red; 4 green, 1 blue, 3 red; 2 green, 1 blue, 13 red; 1 green, 1 blue, 10 red", 0
db "Game 87: 2 red, 5 green, 4 blue; 3 blue, 9 red, 6 green; 7 blue, 9 red, 11 green; 10 green, 11 red, 9 blue; 7 green, 12 red, 4 blue; 5 blue, 1 red, 7 green", 0
db "Game 88: 11 red, 1 green; 9 blue, 4 green, 7 red; 10 red, 4 green, 1 blue; 4 green, 1 red, 1 blue; 10 blue, 1 red, 3 green; 2 green, 12 blue, 11 red", 0
db "Game 89: 3 green, 3 blue; 1 red, 7 green, 9 blue; 8 red, 11 blue, 11 green; 2 green, 6 blue, 5 red; 5 blue, 9 green", 0
db "Game 90: 3 blue, 10 red, 2 green; 2 blue; 8 red", 0
db "Game 91: 2 red, 10 green, 2 blue; 9 blue; 8 green, 5 red, 10 blue; 7 green, 6 blue, 5 red; 1 green, 6 red, 12 blue; 1 red, 4 green, 3 blue", 0
db "Game 92: 12 blue, 5 red, 2 green; 4 blue, 1 red, 3 green; 6 red, 6 blue; 1 blue, 8 red, 6 green; 6 blue, 3 red, 2 green; 7 green, 4 red, 1 blue", 0
db "Game 93: 3 blue; 8 blue; 3 blue, 2 red; 2 red, 1 green", 0
db "Game 94: 5 red, 7 blue, 6 green; 15 red, 7 blue, 4 green; 6 blue, 1 red, 2 green; 7 green, 4 blue, 17 red; 12 red, 5 green, 1 blue", 0
db "Game 95: 7 blue, 11 red, 9 green; 10 red, 6 blue, 7 green; 6 blue, 6 red, 7 green", 0
db "Game 96: 2 red, 1 green, 3 blue; 3 blue, 1 green; 1 green, 1 blue; 1 red, 1 blue; 1 green, 1 red, 4 blue", 0
db "Game 97: 6 red, 1 blue, 7 green; 2 blue, 5 red, 7 green; 8 red, 3 blue, 6 green; 6 green, 1 red, 3 blue; 5 red, 2 blue, 14 green; 3 green, 6 red, 6 blue", 0
db "Game 98: 9 red, 14 blue; 19 red, 4 blue; 11 red, 17 blue; 14 blue, 1 green, 18 red", 0
db "Game 99: 1 green, 1 red, 12 blue; 2 green, 4 red, 14 blue; 4 blue, 6 red; 10 red, 2 green, 1 blue", 0
db "Game 100: 5 red, 9 green, 2 blue; 9 blue, 6 green, 1 red; 8 blue, 7 green, 3 red", 0
db 0
