{{
 Gameduino PASM library for Propeller ASC
 Written by Martin Hodge, with help from kuroneko & Alessandro De Luca 

 Jan, 2018 ; v4.0: Heavily modified by Gavin Garner for easier use in UVA's MAE 4710 Mechatronics course
 Feb, 2012 ; v1.3: Fixed timing issues in PASM shiftio routine. (swapped clock-high and read-input operations)
 Oct, 2011 ; v1.2: First non-beta release

 Based on "Gameduino library for arduino"
 Copyright (c) 2011 by James Bowman <jamesb@excamera.com>
}}

                                                                
CON
TRANSPARENT     = (1 << 15)     ' transparent for chars and sprites

RAM_PIC         = $0000         ' Screen Picture, 64 x 64 = 4096 bytes
RAM_CHR         = $1000         ' Screen Characters, 256 x 16 = 4096 bytes
RAM_PAL         = $2000         ' Screen Character Palette, 256 x 8 = 2048 bytes

IDENT           = $2800
REVISION        = $2801         ' (Was "REV", which is reserved in SPIN/PASM)
FRAME           = $2802
VBLANK          = $2803
SCROLL_X        = $2804
SCROLL_Y        = $2806
JK_MODE         = $2808
J1_RESET        = $2809
SPR_DISABLE     = $280A
SPR_PAGE        = $280B
IOMODE          = $280C

BG_COLOR        = $280E
SAMPLE_L        = $2810
SAMPLE_R        = $2812

MODULATOR       = $2814

SCREENSHOT_Y    = $281E

PALETTE16A      = $2840         ' 16-color palette RAM A, 32 bytes
PALETTE16B      = $2860         ' 16-color palette RAM B, 32 bytes
PALETTE4A       = $2880         ' 4-color palette RAM A, 8 bytes
PALETTE4B       = $2888         ' 4-color palette RAM A, 8 bytes
COMM            = $2890         ' Communication buffer
COLLISION       = $2900         ' Collision detection RAM, 256 bytes
VOICES          = $2A00         ' Voice controls
J1_CODE         = $2B00         ' J1 coprocessor microcode RAM
SCRNSHOT        = $2C00         ' Screenshot line RAM (was "SCREENSHOT", a function has same name)

RAM_SPR         = $3000         ' Sprite Control, 512 x 4 = 2048 bytes
RAM_SPRPAL      = $3800         ' Sprite Palettes, 4 x 256 = 2048 bytes
RAM_SPRIMG      = $4000         ' Sprite Image, 64 x 256 = 16384 bytes


VAR
  long cog, command, _spr

PUB start(cognumber) '(_mosi, _sclk, _miso, _scs)
  MOSI := |< 11 '_mosi                                      ' Overwrite PASM variables before loading program into cog.
  SCLK := |< 13 '_sclk
  MISO := |< 12 '_miso
  SCS := |<  9  '_scs
  '              MODE  PLL    -      BPIN   -         APIN
  ctrbmode := %0_00100_000_00000000_000000_000 << 6 | 11' _mosi

  ASMstart(cognumber)                                              ' Load PASM program into cog and start

  waitcnt(clkfreq/1000+cnt)                             ' Give 1ms of time to complete cog load/start
  command := INIT_C                                     ' Set pin direction registers
  repeat while command                                  ' PASM takes action as soon as 'command' is written to
  m_wr(J1_RESET, 1)                                     ' HALT coprocessor
  'fill(RAM_PIC, 0, constant(1024 * 10))                 ' Zero all character RAM
  'fill(RAM_SPRPAL, 0, 2048)                             ' Sprite palletes black
  'fill(RAM_SPRIMG, 0, constant(64 * 256))               ' Clear all sprite data
  fill(VOICES, 0, 256)                                  ' Silence
  'fill(PALETTE16A, 0, 128)                              ' Black 16-, 4-palletes and COMM
  
  m_wr16(SCROLL_X, 0)
  m_wr16(SCROLL_Y, 0)  
  m_wr(JK_MODE, 0)     
  m_wr(SPR_DISABLE, 0)
  m_wr(SPR_PAGE, 0)
  m_wr(IOMODE, 0)
  m_wr16(BG_COLOR, 0)
  m_wr16(SAMPLE_L, 0)
  m_wr16(SAMPLE_R, 0)
  m_wr16(SCREENSHOT_Y, 0)
  m_wr(MODULATOR, 64)
  _wstart(RAM_SPR)
  repeat 256 '512
    xhide                       ' Hide all sprites
  _end
  
PUB RGB(r,g,b) | rval
  command :=  @r | RGB_C
  repeat while command
  return rval

PUB _start(address)                                     
  command := @address | START_C
  repeat while command

PUB _wstart(address)                                    
  command := @address | WSTART_C
  repeat while command

PUB _wstartspr(sprnum)                                  
  command := @sprnum | WSTARTSPR_C
  repeat while command
  _spr := 0

PUB _end                                                
  command := END_C
  repeat while command

PUB m_rd(address) | rval                           
  command := @address | RD_C
  repeat while command
  return rval

PUB m_wr(address, wval)                                 
  command := @address | WR_C
  repeat while command

PUB m_rd16(address) | rval                         
  command := @address | RD16_C
  repeat while command
  return rval
                                                        
PUB m_wr16(address, v)                                  
  command := @address | WR16_C
  repeat while command

PUB fill(address, v, count)                             
  command := @address | FILL_C
  repeat while command

PUB copy(address, src, count)                           
  command := @address | COPY_C
  repeat while command

PUB microcode(src, count)                               
  m_wr(J1_RESET, 1)
  copy(J1_CODE, src, count)
  m_wr(J1_RESET, 0)

PUB setpal(pal, argibi)                                 
  command := @pal | SETPAL_C
  repeat while command
  
PUB sprite(sprp, x, y, img, pal, rot, jk)               
  command := @sprp | SPRITE_C
  repeat while command
  
