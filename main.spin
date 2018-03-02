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
  Propeller=6                                                                   'Propeller hat
  RobotHL = 2                                                                   'Different sprites for Chomper H - head, L-legs
  RobotHR = 3
  RobotLL = 4
  RobotLR = 5
  Laser=8                                                                       'Chomper's Laser
  player_top = 0                                                                'Chosen player's top sprite
  player_bottom = 1                                                             'Chosen player's bottom sprite
  BG1  = 9                                                                      'Set of 16 big Garner sprites  
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
  BGMouthAlt = 30                                                               'Alternate mouth for speaking                
  LGarnerHead =25                                                               'Little Garner head and leg sprites
  LGarnerLegs =26          
  static_discharge_1 =27                                                        'Garner's static discharge sprites
  static_discharge_2 =28
  static_discharge_3=29
  off = 450                                                                     'Coordinate that is off the visible screen

OBJ
  gd : "GD_ASM_v4"                                                              'Include the external "GD_ASM_v4" object so that your code can call its methods using gd.<method name>

VAR
  byte collisions[256], OldChar[12]                                             'Reserve 256 bytes to store sprite collision data and 12 bytes to temporarily store background characters when displaying up to 12-digit numbers over top of them (so that they can be redrawn if the number gets smaller and takes up fewer decimal places)                        
  byte C1buttons, C2buttons                                                     'NES controller button states
  long x, y, y_min, player_rot                                                  'vars for player character position and rotation
  long x_p,y_p                                                                  'vars for propeller position
  byte count,lives                                                              'count is the level the propeller is on, lives is number of lives left
  long laser_x,laser_y                                                          'coordinates of the chomper's laser
  long chomp_x, chomp_y, ChompRot,nu                                            'chomper position coodinates, rotation, and whether it is going left or right (nu =1 if going left and 2 if right)
  long lgarner_x, lgarner_y                                                     'Little Garner's x and y position
  byte lgarner_dir                                                              'Direction little garner is going (1 for right and 2 for left)
  byte alt1LGarnerLegs, alt2LGarnerLegs, lGarnerMvmt                            'Alternate sprite legs for Little Garner's motion
  byte TPlayer, BPlayer, Alt1Player, Alt2Player, feet                           'Sprite image shorthands for player : diff. from Demo prgm
  long Stack1[100],Stack2[100],Stack3[100],Stack4[100],Stack5[100],Stack6[100]  'Reserve 100 longs for extra cogs to use as scratchpad RAM (100 longs is usually a good amount). You should always reserve 100 longs of stack space for every new cog that you start.         
  byte jump, mvmt, static                                                       'Flag variables for player jumping, player movement, and whether the static discharge is off screen respectively
  long bg_x, bg_y,mouth                                                         'Coordinates of Big Garner and current mouth sprite
  long sdx1, sdx2, sdx3, sdy1, sdy2, sdy3                                       'Static discharge position variables          
  byte easter                                                                   'If the character activates the easter egg (initially false)
  byte bgline                                                                   'Flag for garner talking
  byte rhr, rll, rlr                                                            'Chomper's alternate legs for motion
  long lgarner_rbound, lgarner_lbound                                           'Little Garner's left and right bounds for motion
  long deathy                                                                   'Y coordinate of where the player respawns when losing a life
                  
PUB Main 
  gd.start(7)                                                                   'Starts Gameduino assembly program on Cog 7 and resets the Gamduino's previous RAM values
  dira[clk..latch]~~                                                            'Sets I/O directions of NES Controllers' clock and latch interface pins to be outputs
  
  repeat
    SelectCharacter                                                             'Character Selection -- runs before game starts, allows player to choose character                                                            
    Background                                                                  'Initial "Mechatronics lab" Background Drawing
    RunGame                                                                     'Gameplay, should always be running on Cog 0                                             
    Replay                                                                      'Win Conditions, should reset the game if the player wins or loses

