; =============================
; SPRITE NUMBERS
; =============================

_DigitSpriteNumber  .func \1 - '0' + BGNAME_DIGITS     ; Arguments [letter '0'-'1']
_LetterSpriteNumber .func \1 - 'A' + BGNAME_LETTERS    ; Arguments [letter 'A'-'B']
  
; =============================
; 16B MATHS
; =============================

_LoadWord .macro  ; Arguments [dst, #val]
  LDA #LOW(\2)
  STA \1
  LDA #HIGH(\2)
  STA \1 + 1
  .endm

_IncWord .macro   ; Argumets [dst]
  CLC
  INC \1      ; [dst]++
  LDA \1 + 1
  ADC #$00
  STA \1 + 1  ; [dst+1] += C
  .endm
  
_AddWord .macro   ; Arguments [dst, #val]
  CLC
  LDA \1
  ADC #\2
  STA \1      ; [dst] += val
  LDA \1 + 1
  ADC #$00
  STA \1 + 1  ; [dst+1] += C
  .endm
  
; =============================
; FRACTIONAL MATHS
; =============================

; Arguments[var   - updated variable, 
;           delta - variable's delta cache (numerator), 
;           num   - added value (numerator), 
;           den   - added value (denominator),
;           onUpd - callback called on position update (it can't affect accumulator] 
_AddFraction .macro   
  LDA \2
  CLC
  ADC \3
loopLowerBound\@:     ; make delta >= 0
  BPL loopUpperBound\@
  JSR \5
  DEC \1
  CLC
  ADC \4
  JMP loopLowerBound\@
loopUpperBound\@:     ; make delta < divider
  CMP \4
  JSR \5
  BMI end\@
  INC \1
  SEC
  SBC \4
  JMP loopUpperBound\@
end\@:
  STA \2
  .endm
  
  
; =============================
; BLOCKS OF DATA
; =============================
      
_SendWord .macro ; Arguments [port address, #val]
  LDA #HIGH(\2)
  STA \1
  LDA #LOW(\2)
  STA \1
  .endm
  
_SendArray .macro ; Arguments [port, src, #number of bytes]
  LDY #$00
loop\@:
  LDA \2, Y
  STA \1
  INY
  CPY #\3
  BNE loop\@
  .endm
  
_SendMatrix .macro ; Arguments [port, src, #sizex, #sizey]
  LDX #$00
  _LoadWord pointer, \2
loop\@:
  _SendArray \1, [pointer], #\3
  _AddWord pointer, #\3
  INX
  CPX #\4
  BNE loop\@
  .endm
      
_CopyArray .macro ;  Arguments [dst, src, #number of bytes]
  LDY #$00
loop\@:
  LDA \2, Y
  STA \1, Y
  INY
  CPY #\3
  BNE loop\@
  .endm
  
_CopyMatrix .macro ; Arguments [dst, src, #sizex, #sizey]
  LDX #$00
  _LoadWord pointer, \1
  _LoadWord pointer2, \2
loop\@:
  _CopyArray [pointer], [pointer2], #\3
  _AddWord pointer, #\3
  _AddWord pointer2, #\3
  INX
  CPX #\4
  BNE loop\@
  .endm
  
_FillArrayA .macro ; Arguments [A=val, dst, #number of bytes]
  LDY #$00
loop\@:
  STA \1, Y
  INY
  CPY #\2
  BNE loop\@
  .endm
  
_FillArray .macro ; Arguments [dst, #val, #number of bytes]
  LDA #\2
  _FillArrayA \1, \3
  .endm
  
_FillMatrix .macro ; Arguments [dst, #val, #sizex, #sizey]
  LDX #$00
  _LoadWord pointer, \1
loop\@:
  _FillArray [pointer], #\2, #\3
  _AddWord pointer, #\3
  INX
  CPX #\4
  BNE loop\@
  .endm
  
      
      
      