PUB xsprite(ox, oy, x, y, img, pal, rot, jk)            
  command := @ox | XSPRITE_C
  repeat while command
  _spr++

PUB xhide                                                                                                                     
  command := XHIDE_C
  repeat while command              
  _spr++

PUB sprite2x2(sprp, x, y, img, pal, rot, jk)     
  command := @sprp | SPR2X2_C

PUB waitvblank                                   
  command := WAITVB_C
  repeat while command

PUB ascii | f,s 
  f := @font8x8
  s := @stretch
  command := @f | ASCII_C
  repeat while command
  
PUB putstr(x, y, str)                                   
  command := @x | PUTSTR_C
  repeat while command

PUB voice(v, wave, freq, lamp, ramp)                    
  command := @v | VOICE_C
  repeat while command

PUB screenshot(frm)                                     
'TODO

PUB uncompress(address, srcp)
  command := @address | UNCOMP_C
  repeat while command

PUB transfer(wval) | rval
  command := @wval | TRANSFER_C
  repeat while command
  return rval

PUB load_hub(adr, ptr, count)
' Load specified segment of GD RAM into hub RAM.
' adr is where in GD RAM to begin reading
' ptr is where in hub RAM to begin writing
' count is the number of bytes to read
  command := @adr | LHUB_C
  repeat while command

PUB blit(src, sstep, dst, dstep, count)
' Copy count bytes of Gameduino RAM from src to dst
'    sstep and dstep are deltas for src and dst
  command := @src | BLIT_C
  repeat while command

PRI ASMstart(cognumber) : okay
' Start Assembly Engine - starts a cog
  coginit(cognumber,@entry, @command)
    
PRI stop
' Stop SPI Engine - frees a cog
    if cog
       cogstop(cog~ - 1)
    command~
    
DAT
stretch byte
  byte  $00, $03, $0C, $0F
  byte  $30, $33, $3C, $3F
  byte  $C0, $C3, $CC, $CF
  byte  $F0, $F3, $FC, $FF

font8x8 byte
  byte $00, $00, $00, $00, $00, $00, $00, $00, $18, $18, $18, $18, $18, $00, $18, $00
  byte $6c, $6c, $6c, $00, $00, $00, $00, $00, $36, $36, $7f, $36, $7f, $36, $36, $00
  byte $0c, $3f, $68, $3e, $0b, $7e, $18, $00, $60, $66, $0c, $18, $30, $66, $06, $00
  byte $38, $6c, $6c, $38, $6d, $66, $3b, $00, $0c, $18, $30, $00, $00, $00, $00, $00
  byte $0c, $18, $30, $30, $30, $18, $0c, $00, $30, $18, $0c, $0c, $0c, $18, $30, $00
  byte $00, $18, $7e, $3c, $7e, $18, $00, $00, $00, $18, $18, $7e, $18, $18, $00, $00
  byte $00, $00, $00, $00, $00, $18, $18, $30, $00, $00, $00, $7e, $00, $00, $00, $00
  byte $00, $00, $00, $00, $00, $18, $18, $00, $00, $06, $0c, $18, $30, $60, $00, $00
  byte $3c, $66, $6e, $7e, $76, $66, $3c, $00, $18, $38, $18, $18, $18, $18, $7e, $00
  byte $3c, $66, $06, $0c, $18, $30, $7e, $00, $3c, $66, $06, $1c, $06, $66, $3c, $00
  byte $0c, $1c, $3c, $6c, $7e, $0c, $0c, $00, $7e, $60, $7c, $06, $06, $66, $3c, $00
  byte $1c, $30, $60, $7c, $66, $66, $3c, $00, $7e, $06, $0c, $18, $30, $30, $30, $00
  byte $3c, $66, $66, $3c, $66, $66, $3c, $00, $3c, $66, $66, $3e, $06, $0c, $38, $00
  byte $00, $00, $18, $18, $00, $18, $18, $00, $00, $00, $18, $18, $00, $18, $18, $30
  byte $0c, $18, $30, $60, $30, $18, $0c, $00, $00, $00, $7e, $00, $7e, $00, $00, $00
  byte $30, $18, $0c, $06, $0c, $18, $30, $00, $3c, $66, $0c, $18, $18, $00, $18, $00

  byte $3c, $66, $6e, $6a, $6e, $60, $3c, $00, $3c, $66, $66, $7e, $66, $66, $66, $00
  byte $7c, $66, $66, $7c, $66, $66, $7c, $00, $3c, $66, $60, $60, $60, $66, $3c, $00
  byte $78, $6c, $66, $66, $66, $6c, $78, $00, $7e, $60, $60, $7c, $60, $60, $7e, $00
  byte $7e, $60, $60, $7c, $60, $60, $60, $00, $3c, $66, $60, $6e, $66, $66, $3c, $00
  byte $66, $66, $66, $7e, $66, $66, $66, $00, $7e, $18, $18, $18, $18, $18, $7e, $00
  byte $3e, $0c, $0c, $0c, $0c, $6c, $38, $00, $66, $6c, $78, $70, $78, $6c, $66, $00
  byte $60, $60, $60, $60, $60, $60, $7e, $00, $63, $77, $7f, $6b, $6b, $63, $63, $00
  byte $66, $66, $76, $7e, $6e, $66, $66, $00, $3c, $66, $66, $66, $66, $66, $3c, $00
  byte $7c, $66, $66, $7c, $60, $60, $60, $00, $3c, $66, $66, $66, $6a, $6c, $36, $00
  byte $7c, $66, $66, $7c, $6c, $66, $66, $00, $3c, $66, $60, $3c, $06, $66, $3c, $00
  byte $7e, $18, $18, $18, $18, $18, $18, $00, $66, $66, $66, $66, $66, $66, $3c, $00
  byte $66, $66, $66, $66, $66, $3c, $18, $00, $63, $63, $6b, $6b, $7f, $77, $63, $00
  byte $66, $66, $3c, $18, $3c, $66, $66, $00, $66, $66, $66, $3c, $18, $18, $18, $00
  byte $7e, $06, $0c, $18, $30, $60, $7e, $00, $7c, $60, $60, $60, $60, $60, $7c, $00
  byte $00, $60, $30, $18, $0c, $06, $00, $00, $3e, $06, $06, $06, $06, $06, $3e, $00
  byte $18, $3c, $66, $42, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $ff

  byte $1c, $36, $30, $7c, $30, $30, $7e, $00, $00, $00, $3c, $06, $3e, $66, $3e, $00
  byte $60, $60, $7c, $66, $66, $66, $7c, $00, $00, $00, $3c, $66, $60, $66, $3c, $00
  byte $06, $06, $3e, $66, $66, $66, $3e, $00, $00, $00, $3c, $66, $7e, $60, $3c, $00
  byte $1c, $30, $30, $7c, $30, $30, $30, $00, $00, $00, $3e, $66, $66, $3e, $06, $3c
  byte $60, $60, $7c, $66, $66, $66, $66, $00, $18, $00, $38, $18, $18, $18, $3c, $00
  byte $18, $00, $38, $18, $18, $18, $18, $70, $60, $60, $66, $6c, $78, $6c, $66, $00
  byte $38, $18, $18, $18, $18, $18, $3c, $00, $00, $00, $36, $7f, $6b, $6b, $63, $00
  byte $00, $00, $7c, $66, $66, $66, $66, $00, $00, $00, $3c, $66, $66, $66, $3c, $00
  byte $00, $00, $7c, $66, $66, $7c, $60, $60, $00, $00, $3e, $66, $66, $3e, $06, $07
  byte $00, $00, $6c, $76, $60, $60, $60, $00, $00, $00, $3e, $60, $3c, $06, $7c, $00
  byte $30, $30, $7c, $30, $30, $30, $1c, $00, $00, $00, $66, $66, $66, $66, $3e, $00
  byte $00, $00, $66, $66, $66, $3c, $18, $00, $00, $00, $63, $6b, $6b, $7f, $36, $00
  byte $00, $00, $66, $3c, $18, $3c, $66, $00, $00, $00, $66, $66, $66, $3e, $06, $3c
  byte $00, $00, $7e, $0c, $18, $30, $7e, $00, $0c, $18, $18, $70, $18, $18, $0c, $00
  byte $18, $18, $18, $00, $18, $18, $18, $00, $30, $18, $18, $0e, $18, $18, $30, $00
  byte $31, $6b, $46, $00, $00, $00, $00, $00, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

