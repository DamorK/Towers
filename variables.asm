
  .rsset $0000
pointer     .rs 2
pointer2    .rs 2
var         .rs 1
ix          .rs 1
iy          .rs 1
endx        .rs 1
endy        .rs 1
ix2         .rs 1
iy2         .rs 1
  
  
  .rsset $0200
spritePlayer00  .rs 4
spritePlayer01  .rs 4
spritePlayer10  .rs 4
spritePlayer11  .rs 4
spriteDative    .rs 4
spriteBullet    .rs 4

  .rsset $0300
bgNametable .rs SCR_NAMETABLESIZE
bgAttrtable .rs SCR_ATTRTABLESIZE

height      .rs SCR_TILEW

buttons0    .rs 1
buttons1    .rs 1
buttons     .rs 1 ; temporary variable to store buttons of current player

bulletDX    .rs 1 ; delta [x,y]
bulletDY    .rs 1
bulletVX    .rs 1 ; velocity [x, y]
bulletVY    .rs 1
bulletDVY   .rs 1 ; delta velocity [y]
bulletFrame   .rs 1
bulletDFrame  .rs 1
explFrame     .rs 1
explDFrame    .rs 1
winnerAnimFrame  .rs 1
winnerAnimDFrame .rs 1

score0      .rs 1
score1      .rs 1

currentPlayer .rs 1
currentState  .rs 1
