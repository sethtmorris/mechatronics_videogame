'Names

'TO DO 02/22 : (1) chomper movement + animation + collisions; (2) everything with little garner; (3) everything with a possible projectile; (4) everything with a 4th NPC (another chomper?);
  '(5) death + lives + scorekeeping;(6) debug winning / game restart conditions; (7) animate / spice up intro / end screens (optional?)

CON
  _xinfreq=6_250_000
  _clkmode=xtal1+pll16x

  'NES Controller interface pins
  clk=4
  latch=5    
  data1=6           
  data2=7                         

'Sprite Number Shorthands                             
  Propeller=6
  RobotHL=2
  RobotHR = 3
  RobotLL=4
  RobotLR=5
  Laser=8
  player_top = 0
  player_bottom = 1                                           

OBJ
  gd : "GD_ASM_v4"                                  'Include the external "GD_ASM_v4" object so that your code can call its methods using gd.<method name>

VAR

  byte collisions[256], OldChar[12]                                'Reserve 256 bytes to store sprite collision data and 12 bytes to temporarily store background characters when displaying up to 12-digit numbers over top of them (so that they can be redrawn if the number gets smaller and takes up fewer decimal places)                        
  byte C1buttons, C2buttons 'NES controller button states
  long x, y, y_min, player_rot 'vars for player position and rotation
  long spacing  'does something with the background? only called in one method ... better as a local var?
  long x_p,y_p 'vars for propeller position
  byte count,nu,lives,laser_x,laser_y 'var for number of propellers obtained
  long chomp_x, chomp_y, ChompRot 'chomper position coodinates
  byte TPlayer, BPlayer, Alt1Player, Alt2Player, feet 'Sprite image shorthands for player : diff. from Demo prgm
  long Stack1[100],Stack2[100],Stack3[100],Stack4[100],Stack5[100],Stack6[100]   'Reserve 100 longs for extra cogs to use as scratchpad RAM (100 longs is usually a good amount). You should always reserve 100 longs of stack space for every new cog that you start.         
  byte jump, mvmt, firsttime 'flag variables for player jumping, player movement, and first run through game, respectively
                   
PUB Main 
  gd.start(7)                                                       'Starts Gameduino assembly program on Cog 7 and resets the Gamduino's previous RAM values
  dira[clk..latch]~~                                                'Sets I/O directions of NES Controllers' clock and latch interface pins to be outputs
  firsttime := 0
  
  repeat
    Intro              'Intro Sequence
    SelectCharacter    'Character Selection                                                            
    Background         'Background Drawing
    RunGame            'Gameplay                                             
    Winning            'Win Conditions
  
PUB Intro