DAT
        RGB_C           long (((@RGB_         - @entry) >> 2) << 9 | (@RGB__ret        - @entry) >> 2) <- 16
        START_C         long (((@START_       - @entry) >> 2) << 9 | (@START__ret      - @entry) >> 2) <- 16
        WSTART_C        long (((@WSTART_      - @entry) >> 2) << 9 | (@WSTART__ret     - @entry) >> 2) <- 16
        WSTARTSPR_C     long (((@WSTARTSPR_   - @entry) >> 2) << 9 | (@WSTARTSPR__ret  - @entry) >> 2) <- 16
        END_C           long (((@END_         - @entry) >> 2) << 9 | (@END__ret        - @entry) >> 2) <- 16
        RD_C            long (((@RD_          - @entry) >> 2) << 9 | (@RD__ret         - @entry) >> 2) <- 16
        WR_C            long (((@WR_          - @entry) >> 2) << 9 | (@WR__ret         - @entry) >> 2) <- 16
        RD16_C          long (((@RD16_        - @entry) >> 2) << 9 | (@RD16__ret       - @entry) >> 2) <- 16
        WR16_C          long (((@WR16_        - @entry) >> 2) << 9 | (@WR16__ret       - @entry) >> 2) <- 16
        FILL_C          long (((@FILL_        - @entry) >> 2) << 9 | (@FILL__ret       - @entry) >> 2) <- 16
        COPY_C          long (((@COPY_        - @entry) >> 2) << 9 | (@COPY__ret       - @entry) >> 2) <- 16
        SETPAL_C        long (((@SETPAL_      - @entry) >> 2) << 9 | (@SETPAL__ret     - @entry) >> 2) <- 16
        SPRITE_C        long (((@SPRITE_      - @entry) >> 2) << 9 | (@SPRITE__ret     - @entry) >> 2) <- 16
        XSPRITE_C       long (((@XSPRITE_     - @entry) >> 2) << 9 | (@XSPRITE__ret    - @entry) >> 2) <- 16
        XHIDE_C         long (((@XHIDE_       - @entry) >> 2) << 9 | (@XHIDE__ret      - @entry) >> 2) <- 16
        SPR2X2_C        long (((@SPR2X2_      - @entry) >> 2) << 9 | (@SPR2X2__ret     - @entry) >> 2) <- 16
        WAITVB_C        long (((@WAITVB_      - @entry) >> 2) << 9 | (@WAITVB__ret     - @entry) >> 2) <- 16
        ASCII_C         long (((@ASCII_       - @entry) >> 2) << 9 | (@ASCII__ret      - @entry) >> 2) <- 16
        PUTSTR_C        long (((@PUTSTR_      - @entry) >> 2) << 9 | (@PUTSTR__ret     - @entry) >> 2) <- 16
        VOICE_C         long (((@VOICE_       - @entry) >> 2) << 9 | (@VOICE__ret      - @entry) >> 2) <- 16
'       SCREENSHOT_C    long (((@SCREENSHOT_  - @entry) >> 2) << 9 | (@SCREENSHOT__ret - @entry) >> 2) <- 16
        UNCOMP_C        long (((@UNCOMP_      - @entry) >> 2) << 9 | (@UNCOMP__ret     - @entry) >> 2) <- 16
        INIT_C          long (((@INIT_        - @entry) >> 2) << 9 | (@INIT__ret       - @entry) >> 2) <- 16
        TRANSFER_C      long (((@TRANSFER_    - @entry) >> 2) << 9 | (@TRANSFER__ret   - @entry) >> 2) <- 16
        LHUB_C          long (((@LHUB_        - @entry) >> 2) << 9 | (@LHUB__ret       - @entry) >> 2) <- 16
        BLIT_C          long (((@BLIT_        - @entry) >> 2) << 9 | (@BLIT__ret       - @entry) >> 2) <- 16

