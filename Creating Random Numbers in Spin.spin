CON
  _xinfreq=6_250_000  
  _clkmode=xtal1+pll16x     'The system clock is set at 100MHz

'This program demonstrates easy ways to create random numbers using Spin code

OBJ
  pst : "PST_Driver"

PUB RandomExamples | x,seed
  pst.start
  repeat
    pst.str(string("Enter a seed value and press Enter. seed = "))
    seed:=pst.getdec          'Wait for human operator to enter a seed value
    pst.str(string("That seed value always creates a pseudo-random number = "))
    x:=?seed                  'Using the ? operator with a seed value creates a 32-bit pseudo-random number  
    pst.dec(x)                'For example, if you use 42 as the seed value, you will always get 805,306,423
    pst.NewLine               'as the 32-bit pseudo-random number result. Try using 42 a few times in a row. 
    pst.str(string("and when this pseudo-random number is divided by 9 the remainder is always = "))   
    x:=||?seed//9             'You can use the // modulus operator to limit the range of random values
    pst.dec(x)                'e.g. in this case the random number created will be between 0-9. Note that
    pst.NewLine               'if you always use the same seed value, you will always get the same
                              'pseudo-random number in this range. For example, with the seed=42, which leads to 
                              'the pseudo-random number being 805,306,423 you'll always get a remainder of 6
                              'when you divide 805,306,423 by 9 (i.e. the "random" result between 0-9 will be 6)

                              'Here's an easy way around this:
    pst.str(string("But if we now use the cnt value as a seed, we get a completely random number between 0-9 = ")) 
    seed:=cnt                 'This cnt value is essentially random each time this program is run because
    x:=||?seed//9             'of the random amount of time that it takes for a human to enter a value and
    pst.dec(x)                'hit the enter key (humans can't do this with 10ns accuracy every time so as far                                             
    pst.NewLines(2)           'as the user is concerned, this number is now for all intents & purposes totally random.
    pst.str(string("These are also all random numbers at this point...")) 
    pst.Newline
    pst.str(string("Random number between 0-10 = "))  
    seed:=cnt
    x:=||?seed//10            'Divide the random # by 10 and the remainder will be a random number 0-10
    pst.dec(x)
    pst.NewLine
       
    pst.str(string("Random number between 0-100 = "))  
    seed:=cnt
    x:=||?seed//100           'Divide the random # by 100 and the remainder will be a random number 0-100 
    pst.dec(x)
    pst.NewLine
       
    pst.str(string("Random number between 0-255 = "))  
    seed:=cnt                 'If your range is a power of 2, you can simply shift away the bits you don't need
    x:=?seed>>24              'A 32-bit number shifted 24 bits left becomes an 8-bit number (0-255)
                              'You could also use Bitwise AND to lop off bits (e.g. ?seed & %11111111)
    pst.dec(x)                'The processor can do these operations much more quickly than the modulus operation
    pst.NewLines(2)           'so it might be worth working in powers of two if speed is an important factor
    waitcnt(clkfreq+cnt)




  