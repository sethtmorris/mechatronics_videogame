'Names

'TO DO 02/26 : (1) finish mechatronics forest + all animation / mechanics concerning; (2) debug positions of sprites during selection; (3) add falling projectile; (4) animate NPC legs
'BIG CAVEAT TO ALL FURTHER WORK : we are OUT. OF. COGS. no animation / further movement can take place without freeing up a cog or two ... may make NPC leg animation impossible

CON
  _xinfreq=6_250_000
  _clkmode=xtal1+pll16x

  'NES Controller interface pins
  clk=4
  latch=5    
  data1=6           
  data2=7                         

'Sprite Number Shorthands                             
  Propeller=6               'Propeller hat
  RobotHL = 2               'Different sprites for Chomper H - head, L-legs
  RobotHR = 3
  RobotLL = 4
  RobotLR = 5
  Laser=8                   'Chomper's Laser
  player_top = 0            'Chosen player's top sprite
  player_bottom = 1         'Chosen player's bottom sprite
  BG1  = 9                  'Set of big Garner sprites  
  BG2  =10
  BG3  =11
  BG4  =12
  BG5  =13
  BG6  =14
  BG7  =15
  BG8  =16
  BG9  =17
  BG10 =18
  BG11 =19
  BG12 =20
  BG13 =22
  BG14 =23
  BG15 =24
  BGMouthAlt = 30          'Alternate mouth for speaking                
  LGarnerHead =25          'Little Garner head and leg sprites
  LGarnerLegs =26          
  static_discharge_1 =27   'Garner's static discharge sprites
  static_discharge_2 =28
  static_discharge_3=29
  off = 450 'coordinate that is off the screen

OBJ
  gd : "GD_ASM_v4"                                  'Include the external "GD_ASM_v4" object so that your code can call its methods using gd.<method name>

VAR
  byte collisions[256], OldChar[12]  'Reserve 256 bytes to store sprite collision data and 12 bytes to temporarily store background characters when displaying up to 12-digit numbers over top of them (so that they can be redrawn if the number gets smaller and takes up fewer decimal places)                        
  byte C1buttons, C2buttons 'NES controller button states
  long x, y, y_min, player_rot 'vars for player position and rotation
  long x_p,y_p 'vars for propeller position
  byte count,lives  'count is how many propellers have been collected, lives is number of lives left
  long laser_x,laser_y  'coordinates of the chomper's laser
  long chomp_x, chomp_y, ChompRot,nu 'chomper position coodinates, rotation, and whether it is going left or right (nu =1 if going left and 2 if right)
  long lgarner_x, lgarner_y   'Little Garner's x and y position
  byte lgarner_dir  'Direction little garner is going
  byte alt1LGarnerLegs, alt2LGarnerLegs, lGarnerMvmt  'used for Little Garner's motion
  byte TPlayer, BPlayer, Alt1Player, Alt2Player, feet 'Sprite image shorthands for player : diff. from Demo prgm
  long Stack1[100],Stack2[100],Stack3[100],Stack4[100],Stack5[100],Stack6[100]   'Reserve 100 longs for extra cogs to use as scratchpad RAM (100 longs is usually a good amount). You should always reserve 100 longs of stack space for every new cog that you start.         
  byte jump, mvmt, static 'flag variables for player jumping, player movement, and first run through game, respectively
  long bg_x, bg_y,mouth                                      'Coordinates of Big Garner and current mouth sprite
  long sdx1, sdx2, sdx3, sdy1, sdy2, sdy3               'static discharge position variables          
  byte easter   'if the character activates the easter egg (initially false)
  byte bgline   'flag for garner talking
  byte rhr, rll, rlr
  long lgarner_rbound, lgarner_lbound
  long deathy    
                  
PUB Main 
  gd.start(7)                                                       'Starts Gameduino assembly program on Cog 7 and resets the Gamduino's previous RAM values
  dira[clk..latch]~~                                                'Sets I/O directions of NES Controllers' clock and latch interface pins to be outputs
  
  repeat
    Intro              'Intro Sequence
    SelectCharacter    'Character Selection                                                            
    Background         'Background Drawing
    RunGame            'Gameplay                                             
    Winning            'Win Conditions
  
PUB Intro
  'bg_x :=200
  'bg_y :=200
  'PlaceBigGarner
  'gd.putstr(15,10,string("Story")) 
  'waitcnt(clkfreq*5 + cnt)
  'bg_x :=300
  'bg_y :=300
  'PlaceBigGarner 'Move out of the way.