DAT
'  
' GD Engine - main loop
'
entry         org       0

 'Debug kernel 
'  --------- Debugger Kernel add this at Entry (Addr 0) ---------
'   long $34FC1202,$6CE81201,$83C120B,$8BC0E0A,$E87C0E03,$8BC0E0A
'   long $EC7C0E05,$A0BC1207,$5C7C0003,$5C7C0003,$7FFC,$7FF8
'  --------------------------------------------------------------                                                                  
:loop         rdlong    retaddr, par wz         'wait for command
        if_z  jmp       #:loop

              movd      :arg, #arg0             'get 8 arguments ; arg0 to arg7
              mov       t1, retaddr                     
              mov       t2, #8                          
:arg          rdlong    0-0, t1
              add       :arg, d0
              add       t1, #4
              djnz      t2, #:arg

              ror       t1, #16                 
              movd      :call, t1               ' extract return address

              ror       t1, #9                  ' function entry point
:call         jmpret    0-0, t1                 '                                       (%%)

:done         wrlong    par, par               'zero command to signify command complete
              jmp       #:loop

'-------------------------------------------------------------------------------------------------------------------------------

INIT_
              andn      outa,   MOSI            ' PreSet DataPin LOW                                          
              andn      outa,   SCLK            ' PreSet ClockPin LOW                                         
              or        outa,   SCS             ' PreSet SCS HIGH

              or        dira,   MOSI            ' Set DataPin to an OUTPUT                                    
              or        dira,   SCLK            ' Set ClockPin to an OUTPUT
              or        dira,   SCS             ' set SCS to OUTPUT
              mov       ctrb,   ctrbmode        ' setup ctrb for data I/O shift
INIT__ret     ret

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB _wstart(addr)
' start an SPI write transaction to addr
  _start($8000 | addr)
}
WSTART_                                         ' arg0 contains addr passed from SPIN
              or        arg0, SPIWTR            ' ($8000 | addr)
              call      #START_
WSTART__ret   ret                                          

'-------------------------------------------------------------------------------------------------------------------------------
{              
PUB _start(addr)
' start an SPI transaction to addr
  'SPI_Enable
  'SPI_Send(addr >> 8)
  'SPI_Send(addr & $FF)
}
START_                                          ' arg0 contains addr passed from SPIN
              andn      outa, SCS               ' SPI_Enable (Send SCS line low)
              mov       outreg, arg0            ' Load the addr
              shr       outreg, #8
              call      #SHIFTIO_
              mov       outreg, arg0
              call      #SHIFTIO_
START__ret    ret

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB _wstartspr(sprnum)
  _start(($8000 | RAM_SPR) + (sprnum << 2))
  _spr := 0
}
WSTARTSPR_                                      ' arg0 contains sprnum
              mov       t1, SPIWTR              ' SPI Write TRansaction
              or        t1, RAMSPR              ' Sprite RAM
              shl       arg0, #2
              add       arg0, t1
              call      #START_                             
WSTARTSPR__ret
              ret

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB _end
' end the SPI transaction
  SPI_Disable
}
END_          or        outa, SCS
END__ret      ret

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB m_rd(addr) | rval           
  _start(addr)
  rval := SPI_Recv
  _end
  return rval
}
RD_                                             ' arg0=addr | rval
              call      #START_                 ' _start(addr)
              call      #SHIFTIO_                       
                                                ' Write data back
              add       retaddr , #4            ' Arg0 = #0 | rval = #4
              wrlong    inreg, retaddr          ' (data returns from SHIFTIO_ on inreg)
              or        outa, SCS               ' _end (Send SCS line high)
RD__ret       ret

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB m_wr(addr, wval)
  _wstart(addr)
  SPI_Send(wval)
  _end
}
WR_                                             ' arg0 = addr; arg1 = wval
              call      #WSTART_                ' _wstart(addr)
              mov       outreg, arg1            ' Move data to SHIFTIO
              call      #SHIFTIO_               ' SPI_Send(wval)
              or        outa, SCS               ' _end (Send SCS line high)
WR__ret       ret

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB m_rd16(address) | rval      
  _start(address)
  rval := SPI_Recv
  rval |= SPI_Recv << 8
  _end
  return rval
}
RD16_
              call      #START_                 ' _start(addr) [arg0 already = addr]
              call      #SHIFTIO_                       
              mov       t2, inreg               ' (data returns from SHIFTIO_ on inreg)
              call      #SHIFTIO_
              shl       t2, #8
              or        t2, inreg
                                                 
              add       retaddr, #4              ' Arg0 = #0 | rval = #4
              wrlong    t2, retaddr              ' Write data back            
              or        outa, SCS                ' _end (Send SCS line high)
RD16__ret     ret

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB m_wr16(addr, v)
  _wstart(addr)
  SPI_Send(v & $FF)
  SPI_Send(v >> 8)
  _end
}                                                      
WR16_                                           ' arg0 = addr; arg1 = v                        
              call      #WSTART_                ' _wstart(addr)                                
              mov       outreg, arg1            ' Move data to SHIFTIO                        
              call      #SHIFTIO_               ' SPI_send(v & $FF)                            
              mov       outreg, arg1                                                                  
              shr       outreg, #8                                                                                            
              call      #SHIFTIO_               ' SPI_send(v >> 8)                               
              or        outa, SCS               ' _end (Send SCS line high)                    
WR16__ret     ret                                                                                                            
                                                                                                                             
 '-------------------------------------------------------------------------------------------------------------------------------
{
PUB fill(addr, v, count)
  '_wstart(addr)
  'repeat while (count--)
  '  SPI_Send(v)
  '_end
}
FILL_                                           ' arg0 = addr; arg1 = v; arg2 = count
              call      #WSTART_                ' _wstart(addr)
              mov       outreg, arg1            ' Move data to SHIFTIO
