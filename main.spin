''2018_Demo_v1.2 by Gavin T. Garner, February 6, 2018

CON
  _xinfreq=6_250_000
  _clkmode=xtal1+pll16x

  'NES Controller interface pins
  clk=4
  latch=5
  data1=6
  data2=7
  'Hint: It's a lot easier to keep track of things if you create simple names for sprite numbers and their images
  MarioTop=0                                        'Refer to sprite number 0 as "MarioTop"
  MarioBottom=1                                     'Refer to sprite number 1 as "MarioBottom" 
  Goomba=3                                          'Refer to sprite number 3 as "Goomba"
  Qmark1=4                                          'Refer to sprite number 4 as "Qmark1" 
  Qmark2=5                                          'Refer to sprite number 5 as "Qmark2" 
  Qmark3=6                                          'Refer to sprite number 6 as "Qmark3" 
  Qmark4=7                                          'Refer to sprite number 7 as "Qmark4" 
  OneUpMushroom=8                                   'Refer to sprite number 8 as "OneUpMushroom" 
                                                    'etc.
OBJ
  gd : "GD_ASM_v4"                                  'Include the external "GD_ASM_v4" object so that your code can call its methods using gd.<method name>

VAR
  byte collisions[256], OldChar[12]                                 'Reserve 256 bytes to store sprite collision data and 12 bytes to temporarily store background characters when displaying up to 12-digit numbers over top of them (so that they can be redrawn if the number gets smaller and takes up fewer decimal places)
  byte C1buttons, C2buttons                                         'These variables are used to store the button states of the two NES controllers
  long x, y, MarioRot, GoombaPos, GoombaRot                         'Use x and y to store sprite number 1's (MarioBottom's) position coordinates, MarioRot to store sprite number 0's rotation orrientation, GoombaPos to store sprite number 3's (Goomba's) position, and GoombaRot to store sprite number 3's rotation orrientation
  long Stack1[100],Stack2[100],Stack3[100],Stack4[100],Stack5[100],Stack6[100]   'Reserve 100 longs for extra cogs to use as scratchpad RAM (100 longs is usually a good amount). You should always reserve 100 longs of stack space for every new cog that you start. 
                     
PUB Main 
  gd.start(7)                                                       'Starts Gameduino assembly program on Cog 7 and resets the Gamduino's previous RAM values                  
  dira[clk..latch]~~                                                'Sets I/O directions of NES Controllers' clock and latch interface pins to be outputs
  SuperMarioBackground                                              'Call the "SuperMarioBackground" method (below) then return here and run the next line
  VideoGame                                                         'Call the "VideoGame" method (note that even though this is the next line anyway, the program would not automatically run it without this specific method call). When a method runs out of code, it returns to from where it was called. It does not automatically start running the method beneath it. 
  