PUB RunGame

  lives := 6 'initialize lives

  'Player Initial Position
  x := 200
  y := 150   
  y_min :=266

  'Propeller Initial Position
  x_p :=5
  y_p :=250

  deathy := y_min

  Move(Propeller,2,8,x_p,y_p)   'Initial position of the propeller hat 
  count:= 1 'Propeller is on level 1
  
  chomp_x :=200
  chomp_y :=185
  laser_x :=385
  laser_y :=chomp_y-16
  nu := 2 'Initialize Chomper

  'initialize little Garner
  lgarner_x := 200
  lgarner_y := 25
  lgarner_rbound := 230
  lgarner_lbound := 149     
  lgarner_dir := 1
  alt1LGarnerLegs := 4
  alt2LGarnerLegs := 5                             
  
  'Player "falls" downscreen at beginning of game
  repeat until y == y_min
    waitcnt(clkfreq/75 + cnt)
    y := y +1
    Move(0,0,TPlayer,x,y-16)
    Move(1,0,BPlayer,x,y)

  'Intialize Flags
  mvmt := false
  jump := false
  static := false
  easter := false
  bgline := -1
 
  rhr := 1
  rll := 2
  rlr := 3
  
  coginit(1, animate_player,@Stack1)   'Run player animation on cog 1
  coginit(2, animate_chomper,@Stack2)      'Run player jumping on cog 2
  coginit(3, ChomperMotion,@Stack3)    'Run robot chomper on cog 3
  coginit(4, ChomperLaser,@Stack4)     'Run the robot's laser beam on cog 4
  coginit(5, LittleGarnerMotion,@Stack5) 'Run little garner on cog 5.
  coginit(6, StaticDischarge,@Stack6)

  repeat until (count => 15 or lives =< 0)                            'Main loop
    UpdateAll
    gd.putstr(0,0,string("Health"))
    gd.putstr(7,0,string("      "))  'Actual health bar (For some reason doesn't show up unless this is here)
    CheckLives   
    
    'Checks collisions between propeller hat and player, repositions propeller up one level       
    if CheckCollision(player_bottom,Propeller) or CheckCollision(player_top,Propeller)
      count:=count+1
      case count
        2:
          x_p := 215
          y_p :=y_p-40
        3:
          x_p := 350
          y_p :=y_p-40
        4:
          x_p := 175
          y_p :=y_p-40
        5:
          x_p := 10
          y_p :=y_p-40
        6:
          x_p := 260
          y_p :=y_p-40
        7:
          x_p := 5
          y_p :=y_p-40
        10:
          x_p := 10
          y_p := 125
        11:
          x_p := 275
          y_p := 175
        12:
          x_p := 100
          y_p := 200
        13:
          x_p := 250
          y_p := 150
        14:
          x_p := 170
          y_p := 175

   'Checks collisions between Chomper and Player, repositions player at beginning, docs a life    
    CheckCollisionChomper(player_top,player_bottom)

    'Checks collisions between Laser and Player, repositions player at beginning, docs a life
    if CheckCollision(player_bottom,Laser) or CheckCollision(player_top,Laser)
      Death

    'Checks collisions between Little Garner and Player, repositions player at beginning, docs a life
    if CheckCollision(player_top,LGarnerLegs) or CheckCollision(player_top,LGarnerHead) or CheckCollision(player_bottom,LGarnerLegs) or CheckCollision(player_bottom,LGarnerHead)
      Death
      lives :=lives-1

    'Checks collisions between Static Discharge and Player, repositions player at beginning, docs a life
    if CheckCollision(player_bottom,static_discharge_3) or CheckCollision(player_top,static_discharge_3)
      Death

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
        if (GetCharacterXY(x+8,y+16)== 26) or ( GetCharacterXY(x+8,y+16)== 22) or ( GetCharacterXY(x+8,y+16)== 18)  or ( GetCharacterXY(x+8,y+16)== 19)
          jump := true
      %1111_0101 :    'Up and to the Left
        if (GetCharacterXY(x+8,y+16)== 26) or ( GetCharacterXY(x+8,y+16)== 22) or ( GetCharacterXY(x+8,y+16)== 18)  or ( GetCharacterXY(x+8,y+16)== 19)
          jump := true
        player_rot:=2    
        x := x-1
        mvmt := true     
      %1111_0110 :       'Up and to the Right
        if (GetCharacterXY(x+8,y+16)== 26) or ( GetCharacterXY(x+8,y+16)== 22) or ( GetCharacterXY(x+8,y+16)== 18)  or ( GetCharacterXY(x+8,y+16)== 19)
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
    Move(Propeller,2,8,x_p,y_p) 

    UpdateChomper
    UpdateLittleGarner
    update_static
    PlaceBigGarner
    MechatronicsForest                         'Checks if drawing mechatronics forest
    GarnerText

