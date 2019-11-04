  .inesprg 2   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring
  
  .include "constants.asm"
  .include "macros.asm"
  .include "variables.asm"

;;;;;;;;;;;;;;;;;;;;;
; Framework functions
;;;;;;;;;;;;;;;;;;;;;

  .bank 0
  .org $8000
  
  .include "framework.asm"

;;;;;;;;;;;;;;;;;;;;;
; Main functions
;;;;;;;;;;;;;;;;;;;;;

  .bank 2
  .org $C000

;==================== Initialization functions ==============================;

; Currently it just copies values from data memory
InitMapHeight:
  _CopyArray height, heightInitial, #SCR_TILEW
  RTS

; Initialize attribute and name table based on terrain height
PrepareMap:
  _FillArray bgAttrtable, #BGATTR_MAP, #SCR_ATTRTABLESIZE
  _LoadWord pointer, #bgNametable
  ; And now be careful! We use X register to store y coordinate and vice versa
  LDX #$00
pmLoopY:
  LDY #$00
pmLoopX:
  TXA                 ; A = y coord
  CMP height, Y
  BEQ pmGround
  BPL pmUnderTerrain
  LDA #BGNAME_SKY            ; set tile above terrain
  STA [pointer], Y
  JMP pmLoopXEpilog
pmUnderTerrain:
  LDA #BGNAME_UNDERGROUND    ; set tile under terrain
  STA [pointer], Y
  JMP pmLoopXEpilog
pmGround:
  LDA #BGNAME_GROUND
  STA [pointer], Y
pmLoopXEpilog:
  INY                 ; inc x coordinate and check loop condition
  CPY #SCR_TILEW
  BNE pmLoopX
  _AddWord pointer, #SCR_TILEW
  INX                 ; inc y coordinate and check loop condition
  CPX #SCR_TILEH
  BNE pmLoopY
  RTS
  
; Change background to display players' names and scores
PrepareHud:
  _FillArray bgAttrtable, #BGATTR_HUD, #SCR_TILEW*4/16  ; Fill four rows
  ; player0
  LDX player0Name       ; X = length of string
  INX
  STX endx
  LDX #1                ; string index
  LDY #SCR_TILEW        ; destination array index
phLoop1:
  LDA player0Name, X
  STA bgNametable, Y
  INX
  INY
  CPX endx
  BNE phLoop1
  ; player1
  LDX player1Name       ; X = length of string
  INX
  STX endx
  LDX #1                ; string index
  LDA #SCR_TILEW*2 
  SEC
  SBC endx
  TAY
  INY                   ; destination array index
