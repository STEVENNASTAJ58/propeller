{{
****************************************
*  Multiple Frequency Output X31 v1.0  *
*  Author: Brandon Nimon               *
*  Created: September 9, 2009          *
*  Copyright (c) 2009 Parallax, Inc.   *
*  See end of file for terms of use.   *
********************************************************************
* This program grants the ability to output up to 31 frequencies   *
* at once using the resources of only a single cog. With a clock   *
* speed of 80MHz, output can stably reach as high as 320KHz. If    *
* more than one output is used (the main purpose of this program), *
* the maximum frequencies depend on the amount and combination of  *
* frequencies. To approximate: 4000 * MHz / channels. Changing the *
* duty parameter allows programmers to alter the high to low ratio *
* of the frequencies being outputted. The value is the percentage  *
* of high time. If an output is not needed, just enter -1 for the  *
* pin, 0 for the frequency, or 0 for the duty.                     *
*                                                                  *
* Due to the demand of having many frequencies occurring at once,  *
* the goal of this object is to hit an average frequency. The      *
* distance between pulses may vary from one another, and the duty  *
* is only an approximation. The fewer the number of active         *
* channels, and the lower the frequencies being used, the more     *
* accurate the output will be.                                     *
********************************************************************
}}

CON

OBJ

VAR

  byte cogon, cog

PUB start (dutyAddr, pinAddr, freqAddr) | i, j, pinhigh
'' setup and start multi-frequency output

  stop

  pinmask~
  j~
  REPEAT i FROM 0 TO 30
    IF (long[pinAddr][i] => 0 AND long[pinAddr][i] < 32)
      IF (long[freqAddr][i] > 0)
        IF (long[dutyAddr][i] > 0 AND long[dutyAddr][i] < 100)
          pinpers[j] := clkfreq / long[freqAddr][i]
          pinhigh := clkfreq / long[freqAddr][i] * long[dutyAddr][i] / 100
          pinlows[j] := pinpers[i] - pinhigh
          pinmasks[j] := |< long[pinAddr][i]
          pinmask |= |< long[pinAddr][i]
          j++

  IF (j > 0)
    cogon := (cog := cognew(@freqout, 0)) > 0

PUB stop 
'' stop cogs if already in use

  if cogon~
    cogstop(cog)


DAT
                        ORG 0

freqout                        
                        MOV     addtotime, #434
                        SHL     addtotime, #2                                   ' 1736 cycles to add to first start clock

                        MOV     OUTA, #0                                        ' set to low
                        MOV     DIRA, pinmask                                   ' set output pins

                        MOV     countmask, #0
                        MOV     idx, #31
setup
:getper                 MOV     p2, pinpers     WZ                              ' check to see if it is active
              IF_Z      JMP     #:cont
                        MOV     p1, cnt                                         ' set start time
                        ADD     p1, p2                                          ' set next low time
                        ADD     p1, addtotime                        
:setlow                 MOV     timel, p1     
:getlow                 ADD     p1, pinlows                                     ' set high time
:sethigh                MOV     timeh, p1

                        SHL     countmask, #1
                        ADD     countmask, #1                                   ' add position to mask of number of active channels

                        ADD     addtotime, #36
                        ADD     :setlow, dplus1                                 ' add 1 to destination
                        ADD     :sethigh, dplus1                                ' add 1 to destination
                        ADD     :getlow, #1                                     ' add 1 to source
                        ADD     :getper, #1                                     ' add 1 to source
                        DJNZ    idx, #setup
:cont
                        MOV     countmask2, countmask                           ' "backup"

out
getper                  MOV     p1, pinpers
getmask                 MOV     p2, pinmasks                        
gethigh                 MOV     timet, timeh                                    ' test high time against now
                        SUB     timet, cnt                                      ' test high time against now
                        CMP     timet, p1       WZ, WC                          ' test high time against now
              IF_A      JMP     #skiphigh
                        OR      OUTA, p2                                        ' set high
sethigh                 ADD     timeh, p1                                       ' set next high time
skiphigh

getlow                  MOV     timet, timel                                    ' test low time against now
                        SUB     timet, cnt                                      ' test low time against now
                        CMP     timet, p1       WZ, WC                          ' test low time against now
              IF_A      JMP     #skiplow
                        ANDN    OUTA, p2                                        ' set low
setlow                  ADD     timel, p1                                       ' set next low time
skiplow


                        SHR     countmask, #1   WC                              ' test if next pin is acutally being used, if not, reset back to beginning
              IF_NC     JMP     #reset 

                        ADD     getper, #1                                      ' add 1 to source
                        ADD     gethigh, #1                                     ' add 1 to source
                        ADD     getlow, #1                                      ' add 1 to source
                        ADD     getmask, #1                                     ' add 1 to source
                        ADD     sethigh, dplus1                                 ' add 1 to destination
                        ADD     setlow, dplus1                                  ' add 1 to destination
                        JMP     #out                                            ' check next pin

reset
                        MOV     countmask, countmask2
                        MOVS    getper, #pinpers                                ' reset source                                              
                        MOVS    getmask, #pinmasks                              ' reset source
                        MOVS    gethigh, #timeh                                 ' reset source
                        MOVS    getlow, #timel                                  ' reset source
                        MOVD    sethigh, #timeh                                 ' reset destination
                        MOVD    setlow, #timel                                  ' reset destination
                        JMP     #out                                            ' do it all again


dplus1                  LONG    1 << 9                                          ' destination plus one value

pinpers                 LONG    0 [31]
pinlows                 LONG    0 [31]
pinmasks                LONG    0 [31]

pinmask                 LONG    0

countmask               RES
countmask2              RES

addtotime               RES
timel                   RES     31
timeh                   RES     31
idx                     RES
p1                      RES
p2                      RES
timet                   RES  

                        FIT 496

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