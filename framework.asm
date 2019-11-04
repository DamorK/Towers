InitRendering:
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA PPU_CTRL
  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA PPU_MASK
  RTS
  
;==============
  
DisableRendering:
  LDA #$00
  STA PPU_CTRL
  STA PPU_MASK
  RTS

;==============
  
WaitVBlank:
  BIT PPU_STATUS
  BPL WaitVBlank
  RTS

;==============

LoadPalettes:                 ; send palettes from PRG to PPU memory
  LDA PPU_STATUS              ; read PPU status to reset the high/low latch
  _SendWord PPU_DSTADDR, PPUADDR_PALETTES
  _SendArray PPU_DATA, Palettes, #$20
  RTS
  
;===============

LoadSpritesDMA:      ; load 256 sprites' data from RAM to PPU using DMA
  LDA #LOW(CPUADDR_SPRITES)
  STA DMA_LOWADDR
  LDA #HIGH(CPUADDR_SPRITES)
  STA DMA_HIGHADDR
  RTS  
  
;==============

LoadBackground:
  LDA PPU_STATUS        ; read PPU status to reset the high/low latch
  _SendWord PPU_DSTADDR, #PPUADDR_BGNAME0
  _SendMatrix PPU_DATA, bgNametable, #SCR_TILEW, #SCR_TILEH
  LDA PPU_STATUS        ; read PPU status to reset the high/low latch
  _SendWord PPU_DSTADDR, #PPUADDR_BGATTR0
  _SendArray PPU_DATA, bgAttrtable, #SCR_ATTRTABLESIZE
  RTS
  
;==============

LoadAttrTable:
  LDA PPU_STATUS        ; read PPU status to reset the high/low latch
  _SendWord PPU_DSTADDR, #PPUADDR_BGATTR0
  _SendArray PPU_DATA, bgAttrtable, #SCR_ATTRTABLESIZE
  RTS

;==============

ReadControllers:    ; load controllers' data to buttonsX variables
  LDX #$01          ; send sequence [1,0] to CTR_PLAYER0 port
  STX CTR_PLAYER0
  DEX
  STX CTR_PLAYER0
  STX buttons0
  STX buttons1
  LDX #$08          ; read state of 8 buttons [A,B,Select,Start,Up,Down,Left,Right]
readCtrLoop:
  LDA CTR_PLAYER0   ; read player0
  LSR A
  ROL buttons0
  LDA CTR_PLAYER1   ; read player1
  LSR A
  ROL buttons1  
  DEX
  BNE readCtrLoop
  RTS