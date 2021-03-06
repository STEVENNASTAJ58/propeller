{{
  Play Station 2 Controller driver demo v1.1

  Author: Juan Carlos Orozco
  Copyright 2007 Juan Carlos Orozco ACELAB LLC
  http://www.acelab.com
  Industrial Automation

  License: See end of file for terms of use.

  Program to test PS2_Controller object
  Use a terminal with 19200N1 settings to see live data from Controller.

  Use the Sony Playstation Controller Cable (adapter) from LynxMotion
  http://www.lynxmotion.com/Product.aspx?productID=73&CategoryID=

  Connect DAT, CMD, SEL, CLK signals to four consecutive pins of the propeller
  DAT should be the lowest pin. Use this pin when calling Start(first_pin)
  DAT (Brown), CMD (Orange), SEL (Blue) and CLK (Black or White) 
  Use a 1K resistor from Propeller output to each controller pin.
  Use a 10K pullup to 5V for DAT pin. 

  Conect Power 5V (Yellow) and Gnd (Red covered with black)
}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000                      

OBJ
  Num : "Simple_Numbers"
  Serial: "Simple_Serial"
  PS2 : "PS2_Controller"

PUB Main
  Serial.init(31, 30, 19200)  'Use the USB connection that is used to progam the Propeller.

  PS2.Start(0, 5000) 'first_pin 0, Poll every 5ms  (1ms works for MadCatz wired but not for Predator wireless)
  Repeat
    Display

PUB Display
  waitcnt(clkfreq/4 + cnt)
  'Serial.str(Num.dec(Pulse_High_Ticks))
  'Serial.str(Num.dec(Pulse_Low_Ticks))
  'Serial.str(Num.dec(Delay_Ticks))
  Serial.str(Num.ihex(PS2.get_Data1,8))
  Serial.str(Num.ihex(PS2.get_Data2,8))
  Serial.str(Num.decf(PS2.get_RightX,4))
  Serial.str(Num.decf(PS2.get_RightY,4))
  Serial.str(Num.decf(PS2.get_LeftX,4))
  Serial.str(Num.decf(PS2.get_LeftY,4))
  Serial.str(string("       "))
  'Send carriage return so no new line is created and data is overwritten in the same line
  Serial.tx(13)

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