Palettes:
  .incbin "palettes.dat"

spritesInitial:
     ;vert tile attr horiz
  .db $80, $32, $00, $80   ;sprite 0
  .db $80, $33, $00, $88   ;sprite 1
  .db $88, $34, $00, $80   ;sprite 2
  .db $88, $35, $00, $88   ;sprite 3
 
heightInitial:
  ;.db 10,11,13,15,14,14,13,14,11,9,6,7,8,9,11,12
  ;.db 10,11,13,15,14,14,13,14,11,9,6,7,8,9,11,12
  .db 25, 23, 21, 21, 19, 20, 18, 17, 18, 17, 16, 19, 18, 18, 21, 23
  .db 22, 22, 20, 20, 19, 17, 14, 13, 13, 15, 14, 16, 17, 17, 19, 17

player0Name:
  .db 7
  .db _LetterSpriteNumber('P')
  .db _LetterSpriteNumber('L')
  .db _LetterSpriteNumber('A')
  .db _LetterSpriteNumber('Y')
  .db _LetterSpriteNumber('E')
  .db _LetterSpriteNumber('R')
  .db _LetterSpriteNumber('A')
  
player1Name:
  .db 7
  .db _LetterSpriteNumber('P')
  .db _LetterSpriteNumber('L')
  .db _LetterSpriteNumber('A')
  .db _LetterSpriteNumber('Y')
  .db _LetterSpriteNumber('E')
  .db _LetterSpriteNumber('R')
  .db _LetterSpriteNumber('B')
  