PUB RunGame
  lives :=5
  'Player Initial Position
  x := 200
  y := 150   
  y_min :=266

  'Propeller Initial Position
  x_p :=5
  y_p :=250

  
  Move(Propeller,2,8,x_p,y_p)   'Initial position of the propeller hat
  count:= 1 'Propeller is on level 1
  
  chomp_x :=200
  chomp_y :=185
  laser_x :=385
  laser_y :=chomp_y-16
  nu:=0 'Initialize Chomper
  UpdateChomper
  Move(laser,1,15,450,450)
  
  'Player "falls" downscreen at beginning of game
  repeat until y == y_min
    waitcnt(clkfreq/75 + cnt)
    y := y +1
    Move(0,0,TPlayer,x,y-16)
    Move(1,0,BPlayer,x,y)

  'Intialize Flags
  mvmt := false
  jump := false

  if firsttime == 0
    coginit(1,animate_player,@Stack1)   'Run player animation on cog 1
    coginit(2,player_jump,@Stack2)      'Run player jumping on cog 2
    coginit(3,ChomperMotion,@Stack3)    'Run robot chomper on cog 3
    coginit(4,ChomperLaser,@Stack4)     'Run the robot's laser beam on cog 4
  repeat until count > 7                             'Main loop
    UpdateAll
           
    if CheckCollision(Bplayer,Propeller) or CheckCollision(Tplayer,Propeller) 'checks for player-propeller collision / repositions propeller
      y_p :=y_p-40
      count:=count+1
      if(count ==2)
        Move(Propeller,2,8,215,y_p)
      if(count ==3)
        Move(Propeller,2,8,350,y_p)
      if(count ==4)
        Move(Propeller,2,8,175,y_p)
      if(count ==5)
        Move(Propeller,2,8,10,y_p)
      if(count ==6)
        Move(Propeller,2,8,260,y_p)
      if(count ==7)
        Move(Propeller,2,8,5,y_p)
        
    if CheckCollision(Bplayer,RobotHL) or CheckCollision(Bplayer,RobotLR) or CheckCollision(Bplayer,RobotLL) or CheckCollision(Bplayer,RobotHR)
      lives := lives-1
      x := 200
      y := y_min
      Flash(5)
      lives :=lives-1 
      Move(0,0,TPlayer,x,y-16)
      Move(1,0,BPlayer,x,y)  
    if CheckCollision(Tplayer,RobotHL) or CheckCollision(Tplayer,RobotLR) or CheckCollision(Tplayer,RobotLL) or CheckCollision(Tplayer,RobotHR)
      x := 200
      y := y_min 
      Flash(5)
      lives := lives-1
      Move(0,0,TPlayer,x,y-16)
      Move(1,0,BPlayer,x,y) 

    case C1buttons   'Controller Input / Character Control
      %1111_1101 :   'Left Button
        x:=x-1
        player_rot:=2
        mvmt := true                                            
      %1111_1110 :   'Right Button                                             
        x:=x+1     
        player_rot:=0
        mvmt := true 
      %1111_0111 :    'Up Button
        if (GetCharacterXY(x,y+16)== 26) or ( GetCharacterXY(x,y+16)== 22) 
          jump := true
      %1111_0101 :    'Up and to the Left
        if (GetCharacterXY(x,y+16)== 26) or ( GetCharacterXY(x,y+16)== 22) 
          jump := true
        player_rot:=2    
        x := x-1
        mvmt := true     
      %1111_0110 :       'Up and to the Right
        if (GetCharacterXY(x,y+16)== 26) or ( GetCharacterXY(x,y+16)== 22) 
          jump := true
        x := x+1
        player_rot:=0
        mvmt := 1      
      '%1111_1011 :   'Down Button                                              
        'y:=y+1

    y := gravity(x,y)   'Check to see if player is standing on solid ground
    x := xboundaries(x) 'Check to see if player is hitting edge of visible screen

   'Update Player Character
    Rotate(0,player_rot) 
    Rotate(1,player_rot) 
    Move(player_top,0,TPlayer,x,y-16)
    Move(player_bottom,0,BPlayer,x,y)

    Move(laser,1,15,laser_x,laser_y)

    UpdateChomper
PUB Flash(numFlashes)
  repeat until numFlashes=<0
    Move(0,0,TPlayer,x,y-16)
    Move(1,0,BPlayer,x,y)
    waitcnt(clkfreq/10+cnt)
    Move(0,0,TPlayer,450,450)
    Move(1,0,BPlayer,450,450)
    waitcnt(clkfreq/10+cnt)
    numFlashes :=numFlashes-1