PUB MechatronicsForest
  if count == 8       
     'Moves the propeller, laser and chomper off of the screen
     chomp_x := off
     chomp_y := off
     laser_x :=off 
     laser_y :=off
     x_p := 50
     y_p := 200     
     lgarner_y := y_min - 8
     lgarner_x := 150
     lgarner_rbound := 399
     lgarner_lbound := 3
     deathy := 75         
     cogstop(3)
     cogstop(4)     
     cogstop(6)
     coginit(3,MoveMouth,@Stack3)
     coginit(4,toggle_text,@Stack4)   

     MechatronicsForestBackground             'change the background to the mechatronics forest
     Move(Propeller,2,8,x_p,y_p)     'Moves the propeller off the screen
     'Move(laser,1,15,500,500)       'No lasers in the mechatronics forest!
     bg_x :=20                      'sets coordinates and places big Garner on the screen
     bg_y :=36
     PlaceBigGarner
     gd.putstr(0,2,string("Welcome to the"))
     gd.putstr(0,3,string("Mechatronics Forest!"))
     count := 9
  if C1buttons == %1111_1011      'If the player is standing in a certain spot and hits the down button  
    easter := true
         
'----------------------CHARACTER CODE-------------------------------------
PUB GarnerText
'puts garners lines onscreen based on toggle_text method   
  case bgline
    0:
      gd.putstr(10,5,string("Mechatronics IS the future!"))      
    1:
      gd.putstr(10,5,string("Computers ARE NOT a fad!   "))
    2:
      gd.putstr(10,5,string("They count in CIRCLES!     "))
    3:
      gd.putstr(10,5,string("Arduino sux hehe           "))
    4:
      gd.putstr(10,5,string("I <3 T-Swift! Hear me sing!"))
    5:
      gd.putstr(10,5,string("I stay out too late        "))
    6:
      gd.putstr(10,5,string("got nothin in my brain     "))
    7:
      gd.putstr(10,5,string("Thats what ppl say, mmmhmmm"))
    8:
      gd.putstr(10,5,string("Thats what ppl say, mmmhmmm"))
    9:
      gd.putstr(10,5,string("Thanks for listening!      "))         
             
PUB toggle_text
'toggles garner's lines
  repeat
    bgline := 0
    waitcnt(clkfreq*3+cnt)
    bgline := 1
    waitcnt(clkfreq*3+cnt)
    bgline := 2
    waitcnt(clkfreq*3+cnt)
    bgline := 3
    waitcnt(clkfreq*3+cnt)
    if easter
      bgline := 4
      waitcnt(clkfreq*3+cnt)
      bgline := 5
      waitcnt(clkfreq*3+cnt)
      bgline := 6
      waitcnt(clkfreq*3+cnt)
       bgline := 7
      waitcnt(clkfreq*3+cnt)
      bgline := 8
      waitcnt(clkfreq*3+cnt)
      bgline := 9
      easter := false
      waitcnt(clkfreq*3+cnt)
PUB UpdateLittleGarner
'Updates Little Garner Character

  Move(LGarnerHead, 2, 0, lgarner_x, lgarner_y-16)
  Move(LGarnerLegs, 2, 1, lgarner_x, lgarner_y)
  
  if lgarner_x == lgarner_lbound or lgarner_x == lgarner_rbound
    if lgarner_x == lgarner_lbound
      static := true
    if lgarner_dir == 2
      Rotate(LGarnerHead, 0)
      Rotate(LGarnerLegs, 0)
    elseif lgarner_dir == 1
      Rotate(LGarnerHead, 2)
      Rotate(LGarnerLegs, 2)   

PUB update_static

  Move(static_discharge_1, 2, 12, sdx1, sdy1)
  Rotate(static_discharge_1,2)
  Move(static_discharge_2, 2, 14, sdx2, sdy2)
  Rotate(static_discharge_2,2)
  Move(static_discharge_3, 2, 15, sdx3, sdy3)
  Rotate(static_discharge_3,2)