:loop         call      #SHIFTIO_               ' SPI_Send(v)
              djnz      arg2, #:loop            ' repeat while (count--)
              or        outa, SCS               ' _end (Send SCS line high)
FILL__ret     ret

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB copy(addr, src, count)
  _wstart(addr)
  repeat while (count--)
    SPI_Send(byte[src])
    src++
  _end
}
COPY_                                           ' arg0 = addr ; arg1 = src ; arg2 = count
              call      #WSTART_
:loop         rdbyte    outreg, arg1
              call      #SHIFTIO_
              add       arg1, #1
              djnz      arg2, #:loop
              or        outa, SCS               ' _end (Send SCS line high)
COPY__ret     ret                                       

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB setpal(pal, argibi)
  m_wr16(RAM_PAL + (pal << 1), argibi)
}
SETPAL_                                         ' arg0=pal ; arg1=argibi
              shl       arg0, #1
              add       arg0, RAMPAL
              call      #WR16_
SETPAL__ret   ret

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB sprite(sprp, x, y, img, pal, rot, jk)
  _wstart(RAM_SPR + (sprp << 2))
  SPI_Send(x & $FF)
  SPI_Send((pal << 4) | (rot << 1) | ((x >> 8) & 1))
  SPI_Send(y & $FF)
  SPI_Send((jk  << 7) | (img << 1) | ((y >> 8) & 1))
  _end
}
SPRITE_                                         ' arg0=sprp ; arg1=x ; arg2=y ; arg3=img ; arg4=pal ; arg5=rot ; arg6=jk
              shl       arg0, #2                ' _wstart(RAM_SPR + (sprp << 2))
              add       arg0, RAMSPR
              call      #WSTART_

              mov       outreg, arg1            ' SPI_Send(x & $FF)
              call      #SHIFTIO_

              shl       arg4, #4                ' SPI_Send((pal << 4) | (rot << 1) | ((x >> 8) & 1))
              mov       outreg, arg4
              shl       arg5, #1
              test      arg1, #|< 8 wc
              addx      outreg, arg5            ' outreg += arg5 + (carry := parity(arg1[8]))
              call      #SHIFTIO_       

              mov       outreg, arg2            ' SPI_Send(y & $FF)
              call      #SHIFTIO_

              shl       arg6, #7                ' SPI_Send((jk  << 7) | (img << 1) | ((y >> 8) & 1))
              mov       outreg, arg6
              shl       arg3, #1
              test      arg2, #|< 8 wc
              addx      outreg, arg3            ' outreg += arg3 + (carry := parity(arg2[8]))
              call      #SHIFTIO_
              
              or        outa, SCS               ' _end (Send SCS line high)
SPRITE__ret   ret 

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB xsprite(ox, oy, x, y, img, pal, rot, jk) | s
  if (rot & 2)
    x := -16 - x
  if (rot & 4)
    y := -16 - y
  if (rot & 1)
    s := x
    x := y
    y := s
  ox += x
  oy += y
  SPI_Send(ox & $FF)
  SPI_Send((pal << 4) | (rot << 1) | ((ox >> 8) & 1))
  SPI_Send(oy & $FF)
  SPI_Send((jk  << 7) | (img << 1) | ((oy >> 8) & 1))
}
XSPRITE_                        ' arg0=ox ; arg1=oy ; arg2=x ; arg3=y ; arg4=img ; arg5=pal ; arg6=rot ; arg7=jk
              mov       t2, arg2
              mov       t3, arg3
                                                        
              test      arg6, #2 wz             '   if (rot & 2)
        if_nz neg       t2, #16                 '     x := -16 - x
        if_nz sub       t2, arg2
              test      arg6, #4 wz             '   if (rot & 4)
        if_nz neg       t3, #16                 '     y := -16 - y
        if_nz sub       t3, arg3
              test      arg6, #1 wz             '   if (rot & 1)
        if_nz mov       t1, t2                  '     s := x
        if_nz mov       t2, t3                  '     x := y
        if_nz mov       t3, t1                  '     y := s

              add       arg0, t2                ' ox += x
              add       arg1, t3                ' oy += y

              mov       outreg, arg0            ' SPI_Send(ox & $FF)
              call      #SHIFTIO_

              shl       arg5, #4                ' SPI_Send((pal << 4) | (rot << 1) | ((ox >> 8) & 1))
              mov       outreg, arg5
              shl       arg6, #1
              test      arg0, #|< 8 wc
              addx      outreg, arg6            ' outreg += arg6 + (carry := parity(arg0[8]))
              call      #SHIFTIO_

              mov       outreg, arg1            ' SPI_Send(oy & $FF)
              call      #SHIFTIO_

              shl       arg7, #7                ' SPI_Send((jk  << 7) | (img << 1) | ((oy >> 8) & 1)) 
              mov       outreg, arg7
              shl       arg4, #1
              test      arg1, #|< 8 wc
              addx      outreg, arg4            ' outreg += arg4 + (carry := parity(arg1[8]))
              call      #SHIFTIO_
                            
XSPRITE__ret  ret

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB xhide                                                                      
  SPI_Send(400 & $FF)
  SPI_Send(400 >> 8)
  SPI_Send(400 & $FF)
  SPI_Send(400 >> 8)
  _spr++
}
XHIDE_
              mov       arg3,   #8              'Nr of bits
              mov       outreg, #$90            '400 & $FF
              call      #SHIFTIO_
              mov       outreg, #$01            '400 >> 8
              call      #SHIFTIO_
              mov       outreg, #$90            '400 & $FF
              call      #SHIFTIO_
              mov       outreg, #$01            '400 >> 8
              call      #SHIFTIO_