PUB RunGame                                                                     'Program called in main to run the game

  lives := 6                                                                    'initialize lives to 6
  
  x := 200                                                                      'Player Initial x Position, middle of the screen                           
  y := 150                                                                      'Player Initial y Position 
  y_min :=266                                                                   'Top of the base level, ground

  x_p :=5                                                                       'Propeller Initial x Position, Level 1 (count =1)
  y_p :=250                                                                     'Propeller Initial y Position, Level 1

  deathy := y_min                                                               'Player respawns at the bottom level

  Move(Propeller,2,8,x_p,y_p)                                                   'Move the propeller hat to its initial position on Level 1 
  count:= 1                                                                     'Propeller is on level 1
  
  chomp_x :=200                                                                 'Place the chomper in the middle of his platform (x coordinate)  
  chomp_y :=185                                                                 'Place the chomper standing on his platform (y coordinate)
  laser_x :=385                                                                 'Place the laser by the chomper's head (x-coordinate)
  laser_y :=chomp_y-16                                                          'Place the laser by the chomper's head (y-coordinate)
  nu := 2                                                                       'Initialize Chomper to move to the right

  lgarner_x := 200                                                              'Place Little Garner in the middle of his platform (x coordinate)
  lgarner_y := 25                                                               'Place Little Garner standing on his platform (y coordinate)
  lgarner_rbound := 230                                                         'Limit the right motion to the end of Little Garner's platform, otherwise he would be floating
  lgarner_lbound := 149                                                         'Limit the left motion to the end of Little Garner's platform
  lgarner_dir := 1                                                              'Little Garner is initially moving to the right
  alt1LGarnerLegs := 4                                                          'Initiallize the sprite number of Little Garner's alternative legs
  alt2LGarnerLegs := 5                                                          'Initiallize the sprite number of Little Garner's alternative legs
  
  'Player "falls" downscreen at beginning of game
  repeat until y == y_min                                                       'Stop when the player is on the groun level
    waitcnt(clkfreq/75 + cnt)                                                   'Pause so the player doesn't just appear on the ground instead of "falling"
    y := y +1                                                                   'Increment the y-coordinate by 1, so the player moves down the screen 
    Move(0,0,TPlayer,x,y-16)                                                    'Move the top sprite of the player
    Move(1,0,BPlayer,x,y)                                                       'Move the player's bottom sprite

  'Intialize Flags
  mvmt := false                                                                 'Player is not moving
  jump := false                                                                 'Player is not jumping
  static := false                                                               'Static discharge is not active (i.e. Little Garner is not at the left edge of his platform)
  easter := false                                                               'The player has not activated the easter egg
  bgline := -1                                                                  'No text being displayed
 
  rhr := 1                                                                      'Initiallize the first sprite value for Chomper's alternative legs
  rll := 2                                                                      'Initiallize the second sprite value for Chomper's alternative legs 
  rlr := 3                                                                      'Initiallize the third sprite value for Chomper's alternative mouth 
  
  coginit(1, animate_player,@Stack1)                                            'Run player animation on cog 1, allows player to jump and move left and right
  coginit(2, animate_chomper,@Stack2)                                           'Run animate chomper on cog 2, makes chomper look like he is walking/running and opens and closes his mouth
  coginit(3, ChomperMotion,@Stack3)                                             'Run robot chomper's motion on cog 3. He turns around when he reaches the edge of his platform
  coginit(4, ChomperLaser,@Stack4)                                              'Run the robot's laser beam on cog 4, should come out Chomper's eyes and be moving in the correct direction.
  coginit(5, LittleGarnerMotion,@Stack5)                                        'Run little garner's motion on cog 5. He should turn around when he reaches a boundary.
  coginit(6, StaticDischarge,@Stack6)                                           'Run static discharge when the x-ccordinate of Little Garner is at lgarner_lbound

  repeat until (count => 15 or lives =< 0)                                      'Main loop, repeats until the game is restarted.
    UpdateAll                                                                   'Read both NES controllers' button states, refresh collision data, and wait for video blanking to synch up with the screen's refresh 
    gd.putstr(0,0,string("Health"))                                             'Displays the word "health" on the screen right before the health bar.
    gd.putstr(7,0,string("      "))                                             'Where the health bar will display. Length of 6 characters, since lives = 6.
    CheckLives                                                                  'Checks whether the player has lost any lives and updates the health bar to the correct length if they have
    
    'Checks collisions between propeller hat and player, repositions propeller up one level       
    if CheckCollision(player_bottom,Propeller) or CheckCollision(player_top,Propeller)
      count:=count+1                                                            'The propeller is on the next level (count represents the level of the propeller chips, subtract one for number of propeller chips the player has collected)
      case count
        2:                                                                      'Each of these represents a new position for each level. The hat is repositioned up 40 pixels which will get it in the middle of each level.
          x_p := 215                                                            'The x-coordinate could not have been replaced with a random value without the risk of the propeller ending up in the air instead of on a platform, so the values are not ranomized and only work for one round.
          y_p :=y_p-40                                                          'i.e. when you replay, the propeller will always go back to the same position on each level.
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
          x_p := 200
          y_p :=y_p-40
        10:                                                                     'After count = 7, the player is in the mechatronics forest, so the rest are positioned in the trees instead of on platforms. 
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
          x_p := 170                                                            'Once the player collects the last propeller, they win the game.
          y_p := 175
     
    if CheckCollisionChomper(player_top,player_bottom)                          'Checks collisions between Chomper and Player, repositions player at beginning, docs a life 
      Death                                                                     'Death repositions the player at the bottom of the screen and docs a life, also calls the flash function so the player knows they died
      
    if CheckCollision(player_bottom,Laser) or CheckCollision(player_top,Laser)  'Checks collisions between Laser and Player, repositions player at beginning, docs a life
      Death                                                                     'Death repositions the player at the bottom of the screen and docs a life, also calls the flash function so the player knows they died

    'Checks collisions between Little Garner and Player, repositions player at beginning, docs a life
    if CheckCollision(player_top,LGarnerLegs) or CheckCollision(player_top,LGarnerHead) or CheckCollision(player_bottom,LGarnerLegs) or CheckCollision(player_bottom,LGarnerHead)
      Death                                                                     'Death repositions the player at the bottom of the screen and docs a life, also calls the flash function so the player knows they died      
      lives :=lives-1                                                           'Docs an extra life because the player ran into Garner

    'Checks collisions between Static Discharge and Player, repositions player at beginning, docs a life
    if CheckCollision(player_bottom,static_discharge_3) or CheckCollision(player_top,static_discharge_3)
      Death                                                                     'Death repositions the player at the bottom of the screen and docs a life, also calls the flash function so the player knows they died

    case C1buttons                                                              'Controller Input / Character Control
      %1111_1101 :                                                              'If the Left Button is pressed
        x:=x-1                                                                  'Move the player one pixel to the left
        player_rot:=2                                                           'Rotate so the player is facing left
        mvmt := true                                                            'Player is moving
      %1111_1110 :                                                              'If Right Button is pressed                                             
        x:=x+1                                                                  'Move the player one pixel to the right
        player_rot:=0                                                           'Rotate so the player is facing right
        mvmt := true                                                            'Player is moving
      %1111_0111 :                                                              'If Up Button is pressed
        'Checks whether the player is standing on solid ground. Has to check both backgrounds (mechatronics lab and forest)
        if (GetCharacterXY(x+8,y+16)== 26) or ( GetCharacterXY(x+8,y+16)== 22) or ( GetCharacterXY(x+8,y+16)== 18)  or ( GetCharacterXY(x+8,y+16)== 19)
          jump := true                                                          'Increments player's y value                                                                               '
      %1111_0101 :                                                              'If Up and Left buttons are pressed
        'Checks whether the player is standing on solid ground. Has to check both backgrounds (mechatronics lab and forest)
        if (GetCharacterXY(x+8,y+16)== 26) or ( GetCharacterXY(x+8,y+16)== 22) or ( GetCharacterXY(x+8,y+16)== 18)  or ( GetCharacterXY(x+8,y+16)== 19)
          jump := true                                                          'Increments player's y value
        player_rot:=2                                                           'Rotates the player to the left
        x := x-1                                                                'Moves the player to the left
        mvmt := true                                                            'Player is moving (makes legs move)
      %1111_0110 :                                                              'If Up and Right button are pressed        
        'Checks whether the player is standing on solid ground. Has to check both backgrounds (mechatronics lab and forest)
        if (GetCharacterXY(x+8,y+16)== 26) or ( GetCharacterXY(x+8,y+16)== 22) or ( GetCharacterXY(x+8,y+16)== 18)  or ( GetCharacterXY(x+8,y+16)== 19)
          jump := true                                                          'Increments player's y value
        x := x+1                                                                'Moves the player to the right
        player_rot:=0                                                           'Rotates the player to the right
        mvmt := 1                                                               'Player is moving (makes legs move)
  
    y := gravity(x,y)                                                           'Check to see if player is standing on solid ground, if not chages y coordinate
    x := xboundaries(x)                                                         'Check to see if player is hitting edge of visible screen

   'Update Player Character
    Rotate(player_top,player_rot)                                               'Rotates the player's top in the direction they are facing 
    Rotate(player_bottom,player_rot)                                            'Rotates the player's bottom in the direction they are facing
    Move(player_top,0,TPlayer,x,y-16)                                           'Updates and moves the player's top to its correct position
    Move(player_bottom,0,BPlayer,x,y)                                           'Updates and moves the player's bottom to its correct position

    Move(laser,1,15,laser_x,laser_y)                                            'Updates and moves the lasers to its correct position
    Move(Propeller,2,8,x_p,y_p)                                                 'Updates and moves the propeller to its correct position

    UpdateChomper                                                               'Updates and moves all of chomper's sprites to their correct positions
    UpdateLittleGarner                                                          'Updates and moves all of Little Garner's sprites to their correct positions
    update_static                                                               'Updates and moves all of Garner's Static Discharge sprites to their correct positions
    PlaceBigGarner                                                              'Updates and moves all of Big Garner's sprites to their correct positions
    MechatronicsForest                                                          'Checks if player has reached the top level and collected the propeller hat, if so runs mechatronics forest
    GarnerText                                                                  'Updates Garner's text

