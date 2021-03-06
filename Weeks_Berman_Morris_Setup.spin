''Gamduino_Setup
''Rachel Weeks and Ryan Berman

''Run this program whenever you first turn the power to the Gameduino on (i.e. when you plug in the USB cable).
''Set the LoadBackground and LoadSprites methods to load the Gamduino's RAM with the data for the
''Background characters and Sprites of your choosing. These methods transfer data from text files
''on the SD card (non-volatile flash memory) into the Gameduino's RAM. This process will take about
''20-40 seconds. This data will remain on the Gameduino's RAM until the unit loses power.

CON
  _xinfreq=6_250_000
  _clkmode=xtal1+pll16x

OBJ
  gd : "GD_ASM_v4" 
  sd : "SD-MMC_FATEngine" 
                       
PUB Main 
  dira[16]~~                                 'Set Pin 16 (which controls blue bar graph's right LED) to be an output
  outa[16]~~                                 'Turn on Pin 16's LED to indicate loading data 
  StartGameduino                             'Start the Gameduino driver on Cog 1 
  sd.FATEngineStart(0,1,2,3,-1,-1,-1,-1,-1)  'Start SD card driver on Cog 2  sd.FATEngineStart(DOPin, CLKPin, DIPin, CSPin, WPPin, CDPin, RTCReserved1, RTCReserved2, RTCReserved3)  

  'You can load up to two extra background tile sets into the Gameduino's memory into the second and third background sections. (Sections 1 and 2 are predefined by default.)
  LoadBackground(2,2)  'Load BackgroundTileSet#2 (Super Mario Brothers) into Background Section 2
  'LoadBackground(3,3)  'Load BackgroundTileSet#3 (Legend of Zelda) into Background Section 3 

  'Choose four of your favorite Sprite Sets (see Reference Booklet) to load into the four different sections of the Gameduino's
  ' Sprite RAM(Sections 0, 1, 2, and 3). Note that each Sprite Set contains 16 sprite images, and you can only have a total of 64
  ' sprite images loaded into the Gameduino at at time (in the 256 color mode). However, the Gameduino can handle 256 total sprites
  ' at once, any of which can display any one of these 64 sprite images (i.e. more than one sprite number can be showing the same
  ' sprite image at the same time). While programming your game, you need to remember which images you placed into which section.
  LoadSprites(32,0)                           'Load SpriteSet#32 (Futurama characters) into Sprite Section 0 of the Gameduino's RAM
  LoadSprites(41,1)                           'Load SpriteSet#41 (Robot Chomper) into Sprite Section 1 of the Gameduino's RAM                                                                   
  LoadSprites(21,2)                           'Load SpriteSet#19 (Small Garner) into Sprite Section 2 of the Gameduino's RAM  
  LoadSprites(22,3)                           'Load SpriteSet#2 (Big Garner) into Sprite Section 3 of the Gameduino's RAM 
  
  outa[16]~                                  'Turn off Pin 16's LED to indicate data upload to the Gameduino chip has completed
  gd.putstr(1,0,string("Sprite and Character data uploaded to Gameduino"))

PUB StartGameduino   'Starts Gameduino driver on a new cog and loads default sprites and background characters
  gd.start(1)                                                                       'Starts Gameduino assembly program on Cog 1 and resets the Gamduino's previous RAM values
  LoadDefaultBackground                                                             'Load default color/texture background characters into the first half of Section 0 (characters 0-31)
  gd.ascii                                                                          'Loads ASCII characters into Gameduino's character RAM at locations 32-127 (2nd half of Section 0 and all of Section 1)            
  