XHIDE__ret    ret              

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB sprite2x2(sprp, x, y, img, pal, rot, jk)            
  _wstart($3000 + (sprp << 2))
  xsprite(x, y, -16, -16, img + 0, pal, rot, jk)
  xsprite(x, y,   0, -16, img + 1, pal, rot, jk)
  xsprite(x, y, -16,   0, img + 2, pal, rot, jk)
  xsprite(x, y,   0,   0, img + 3, pal, rot, jk)
  _end
}                  
SPR2X2_                                         ' arg0=sprp ; arg1=x ; arg2=y ; arg3=img ; arg4=pal ; arg5=rot ; arg6=jk
              mov       _x,     arg1
              mov       _y,     arg2
              mov       _img,   arg3
              mov       _pal,   arg4
              mov       _rot,   arg5
              mov       _jk,    arg6
              
              shl       arg0, #2                ' _wstart($3000 + (sprp << 2))
              add       arg0, RAMSPR
              call      #WSTART_
              call      #reset
              neg       arg2, #16               ' xsprite(x, y, -16, -16, img + 0, pal, rot, jk)
              neg       arg3, #16
              call      #XSPRITE_
              call      #reset
              mov       arg2, #0                ' xsprite(x, y,   0, -16, img + 1, pal, rot, jk)
              add       arg4, #1
              call      #XSPRITE_
              call      #reset
              neg       arg2, #16               ' xsprite(x, y, -16,   0, img + 2, pal, rot, jk)
              mov       arg3, #0
              add       arg4, #2
              call      #XSPRITE_
              call      #reset
              mov       arg2, #0                ' xsprite(x, y,   0,   0, img + 3, pal, rot, jk) 
              mov       arg3, #0
              add       arg4, #3
              call      #XSPRITE_
              or        outa, SCS               ' _end

SPR2X2__ret   ret

'' support function for sprite2x2
reset         mov       arg0, _x                ' arg0=ox ; arg1=oy ; arg2=x ; arg3=y ; arg4=img ; arg5=pal ; arg6=rot ; arg7=jk
              mov       arg1, _y       
              mov       arg4, _img
              mov       arg5, _pal
              mov       arg6, _rot
              mov       arg7, _jk
reset_ret     ret

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB waitvblank | Flag
  repeat while (m_rd(VBLANK) == 1)
  repeat while (m_rd(VBLANK) == 0)
}
WAITVB_     
              mov       arg0, VBR               ' load the vertical blanking register addr
:loop1        call      #START_                 ' _start(addr)
              call      #SHIFTIO_
              or        outa, SCS                     
              tjnz      inreg, #:loop1          ' repeat while (m_rd(VBLANK) == 1)

:loop2        call      #START_                         
              call      #SHIFTIO_
              or        outa, SCS
              tjz       inreg, #:loop2          ' repeat while (m_rd(VBLANK) == 0)

WAITVB__ret   ret

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB ascii | i, b, h, l
  repeat i from 0 to 767
     b := font8x8[i]
     h := stretch[b >> 4]
     l := stretch[b & 15]
     m_wr($1000 + (" " << 4) + (i << 1) + 0, h)
     m_wr($1000 + (" " << 4) + (i << 1) + 1, l)
  repeat i from $80 to $1FC
     setpal(i + 0, TRANSPARENT)
     setpal(i + 3, RGB(255,255,255))
  fill(RAM_PIC, " ", 4096)
}
ASCII_                                          ' arg0 = @font8x8 ; arg1 = @stretch
              mov       t1, #0                  ' t1 = i
              mov       arg3, arg1              ' arg3 = @stretch
              mov       arg2, arg0              ' arg2 = @font8x8
:loop                                           
              rdbyte    t2, arg2                ' t2 = b
              ror       t2, #4                  ' t2 = b >> 4, preserve lower 4 bits
              add       t2, arg3
              rdbyte    t4, t2                  ' t4 = h
              shr       t2, #28                 ' t2 = b & 15, restore preserved bits
              add       t2, arg3
              rdbyte    t5, t2                  ' t5 = l

              ' (at this point t2 and t3 are reusable) t1=i ; t4=h ; t5=l
                                                ' m_wr($1000 + (" " << 4) + (i << 1) + 0, h)
              mov       t2, #$20 << 3           '      t2 = (" " << 3)
              add       t2, t1                  '      t2 = (" " << 3) + i
              shl       t2, #1                  '      t2 = (" " << 4) + (i << 1)              
              add       t2, RAMCHR              '      t2 =  $1000 + (" " << 4) + (i << 1)
              mov       arg0, t2
              mov       arg1, t4
              call      #WR_
              
              mov       arg0, t2                ' m_wr($1000 + (" " << 4) + (i << 1) + 1, l)
              add       arg0, #1                
              mov       arg1, t5
              call      #WR_

              cmp       t1, c767 wz
        if_z  jmp       #:next
              add       t1, #1                  ' inc i
              add       arg2, #1                ' inc font8x8 pointer
              jmp       #:loop
:next
              mov       t1, #$80                ' t1 = $80
:loop2
              mov       t2, t1                  ' setpal(i + 0, TRANSPARENT)
              mov       arg0, t2
              mov       arg1, TRANSP
              call      #SETPAL_

              mov       arg0, t2                ' setpal(i + 3, RGB(255,255,255))
              add       arg0, #3
              mov       arg1, c32767            ' RGB(255,255,255) = 32767 ($1FFF)
              call      #SETPAL_

              cmp       t1, #$1FC wz
        if_z  jmp       #ASCII__ret
              add       t1, #4
              jmp       #:loop2
              
ASCII__ret    ret

'-------------------------------------------------------------------------------------------------------------------------------
{
PRI GDFB_get1 | r
  if (byte[GDFB_srcp] & GDFB_mask)
    r := 1
  else
    r := 0
  GDFB_mask <<= 1
  if (GDFB_mask == $100)
    GDFB_mask := 1
    GDFB_srcp++
  return r
}
GDFB_get1
              test      GDFB_mask, #1 wz        'Only get new byte from hub when necessary
        if_nz rdbyte    rdbuf, GDFB_srcp

              test      rdbuf, GDFB_mask wz
              muxnz     t1, #1
              shl       GDFB_mask, #1
              test      GDFB_mask, #$100 wz
        if_nz mov       GDFB_mask, #1
        if_nz add       GDFB_srcp, #1