PUB MechatronicsForest                                                          'Method that runs, updates, and draws the mechatronics forest
  if count == 8                                                                 'If the player has collected the last propeller in the mechatronics lab background

     chomp_x := off                                                             'Moves laser and chomper off of the screen
     chomp_y := off
     laser_x :=off 
     laser_y :=off
     x_p := 50                                                                  'Place the propeller at the first x-coordinate in the mechatronics forest
     y_p := 200                                                                 'Place the propeller at the first y-coordinate in the mechatronics forest
         
     lgarner_y := y_min - 8                                                     'Place little garner at the correct y-coordinate
     lgarner_x := 150                                                           'Place little garner at the correct x-coordinate 
     lgarner_rbound := 399                                                      'Sets little garner's right bound at the correct x-coordinate
     lgarner_lbound := 3                                                        'Sets little garner's left bound at the correct x-coordinate 
     deathy := 75                                                               'Sets y-coordinate for respawning after death in the mechatronics forest 

     cogstop(3)                                                                 'Stop cog 3 from running chomper motion
     cogstop(4)                                                                 'Stop cog 4 from running chomper's laser motion
     cogstop(6)                                                                 'Stop cog 6 from running Little Garner's static discharge
     coginit(3,MoveMouth,@Stack3)                                               'Starts big Garner's mouth moving
     coginit(4,toggle_text,@Stack4)                                             'Allows Garner to say different things (there is a waitcnt between each text being shown)

     MechatronicsForestBackground                                               'Changes the background to the mechatronics forest
     Move(Propeller,2,8,x_p,y_p)                                                'Moves the propeller to the updated x and y coordinates for the first postion
     bg_x :=20                                                                  'Sets coordinates and places big Garner on the screen
     bg_y :=36
     PlaceBigGarner                                                             'Places all of Big Garner's sprites on the screen at the set coordinates
     gd.putstr(0,2,string("Welcome to the"))                                    'Welcomes the user to the mechatronics forest
     gd.putstr(0,3,string("Mechatronics Forest!"))
     count := 9                                                                 'Allows the player to start collecting propellers
  if C1buttons == %1111_1011                                                    'If the player hits the down button ("Arduino sux hehe" has to be on the screen too)  
    easter := true                                                              'The easter egg is activated
         