PUB UpdateChomper
  if nu ==0      'Initial position of the chomper sprite
    Move(RobotHL,1,0,chomp_x,chomp_y-16)
    Move(RobotHR,1,1,chomp_x+16,chomp_y-16)
    Move(RobotLL,1,2,chomp_x,chomp_y)
    Move(RobotLR,1,3,chomp_x+16,chomp_y)
  if nu == 1      'If the chomper is moving to the left
    RotateChomper
    Move(RobotHL,1,0,chomp_x,chomp_y-16)
    Move(RobotHR,1,1,chomp_x-16,chomp_y-16)
    Move(RobotLL,1,2,chomp_x,chomp_y)
    Move(RobotLR,1,3,chomp_x-16,chomp_y)
  if nu == 2      'If the chomper is moving to the right
    RotateChomper
    Move(RobotHL,1,0,chomp_x,chomp_y-16)
    Move(RobotHR,1,1,chomp_x+16,chomp_y-16)
    Move(RobotLL,1,2,chomp_x,chomp_y)
    Move(RobotLR,1,3,chomp_x+16,chomp_y)
    
  if chomp_x ==382 OR chomp_x ==178   'If the chomper hits a wall
    RotateChomper
 
PUB ChomperMotion
  repeat
    repeat until chomp_x=>382
      nu:=2
      chomp_x:=chomp_x+2
      waitcnt(clkfreq/12+cnt)
    repeat until chomp_x=<176
      nu:=1
      chomp_x:=chomp_x-2 
      waitcnt(clkfreq/12+cnt)
      
PUB ChomperLaser
  repeat
   ' laser_x:=chomp_x-16
    'laser_y:=450
    'if nu==1
      repeat until laser_x=<0
        laser_x:=laser_x-10
        waitcnt(clkfreq/12+cnt)
    {
    if nu==2
      repeat until laser_x=>385
        laser_x:=laser_x+10
        waitcnt(clkfreq/12+cnt)}
    waitcnt(clkfreq*10+cnt)
    
      
PUB RotateChomper 'if n is 1 then the chomper is going left, if n is 2 the chomper is going right
    if nu ==1
      Rotate(RobotHR, 2)
      Rotate(RobotHL, 2)
      Rotate(RobotLL, 2)
      Rotate(RobotLR, 2)                 
    if nu ==2
      Rotate(RobotHR, 0)
      Rotate(RobotHL, 0)
      Rotate(RobotLL, 0)
      Rotate(RobotLR, 0)
       

PUB gravity(xcord, ycord)
'Implements gravity for a sprite at position xcord, ycord

    if (GetCharacterXY(xcord+8,ycord+16)<> 26) and ( GetCharacterXY(xcord+8,ycord+16)<> 22)  
      ycord := ycord+1
    return ycord

PUB xboundaries(xcord)
'Implements x-boundaries for a sprite at position xcord

    if xcord > 390
      xcord := 390
    elseif xcord < 1
      xcord := 1
    return xcord
         
PUB player_jump
'Implements jumping for a player character, designed to be run on seperate cog

  repeat
    if jump
      repeat 36
        y := y-2
        waitcnt(clkfreq/100 + cnt)
      jump := 0

PUB Winning 
'Displayed if win conditions satisfied

  repeat until (C1buttons == %0111_1111)  'Runs until A button pressed
    UpdateAll
    gd.putstr(22,0,string("YOU WON!!!!"))
    gd.putstr(22,1,string("Press A to Play Again."))
  firsttime := firsttime + 1
  waitcnt(clkfreq/10 + cnt)

PUB animate_player
'Implements animation for player character legs, designed to be run on seperate cog

  repeat
    if BPlayer == feet and mvmt
      BPlayer := Alt2Player
      waitcnt(clkfreq/10+cnt)
      mvmt := 0
    if BPlayer == Alt2Player
      BPlayer := feet
      waitcnt(clkfreq/10+cnt)
  

PUB SelectCharacter | i, j, k
'Character Selection Method, runs before start of main game