GDFB_get1_ret ret

{
PRI GDFB_getn(n) | r
  r := 0
  repeat while (n--)
    r <<= 1
    r |= GDFB_get1
  return r
}
GDFB_getn
              mov       t2, #0
:loop         shl       t2, #1
              call      #GDFB_get1
              or        t2, t1
              djnz      t3, #:loop
GDFB_getn_ret ret

{  
PUB uncompress(addr, srcp) | b_off, b_len, minlen, items, offset, l
  GDFB_srcp := srcp
  GDFB_mask := 1
  b_off  := GDFB_getn(4)
  b_len  := GDFB_getn(4)
  minlen := GDFB_getn(2)
  items  := GDFB_getn(16)
  repeat while (items--)
    if (GDFB_get1 == 0)
      m_wr(addr++, GDFB_getn(8))
    else
      offset := -GDFB_getn(b_off) - 1
      l := GDFB_getn(b_len) + minlen
      repeat while (l--)
        m_wr(addr, m_rd(addr + offset))
        addr++
}
UNCOMP_                                         ' arg0=addr ; arg1=scrp
              mov       t1, #0
              mov       addr, arg0
              mov       GDFB_srcp, arg1
              mov       GDFB_mask, #1
              mov       t3, #4
              call      #GDFB_getn
              mov       b_off, t2
              mov       t3, #4
              call      #GDFB_getn
              mov       b_len, t2
              mov       t3, #2
              call      #GDFB_getn
              mov       minlen, t2
              mov       t3, #16
              call      #GDFB_getn
              mov       items, t2
:loop1                                          ' repeat while...
              call      #GDFB_get1              '   if (GDFB_get1 == 0)
              tjnz      t1, #:skip1                         
              mov       t3, #8                  '   m_wr(addr++, GDFB_getn(8))
              call      #GDFB_getn
              mov       arg0, addr
              call      #WSTART_                        
              mov       outreg, t2
              call      #SHIFTIO_                      
              or        outa, SCS      

              add       addr, #1
              jmp       #:loop1_end
:skip1                                          ' else
              mov       t3, b_off               '   offset := -GDFB_getn(b_off) - 1
              call      #GDFB_getn
              mov       offset, t2
              add       offset, #1
              mov       t3, b_len               '   l := GDFB_getn(b_len) + minlen
              call      #GDFB_getn
              mov       len, t2
              add       len, minlen
:loop2                                          '     repeat while...
              mov       arg0, addr
              sub       arg0, offset            '       m_rd(addr + offset)
              call      #START_                         
              call      #SHIFTIO_                            
              or        outa, SCS
              mov       t3, inreg               '       [Data returns from SHIFTIO_ on inreg)
              mov       arg0, addr
              call      #WSTART_                '       m_wr(addr, [m_rd from above])
              mov       outreg, t3
              call      #SHIFTIO_                      
              or        outa, SCS      
              add       addr, #1                '       addr++
              djnz      len, #:loop2            '     ... (l--)
:loop1_end    djnz      items, #:loop1          ' ...(items--)
              
UNCOMP__ret   ret

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB putstr(x, y, str)                                 
  _wstart((y << 6) + x)
  repeat while (byte[str])
    transfer(byte[str])
    str++
  _end
}
PUTSTR_                                         ' arg0=x ; arg1=y ; arg2= str
              shl       arg1, #6
              add       arg0, arg1
              call      #WSTART_
:loop
              rdbyte    outreg, arg2 wz
        if_z  jmp       #:done
              call      #SHIFTIO_
              add       arg2, #1
              jmp       #:loop
:done         or        outa, SCS
        
PUTSTR__ret   ret
'-------------------------------------------------------------------------------------------------------------------------------
{
PUB voice(v, wave, freq, lamp, ramp)
  _wstart(VOICES + (v << 2))                                       
  SPI_Send(freq & $FF)
  SPI_Send((freq >> 8) | (wave << 7))
  SPI_Send(lamp)
  SPI_Send(ramp)
  _end
}              
VOICE_                                          ' arg0=v ; arg1=wave ; arg2=freq ; arg3=lamp ; arg4=ramp
              shl       arg0, #2
              add       arg0, RAMVOI
              call      #WSTART_                ' _wstart(VOICES + (v << 2))
              
              mov       outreg, arg2            ' SPI_Send(freq & $FF)
              call      #SHIFTIO_

              shr       arg2, #8                ' SPI_Send((freq >> 8) | (wave << 7))
              mov       outreg, arg2
              shl       arg1, #7
              or        outreg, arg1
              call      #SHIFTIO_

              mov       outreg, arg3            ' SPI_Send(lamp)
              call      #SHIFTIO_

              mov       outreg, arg4            ' SPI_Send(ramp)
              call      #SHIFTIO_
                                                
              or        outa, SCS               ' _end
VOICE__ret    ret

'-------------------------------------------------------------------------------------------------------------------------------
{
PUB RGB(r,g,b)
  return((((r) >> 3) << 10) | (((g) >> 3) << 5) | ((b) >> 3))
}
RGB_                                            ' arg0=r , arg1=g , arg2=b | Value
              shr       arg0, #3                '                             arg3
              shl       arg0, #10               ' (((r) >> 3) << 10)
              mov       t1, arg0

              shr       arg1, #3
              shl       arg1, #5                ' (((g) >> 3) << 5)
              or        t1, arg1

              shr       arg2, #3                ' ((b) >> 3)
              or        t1, arg2
              
              add       retaddr, #12            '   Arg0 = #0 ; Arg1 = #4 ; Arg2 = #8 ; Value = #12
              wrlong    t1, retaddr             ' Write data back to Arg3
              