PUB UpdateChomper

  if nu == 1      'If the chomper is moving to the left
    RotateChomper
    Move(RobotHL,1,0,chomp_x,chomp_y-16)
    Move(RobotHR,1,rhr,chomp_x-16,chomp_y-16)
    Move(RobotLL,1,rll,chomp_x,chomp_y)
    Move(RobotLR,1,rlr,chomp_x-16,chomp_y)
  elseif nu == 2      'If the chomper is moving to the right
    RotateChomper
    Move(RobotHL,1,0,chomp_x,chomp_y-16)
    Move(RobotHR,1,rhr,chomp_x+16,chomp_y-16)
    Move(RobotLL,1,rll,chomp_x,chomp_y)
    Move(RobotLR,1,rlr,chomp_x+16,chomp_y)
    
  if chomp_x ==382 OR chomp_x ==178   'If the chomper hits a wall
    RotateChomper

PUB animate_chomper

  repeat
    rhr := 4
    rll := 5
    rlr := 6
    waitcnt(clkfreq/10 + cnt)
    rhr := 1
    rll := 2
    rlr := 3
    waitcnt(clkfreq/10 + cnt)
      
    
PUB PlaceBigGarner 'Allows big Garner to easily change position
  Move(BG1,3,0,bg_x,bg_y)
  Move(BG2,3,1,bg_x+16,bg_y)
  Move(BG3,3,2,bg_x+32,bg_y)      
  Move(BG4,3,3,bg_x,bg_y+16)      
  Move(BG5,3,4,bg_x+16,bg_y+16)
  Move(BG6,3,5,bg_x+32,bg_y+16)   
  Move(BG7,3,6,bg_x,bg_y+32)      
  Move(BG8,3,7,bg_x+16,bg_y+32)
  Move(BG9,3,8,bg_x+32,bg_y+32)
  Move(BG10,3,9,bg_x,bg_y+48)
  Move(BG11,3,mouth,bg_x+16,bg_y+48)
  Move(BG12,3,11,bg_x+32,bg_y+48)
  Move(BG13,3,12,bg_x,bg_y+64)
  Move(BG14,3,13,bg_x+16,bg_y+64)
  Move(BG15,3,14,bg_x+32,bg_y+64)
  
PUB RotateChomper 'if n is 1 then the chomper is going left, if n is 2 the chomper is going right
  if nu == 1
    Rotate(RobotHR, 2)
    Rotate(RobotHL, 2)
    Rotate(RobotLL, 2)
    Rotate(RobotLR, 2)                 
  elseif nu == 2
    Rotate(RobotHR, 0)
    Rotate(RobotHL, 0)
    Rotate(RobotLL, 0)
    Rotate(RobotLR, 0)
  
'------------------------------LOGIC-------------------------------
PUB gravity(xcord, ycord)
  'Implements gravity for a sprite at position xcord, ycord  
  if (GetCharacterXY(xcord+8,ycord+16)<> 26) and ( GetCharacterXY(xcord+8,ycord+16)<> 22) AND ( GetCharacterXY(xcord+8,ycord+16)<> 18)  AND ( GetCharacterXY(xcord+8,ycord+16)<> 19)
    ycord := ycord+1
  return ycord
   
PUB xboundaries(xcord)
  'Implements x-boundaries for a sprite at position xcord 
  if xcord > 390
    xcord := 390
  elseif xcord < 1
    xcord := 1
  return xcord

PUB Winning 
  'Displayed if win conditions satisfied
  cogstop(1)
  cogstop(2)
  cogstop(3)
  cogstop(4)
  cogstop(5)
  cogstop(6)
  repeat until (C1buttons == %0111_1111)  'Runs until A button pressed
    UpdateAll
    if lives =< 0
      gd.putstr(22,0,string("YOU LOST!"))
      gd.putstr(22,1,string("Press A to Play Again."))
    else
      gd.putstr(22,0,string("YOU WON!!!!"))
      gd.putstr(22,1,string("Press A to Play Again."))
      
  waitcnt(clkfreq/10 + cnt)

PUB CheckCollisionChomper(SpriteT, SpriteB)
  if CheckCollision(SpriteB,RobotHL) or CheckCollision(SpriteB,RobotLR) or CheckCollision(SpriteB,RobotLL) or CheckCollision(SpriteB,RobotHR)
    Death 
  if CheckCollision(SpriteT,RobotHL) or CheckCollision(SpriteT,RobotLR) or CheckCollision(SpriteT,RobotLL) or CheckCollision(SpriteT,RobotHR)
    Death

PUB Death
  x := 200
  y := deathy 
  Flash(5)
  lives := lives-1
  Move(0,0,player_top,x,y-16)
  Move(1,0,player_bottom,x,y)

