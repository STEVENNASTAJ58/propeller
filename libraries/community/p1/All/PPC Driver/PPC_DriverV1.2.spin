'' Paralax_Position_Controller_Driver
'' PPC_DriverV1.2
''******************************************************************************* 
''*****  This driver is used to allow the control of the Parallax Position *****
''*****  Controller (PPC) using only a Speed and Turn input. One way this   ***** 
''*****  can be used is with an RC input. Using this driver, you can        ***** 
''*****  control a robot with a joystick and not have to be bothered by     ***** 
''*****  the details of how the PPC work. Specifically the need for a       ***** 
''*****  distance to travel value.                                          *****
''*****                                                                     *****   
''*****  Michael Boswell                                                    ***** 
''*****  Michael@Hilltopcafe.net                                            ***** 
''*****                                                                     ***** 
''*****  Copyright (c) Michael Boswell                                      ***** 
''*****  See end of file for terms of use.                                  ***** 
''*****                                                                     *****  
''*****  Last updated 6/26/09                                               *****
''*****                                                                     *****
''*****                                                                     *****
''***** v1.1 first public release                                           *****
''***** v1.2 embeded PauseMsec and PauseSec as PRI                          *****
''*****                                                                     *****
''*****                                                                     *****    
''******************************************************************************* 

OBJ

  DrvMtr : "Simple_Serial"

                    
  
CON
  WMin  = 381
  QPOS  = $08
  QSPD  = $10
  CHFA  = $18
  TRVL  = $20
  CLRP  = $28
  SREV  = $30
  STXD  = $38
  SMAX  = $40
  SSRR  = $48
  AllWheels     = 0
  RightWheel    = 1
  LeftWheel     = 2
  
VAR
  Long MtrCogNum
  Long MtrCogRunning
  Long MtrCogStack[100]  ' no attempt has been made to optimize the stack size. I expect that 100 is WAY to large.
  Long Cur_Spd           ' Holds the last selected speed
  Long Req_Spd           ' Holds the currently selected speed value
  Long Req_Turn          ' Holds the currently selected turn value


PUB start(MtrDrvPin)

'' Start MtrLoop - starts a cog
'' returns false if no cog available
''
   
  MtrCogRunning := (MtrCogNum := cognew(MtrDrvLoop(MtrDrvPin),@MtrCogStack)) > 0

PUB stop

''  Stop MtrDrv - frees a cog

  if MtrCogRunning~
    cogstop(MtrCogNum)


PUB MtrDrvLoop  (MtrPin) | NxtSpd , Dir, NxtTurn, LorR

''******************************************************************************* 
''*****  This is the main loop for controlling the PPC. First it            *****
''*****  initializes the PPC and loop variables and then begins             ***** 
''*****  positive control                                                   ***** 
''*****                                                                     ***** 
''******************************************************************************* 


   PauseSec(1)                              ' Pause to ensure PPC's have time to power up (likely could be reduced)
   
   DrvMtr.start (MtrPin,MtrPin,19200)            ' Establish comunications to PPC
   PauseMSec(100)                           ' Short dealy prior to sending first commands

 
   ClearPosition(AllWheels)                      ' This is incase the prop is reset and the PPC is still executing commands prior to reset
   PauseMsec(100)                           ' Quiet period after a ClearPosition command
   SetAsReversed(LeftWheel)                      ' This might need to be changed depending upon what direction is "Forward"
   SetSpeedRamp(AllWheels,30)                    ' This is set to meet my needs and can be changed as needed. The PPC default would be 15
   
   Cur_Spd := 0                                  ' Initialize variables
   Req_Turn := 0
   Req_Spd := 0


  Repeat                                          ' Begin the control loop

       Case  ||Req_Spd                            ' This is a table that converts RC values of 0-128 into six steps
          0..19      : NxtSpd :=   0              ' The number of steps and the values can be changed to meet your needs
          20..39     : NxtSpd :=   4
          40..59     : NxtSpd :=   8
          60..79     : NxtSpd :=  12
          80..99     : NxtSpd :=  16
         100..128    : NxtSpd :=  20

       Case  ||Req_Turn
          0..19      : NxtTurn :=   0             ' This table is used to assign 6 different turn speeds or speed delta between the two wheels
          20..39     : NxtTurn :=   3             ' you could add more steps and change the values for different effects
          40..59     : NxtTurn :=   4
          60..79     : NxtTurn :=   8
          80..99     : NxtTurn :=  11
         100..128    : NxtTurn :=  14           

       If NxtSpd > 0
          NxtSpd #>= Cur_Spd      ' Whicever is greater. You can increase the speed but not decrease it (except if is Zero)
                                  ' This is because the PPC does not automaticaly ramp speeds down, only up. I find in practice that this is not too bad