'----------------------CHARACTER CODE-------------------------------------
PUB GarnerText                                                                  'Puts garners lines onscreen based on toggle_text method   
  case bgline                                                                   'The line that is supposed to be on the screen (updated on cog 4 with toggle text)
    0:
      gd.putstr(10,5,string("Mechatronics IS the future!"))      
    1:
      gd.putstr(10,5,string("Computers ARE NOT a fad!   "))
    2:
      gd.putstr(10,5,string("They count in CIRCLES!     "))
    3:
      gd.putstr(10,5,string("Arduino sux hehe           "))
    4:
      gd.putstr(10,5,string("I <3 T-Swift! Hear me sing!"))                     'The lines below 3 will only play when easter egg is activated during line 3.
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
             
PUB toggle_text                                                                 'Toggles garner's lines, waits between each line
  repeat                                                                        'Runs forever when activated on cog 4
    bgline := 0                                                                 'Initally sets line 0 to run
    waitcnt(clkfreq*3+cnt)                                                      'Waits 3 seconds before incrementing line to the next
    bgline := 1
    waitcnt(clkfreq*3+cnt)                                                      'Waits 3 seconds before incrementing line to the next
    bgline := 2
    waitcnt(clkfreq*3+cnt)                                                      'Waits 3 seconds before incrementing line to the next
    bgline := 3
    waitcnt(clkfreq*3+cnt)                                                      'Waits 3 seconds before incrementing line to the next
    if easter                                                                   'If the easter egg is activated (i.e. the player hits the down button during line 3)
      bgline := 4                                                               'The player must activate the easter egg again for it to run more than once.
      waitcnt(clkfreq*3+cnt)                                                    'Waits 3 seconds before incrementing line to the next
      bgline := 5
      waitcnt(clkfreq*3+cnt)                                                    'Waits 3 seconds before incrementing line to the next
      bgline := 6
      waitcnt(clkfreq*3+cnt)                                                    'Waits 3 seconds before incrementing line to the next
       bgline := 7
      waitcnt(clkfreq*3+cnt)                                                    'Waits 3 seconds before incrementing line to the next
      bgline := 8
      waitcnt(clkfreq*3+cnt)                                                    'Waits 3 seconds before incrementing line to the next
      bgline := 9
      easter := false                                                           'Resets easter egg to false
      waitcnt(clkfreq*3+cnt)                                                    'Waits 3 seconds before incrementing line to the next
                                                                                
PUB UpdateLittleGarner                                                          'Updates Little Garner Character
  Move(LGarnerHead, 2, 0, lgarner_x, lgarner_y-16)                              'Moves Garners head to the x and y coordinates
  Move(LGarnerLegs, 2, 1, lgarner_x, lgarner_y)                                 'Moves Garners legs to the x and y coordinates
  
  if lgarner_x == lgarner_lbound or lgarner_x == lgarner_rbound                 'If the Little Garner has reached the bounds
    if lgarner_x == lgarner_lbound                                              'If Little Garner is at the left bound
      static := true                                                            'Turns on static discharge
    if lgarner_dir == 2                                                         'If little garner is going to the left
      Rotate(LGarnerHead, 0)                                                    'Rotate the head and legs sprites so that they are facing the correct direction (left)
      Rotate(LGarnerLegs, 0)
    elseif lgarner_dir == 1                                                     'If little Garner is going right
      Rotate(LGarnerHead, 2)                                                    'Rotate the head and leg sprites so that they are facing right
      Rotate(LGarnerLegs, 2)   

PUB update_static                                                               'Updates Garner's static discharge
                                                                                'Rotates the static discharge sprite so that its facing to the left
  Move(static_discharge_1, 2, 12, sdx1, sdy1)                                   'Moves the first of the static discharge sprites to the correct position (either on the screen or off)
  Rotate(static_discharge_1,2)                                                  'Rotates the static discharge sprite so that its facing to the left
  Move(static_discharge_2, 2, 14, sdx2, sdy2)                                   'Moves the second of the static discharge sprites to the correct position (either on the screen or off)
  Rotate(static_discharge_2,2)                                                  'Rotates the static discharge sprite so that its facing to the left
  Move(static_discharge_3, 2, 15, sdx3, sdy3)                                   'Moves the third of the static discharge sprites to the correct position (either on the screen or off)
  Rotate(static_discharge_3,2)                                                  'Rotates the static discharge sprite so that its facing to the left