PUB CheckLives | i
    if lives <> 0                     
      repeat i from 7 to (6+lives)
        Draw(0,3,i,0)
  
PUB Flash(numFlashes)
  repeat until numFlashes=<0
    Move(0,0,TPlayer,x,y-16)
    Move(1,0,BPlayer,x,y)
    waitcnt(clkfreq/10+cnt)
    Move(0,0,TPlayer,off,off)
    Move(1,0,BPlayer,off,off)
    waitcnt(clkfreq/10+cnt)
    numFlashes :=numFlashes-1

PUB SelectCharacter | i, j, k
'Character Selection Method, runs before start of main game

'Draw Background
  repeat j from 0 to 37
    repeat i from 0 to 49
      Draw(0,0,i,j)
      
  x_p := off
  y_p := off
  sdx1 :=off
  sdx2 := off
  sdx3 :=off
  sdy1 :=off
  sdy2 :=off
  sdy3 :=off
  laser_x := off
  chomp_x := off
  lgarner_x := off
  bg_x := off
  bg_y := off
  PlaceBigGarner
  Move(Propeller,2,8,x_p,y_p)
  Move(laser,1,15,laser_x,laser_y)
  UpdateChomper
  UpdateLittleGarner
  update_static    
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
    gd.putstr(15,0,string("  Select a Character!"))
    gd.putstr(15,1,string("Use Up / Down to Toggle."))
    gd.putstr(15,2,string("  Press A to Select."))  
     
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

'----------------------------CHARACTER MOTION--------------------------------- 
PUB MoveMouth
  repeat
   mouth:=10
   waitcnt(clkfreq/6+cnt)
   mouth:=15
   waitcnt(clkfreq/6+cnt)
    
PUB ChomperMotion                                  'Separate COG
  repeat
    repeat until chomp_x=>382
      chomp_x:=chomp_x+2
      waitcnt(clkfreq/12+cnt)
      nu := 2
    repeat until chomp_x=<176
      chomp_x:=chomp_x-2 
      waitcnt(clkfreq/12+cnt)
      nu := 1
      
PUB ChomperLaser
'Controls the Chomper Laser, designed to be run on seperate cog
  repeat
    laser_y := 170
    if nu == 1
      laser_x := chomp_x-16
      repeat until laser_x =< 0
        laser_x := laser_x - 10
        waitcnt(clkfreq/20+cnt)
    elseif nu == 2
      laser_x := chomp_x+16
      repeat until laser_x => 385
        laser_x := laser_x + 10       
        waitcnt(clkfreq/20+cnt)
    laser_x := off
    waitcnt(clkfreq/3+cnt)
       
PUB LittleGarnerMotion
'Controls Little Garner Motion, designed to be run on seperate cog
  repeat
    repeat until lgarner_x => lgarner_rbound
      lgarner_dir := 1
      lgarner_x := lgarner_x+3
      waitcnt(clkfreq/11+cnt)
    repeat until lgarner_x =< lgarner_lbound
      lgarner_dir := 2  
      lgarner_x := lgarner_x-3
      waitcnt(clkfreq/11+cnt)
      
PUB StaticDischarge
'Implements Little Garner's Static Discharge, designed to be run on seperate cog
  repeat
    if static
      sdx1 := lgarner_x - 16
      sdy1 := lgarner_y
      sdx2 := lgarner_x - 32
      sdy2 := lgarner_y
      sdx3 := lgarner_x - 48
      sdy3 := lgarner_y
      waitcnt(clkfreq/3+cnt)
      sdx1 := 400
      sdx2 := 400
      sdx3 := 400
      static := false
         

PUB animate_player
  'Implements animation for player character legs/ jumping, designed to be run on seperate cog
  repeat
    if BPlayer == feet and mvmt
      BPlayer := Alt2Player
      waitcnt(clkfreq/10+cnt)
      mvmt := 0
    if BPlayer == Alt2Player
      BPlayer := feet
      waitcnt(clkfreq/10+cnt)

    if jump
      repeat 36
        y := y-2
        waitcnt(clkfreq/100 + cnt)
      jump := 0


'------------------------------------------ DRAW BACKGROUND --------------------------------------------
PUB Background | i,j,k,spacing                                    'Note that i,j,k are declared as local variables for use within this method. Local variables are always 32-bit longs.
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
        
  spacing:=5                 'The spacing between the levels
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