''******************************************************************************* 
''*****  The speed input is in a range from -128 to +128. Turns are also    *****
''*****  in the range of -128 to +128. The next two IF statements determine ***** 
''*****  if we are going forward or backwards and turning left or right     ***** 
''*****  based on the RC input (REQ_XXX)                                    ***** 
''******************************************************************************* 



       If Req_Spd > 0              ' Set the direction of travel (Forward or backwards)
          Dir := -1
       Elseif Req_Spd < 0
          Dir := 1

       If Req_Turn > 0               ' do we turn left or right
          LorR := -1
       ElseIf Req_Turn <0
          LorR := 1
             
''******************************************************************************* 
''*****  This is where the commands are sent to the PPC. In order to mimic  *****
''*****  and RC controlled unit, the algorithm calculates a distance to     ***** 
''*****  travel  that will keep things in motion until the next loop        *****
''*****  There are four cases of possible movement                          ***** 
''******************************************************************************* 

      If NxtSpd+NxtTurn == 0                            ' Not turning but stopping
          GoForward(AllWheels,0)

      Elseif (NxtSpd == 0)AND (NxtTurn > 0)              ' stopped but Turning
          SetMaxSpeed(AllWheels,NxtTurn)                ' set speed of turn
          GoForward(LeftWheel,NxtTurn * 10 * -LorR)       ' set a distance to travel that is positive or negative based or Left or Right (LorR) variable set above
          GoForward(RightWheel,NxtTurn * 10 * LorR)       ' The *10 is the distance to travel estimate to keep it going until next loop
        
      Elseif (NxtSpd > 0) AND (NxtTurn == 0)             ' Forward with no Turning                                  
          SetMaxSpeed(AllWheels,NxtSpd)   
          GoForward(AllWheels,NxtSpd * 3 * Dir)           ' * 3 is distance to travel estimate to keep it going until next loop.

      ElseIf (NxtSpd > 0) AND (NxtTurn > 0)              ' forward and turning
          SetMaxSpeed(LeftWheel,NxtSpd + (NxtTurn  * LorR))
          SetMaxSpeed(RightWheel,NxtSpd + (NxtTurn * -LorR))   
          GoForward(AllWheels,NxtSpd * 3 * Dir)
        
      PauseMSec(20)
      Cur_Spd := NxtSpd


''******************************************************************************* 
''*****  This is the object to call to set the speed and turn amount        *****
''*****  After initialization, this and Emergency Stop are the only two     ***** 
''*****  objects that need to be called to use the driver.                  *****
''******************************************************************************* 

PUB MtrMove(Spd,Turn)                     ' input a speed and amount of turn, translate this into Position Controller commnands

        Req_Spd := Spd                    ' Scale is -128 to +128 for full reverse to full forward
        Req_Turn := Turn                  ' Scale is -128 to +128 for full left to full right turn
        
PUB EmergencyStop                          ' Stop things imediatly

        Req_Spd := 0
        Req_Turn := 0
        ClearPosition(allWheels)

''******************************************************************************* 
''*****  The following routines are not all tested or needed for the above  *****
''*****  You could expose them to other code by making them PUB instead of  ***** 
''*****  PRI.                                                               *****
''*****                                                                     ***** 
''******************************************************************************* 



PRI PauseMSec(Duration)
{{Pause execution in milliseconds.
  PARAMETERS: Duration = number of milliseconds to delay.
}}
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> WMin) + cnt)                                     
  

PRI PauseSec(Duration)
{{Pause execution in seconds.
  PARAMETERS: Duration = number of seconds to delay.
}}
  waitcnt(((clkfreq * Duration - 3016) #> WMin) + cnt) 
      
PRI GetSpeed (Wheel)   | SPD
   DrvMtr.TX(QSPD + Wheel)
   SPD := 0
   SPD.BYTE[1] := DrvMtr.RX
   SPD.BYTE[0] := DrvMtr.RX
   Return SPD

PRI ChkForArrival (Wheel, Tollerance) | Arvd
  DrvMtr.TX(CHFA + Wheel)
  DrvMtr.TX(Tollerance.BYTE[0])
  Arvd.BYTE[0] := DrvMtr.RX
  Return Arvd   

PRI SetTXDelay (Wheel,Delay)                                                               
  DrvMtr.TX(STXD + Wheel)
  DrvMtr.TX(Delay.BYTE[0])  

PRI ClearPosition(Wheel)
   DrvMtr.TX(CLRP+Wheel)


PRI GoForward (Wheel, Dist)
   DrvMtr.TX(TRVL + Wheel)
   DrvMtr.TX(Dist.BYTE[1])
   DrvMtr.TX(Dist.BYTE[0])

   
PRI SetMaxSpeed (Wheel, MaxSpeed) 
   DrvMtr.TX(SMAX + Wheel)
   DrvMtr.TX(MaxSpeed.BYTE[1])
   DrvMtr.TX(MaxSpeed.BYTE[0])

PRI SetSpeedRamp (Wheel,Rate) 
  DrvMtr.TX(SSRR + Wheel)
  DRVMTR.TX(Rate.BYTE[0])

PRI SetAsReversed (Wheel) 
  DrvMtr.TX(SREV + Wheel)
  
DAT                             
'***************************************
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
   
      