RGB__ret      ret

'-------------------------------------------------------------------------------------------------------------------------------
LHUB_                                           ' arg0=addr ; arg1=ptr ; arg2=cnt
              call      #START_

:loop         call      #SHIFTIO_
              wrbyte    inreg, arg1
              add       arg1, #1
              djnz      arg2, #:loop
              or        outa, SCS
              
LHUB__ret     ret

'-------------------------------------------------------------------------------------------------------------------------------
BLIT_                                           'arg0=source ; arg1=srcstep ; arg2=dest ; arg3=dststep; arg4=items
              mov       source, arg0
              mov       srcstep, arg1
              mov       dest, arg2
              mov       dststep, arg3
              mov       items, arg4

:loop         call      #START_
              call      #SHIFTIO_
              mov       rdbuf, inreg
              or        outa, SCS
              
              mov       arg0, dest
              call      #WSTART_
              mov       outreg, rdbuf
              call      #SHIFTIO_
              or        outa, SCS

              add       source, srcstep
              add       dest, dststep
              mov       arg0, source
              djnz      items, #:loop

BLIT__ret     ret

'-------------------------------------------------------------------------------------------------------------------------------
TRANSFER_  
              mov       outreg, arg0
              call      #SHIFTIO_
              add       retaddr, #4             ' Arg0 = #0 | rval = #4 
              wrlong    inreg, retaddr          ' (data returns from SHIFTIO_ on inreg)
              
TRANSFER__ret ret

'-------------------------------------------------------------------------------------------------------------------------------
SHIFTIO_      ' Thanks kuroneko
              mov       phsb, outreg            ' idle NCO driving pin lb(MOSI)
              shl       phsb, #24               ' %tttttttt_00000000_00000000_00000000

              or        outa, SCLK              ' Set ClockPin high                                        
              test      MISO, ina wc            ' Read Data Bit into 'C' flag
              rcl       phsb, #1                ' rotate "C" flag into return value
              andn      outa, SCLK              ' Set ClockPin low                                         

              or        outa, SCLK              ' Set ClockPin high                                        
              test      MISO, ina wc            ' Read Data Bit into 'C' flag
              rcl       phsb, #1                ' rotate "C" flag into return value
              andn      outa, SCLK              ' Set ClockPin low
              
              or        outa, SCLK              ' Set ClockPin high                                        
              test      MISO, ina wc            ' Read Data Bit into 'C' flag
              rcl       phsb, #1                ' rotate "C" flag into return value
              andn      outa, SCLK              ' Set ClockPin low

              or        outa, SCLK              ' Set ClockPin high                                        
              test      MISO, ina wc            ' Read Data Bit into 'C' flag
              rcl       phsb, #1                ' rotate "C" flag into return value
              andn      outa, SCLK              ' Set ClockPin low

              or        outa, SCLK              ' Set ClockPin high                                        
              test      MISO, ina wc            ' Read Data Bit into 'C' flag
              rcl       phsb, #1                ' rotate "C" flag into return value
              andn      outa, SCLK              ' Set ClockPin low

              or        outa, SCLK              ' Set ClockPin high                                        
              test      MISO, ina wc            ' Read Data Bit into 'C' flag
              rcl       phsb, #1                ' rotate "C" flag into return value
              andn      outa, SCLK              ' Set ClockPin low

              or        outa, SCLK              ' Set ClockPin high                                        
              test      MISO, ina wc            ' Read Data Bit into 'C' flag
              rcl       phsb, #1                ' rotate "C" flag into return value
              andn      outa, SCLK              ' Set ClockPin low

              or        outa, SCLK              ' Set ClockPin high                                        
              test      MISO, ina wc            ' Read Data Bit into 'C' flag
              rcl       phsb, #1                ' rotate "C" flag into return value
              andn      outa, SCLK              ' Set ClockPin low

              mov       inreg, phsb             ' %00000000_00000000_00000000_rrrrrrrr
SHIFTIO__ret  ret
'------------------------------------------------------------------------------------------------------------------------------

'########################### Assembly variables ###########################

' Constants
d0            long      $200
c767          long      767
c32767        long      32767                   ' RGB(255,255,255)
SPIWTR        long      $8000                   ' Write transaction
TRANSP        long      1 << 15                                                     

' Gameduino memory locations
RAMCHR        long      $1000                   ' Character RAM
RAMPAL        long      $2000                   ' Screen Character Palette, 256 x 8 = 2048 bytes
VBR           long      $2803                   ' Vertical Blanking Regsiter (read only)
RAMVOI        long      $2A00                   ' Voice controls
RAMSPR        long      $3000                   ' Sprite Control, 512 x 4 = 2048 bytes


' Setup I/O pin masks
MOSI          long      0'|< _mosi              
SCLK          long      0'|< _sclk
MISO          long      0'|< _miso
SCS           long      0'|< _scs

'                          MODE  PLL    -      BPIN   -         APIN
ctrbmode      long      0'%0_00100_000_00000000_000000_000 << 6 | _mosi
                            
' Scratchpad
t1            res 1                                                                  
t2            res 1                             
t3            res 1
t4            res 1
t5            res 1

' Shift I/O vars
outreg        res 1
inreg         res 1

' Volitile work vars. (var names overlap for routines that never run in same call; Uncompress, sprite2x2) 
_sprp
source
GDFB_srcp     res 1
dest
_x
GDFB_mask     res 1
srcstep
_y
b_off         res 1
dststep                       
_img
b_len         res 1
_pal
minlen        res 1
_rot
items         res 1
_jk
offset        res 1
len           res 1
addr          res 1
rdbuf         res 1

retaddr       res 1             ' Used to hold return address of first Argument passed

arg0          res 1             ' arguments passed to/from high-level Spin
arg1          res 1         
arg2          res 1         
arg3          res 1         
arg4          res 1         
arg5          res 1         
arg6          res 1         
arg7          res 1         
                                
fit 

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}