PUB LoadSprites(SpriteSet,section) | index
  sd.mountPartition(0) 
  case SpriteSet
     0 : sd.openFile(string("0.TXT"),"R")    'Mario
     1 : sd.openFile(string("1.TXT"),"R")    'Mario Extras
     2 : sd.openFile(string("2.TXT"),"R")    'Mini Mario
     3 : sd.openFile(string("3.TXT"),"R")    'Mario Items
     4 : sd.openFile(string("4.TXT"),"R")    'Kim Possible 1
     5 : sd.openFile(string("5.TXT"),"R")    'Kim Possible 2
     6 : sd.openFile(string("6.TXT"),"R")    'Kim Possible 3
     7 : sd.openFile(string("7.TXT"),"R")    'Avatar 1
     8 : sd.openFile(string("8.TXT"),"R")    'Avatar 2
     9 : sd.openFile(string("9.TXT"),"R")    'Avatar 3
    10 : sd.openFile(string("10.TXT"),"R")   'Power Puff Girl 1
    11 : sd.openFile(string("11.TXT"),"R")   'Power Puff Girl 2 
    12 : sd.openFile(string("12.TXT"),"R")   'Pokemon 1
    13 : sd.openFile(string("13.TXT"),"R")   'Pokemon 2
    14 : sd.openFile(string("14.TXT"),"R")   'Pokemon 3
    15 : sd.openFile(string("15.TXT"),"R")   'Wolverine
    16 : sd.openFile(string("16.TXT"),"R")   'Prof Thacker 1 
    17 : sd.openFile(string("17.TXT"),"R")   'Prof Thacker 2
    18 : sd.openFile(string("18.TXT"),"R")   'Prof Laufer
    19 : sd.openFile(string("19.TXT"),"R")   'Prof Knospe
    20 : sd.openFile(string("20.TXT"),"R")   'Prof Hopkins Boss
    21 : sd.openFile(string("21.TXT"),"R")   'Prof Garner
    22 : sd.openFile(string("22.TXT"),"R")   'Garner Boss
    23 : sd.openFile(string("23.TXT"),"R")   'Yoshi
    24 : sd.openFile(string("24.TXT"),"R")   'Link
    25 : sd.openFile(string("25.TXT"),"R")   'Zelda Enemies
    26 : sd.openFile(string("26.TXT"),"R")   'Tetris Blocks 
    27 : sd.openFile(string("27.TXT"),"R")   'Miscellaneous Items
    28 : sd.openFile(string("28.TXT"),"R")   'Luigi
    29 : sd.openFile(string("29.TXT"),"R")   'Dragonball Z
    30 : sd.openFile(string("30.TXT"),"R")   'Halo Characters
    31 : sd.openFile(string("31.TXT"),"R")   'Sonic the Hedgehog
    32 : sd.openFile(string("32.TXT"),"R")   'Futurama 1     
    33 : sd.openFile(string("33.TXT"),"R")   'Futurama 2    
    34 : sd.openFile(string("34.TXT"),"R")   'Street Fighter
    35 : sd.openFile(string("35.TXT"),"R")   'Bowser
    36 : sd.openFile(string("36.TXT"),"R")   'Thomas Jefferson 
    37 : sd.openFile(string("37.TXT"),"R")   'Galaga 
    38 : sd.openFile(string("38.TXT"),"R")   'Incredible Hulk 1
    39 : sd.openFile(string("39.TXT"),"R")   'Incredible Hulk 2 
    40 : sd.openFile(string("40.TXT"),"R")   'Mike Wazowski 
    41 : sd.openFile(string("41.TXT"),"R")   'Robot Chomper 
    42 : sd.openFile(string("42.TXT"),"R")   'Bart Simpson   
 
  index:=0                                                                                         
  repeat 18                                                                       'Repeat for all 16 sprites in this section 
    repeat 16                                                                     'Repeat for 16 rows in each sprite
      repeat 16                                                                   'Read in bytes 0-15 in each row of each sprite
        TempTransfer[index]:=ASCIItoBinary
        index++

  sd.closeFile
  sd.unmountPartition

  case section                                                                    'Copy sprite data to Gamduino
    0 : gd.copy($4000,@TempTransfer,4096)
    1 : gd.copy($5000,@TempTransfer,4096)
    2 : gd.copy($6000,@TempTransfer,4096)
    3 : gd.copy($7000,@TempTransfer,4096)
                                                                                  
  case section                                                                    'Copy sprite color palette to Gameduino
    0 : gd.copy($3800,@TempTransfer+4096,512)
    1 : gd.copy($3A00,@TempTransfer+4096,512)
    2 : gd.copy($3C00,@TempTransfer+4096,512)
    3 : gd.copy($3E00,@TempTransfer+4096,512)  