'Draw Background
  repeat j from 0 to 37
    repeat i from 0 to 49
      Draw(0,0,i,j)
      
  'Location of Sprites During Selection
  x := 200
  y := 150

  'Initial Sprite Values
  TPlayer := 0
  BPlayer := 1

  UpdateAll

  repeat until (C1buttons == %0111_1111)                'repeats until A button pushed
    UpdateAll
    
    'Display Text
    gd.putstr(22,0,string("Select a Character!"))
    gd.putstr(22,1,string("Use Up / Down to Toggle."))
    gd.putstr(22,2,string("Press A to Select."))  
     
    case C1buttons                'Toggle Sprites Based on User Input
      %1111_0111 :                'Up Button
        if TPlayer =< 8           'Keep Sprites within Range                   
          TPlayer := TPlayer + 4
          BPlayer := BPlayer + 4
      %1111_1011 :                'Down Button
        if TPlayer => 4           'Keep Sprites within Range
          TPlayer := TPlayer - 4
          BPlayer := BPlayer - 4
    waitcnt(clkfreq/7 + cnt)
    Move(player_top,0,TPlayer,x,y-16)
    Move(player_bottom,0,BPlayer,x,y)

  'Set Alternate Sprite Values
  Alt1Player := TPlayer + 2
  Alt2Player := TPlayer + 3
  feet := BPlayer        



PUB LittleGarnerMovement



PUB Background | i,j,k                                    'Note that i,j,k are declared as local variables for use within this method. Local variables are always 32-bit longs.
  'This repeat loop just sets the background to black, might not be necessary in the final run but is convenient for testing
  repeat j from 0 to 37
    repeat i from 0 to 49
      Draw(0,1,i,j)

  'Draw the ground
  j :=35
  repeat j from 35 to 36
    repeat i from 0 to 49
        Draw(0,26,i,j)
        Draw(0,26,i,j+1)
  spacing:=5
  'Level one bricks
  j :=30 
  repeat i from 5 to 20
    Draw(0,22,i,j)
  repeat i from 25 to 30
    Draw(0,22,i,j)   

  'Level two bricks
  j :=j-spacing 
  repeat i from 0 to 9
    Draw(0,22,i,j)
  repeat i from 20 to 49
    Draw(0,22,i,j)
    
  'Level three bricks
  j :=j-spacing  
  repeat i from 15 to 30
    Draw(0,22,i,j)       
  repeat i from 40 to 49
    Draw(0,22,i,j)

   'Level four bricks
  j :=j-spacing  
  repeat i from 0 to 6
    Draw(0,22,i,j)
  repeat i from 12 to 18
    Draw(0,22,i,j)
  repeat i from 30 to 40
    Draw(0,22,i,j)

   'Level five bricks
  j :=j-spacing  
  repeat i from 25 to 35
    Draw(0,22,i,j)
  repeat i from 8 to 15
    Draw(0,22,i,j)
  repeat i from 36 to 41
    Draw(0,22,i,j)
  repeat i from 47 to 49
    Draw(0,22,i,j)

   'Level six bricks
  j :=j-spacing  
  repeat i from 0 to 3
    Draw(0,22,i,j)
  repeat i from 19 to 30
    Draw(0,22,i,j)
  repeat i from 45 to 49
    Draw(0,22,i,j)
                                                                                                     


CON ''WARNING: Do NOT try to call any of the methods below from different cogs at the same time! (These ask the Gameduino driver on Cog 7 to do things, and it can only do one thing at a time and may get confused/corrupted if more than one cog tries to send commands to it at exactly the same time.)

PUB Move(SpriteNumber,SpriteSection,SpriteImage,Xposition,Yposition) | rotation, N,AB             'Move a sprite around on the screen (note that the entire screen in the Gameduino's memory is 512x512 pixels but only a 400x300 section of it is actually displayed on the monitor - depending on where you've scrolled)
  rotation:=(gd.m_rd($3000+SpriteNumber*4+1) & %0000_1110) >> 1                  'Look up this sprite's current rotation orientation in its sprite control register
  gd.sprite(SpriteNumber,Xposition,Yposition,SpriteImage+16*SpriteSection,SpriteSection,rotation,0)'Change the 32-bit control register for this sprite