PUB UpdateChomper                                                               'Updates chomper's sprite locations and directions

  if nu == 1                                                                    'If the chomper is moving to the left
    RotateChomper                                                               'Rotate chomper to the left
    Move(RobotHL,1,0,chomp_x,chomp_y-16)                                        'Updates all of chomper's sprites
    Move(RobotHR,1,rhr,chomp_x-16,chomp_y-16)
    Move(RobotLL,1,rll,chomp_x,chomp_y)
    Move(RobotLR,1,rlr,chomp_x-16,chomp_y)
  elseif nu == 2                                                                'If the chomper is moving to the right
    RotateChomper                                                               'Rotate chomper to the right
    Move(RobotHL,1,0,chomp_x,chomp_y-16)                                        'Updates all of chomper's sprites
    Move(RobotHR,1,rhr,chomp_x+16,chomp_y-16)
    Move(RobotLL,1,rll,chomp_x,chomp_y)
    Move(RobotLR,1,rlr,chomp_x+16,chomp_y)
    
  if chomp_x ==382 OR chomp_x ==178                                             'If the chomper hits a wall
    RotateChomper                                                               'Rotates all of the chomper's sprites so that they are facing the correct direction (depends on value of nu)

PUB animate_chomper                                                             'Changes which sprites chompers legs and mouth are to make it seem like he is running and "chomping"
  repeat
    rhr := 4                                                                    'Changes the chompers mouth to open
    rll := 5                                                                    'Changes the chompers legs to running
    rlr := 6                                                                    'Changes the chompers legs to running 
    waitcnt(clkfreq/10 + cnt)                                                   'Wait for 1/10th of a second before changing the sprites back to the original
    rhr := 1                                                                    'Changes the chompers mouth to closed
    rll := 2                                                                    'Changes the chompers legs to running 
    rlr := 3                                                                    'Changes the chompers legs to running 
    waitcnt(clkfreq/10 + cnt)                                                   'Wait for 1/10th of a second
      
    
PUB PlaceBigGarner                                                              'Allows big Garner to easily change position
  Move(BG1,3,0,bg_x,bg_y)                                                       'Places all 16 of Big Garner's sprites based on the top left being 0,0
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
  
PUB RotateChomper                                                               'If nu is 1 then the chomper is going left, if nu is 2 the chomper is going right
  if nu == 1
    Rotate(RobotHR, 2)                                                          'If chomper is going left
    Rotate(RobotHL, 2)                                                          'Rotate all chomper's sprites to face left
    Rotate(RobotLL, 2)
    Rotate(RobotLR, 2)                 
  elseif nu == 2                                                                'If chomper is going right
    Rotate(RobotHR, 0)                                                          'Rotate all of chomper's sprites to the right
    Rotate(RobotHL, 0)
    Rotate(RobotLL, 0)
    Rotate(RobotLR, 0)
  
'------------------------------LOGIC-------------------------------
PUB gravity(xcord, ycord)                                                       'Implements gravity for a sprite at position xcord, ycord  
  if (GetCharacterXY(xcord+8,ycord+16)<> 26) and ( GetCharacterXY(xcord+8,ycord+16)<> 22) AND ( GetCharacterXY(xcord+8,ycord+16)<> 18)  AND ( GetCharacterXY(xcord+8,ycord+16)<> 19)
    ycord := ycord+1
  return ycord
   
PUB xboundaries(xcord)                                                          'Implements x-boundaries for a sprite at position xcord 
  if xcord > 390                                                                'If the player is at the right wall
    xcord := 390
  elseif xcord < 1                                                              'If the player is at the left wall
    xcord := 1
  return xcord

PUB Replay                                                                      'Displayed if replay conditions satisfied
  cogstop(1)                                                                    'Stop all of the cogs that were running methods
  cogstop(2)
  cogstop(3)
  cogstop(4)
  cogstop(5)
  cogstop(6)
  repeat until (C1buttons == %0111_1111)                                        'Runs until A button pressed
    UpdateAll                                                                   'Read both NES controllers' button states, refresh collision data, and wait for video blanking to synch up with the screen's refresh
    if lives =< 0                                                               'If the player died
      gd.putstr(22,0,string("YOU LOST!"))
      gd.putstr(22,1,string("Press A to Play Again."))
    else                                                                        'If the player won
      gd.putstr(22,0,string("YOU WON!!!!"))
      gd.putstr(22,1,string("Press A to Play Again."))
      
  waitcnt(clkfreq/10 + cnt)                                                     'Wait 1/10th of a second

PUB CheckCollisionChomper(SpriteT, SpriteB)                                     'Check collisions with all four of chomper's sprites
  'Check collisions between bottom sprite and chomper
  if CheckCollision(SpriteB,RobotHL) or CheckCollision(SpriteB,RobotLR) or CheckCollision(SpriteB,RobotLL) or CheckCollision(SpriteB,RobotHR)
    Death                                                                       'Docs a life, moves player, and flashes player
  'Check collisions between top sprite and chomper
  if CheckCollision(SpriteT,RobotHL) or CheckCollision(SpriteT,RobotLR) or CheckCollision(SpriteT,RobotLL) or CheckCollision(SpriteT,RobotHR)
    Death                                                                       'Docs a life, moves player, and flashes player