PUB LoadDefaultBackground
  gd.copy(GD#RAM_CHR, @Default_Background_chr, @Default_Background_chr_end - @Default_Background_chr)  'Destination address in Gameduino, Source starting address, total number of bytes in file                        '
  gd.copy(GD#RAM_PAL, @Default_Background_pal, @Default_Background_pal_end - @Default_Background_pal)

PUB LoadBackground(BackgroundSet,section) | index
  sd.mountPartition(0) 
  case BackgroundSet
    0 : sd.openFile(string("bg0.TXT"),"R") 
    1 : sd.openFile(string("bg1.TXT"),"R")
    2 : sd.openFile(string("bg2.TXT"),"R")
    3 : sd.openFile(string("bg3.TXT"),"R")  

  index:=0                                                                                         
  repeat 6                                                                        'Repeat for all 64 characters in this section 
    repeat 16                                                                     'Repeat for 16 rows in each data section
      repeat 16                                                                   'Read in bytes 0-15 in each row of each section
        TempTransfer[index]:=ASCIItoBinary
        index++
                                                                              
  sd.closeFile
  sd.unmountPartition
  
  case section                                                                  'Copy background character data to Gameduino
    0 : gd.copy($1000,@TempTransfer,1024)
    1 : gd.copy($1400,@TempTransfer,1024)
    2 : gd.copy($1800,@TempTransfer,1024)
    3 : gd.copy($1C00,@TempTransfer,1024)

  case section                                                                  'Copy background character palettes to Gameduino
    0 : gd.copy($2000,@TempTransfer+1024,512)
    1 : gd.copy($2200,@TempTransfer+1024,512)
    2 : gd.copy($2400,@TempTransfer+1024,512)
    3 : gd.copy($2600,@TempTransfer+1024,512) 

PRI ASCIItoBinary | TextChar, upper, lower
  TextChar:=sd.readByte     'Wait for a byte of data that represents a hexadecimal number (i.e. not a comma, space, carriage return, line feed, etc.)
  repeat until (TextChar=="0" or TextChar=="1" or TextChar=="2" or TextChar=="3" or TextChar=="4" or TextChar=="5" or TextChar=="6" or TextChar=="7" or TextChar=="8" or TextChar=="9" or TextChar=="a" or TextChar=="b" or TextChar=="c" or TextChar=="d" or TextChar=="e" or TextChar=="f")
    TextChar:=sd.readByte  
   
  case TextChar           'converts upper character
      "0": upper:=0 
      "1": upper:=1 
      "2": upper:=2 
      "3": upper:=3 
      "4": upper:=4 
      "5": upper:=5
      "6": upper:=6
      "7": upper:=7 
      "8": upper:=8 
      "9": upper:=9 
      "a": upper:=10
      "b": upper:=11
      "c": upper:=12 
      "d": upper:=13 
      "e": upper:=14 
      "f": upper:=15
      
  TextChar:=sd.readByte   'Reads next ASCII character from text file on SD card  
  case TextChar           'converts lower character
      "0": lower:=0 
      "1": lower:=1 
      "2": lower:=2 
      "3": lower:=3 
      "4": lower:=4 
      "5": lower:=5
      "6": lower:=6
      "7": lower:=7 
      "8": lower:=8 
      "9": lower:=9 
      "a": lower:=10
      "b": lower:=11
      "c": lower:=12 
      "d": lower:=13 
      "e": lower:=14 
      "f": lower:=15
      
  return upper<<4 + lower
   
DAT

Default_Background_chr byte {
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 

}$82,  $55,  $02,  $55,  $02,  $d5,  $aa,  $f5,  $5f,  $aa,  $57,  $80,  $55,  $80,  $55,  $82,{ 
}$39,  $92,  $60,  $f3,  $09,  $d8,  $e3,  $46,  $ef,  $8b,  $a5,  $d2,  $38,  $a0,  $11,  $0b,{ 
}$00,  $00,  $02,  $0b,  $5d,  $fa,  $7f,  $79,  $de,  $e9,  $dd,  $7d,  $5e,  $7e,  $9e,  $ae,{ 
}$72,  $bb,  $5d,  $aa,  $2e,  $39,  $dc,  $a1,  $cc,  $2c,  $1c,  $7e,  $0c,  $0a,  $69,  $c8,{ 
}$fc,  $fc,  $01,  $01,  $cf,  $cf,  $10,  $10,  $fc,  $fe,  $01,  $01,  $cf,  $cf,  $18,  $18,{ 
}$55,  $55,  $00,  $01,  $2a,  $a9,  $2a,  $a9,  $55,  $55,  $01,  $00,  $a9,  $2a,  $a9,  $2a,{ 
}$aa,  $aa,  $00,  $02,  $15,  $56,  $15,  $56,  $aa,  $aa,  $02,  $00,  $56,  $15,  $56,  $15,{ 
}$00,  $01,  $10,  $00,  $00,  $00,  $01,  $04,  $00,  $00,  $00,  $00,  $10,  $10,  $00,  $00,{ 
}$5a,  $3a,  $d1,  $12,  $b7,  $54,  $be,  $01,  $b6,  $43,  $f0,  $c7,  $d7,  $04,  $88,  $42,{ 
}$6c,  $2e,  $07,  $e6,  $a8,  $16,  $f4,  $62,  $ec,  $9e,  $1f,  $24,  $97,  $f2,  $9b,  $de,{ 
}$f7,  $fe,  $97,  $3e,  $4c,  $36,  $d7,  $82,  $09,  $3c,  $f0,  $a3,  $55,  $5a,  $88,  $ea,{ 
}$c5,  $86,  $85,  $46,  $40,  $9f,  $ee,  $42,  $ca,  $19,  $7a,  $07,  $15,  $a9,  $b2,  $79,{ 
}$40,  $00,  $10,  $00,  $04,  $00,  $01,  $00,  $00,  $40,  $00,  $15,  $00,  $15,  $00,  $15,{ 
}$aa,  $a8,  $aa,  $a0,  $aa,  $80,  $aa,  $00,  $a8,  $00,  $54,  $00,  $54,  $00,  $54,  $00,{ 
}$aa,  $80,  $aa,  $80,  $aa,  $80,  $aa,  $95,  $aa,  $55,  $a9,  $55,  $a5,  $55,  $95,  $55,{ 
}$54,  $00,  $54,  $00,  $54,  $00,  $01,  $00,  $00,  $40,  $00,  $10,  $00,  $04,  $00,  $01,{ 

}$aa,  $a8,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,{ 
}$d5,  $56,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$7f,  $fe,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$80,  $01,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,{ 
}$15,  $56,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,{ 
}$95,  $57,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$15,  $55,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,{ 
}$95,  $54,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,{ 
}$aa,  $a8,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,{ 
}$95,  $57,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$2a,  $a9,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,{ 
}$bf,  $fc,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,{ 
}$95,  $54,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,{ 
}$6a,  $ab,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$15,  $56,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,{ 
}$2a,  $ab,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,{ 

}$c0,  $ab,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,  $55,{ 
}$66,  $bf,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$3f,  $7d,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,{ 
}$44,  $46,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,{ 
}$7c,  $fc,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,{ 
}$12,  $86,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,{ 
}$47,  $c1,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,{ 
}$15,  $56,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,{ 
}$06,  $a6,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,{ 
}$7f,  $01,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,{ 
}$70,  $3d,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,{ 
}$2a,  $a1,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,{ 
}$d5,  $ea,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$0a,  $54,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,{ 
}$50,  $00,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,  $aa,{ 
}$aa,  $a4,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff,  $ff 
Default_Background_chr_end 

Default_Background_pal byte {
}$00,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $ff,  $7f,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $7c,  $00,  $00,  $00,  $00,  $00,  $00,  $e0,  $03,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$1f,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $e0,  $7f,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$ff,  $03,  $00,  $00,  $00,  $00,  $00,  $00,  $1f,  $7c,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$10,  $42,  $00,  $00,  $00,  $00,  $00,  $00,  $18,  $63,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $40,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $42,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$00,  $02,  $00,  $00,  $00,  $00,  $00,  $00,  $10,  $02,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$10,  $00,  $00,  $00,  $00,  $00,  $00,  $00,  $10,  $40,  $00,  $00,  $00,  $00,  $00,  $00,{ 
}$80,  $01,  $60,  $02,  $a0,  $01,  $20,  $02,  $06,  $1a,  $04,  $0d,  $85,  $15,  $a7,  $2a,{ 
}$07,  $36,  $e4,  $24,  $05,  $2d,  $46,  $35,  $04,  $29,  $e3,  $24,  $25,  $31,  $66,  $3d,{ 
}$80,  $30,  $40,  $14,  $a0,  $3c,  $61,  $79,  $08,  $41,  $00,  $20,  $00,  $7c,  $00,  $00,{ 
}$ce,  $39,  $f7,  $5e,  $00,  $00,  $00,  $00,  $00,  $00,  $ff,  $7f,  $00,  $00,  $00,  $00,{ 
}$63,  $70,  $62,  $76,  $03,  $6c,  $02,  $75,  $74,  $4a,  $53,  $46,  $95,  $4e,  $74,  $4a,{ 
}$6b,  $31,  $31,  $4e,  $ad,  $3d,  $ef,  $41,  $53,  $6f,  $11,  $67,  $32,  $6b,  $f0,  $62,{ 
}$bb,  $03,  $11,  $02,  $00,  $00,  $00,  $00,  $eb,  $0c,  $11,  $02,  $bb,  $03,  $00,  $00,{ 
}$11,  $02,  $eb,  $0c,  $bb,  $03,  $00,  $00,  $eb,  $0c,  $11,  $02,  $00,  $00,  $00,  $00,{ 

}$4a,  $a9,  $1f,  $fc,  $00,  $80,  $00,  $00,  $1f,  $fc,  $ff,  $ff,  $b5,  $fe,  $b5,  $d6,{ 
}$1f,  $fc,  $4a,  $fd,  $40,  $d5,  $00,  $fc,  $e0,  $83,  $aa,  $82,  $a0,  $aa,  $1f,  $fc,{ 
}$55,  $81,  $1f,  $80,  $55,  $a9,  $1f,  $fc,  $1f,  $fc,  $e0,  $ff,  $aa,  $d6,  $ea,  $d7,{ 
}$f5,  $ab,  $ff,  $83,  $1f,  $fc,  $00,  $00,  $10,  $c2,  $1f,  $fc,  $ff,  $83,  $00,  $00,{ 
}$52,  $ca,  $1f,  $fc,  $10,  $c2,  $00,  $00,  $1f,  $fc,  $18,  $e3,  $b5,  $d6,  $10,  $d6,{ 
}$08,  $c9,  $a0,  $c0,  $00,  $c0,  $1f,  $fc,  $00,  $aa,  $1f,  $fc,  $40,  $c1,  $00,  $c2,{ 
}$05,  $82,  $00,  $82,  $00,  $96,  $1f,  $fc,  $1f,  $fc,  $0a,  $82,  $10,  $82,  $50,  $81,{ 
}$b0,  $80,  $10,  $80,  $10,  $94,  $1f,  $fc,  $10,  $a8,  $1f,  $fc,  $10,  $c0,  $ca,  $a8,{ 
}$40,  $02,  $1f,  $7c,  $c1,  $05,  $82,  $09,  $1f,  $7c,  $64,  $0d,  $a5,  $11,  $e5,  $19,{ 
}$45,  $2d,  $04,  $2d,  $1f,  $7c,  $25,  $31,  $25,  $2d,  $04,  $2d,  $e3,  $30,  $1f,  $7c,{ 
}$80,  $34,  $81,  $28,  $1f,  $7c,  $60,  $28,  $20,  $64,  $00,  $74,  $63,  $5c,  $1f,  $7c,{ 
}$d6,  $5a,  $ef,  $4d,  $1f,  $7c,  $8c,  $31,  $e7,  $9c,  $00,  $80,  $01,  $a4,  $1f,  $fc,{ 
}$42,  $64,  $a2,  $74,  $04,  $71,  $1f,  $7c,  $54,  $4a,  $11,  $4a,  $1f,  $7c,  $74,  $4a,{ 
}$ac,  $39,  $ef,  $45,  $1f,  $7c,  $ad,  $3d,  $d0,  $5e,  $33,  $53,  $12,  $67,  $1f,  $7c,{ 
}$1f,  $7c,  $bb,  $03,  $32,  $02,  $37,  $13,  $f0,  $01,  $eb,  $0c,  $6e,  $05,  $1f,  $7c,{ 
}$eb,  $8c,  $d0,  $89,  $1f,  $fc,  $00,  $00,  $6e,  $85,  $4d,  $89,  $eb,  $8c,  $1f,  $fc 
Default_Background_pal_end 

TempTransfer byte {
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
 
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{

}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{

}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{

}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{

}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{

}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{

}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{

}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{

}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{

}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{

}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{

}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{

}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{

}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{

}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{

}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{

}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,{
}0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 

                             