PUB VideoGame | i                                                   'This is the main public method for this program
  GoombaPos:=295                                                    'Start the Goomba with its X position at 295
  Move(Goomba,1,12,GoombaPos,256)                                   'Move Goomba sprite, which we've assigned to sprite number 3 (and which is displaying the image from sprite section=1, sprite number=12) to x=295 y=256  Move(SpriteNumber,SpriteSection,SpriteImage,Xposition,Yposition)                                                                
  Move(Qmark1,1,0,120,208)                                          'Add in the question mark sprites from Sprite Section 1 (into which we chose SpriteSet 3 "Mario Items" to be loaded) and display sprite image 0 from that set (the first question mark block)                   
  Move(Qmark2,1,0,200,208)
  Move(Qmark3,1,0,232,208) 
  Move(Qmark4,1,0,216,152)

  coginit(1,GoombaMotion,@Stack1)                                   'Start Cog 1 and run GoombaMotion method on it. Let Cog 1 use the 100 longs that were reserved starting at "Stack1" as scratchpad RAM to store intermediate variables in as it interprets its Spin code.

  x:=40                                                             'Start Mario's postion at x=40 y=256 (i.e. the upper left pixel of Sprite #1's image will coincide with pixel x=50, y=256 on the screen)  
  y:=256
  repeat                                                            'This is the game's main loop
    UpdateAll                                                       'It is important to refresh the collision data and wait for the screen's blanking signal at the beginning of the video game's main loop (i.e. your program's main loop should start by calling the "UpdateAll" method)              
    if CheckCollision(MarioBottom,Goomba)                           'Checks to see if Sprite #1 (Mario's legs) is colliding with Sprite 3 (Goomba)
      MarioRot:=3                                                   'Rotation=3 rotates the sprite image left by 90 degreees
      Rotate(MarioBottom,MarioRot)                                  'Rotates "MarioBottom" sprite (Sprite 0) see table in "Rosetta Stone" reference document for and exlaination of the different types of sprite rotation and mirror options
      Rotate(MarioTop,MarioRot)
      repeat 4                                                      'Animation of Mario falling back after being hit by Goomba
        x:=x-10                                                     'Push Mario back to the left 10 pixels
        Move(MarioBottom,0,0,x-16,y)
        Move(marioTop,0,1,x,y)
        waitcnt(clkfreq/4+cnt)                                      'Note that this pause stops the main video game's loop, which freezes everything else in the game (which is really bad). Instead, you should use another cog to update global variables that control this motion (see the GoombaMotion method as an example of this)
    else
      MarioRot:=0                                              

    'Read which buttons on the two NES controllers are being pressed (this data is refreshed during "UpdateAll" and stored as bits in the variables "C1buttons" and "C2buttons"
    case C1buttons                                                  'A "case" statement is an elegant way of doing lots of "if" statements in Spin (this is similar to "switch" statement in Java)
      %1111_1101 :                                                  'NES controllers use a bit for each button and inverted logic in this order MSB=A_button__B_button__Select__Start____Up__Down__Left__Right=LSB. In this case, %1111_1101 indicates that the LEFT button is being pressed (since there is a zero in that bit)
        x:=x-1
        MarioRot:=2                                         
      %1111_1110 :                                                  '%1111_1110 indicates that the RIGHT button is being pressed (since there is a zero in that bit). Note that multiple button presses can be recorded simultaneously (e.g. %0111_1110 would indicate the right button and the A button were being pressed at the same time).
        if GetCharacterXY(x+16,y)<>3                                'Check to see if Mario has the hill character (Background Character Image 3) to the right, and if so, don't let him move right any further. This demonstrates how to have a sprite interact with the backgound characters. in Spin, <> means "not equals to".
          x:=x+1     
          MarioRot:=0
      %1111_0111 :                                                  '%1111_0111 indicates that the UP button is being pressed
        y:=y-1  
      %1111_1011 :                                                  '%1111_1011 indicates that the DOWN button is being pressed
        if GetCharacterXY(x,y+16)<>7 and GetCharacterXY(x,y+16)<>8  'Check to make sure that there isn't one of the two ground characters beneath Mario. If there is, don't let him move down any further
          y:=y+1 
    case C2buttons                                                  'Check Player #2's controller buttons
      %1111_1101 : GoombaPos:=GoombaPos-5
      %1111_1110 : GoombaPos:=GoombaPos+5 
    
    'Update the position and rotation of both of Mario's sprites (Sprite #0 and Sprite #1)
    Rotate(MarioTop,MarioRot) 
    Rotate(MarioBottom,MarioRot) 
    Move(MarioTop,0,0,x,y-16)
    Move(MarioBottom,0,1,x,y)

    'Update Goomba sprite
    Rotate(Goomba,GoombaRot)                                        'Set Sprite #3's orrientation to flipped horizonally (2 or %010 - see poster)   
    Move(Goomba,1,12,GoombaPos,256)                                 'Move Sprite #3 from its default position x=512,y=512 (which is off of the screen) to 116,142onto the visible part of the screen  

    if SpriteCollision(Qmark1)==MarioTop                            'If Sprite #4 (the leftmost Question Mark Block) is colliding with Sprite #0 (Mario's head), then release a 1up Mushroom
      Move(OneUpMushroom,1,9,120,192)    

    'These are just here to help you get a better understanding of how the screen's coordinates work as you experiment with programming
    gd.putstr(22,0,string("X="))                                    'Print a string of text on the screen at col=22 row=0
    DisplayNumber(24,0,GetSpriteX(1))                               'Look up and display Mario's feet sprite's X position         
    gd.putstr(22,1,string("Y="))
    DisplayNumber(24,1,GetSpriteY(1))                               'Look up and display Mario's feet sprite's Y position
    gd.putstr(19,2,string("Char="))       
    DisplayNumber(24,2,GetCharacterXY(x+8,y+8))                     'Look up and display the background character at Mario's feet sprite's current X and Y position (sprite coordinates are based on the upper left corner of the 16x16 pixel sprite bitmap image)
    gd.putstr(17,3,string("Goomba="))       
    DisplayNumber(24,3,GetSpriteX(3))                               'Look up and display Goomba's X position
      

PUB SuperMarioBackground | i,j,k                                    'Note that i,j,k are declared as local variables for use within this method. Local variables are always 32-bit longs.
  'Draw the sky
  repeat j from 0 to 33
    repeat i from 0 to 49
       Draw(2,0,i,j)                                                'Fill the screen with sky blue character  Draw(section=2,character=0,col=i,row=j) 
  'Draw the ground
  repeat j from 34 to 36 step 2
    repeat i from 0 to 49 step 2
      Draw(2,7,i,j)              
      Draw(2,8,i+1,j)            
      Draw(2,9,i,j+1)              
      Draw(2,10,i+1,j+1) 
  'Draw the triple bush 
   '<-------------INSERT YOUR OWN CODE HERE
  
  'Draw hill
  Draw(2,3,15,33)
  repeat i from 16 to 19
    Draw(2,4,i,33) 
  Draw(2,6,20,33)
  Draw(2,3,16,32)
  Draw(2,4,17,32)
  Draw(2,5,18,32)
  Draw(2,6,19,32)
  Draw(2,1,17,31)
  Draw(2,2,18,31)
  'Draw the little bush
   '<-------------INSERT YOUR OWN CODE HERE
  
  'Draw the pipe
   '<-------------INSERT YOUR OWN CODE HERE

  'Draw the bricks
   '<-------------INSERT YOUR OWN CODE HERE

  'Draw the single cloud
  repeat i from 0 to 3
    Draw(2,34+i,22+i,14)
  Draw(2,31,22,13)
  Draw(2,32,23,13)
  Draw(2,32,24,13)
  Draw(2,33,25,13)
  Draw(2,29,23,12)
  Draw(2,30,24,12)
  'Draw the tripple cloud
   '<-------------INSERT YOUR OWN CODE HERE
   

PUB GoombaMotion                                                    'It will probably be helpful to use additional cogs to keep track of sprite movements and rotations (just don't try to call any of Gameduino methods below (i.e. "gd._something_") on additional cogs. See the yellow warning below!
  repeat
    repeat until GoombaPos=>295
      GoombaPos:=GoombaPos+3
      ToggleGoomba
    repeat until GoombaPos=<100
      GoombaPos:=GoombaPos-3 
      ToggleGoomba      

PUB ToggleGoomba
  if GoombaRot==0
    GoombaRot:=2
    waitcnt(clkfreq/8+cnt)                                          'Because this is running on a different cog/processor than the video game's main loop (on Cog 0), this pause does not slow the game down
  if GoombaRot==2
    GoombaRot:=0
    waitcnt(clkfreq/8+cnt)



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