PUB Death                                                                       'If the player runs into Little Garner, Static discharge, chomper or his laser
  x := 200                                                                      'Changes the x-coordinate of the player to the center of the screen
  y := deathy                                                                   'Changes teh y-coordinate of the player to the ground
  Flash(5)                                                                      'Flashes the player 5 times so they know they died
  lives := lives-1                                                              'Decrement lives by one, health bar also moves down by one
  Move(0,0,player_top,x,y-16)                                                   'Moves the player's top and bottom to the x and y coordinates specified
  Move(1,0,player_bottom,x,y)

PUB CheckLives | i                                                              'Checks whether the player lost a life and redraws the health bar
    if lives <> 0                                                               'If the player is still alive
      repeat i from 7 to (6+lives)                                              'Draw a green block from the end of the word health, the length of the number of lives left
        Draw(0,3,i,0)                                                           'Black under the green health bar was intentionally left
  
PUB Flash(numFlashes)                                                           'Flash the character to let the player know they died
  repeat until numFlashes=<0                                                    'Repeat until player isn't supposed to flash anymore
    Move(0,0,TPlayer,x,y-16)                                                    'Move the player on the screen
    Move(1,0,BPlayer,x,y)
    waitcnt(clkfreq/10+cnt)                                                     'Wait 1/10th of a second
    Move(0,0,TPlayer,off,off)                                                   'Move the player off the screen
    Move(1,0,BPlayer,off,off)
    waitcnt(clkfreq/10+cnt)                                                     'Wait for 1/10th of a second
    numFlashes :=numFlashes-1                                                   'Decrement number of flashes by one

PUB SelectCharacter | i, j, k                                                   'Character Selection Method, runs before start of main game

                                                                                'Draw the Background as black
  repeat j from 0 to 37                                                         'All y pixels
    repeat i from 0 to 49                                                       'All x pixels
      Draw(0,0,i,j)                                                             'Black
          
                                                                                'All of these remove the sprites from the screen for replaying the game
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
                                                                                'Moves all of the sprites off the screen
  PlaceBigGarner
  Move(Propeller,2,8,x_p,y_p)
  Move(laser,1,15,laser_x,laser_y)
  UpdateChomper
  UpdateLittleGarner
  update_static    
                                                                                'Location of Sprites During Selection
  x := 200
  y := 150
  
  TPlayer := 0
  BPlayer := 1                                                                  'Initial Sprite Top Value
                                                                                'Initial Sprite Bottom Value
  UpdateAll                                                                     'Read both NES controllers' button states, refresh collision data, and wait for video blanking to synch up with the screen's refresh

  repeat until (C1buttons == %0111_1111)                                        'repeats until A button pushed
    UpdateAll                                                                   'Read both NES controllers' button states, refresh collision data, and wait for video blanking to synch up with the screen's refresh
                          
                                                                                'Display Text
    gd.putstr(15,0,string("  Select a Character!"))
    gd.putstr(15,1,string("Use Up / Down to Toggle."))
    gd.putstr(15,2,string("  Press A to Select."))  
     
    case C1buttons                                                              'Toggle Sprites Based on User Input
      %1111_0111 :                                                              'Up Button
        if TPlayer =< 8                                                         'Keep Sprites within Range                   
          TPlayer := TPlayer + 4
          BPlayer := BPlayer + 4
      %1111_1011 :                                                              'Down Button
        if TPlayer => 4                                                         'Keep Sprites within Range
          TPlayer := TPlayer - 4
          BPlayer := BPlayer - 4
    waitcnt(clkfreq/7 + cnt)                                                    'Waits for 1/7th of a second, for player to toggle button (otherwise will scroll through too quickly)
    Move(player_top,0,TPlayer,x,y-16)                                           'Moves the top sprite off the screen
    Move(player_bottom,0,BPlayer,x,y)                                           'Moves the bottom sprite off the screen

  Alt1Player := TPlayer + 2                                                     'Set Alternate Sprite Values 
  Alt2Player := TPlayer + 3
  feet := BPlayer        

'----------------------------CHARACTER MOTION--------------------------------- 
PUB MoveMouth                                                                   'Changes out sprites values to make big Garner's mouth move to mimic speaking, on a separate cog
  repeat
   mouth:=10                                                                    'Mouth closed
   waitcnt(clkfreq/6+cnt)                                                       'Wait for 1/6th of a second
   mouth:=15                                                                    'Mouth open
   waitcnt(clkfreq/6+cnt)                                                       'Wait for 1/6th of a second
    
PUB ChomperMotion                                                               'Initiates chomper's legs moving, on a separate cog
  repeat
    repeat until chomp_x=>382                                                   'Repeat until chomper reaches the end of his platform on the right
      chomp_x:=chomp_x+2                                                        'Move chomper two pixels to the right
      waitcnt(clkfreq/12+cnt)                                                   'Wait for 1/12th of a second
      nu := 2                                                                   'Chomper is going right
    repeat until chomp_x=<176                                                   'Repeat until chomper reaches the left end of his platform
      chomp_x:=chomp_x-2                                                        'Move chomper 2 pixels to the left
      waitcnt(clkfreq/12+cnt)                                                   'Wait for 1/12th of a second
      nu := 1                                                                   'Chomper is going left
      