phLoop2:
  LDA player1Name, X
  STA bgNametable, Y
  INX
  INY
  CPX endx
  BNE phLoop2
  ; scores (Y now contains position of player0's score)
  LDA score0
  STA bgNametable, Y
  DEY
  TYA
  CLC
  ADC #SCR_TILEW
  TAY
  LDA score1
  STA bgNametable, Y
  RTS
  
PrepareSprites:
  ; setup towers' positions
  LDX height + 2
  DEX
  TXA
  ASL A
  ASL A
  ASL A
  STA spritePlayer00
  STA spritePlayer01  
  LDA #(2 * 8)
  STA spritePlayer00 + 3  
  LDA #(3 * 8)
  STA spritePlayer01 + 3 
  LDX height + SCR_TILEW - 4
  DEX
  TXA
  ASL A
  ASL A
  ASL A
  STA spritePlayer10
  STA spritePlayer11 
  LDA #((SCR_TILEW-4) * 8)
  STA spritePlayer10 + 3  
  LDA #((SCR_TILEW-3) * 8)
  STA spritePlayer11 + 3 
  ; setup towers' graphics
  LDA #SPNAME_TOWERLEFT
  STA spritePlayer00 + 1
  STA spritePlayer10 + 1
  LDA #SPNAME_TOWERRIGHT
  STA spritePlayer01 + 1
  STA spritePlayer11 + 1
  LDA #SPATTR_TOWER
  STA spritePlayer00 + 2
  STA spritePlayer01 + 2
  STA spritePlayer10 + 2
  STA spritePlayer11 + 2
  ; setup dative
  LDA #$FF  
  STA spriteDative 
  STA spriteDative + 3
  LDA #SPNAME_DATIVE
  STA spriteDative + 1
  LDA #SPATTR_DATIVE
  STA spriteDative + 2
  ; setup bullet
  LDA #$FF
  STA spriteBullet
  STA spriteBullet + 3
  LDA #SPNAME_BULLET
  STA spriteBullet + 1
  LDA #SPATTR_BULLET
  STA spriteBullet + 2
  RTS
  
; Zero RAM variables 
ClearMemory:
  LDX #0
clearMemoryLoop:
  LDA #$00
  STA $0000, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FF
  STA $0200, x  ; sprites
  INX
  BNE clearMemoryLoop
  RTS
  
ResetGame:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs
  ; init variables
  JSR WaitVBlank
  JSR ClearMemory
  LDA #0
  STA currentPlayer
  LDA #STATE_INIT
  STA currentState
  ; init palettes, background and sprites
  JSR WaitVBlank
  JSR LoadPalettes  
  JSR InitMapHeight
  JSR PrepareMap
  JSR PrepareHud
  JSR LoadBackground
  JSR PrepareSprites
  JSR InitRendering
  RTS
  
;==================== Game logic functions ==============================;

InitDativePosition:
  LDA currentPlayer
  BNE idpPlayer1
  LDX spritePlayer00 + 3
  LDY spritePlayer00
  JMP idpCommonPart
idpPlayer1:
  LDX spritePlayer10 + 3
  LDY spritePlayer10
idpCommonPart:
  TXA 
  CLC
  ADC #4
  STA spriteDative + 3
  TYA
  SEC
  SBC #32
  STA spriteDative
  LDA #STATE_CONTROL
  STA currentState
  RTS
  
HandleInput:
  JSR ReadControllers
  LDA currentPlayer
  BNE hiPlayer1
  LDA buttons0
  JMP hiCommonPart
hiPlayer1:
  LDA buttons1
hiCommonPart:
  STA buttons
  LDA #%10000000  ; A
  BIT buttons
  BNE hiA
  LDA #%00001000  ; up
  BIT buttons
  BNE hiUp
  LSR A           ; down
  BIT buttons
  BNE hiDown
  LSR A           ; left
  BIT buttons
  BNE hiLeft
  LSR A           ; right
  BIT buttons
  BNE hiRight
hiEnd:
  RTS
hiA:
  JSR InitBullet
  RTS
hiUp:
  LDA spriteDative
  BEQ hiEnd
  DEC spriteDative
  RTS
hiDown:
  LDA spriteDative
  CMP #(SCR_H - 8)
  BCS hiEnd
  INC spriteDative
  RTS
hiLeft:
  LDA spriteDative + 3
  BEQ hiEnd
  DEC spriteDative + 3
  RTS
hiRight:
  LDA spriteDative + 3
  CMP #(SCR_W - 8)
  BCS hiEnd
  INC spriteDative + 3
  RTS
  
InitBullet:
  ; calc position
  LDA currentPlayer
  BNE ibPlayer1
  LDX spritePlayer00 + 3
  LDY spritePlayer00
  JMP ibCommonPart
ibPlayer1:
  LDX spritePlayer10 + 3
  LDY spritePlayer10
ibCommonPart:
  TXA 
  CLC
  ADC #4
  STA spriteBullet + 3
  STY spriteBullet
  ; calc velocity
  LDA spriteDative + 3
  SEC
  SBC spriteBullet + 3
  STA bulletVX
  LDA spriteDative
  SEC 
  SBC spriteBullet
  STA bulletVY
  ; zero deltas etc
  LDA #0
  STA bulletDX
  STA bulletDY
  STA bulletDVY
  ; change state
  LDA #STATE_BULLET_FLIGHT
  STA currentState
  RTS
  
; args[X = bullet.x, Y = bullet.y] ret[A = collision detected?]
CheckCollisionWithPlayer: 
  LDA currentPlayer
  BEQ ccwpGetPlayer1Position
  LDA spritePlayer00 + 3
  STA ix                ; ix = player0.left
  LDA spritePlayer00
  STA iy                ; iy = player0.top
  JMP ccwpCommon
ccwpGetPlayer1Position:
  LDA spritePlayer10 + 3
  STA ix                ; ix = player1.left
  LDA spritePlayer10
  STA iy                ; iy = player1.top
ccwpCommon:
  TXA
  CLC
  ADC #(4 + BULLET_RADIUS)  ; A = bullet.right
  CMP ix
  BCC ccwpFalse             ; break if bullet.right < player0.left
  LDA ix
  CLC
  ADC #16
  STA ix                    ; ix = player0.right
  TXA
  CLC 
  ADC #(4 - BULLET_RADIUS)  ; A = bullet.left
  CMP ix
  BCS ccwpFalse             ; break if bullet.left > player0.right
  TYA
  CLC
  ADC #(4 + BULLET_RADIUS)  ; A = bullet.bottom
  CMP iy
  BCC ccwpFalse             ; break if bullet.bottom < player0.top
  LDA iy
  CLC
  ADC #8
  STA iy                    ; iy = player0.bottom
  TXA
  CLC 
  ADC #(4 - BULLET_RADIUS)  ; A = bullet.top
  CMP ix
  BCS ccwpFalse             ; break if bullet.top > player0.bottom  
  ; update score
  LDA currentPlayer
  BNE ccwpScore1
  INC score0
  JMP ccwpTrue
ccwpScore1:
  INC score1
ccwpTrue
  LDA #1
  RTS
ccwpFalse:
  LDA #0
  RTS  
  
; args[X = bullet.x, Y = bullet.y] ret[A = collision detected?]
CheckCollisionWithTerrain
  TXA
  CLC
  ADC #4
  LSR A
  LSR A
  LSR A
  TAX   ; X = center(bullet.x)/8
  LDA height, X
  ASL A
  ASL A
  ASL A  
  SEC
  SBC #(4 + BULLET_RADIUS) ; A = max bullet.y
  STY iy
  CMP iy
  BCS ccwtFalse
  INC height, X
  LDA #1
  RTS
ccwtFalse:
  LDA #0
  RTS
  
CheckBulletPosition:
  PHA
  LDX currentState
  CPX #STATE_BULLET_FLIGHT
  BNE cbpRet
  ; compare x with edges of screen
  LDX spriteBullet + 3  ; X = bullet.x
  BEQ cbpExplosion
  CPX #(SCR_W - 8)
  BEQ cbpExplosion
  ; compare y with edges of screen
  LDY spriteBullet      ; Y = bullet.y
  BEQ cbpExplosion
  CPY #(SCR_H - 8)
  BEQ cbpExplosion
  ; check collision with player
  JSR CheckCollisionWithPlayer
  BNE cbpExplosion  
  ; check collision with terrain
  JSR CheckCollisionWithTerrain
  BNE cbpExplosion
  ; no collision detected
  JMP cbpRet  
cbpExplosion:
  LDA #STATE_BULLET_EXPL
  STA currentState
  LDA #0
  STA explFrame
  STA explDFrame
cbpRet:
  PLA
  RTS

EmptyFunc:
  RTS
  
UpdateBulletPosition:
  _AddFraction spriteBullet + 3, bulletDX, bulletVX, #BULLET_DIVIDER, CheckBulletPosition
  _AddFraction spriteBullet, bulletDY, bulletVY, #BULLET_DIVIDER, CheckBulletPosition
  _AddFraction bulletVY, bulletDVY, #BULLET_ACCELY, #BULLET_DIVIDER, EmptyFunc
  _AddFraction spriteBullet, bulletDFrame, #1, #BULLET_ANIM_DIVIDER, EmptyFunc
  RTS
  
UpdateBulletAnim:
  _AddFraction bulletFrame, bulletDFrame, #1, #BULLET_ANIM_DIVIDER, EmptyFunc
  LDA bulletFrame
  CMP #BULLET_ANIM_FRAMES
  BNE ubaSprite
  LDA #0
  STA bulletFrame
ubaSprite:
  CLC
  ADC #SPNAME_BULLET
  STA spriteBullet + 1
  RTS
  
UpdateExplosion:
  _AddFraction explFrame, explDFrame, #1, #BULLET_EXPL_DIVIDER, EmptyFunc
  LDA explFrame
  CMP #BULLET_EXPL_FRAMES
  BEQ ueEnd
  CLC
  ADC #SPNAME_EXPL
  STA spriteBullet + 1
  RTS
ueEnd:
  LDA #$FF
  STA spriteBullet
  LDA #STATE_UPDATE_MAP
  STA currentState
  RTS
  
SwitchPlayer:
  LDA currentPlayer ; switch player
  CLC
  ADC #1
  AND #1
  STA currentPlayer
  RTS
  
CheckContinueGame:
  LDA score0
  CMP #5
  BEQ ccgEndOfGame
  LDA score1
  CMP #5
  BEQ ccgEndOfGame
  LDA #STATE_INIT
  STA currentState
  RTS
ccgEndOfGame:
  LDA #STATE_WINNER
  STA currentState
  RTS
  
UpdateWinnerAnim:
  _AddFraction winnerAnimFrame, winnerAnimDFrame, #1, #WINNER_ANIM_DIVIDER, EmptyFunc
  LDA winnerAnimFrame
  CMP #WINNER_ANIM_FRAMES
  BEQ uwaResetGame
  CLC
  AND #1
  ADC #BGATTR_HUD
  STA var
  ASL A
  ASL A
  ADC var
  ASL A
  ASL A
  ADC var
  ASL A
  ASL A
  ADC var
  _FillArrayA bgAttrtable + #SCR_TILEW*2/1, #SCR_TILEW*4/16  ; Fill four rows
  JSR LoadAttrTable
  RTS
uwaResetGame:
  JSR ResetGame
  RTS
  
;==================== Interrupt functions ==============================;
RESET:
  LDX #$FF
  TXS          ; Set up stack
  JSR ResetGame
infiniteloop:
  JMP infiniteloop
  
; ====================

NMI:
  LDA #$00        ; tell the PPU there is no background scrolling
  STA $2005
  STA $2005  
  ; game logic
  LDA currentState
  CMP #STATE_INIT
  BEQ StateInit
  CMP #STATE_CONTROL
  BEQ StateControl
  CMP #STATE_BULLET_FLIGHT
  BEQ StateBulletFlight
  CMP #STATE_BULLET_EXPL
  BEQ StateBulletExplosion
  CMP #STATE_UPDATE_MAP
  BEQ StateUpdateMap
  CMP #STATE_WINNER
  BEQ StateWinner
  JMP EndOfGameStates
StateInit:
  JSR InitDativePosition
  JMP EndOfGameStates
StateControl:
  JSR HandleInput
  JMP EndOfGameStates
StateBulletFlight:
  JSR UpdateBulletPosition
  JSR UpdateBulletAnim
  JMP EndOfGameStates
StateBulletExplosion:
  JSR UpdateExplosion
  JMP EndOfGameStates
StateUpdateMap:
  JSR DisableRendering
  JSR PrepareMap
  JSR PrepareHud
  JSR LoadBackground
  JSR SwitchPlayer
  JSR CheckContinueGame
  JSR InitRendering
  JMP EndOfGameStates
StateWinner:
  JSR UpdateWinnerAnim
EndOfGameStates:
  ; update graphics
  JSR LoadSpritesDMA  
  RTI 
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Game content and other data 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
  
  .bank 3
  .org $E000
  .include "data.asm"
  
  .org $FFFA     ; first of the three vectors starts here
  .dw NMI
  .dw RESET
  .dw 0          ; external interrupt IRQ
  
  
;;;;;;;;;;;;;;;;;;;;;;;;
; PRG content
;;;;;;;;;;;;;;;;;;;;;;;;  
  
  .bank 4
  .org $0000
  .incbin "towers.chr"   ;includes 8KB graphics file from SMB1