PUB Rotate(SpriteNumber,rotation) | databyte
  databyte:=gd.m_rd($3000+(SpriteNumber*4)+1)
  databyte:=(databyte & %11110001) + (rotation << 1)                              'Read 2nd byte of sprite's control data and replace it's 3-bit rotation value                                         
  gd.m_wr($3000+SpriteNumber*4+1,databyte)


  
PUB CheckCollision(SpriteNumberA,SpriteNumberB) : collision | OverlappingSprite  'Returns true (-1) or false (0) depending on whether or not the two sprites are colliding      
  if SpriteNumberA>SpriteNumberB                                                 'When two sprites overlap, the Gameduino stores the number of the lower sprite in the upper sprites collision memory.                 
    OverlappingSprite:=collisions[SpriteNumberA]                                 'During the UpdateAll method, all 256 bytes of sprite collision data are transferred from the Gameduino's memory into the Propeller's "collisions" variables (a 1x256 array of bytes).      
    if OverlappingSprite==SpriteNumberB                                          'Each byte of the "collisions" varibles stores the value of the sprite that it is overlapping (colliding with).
      collision:=true
    else
      collision:=false  
  else                                                                           'If this "collisions" value is $FF, then it's not colliding with anything. 
    OverlappingSprite:=collisions[SpriteNumberB]                                 'If the value is anything else, it's the sprite number of the next sprite down in sprite numbers that it's colliding with.       
    if OverlappingSprite==SpriteNumberA                                          'For example, if Sprite#0, Sprite#1, and Sprite#2 are all overlapping/colliding, then collisions[0]=255 (since Sprite#0 is always on the bottom, it's value is always 255), collisions[1]=0 (since it's covering Sprite#0), and collisions[2]=1 (since it's covering Sprite#1 and Sprite#0, but Sprite#1 is higher numbered i.e. above or on top of Sprite#0, its value is stored)
      collision:=true
    else
      collision:=false



PUB SpriteCollision(SpriteNumber) : collision                                    'Returns the sprite number of the sprite with which the specified sprite is colliding/overlapping. 'If the specified sprite is not colliding with any other sprites, it returns the number 255 ($FF).   
  collision:=collisions[SpriteNumber]                                            'Note that if the specified sprite is overlapping more than one other sprite, only the highest number sprite's number is returned. However, you could call this method again to find out if this highest sprite was also overlapping another sprite underneath it and keep doing this until a sprite returns 255 (indicating that it isn't covering up any other sprites). 'Hint: It might be easier to make your main character(s) out of the highest sprite numbers so that these sprites will always be overlapping all of the other sprites.                      



PUB ScrollScreen(ScrollToX,ScrollToY)                                            'Moves the 400x300 visible screen "window" around in the 512x512 pixel background (default is X=0 Y=0 and max is X=111 Y=211)
  gd.m_wr16($2804,ScrollToX)
  gd.m_wr16($2806,ScrollToY)



PUB Draw(section,character,col,row)  | address                                   'Draw a character (0-255) on the screen's background
  address:=row*64+col                                                            '512x512 pixel background screen, 64x64 background characters, 1 byte per character 
  gd.m_wr(address,character+64*section) 



PUB DisplayNumber(col,row,number) | i,j,address,numberDigits,temp                'Displays a number out of characters at a specified row and column
  address:=row*64+col                                                            'Convert the column and row arguments to a usable address value

  if gd.m_rd(address+1)<48 or gd.m_rd(address+1)>57                              'If the character currently 1 space over from this row,col is not a number                           
    repeat i from 0 to 11                                                                                                               
      OldChar[i]:=gd.m_rd(address+i+1)                                           'Store the character that is currently there as OldChar                                                                  

  numberDigits~
  temp:=number
  repeat until temp/10 == 0                                                      'Retrieve the number of digits in the number
    numberDigits++
    temp/=10

  repeat i from numberDigits to 11                                               'Excluding the spaces we want to use as numbers,                                               
    Draw(0,oldChar[i],col+i+1,row)                                               'overwrite the unused spaces back to their original character values

  if number < 0                                                                 
    ||number                                                                     'If the number is negative, then
    Draw(0,"-",col,row)                                                          'put a negative sign in the first place.
    col++
  i := 1_000_000_000 
  repeat 10
    if number=>i
      Draw(0,"0"+number/i,col,row)                                               'Plot the first digit of the number,
      col++                                                                      'then increment the column value and plot the next digit.
      number:=number//i
      result~~
    elseif result or i == 1
      Draw(0,"0",col,row)
      col++                                                                     
    i:=i/10



PUB UpdateAll                                                                    'Read both NES controllers' button states, refresh collision data, and wait for video blanking to synch up with the screen's refresh
  C1buttons~
  C2buttons~
  outa[latch]~~
  C1buttons:=ina[data1]                                                          'Read in the two NES controllers' button-state bytes
  C2buttons:=ina[data2]   
  outa[latch]~
  repeat 7
    outa[clk]~~
    C1buttons:=C1buttons<<1+ina[data1]
    C2buttons:=C2buttons<<1+ina[data2] 
    outa[clk]~
  outa[clk]~~ 
  outa[clk]~

  gd.waitvblank                                                                  'Collision RAM data is only valid immediately after waiting for the vertical blanking period
  gd.load_hub($2900,@collisions,256)                                             'Loads all of the collision data from the Gameduino's collision RAM (1 byte for each sprite number, 256 bytes total) into the "collisions" array  



PUB GetSpriteX(SpriteNumber) : Xcoordinate 
  Xcoordinate:=(gd.m_rd($3001+SpriteNumber*4)<<8 + gd.m_rd($3000+SpriteNumber*4)) & %1_11111111 'Get the lower 16-bits of this sprite number's current 32-bit control value, then bitwise "and" away everything except for bits 9-0, which contain the sprite's X coordinate location        


  
PUB GetSpriteY(SpriteNumber) : Ycoordinate
  Ycoordinate:=(gd.m_rd($3003+SpriteNumber*4)<<8 + gd.m_rd($3002+SpriteNumber*4)) & %1_11111111 'Get the upper 16-bits of this sprite number's current 32-bit control value, then bitwise "and" away everything except for bits 24-16, which contain the sprite's Y coordinate location



PUB GetCharacter(col,row) : character                                            'Read and return the relative value/number of a character that has been drawn at a certain column and row on the 64 x 64 Background Character Screen
  character:=gd.m_rd(row*64+col)//64                                             'Note: This gives the character number within the Background Section (e.g. if the character is character #5 in Section 2, it simply returns 5). 



PUB GetRawCharacter(col,row) : character                                         'Read and return the value/number of a character that has been drawn at a certain column and row on the 64 x 64 Background Character Screen
  character:=gd.m_rd(row*64+col)                                                 'Note: This gives the raw character number within the Gamdeuino's character RAM (e.g. if the character is character #5 in Section 2, it returns 133 because each section is 64 characters and Section 2 starts at 128.)  



PUB GetCharacterXY(Xposition,Yposition) : character                              'Read and return the value/number of the character that lies behind a certain X and Y pixel position (i.e. the 512x512 coordinates that sprites are allowed to move through)   
  character:=gd.m_rd(Yposition/8*64+Xposition/8)//64                             'Note: This gives the character number within the Background Section (e.g. if the character is character #5 in Section 2, it simply returns 5).



PUB GetRawCharacterXY(Xposition,Yposition) : character                           'Read and return the value/number of the character that lies behind a certain X and Y pixel position (i.e. the 512x512 coordinates that sprites are allowed to move through)
  character:=gd.m_rd(Yposition/8*64+Xposition/8)                                 'Note: This gives the raw character number within the Gamdeuino's character RAM (e.g. if the character is character #5 in Section 2, it returns 133 because each section is 64 characters and Section 2 starts at 128.) 