PUB ChomperLaser                                                                'Controls the Chomper Laser, designed to be run on seperate cog
  repeat
    laser_y := 170                                                              'Sets the laser's y coordinate to the chomper's eyes
    if nu == 1                                                                  'If chomper is going left
      laser_x := chomp_x-16                                                     'Sets the laser to the chomper's x coordinate
      repeat until laser_x =< 0                                                 'Repeat until the laser is off the screen
        laser_x := laser_x - 10                                                 'Move the laser 10 pixels
        waitcnt(clkfreq/20+cnt)                                                 'Wait for 1/20th of a second
    elseif nu == 2                                                              'If chomper is going right
      laser_x := chomp_x+16                                                     'Sets the laser to the chomper's x coordinate
      repeat until laser_x => 385                                               'Repeat until the laser is off the screen
        laser_x := laser_x + 10                                                 'Moves the laser 10 pixels
        waitcnt(clkfreq/20+cnt)                                                 'Wait for 1/20th of a second
    laser_x := off                                                              'Move the laser off the screen
    waitcnt(clkfreq/3+cnt)                                                      'Wait for 1/3 of a second before the next laser comes back on
       
PUB LittleGarnerMotion                                                          'Controls Little Garner Motion, designed to be run on seperate cog
  repeat
    repeat until lgarner_x => lgarner_rbound                                    'Repeat until little garner hits his right bound
      lgarner_dir := 1                                                          'Direction set to right
      lgarner_x := lgarner_x+3                                                  'Move right three pixels
      waitcnt(clkfreq/11+cnt)                                                   'Wait for 1/11th of a second
    repeat until lgarner_x =< lgarner_lbound                                    'Repeat until little garner hits his left bound
      lgarner_dir := 2                                                          'Direction set to left
      lgarner_x := lgarner_x-3                                                  'Move left three pixels
      waitcnt(clkfreq/11+cnt)                                                   'Wait for 1/11th of a second
      
PUB StaticDischarge                                                             'Implements Little Garner's Static Discharge, designed to be run on seperate cog
  repeat
    if static                                                                   'If Little Garner is at the left edge of his boundary
      sdx1 := lgarner_x - 16                                                    'Assigns the correct x and y coordinates of the 3 static discharge sprites
      sdy1 := lgarner_y
      sdx2 := lgarner_x - 32
      sdy2 := lgarner_y
      sdx3 := lgarner_x - 48
      sdy3 := lgarner_y
      waitcnt(clkfreq/3+cnt)                                                    'Wait for 1/3rd of a second
      sdx1 := 400                                                               'Set the x coordinate of the three static discharge sprites to off of the screen
      sdx2 := 400
      sdx3 := 400
      static := false                                                           'Reset the static discharge flag
         

PUB animate_player                                                              'Implements animation for player character legs/ jumping, designed to be run on seperate cog
  repeat
    if BPlayer == feet and mvmt                                                 'If the player is in the game and moving (i.e. not in select character and button is being pressed)
      BPlayer := Alt2Player                                                     'Bottom of the player is the moving feet
      waitcnt(clkfreq/10+cnt)                                                   'Wait for 1/10th of a second
      mvmt := 0                                                                 'Reset the movement flag
    if BPlayer == Alt2Player                                                    'If the players legs are already moving
      BPlayer := feet                                                           'Reset to the standing feet
      waitcnt(clkfreq/10+cnt)                                                   'Wait for 1/10th of a second

    if jump                                                                     'If the character is on solid ground and the up button is pressed                        
      repeat 36                                                                 'Repeat 36 times
        y := y-2                                                                'Move the player up two pixels
        waitcnt(clkfreq/100 + cnt)                                              'Wait for 1/100th of a second
      jump := 0                                                                 'Reset the jump flag to not jumping


'------------------------------------------ DRAW BACKGROUND --------------------------------------------
PUB Background | i,j,k,spacing                                                  'Note that i,j,k are declared as local variables for use within this method. Local variables are always 32-bit longs.
  repeat j from 0 to 37                                                         'These repeat loops just sets the background to black at the beginning 
    repeat i from 0 to 49
      Draw(0,1,i,j)
       
  j :=35                                                                        'Set the y-coordinate for the ground
  repeat j from 35 to 36                                                        'Draw the ground    
    repeat i from 0 to 49
        Draw(0,26,i,j)
        Draw(0,26,i,j+1)
        
  spacing:=5                                                                    'The spacing between the levels

  j :=30 
  repeat i from 5 to 20                                                         'Level one bricks 
    Draw(0,22,i,j)
  repeat i from 25 to 30
    Draw(0,22,i,j)   

  j :=j-spacing                                                                 
  repeat i from 0 to 9                                                          'Level two bricks 
    Draw(0,22,i,j)
  repeat i from 20 to 49
    Draw(0,22,i,j)

  j :=j-spacing  
  repeat i from 15 to 30                                                        'Level three bricks  
    Draw(0,22,i,j)       
  repeat i from 40 to 49
    Draw(0,22,i,j)
     
  j :=j-spacing  
  repeat i from 0 to 6                                                          'Level four bricks
    Draw(0,22,i,j)
  repeat i from 12 to 18
    Draw(0,22,i,j)
  repeat i from 30 to 40
    Draw(0,22,i,j)

  j :=j-spacing  
  repeat i from 25 to 35                                                        'Level five bricks 
    Draw(0,22,i,j)
  repeat i from 8 to 15
    Draw(0,22,i,j)
  repeat i from 36 to 41
    Draw(0,22,i,j)
  repeat i from 47 to 49
    Draw(0,22,i,j)

  j :=j-spacing  
  repeat i from 0 to 3                                                          'Level six bricks
    Draw(0,22,i,j)
  repeat i from 19 to 30
    Draw(0,22,i,j)
  repeat i from 45 to 49
    Draw(0,22,i,j)