PUB MechatronicsForestBackground | i,j
'Draw the ground
  j :=35
  repeat j from 35 to 37     'Draw underground
    repeat i from 0 to 49
        Draw(0,19,i,j)
  repeat i from 0 to 49      'Draw grassy top ground
    Draw(0,18,i,34)
  repeat j from 0 to 33     'Fill in the sky
    repeat i from 0 to 49
        Draw(0,4,i,j)

  'Draw the sun
  repeat j from 2 to 5
    repeat i from 43 to 46
      Draw(0,5,i,j)
  Draw(0,5,42,6)    'Bottom Left diagonal ray
  Draw(0,5,41,7)
  Draw(0,5,40,8)

  Draw(0,5,45,6)    'Bottom Ray
  Draw(0,5,45,7)
  Draw(0,5,45,8)
  
  Draw(0,5,45,1)    'Top Ray
  Draw(0,5,45,0)
  
  Draw(0,5,47,6)    'Bottom Right diagonal ray
  Draw(0,5,48,7)
  Draw(0,5,49,8)

  Draw(0,5,47,1)    'Top Right diagonal ray
  Draw(0,5,48,0)

  Draw(0,5,42,1)    'Top Left diagonal ray
  Draw(0,5,41,0)

  Draw(0,5,47,3)    'Right Ray
  Draw(0,5,48,3)
  Draw(0,5,49,3) 

  Draw(0,5,42,3)    'Left Ray
  Draw(0,5,41,3)
  Draw(0,5,40,3)

  'Draws three trees
  DrawTree(10,34)
  DrawTree(22,34)
  DrawTree(40,34)                  



PUB DrawTree(xcoord, ycoord) | i,j
  repeat i from xcoord to xcoord+2     'Draw trunk
    repeat j from ycoord to ycoord-17
      Draw(0,19,i,j)
      
  Draw(0,12,xcoord+3,ycoord-3)    'Right diagonal branch
  Draw(0,12,xcoord+4,ycoord-5)
  Draw(0,12,xcoord+5,ycoord-6)
  Draw(0,12,xcoord+6,ycoord-7)
  Draw(0,12,xcoord+7,ycoord-8)
  
  Draw(0,12,xcoord+3,ycoord-6)    'Right diagonal branch
  Draw(0,12,xcoord+4,ycoord-7)
  Draw(0,12,xcoord+5,ycoord-8)
  Draw(0,12,xcoord+6,ycoord-9)
  Draw(0,12,xcoord+7 ,ycoord-10)

  Draw(0,12,xcoord+3,ycoord-10)    'Right diagonal branch
  Draw(0,12,xcoord+4,ycoord-11)
  Draw(0,12,xcoord+5,ycoord-12)
  Draw(0,12,xcoord+6,ycoord-13)

  Draw(0,12,xcoord+3,ycoord-14)    'Right diagonal branch
  Draw(0,12,xcoord+4,ycoord-15)
  Draw(0,12,xcoord+5,ycoord-16)

  Draw(0,12,xcoord+3,ycoord-16)    'Right diagonal branch
  Draw(0,12,xcoord+4,ycoord-17) 
  
  Draw(0,12,xcoord-1,ycoord-3)     'Left diagonal branch
  Draw(0,12,xcoord-2,ycoord-4)
  Draw(0,12,xcoord-3,ycoord-5)
  Draw(0,12,xcoord-4,ycoord-6)
  Draw(0,12,xcoord-4,ycoord-7)

  Draw(0,12,xcoord-1,ycoord-8)     'Left diagonal branch
  Draw(0,12,xcoord-2,ycoord-9)
  Draw(0,12,xcoord-3,ycoord-10)
  Draw(0,12,xcoord-4,ycoord-11)
  
  Draw(0,12,xcoord-1,ycoord-12)    'Left diagonal branch
  Draw(0,12,xcoord-2,ycoord-13)
  Draw(0,12,xcoord-3,ycoord-14)
  
  Draw(0,12,xcoord-1,ycoord-15)    'Left diagonal branch
  Draw(0,12,xcoord-2,ycoord-16)
  Draw(0,12,xcoord-3,ycoord-17)

  Draw(0,12,xcoord+1,ycoord-18)    'Top Branch
  Draw(0,12,xcoord+1,ycoord-19)
  Draw(0,12,xcoord+1,ycoord-20)

  Draw(0,12,xcoord,ycoord-17)      'Top Branch
  Draw(0,12,xcoord-1,ycoord-18)
  Draw(0,12,xcoord+2,ycoord-17)
  Draw(0,12,xcoord+3,ycoord-18)

  
    
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