PUB MechatronicsForestBackground | i,j                                          'Draw the background for the mechatronics forest
  j :=35
  repeat j from 35 to 37                                                        'Draw underground as dirt
    repeat i from 0 to 49
        Draw(0,19,i,j)
  repeat i from 0 to 49                                                         'Draw grassy top ground
    Draw(0,18,i,34)
  repeat j from 0 to 33                                                         'Fill in the sky blue
    repeat i from 0 to 49
        Draw(0,4,i,j)

                                                                                'Draw the sun, uses yellow pixels
  repeat j from 2 to 5                                                          'Draws a square
    repeat i from 43 to 46
      Draw(0,5,i,j)
  Draw(0,5,42,6)                                                                'Bottom Left diagonal ray
  Draw(0,5,41,7)
  Draw(0,5,40,8)

  Draw(0,5,45,6)                                                                'Bottom Ray
  Draw(0,5,45,7)
  Draw(0,5,45,8)
  
  Draw(0,5,45,1)                                                                'Top Ray
  Draw(0,5,45,0)
  
  Draw(0,5,47,6)                                                                'Bottom Right diagonal ray
  Draw(0,5,48,7)
  Draw(0,5,49,8)

  Draw(0,5,47,1)                                                                'Top Right diagonal ray
  Draw(0,5,48,0)

  Draw(0,5,42,1)                                                                'Top Left diagonal ray
  Draw(0,5,41,0)

  Draw(0,5,47,3)                                                                'Right Ray
  Draw(0,5,48,3)
  Draw(0,5,49,3) 

  Draw(0,5,42,3)                                                                'Left Ray
  Draw(0,5,41,3)
  Draw(0,5,40,3)

  DrawTree(10,34)                                                               'Draws three trees 
  DrawTree(22,34)
  DrawTree(40,34)                  

PUB DrawTree(xcoord, ycoord) | i,j                                              'Draws a tree for the mechatronics forest
  repeat i from xcoord to xcoord+2                                              'Draw trunk
    repeat j from ycoord to ycoord-17
      Draw(0,19,i,j)
      
  Draw(0,12,xcoord+3,ycoord-3)                                                  'Right diagonal branch
  Draw(0,12,xcoord+4,ycoord-5)
  Draw(0,12,xcoord+5,ycoord-6)
  Draw(0,12,xcoord+6,ycoord-7)
  Draw(0,12,xcoord+7,ycoord-8)
  
  Draw(0,12,xcoord+3,ycoord-6)                                                  'Right diagonal branch
  Draw(0,12,xcoord+4,ycoord-7)
  Draw(0,12,xcoord+5,ycoord-8)
  Draw(0,12,xcoord+6,ycoord-9)
  Draw(0,12,xcoord+7 ,ycoord-10)

  Draw(0,12,xcoord+3,ycoord-10)                                                 'Right diagonal branch
  Draw(0,12,xcoord+4,ycoord-11)
  Draw(0,12,xcoord+5,ycoord-12)
  Draw(0,12,xcoord+6,ycoord-13)

  Draw(0,12,xcoord+3,ycoord-14)                                                 'Right diagonal branch
  Draw(0,12,xcoord+4,ycoord-15)
  Draw(0,12,xcoord+5,ycoord-16)

  Draw(0,12,xcoord+3,ycoord-16)                                                 'Right diagonal branch
  Draw(0,12,xcoord+4,ycoord-17) 
  
  Draw(0,12,xcoord-1,ycoord-3)                                                  'Left diagonal branch
  Draw(0,12,xcoord-2,ycoord-4)
  Draw(0,12,xcoord-3,ycoord-5)
  Draw(0,12,xcoord-4,ycoord-6)
  Draw(0,12,xcoord-4,ycoord-7)

  Draw(0,12,xcoord-1,ycoord-8)                                                  'Left diagonal branch
  Draw(0,12,xcoord-2,ycoord-9)
  Draw(0,12,xcoord-3,ycoord-10)
  Draw(0,12,xcoord-4,ycoord-11)
  
  Draw(0,12,xcoord-1,ycoord-12)                                                 'Left diagonal branch
  Draw(0,12,xcoord-2,ycoord-13)
  Draw(0,12,xcoord-3,ycoord-14)
  
  Draw(0,12,xcoord-1,ycoord-15)                                                 'Left diagonal branch
  Draw(0,12,xcoord-2,ycoord-16)
  Draw(0,12,xcoord-3,ycoord-17)

  Draw(0,12,xcoord+1,ycoord-18)                                                 'Top Branch
  Draw(0,12,xcoord+1,ycoord-19)
  Draw(0,12,xcoord+1,ycoord-20)
                                                        
  Draw(0,12,xcoord,ycoord-17)                                                   'Top Branch
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