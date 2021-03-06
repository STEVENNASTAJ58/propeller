{{
┌─────────────────────────────────┬──────────────────┬───────────────────┐
│ 64K_BootEEPROM_Driver.spin v1.0 │ Author:I.Kövesdi │ Rel.:05 July 2009 │
├─────────────────────────────────┴──────────────────┴───────────────────┤
│                    Copyright (c) 2009 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│  This is an I2C driver object for the System Boot EEPROM on I/O pins of│
│ 28/29 of the Propeller. The driver is written in SPIN and is aimed for │
│ 64K 24LS512 EEPROMs only. For 32K 24LS256 type System Boot EEPROMs,    │
│ make and use a 32K_BootEEPROM_Driver instead. See Note below. The 32K  │
│ variant can handle both types, but uses only half the available frame  │
│ buffer size in 64K chips. This only affects the block write speed a    │
│ little bit, but the user can address all the 64K range of the 24LS512  │
│ EEPROMs.                                                               │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│ - The external serial I2C EEPROM on I/O pins of 28/29 is an optional,  │
│ but very practical permanent memory, and the Propeller can boot from   │
│ it, if communication from a host is not detected.  After any type of   │
│ Boot-Up procedure completes (there are three of them), this EEPROM may │
│ be accessed as any other external peripherial.                         │
│ - The System Boot EEPROM I2C bus of the Propeller somewhat deviates    │
│ from the standard hardware setup of I2C buses. With the Propeller, only│
│ the SDA line is pulled up to VCC with a 10K resistor, the SCL line is  │
│ not. As a result, the controlling of these line is different in the    │
│ driver. This I2C bus is assumed to be a single Master bus and the SCL  │
│ line is driven directly (and only) by the "Master" Propeller as the    │
│ System Boot EEPROM will not initiate any data transfer on that bus. You│
│ can connect more I2C slave devices onto this bus if you like, but not  │
│ masters.                                                               │
│                                                                        │  
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│ - To make the 32K System Boot EEPROM driver you have to change only one│
│ line in this code in the CON section.                                  │
│ - You can use the so obtained 32K driver for the 24LS512 EEPROMs, as   │
│ well, but you can't use this 64K driver for the 24LS256 chips          │
│ - Warning for those who are using the 32K System Boot EEPROM (24LS256) │
│ and for those who are using the lower 32K address space of a 64K       │
│ (24LS512) System Boot EEPROM:                                          │
│ - Downloading a program into EEPROM overwrites ALL lower 32K EEPROM    │
│ data! So, if you collected or created some data in that address space  │
│ of the System Boot EEPROM, that will be lost at the next "program to   │
│ EEPROM" download. Completed applications (no more EEPROM downloads) can│
│ live and work happily with this feature, but during development this   │
│ will cause some inconvenience.                                         │
│ - Programs are stored in EEPROM and HUB RAM, starting at the smallest  │
│ byte address and building toward larger addresses. So, use the upper   │
│ part of the first 32K EEPROM space for your data collection or storage │
│ if you don't want to overwrite the stored program there. Use F8 to view│
│ the application's memory map to find out how many bytes are left for   │
│ you in the System Boot EEPROM below the 32767 byte address.            │
│ - Avoid writing to the EEPROM frequently and repeteadly to the same    │
│ address. It is not designed for that, as it can wear out after a       │
│ million, or so, writes. Writing to the same cell in every second means │
│ an EEPROM replacement in every two weeks.                              │
│ - When your datalogging needs a storage of a lot of data, sound files  │
│ or pictures for example, that arrives at high pace, use SD cards or USB│
│ memory sticks instead of EEPROMs. However, external EEPROM blocks are  │
│ usually adequate for the reliable and long term recording of  smaller  │
│ amount of data bytes. E.g., Lat, Lon, Alt position and Time data (16B) │
│ can be written in every second for more than nine hours in a block of  │
│ eight 24LS512 EEPROMs.                                                 │
│                                                                        │ 
└────────────────────────────────────────────────────────────────────────┘
}}


CON

'Propeller / System Boot 24LS512 EEPROM interface hardware----------------
_SDA = 29                        'Propeller A29 to EEPROM i2c data line
                                 'This line is pulled up to VCC with 4K7
                             
_SCL = 28                        'Propeller A28 to EEPROM i2c clock line
                                 'This line is not pulled up to VCC and is
                                 'driven directly by the Propeller

'24LS series EEPROM constants
_EEPROM_CONTROL  = %1010_0000    '4 bit contol code for 24LS series chips
                  '          
                   
_EEPROM_CHIPSEL  = %0000_0000    'EEPROM chipselect, all pulled to GND
                  '            (addr = $000) for Propeller System Boot
                                 ' EEPROM

_EEPROM_READBIT  = %0000_0001    'EEPROM Read/Write Bit, 1 for read
                   '        
                   '                 
_EEPROM_WRITEBIT = %0000_0000    'EEPROM Read/Write Bit, 0 for write


'*************************************************************************
'There follows the only difference between the 64K and the 32K Drivers                    
'_EEPROM_FRAME    = 64    'Frame size for 24LS245 (For the 32K variant)
_EEPROM_FRAME    = 128   'Frame size for 24LS512 (For this 64K variant)
                                

'Composit EEPROM codes
_EEPROM_READ     = _EEPROM_CONTROL | _EEPROM_CHIPSEL | _EEPROM_READBIT  
_EEPROM_WRITE    = _EEPROM_CONTROL | _EEPROM_CHIPSEL | _EEPROM_WRITEBIT 

'I2C constants
_ACK = 0             '    Acknowledged when SDA = 0 for the ACK bit
_NAK = 1             'Not acknowledged when SDA = 1 for the ACK bit
  

DAT '------------------------Start of SPIN code---------------------------
  

PUB Init : oK
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ Init │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: - Sets System Boot EEPROM SCL as output
''             - Checks presence of System Boot EEPROM
'' Parameters: None
''     Result: TRUE if System Boot EEPROM present else FALSE
''+Reads/Uses: /_SCL, _EEPROM_WRITE
''    +Writes: None
''      Calls: I2C_Start
''             I2C_WriteEEByte
'-------------------------------------------------------------------------
DIRA[_SCL]~~                             'Set SCL as output
I2C_Start                                'Send I2C start condition
RESULT:=!I2C_WriteEEByte(_EEPROM_WRITE)  'Check System Boot EEPROM present
'-------------------------------------------------------------------------


PUB Write(startHUBAddr,endHUBAddr,startEEAddr)|addr,frameB,eeAddr
'-------------------------------------------------------------------------
'---------------------------------┌───────┐-------------------------------
'---------------------------------│ Write │-------------------------------
'---------------------------------└───────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Writes a block of bytes from HUB to EEPROM
'' Parameters: - Start address of data in HUB
''             - End address of data in HUB
''             - Start address of data in EEPROM
''     Result: None
''+Reads/Uses: _EEPROM_FRAME
''    +Writes: None
''      Calls: Set_EEPROM_Address
''             I2C_WriteEEByte
''             I2C_Stop
'-------------------------------------------------------------------------
addr := startHUBAddr                     'Initialize HUB address
eeAddr := startEEAddr                    'Initialize EEPROM's addr pointer
REPEAT
  'EEPROM frame boundary 
  frameB:=addr+_EEPROM_FRAME-eeAddr//_EEPROM_FRAME<#endHUBAddr+1      
   Set_EEPROM_Address(eeAddr)            'Set EEPROM's address pointer
  REPEAT                                 'Frame Write loop
    I2C_WriteEEByte(BYTE[addr++])        'Copy a byte from HUB to EEPROM 
  UNTIL addr == frameB                   'Until Frame Data is full
  I2C_Stop                               'Initiate EEPROM Frame Write loop
  eeAddr:=addr-startHUBAddr+startEEAddr  'Initialize next EEPROM address
UNTIL addr >endHUBAddr                   'Quit when all done
'-------------------------------------------------------------------------


PUB Read(startHUBAddr,endHUBAddr,startEEAddr)|addr
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ Read │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Reads a block of bytes from EEPROM to HUB RAM
'' Parameters: - Start address of data in HUB
''             - End address of data in HUB
''             - Start address of data in EEPROM
''     Result: None
''+Reads/Uses: /_EEPROM_FRAME, _ACK, _NAK
''    +Writes: None
''      Calls: Set_EEPROM_Address
''             I2C_Start
''             I2C_WriteEEByte
''             I2C_ReadEEByte
''             I2C_SendACKBit
''             I2C_Stop
'-------------------------------------------------------------------------
Set_EEPROM_Address(startEEAddr)   'Set EEPROM's address pointer

I2C_Start
I2C_WriteEEByte(_EEPROM_READ)     'Initiate Read opration

'Read EEPROM bytes sequentially 
REPEAT addr FROM startHUBAddr TO endHUBAddr      
  BYTE[addr] := I2C_ReadEEByte    'Copy a byte from EEPROM to HUB  
  IF (addr < endHUBAddr)          'Not last byte?
    I2C_SendACKBit(_ACK)          'Acknowledge received byte
'Stop sequential read after last byte  
I2C_SendACKBit(_NAK)              'Send NAK
I2C_Stop                          'Stop bus
'-------------------------------------------------------------------------


PRI Set_EEPROM_Address(addr) | aCK
'-------------------------------------------------------------------------
'-------------------------┌────────────────────┐--------------------------
'-------------------------│ Set_EEPROM_Address │--------------------------
'-------------------------└────────────────────┘--------------------------
'-------------------------------------------------------------------------
'     Action: Sets EEPROM internal address counter
' Parameters: Address in EEPROM
'     Result: None
'+Reads/Uses: /_EEPROM_WRITE
'    +Writes: None
'      Calls: I2C_Start
'             I2C_WriteEEByte
'-------------------------------------------------------------------------
'Wait while the Internal Write Cycle of the EEPROM is not complete.  
aCK~~                                    'aCK=1 to drop in loop
REPEAT                                   'Poll EEPROM for ACK
  I2C_Start                              'Send I2C start condition
  aCK := I2C_WriteEEByte(_EEPROM_WRITE)  'Write EEPROM control byte
WHILE aCK                                'Repeat WHILE aCK==_NAK=1

'EEPROM is ready now to accept address             
I2C_WriteEEByte(addr >> 8)               'Send address high byte
I2C_WriteEEByte(addr)                    'Send address low byte
'-------------------------------------------------------------------------

  
PRI I2C_Start
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ I2C_Start │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Starts I2C bus
' Parameters: None
'     Result: None
'+Reads/Uses: /_SCL, _SDA
'    +Writes: None
'      Calls: None
'       Note: I2C start condition: SDA goes from HIGH to LOW while
'             SCL is HIGH
'-------------------------------------------------------------------------
OUTA[_SCL]~~     'Set SCL output state to HIGH
DIRA[_SDA]~      'Let SDA line pulled up HIGH by 10K
'Everything is prepared to generate a START condition
OUTA[_SDA]~      'Set SDA output state to LOW 
DIRA[_SDA]~~     'Set SDA as output, line is driven LOW by Prop
'------------------------------------------------------------------------- 


PRI I2C_Stop
'-------------------------------------------------------------------------
'-------------------------------┌──────────┐------------------------------
'-------------------------------│ I2C_Stop │------------------------------
'-------------------------------└──────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Stops I2C bus
' Parameters: None
'     Result: None
'+Reads/Uses: _SCL, _SDA
'    +Writes: None
'      Calls: None
'       Note: I2C stop condition: SDA goes from LOW to HIGH while
'             SCL is HIGH
'-------------------------------------------------------------------------
OUTA[_SDA]~      'Set SDA output state to LOW 
DIRA[_SDA]~~     'Set SDA as output, line driven LOW by Prop 
OUTA[_SCL]~~     'Set SCL output state to HIGH, line driven HIGH by Prop
'Everything is prepared for a STOP
DIRA[_SDA]~      'Let SDA line pulled up HIGH by 10K  
'-------------------------------------------------------------------------



PRI I2C_WriteEEByte(b) : aCK | i
'-------------------------------------------------------------------------
'----------------------------┌─────────────────┐--------------------------
'----------------------------│ I2C_WriteEEByte │--------------------------
'----------------------------└─────────────────┘--------------------------
'-------------------------------------------------------------------------
'     Action: Writes a byte into the EEPROM
' Parameters: Data byte
'     Result: Acknowledge bit from EEPROM  
'+Reads/Uses: _SCL, _SDA
'    +Writes: None
'      Calls: None
'-------------------------------------------------------------------------
b ><= 8                      'Reverse bits for shifting MSB right
OUTA[_SCL]~                  'SCL low, _SDA can change
REPEAT 8                     'Send 8 bits
  OUTA[_SDA] := b            'Lowest bit sets _SDA
  OUTA[_SCL]~~               'Start clock pulse
  OUTA[_SCL]~                'Stop clock pulse
  b >>= 1                    'Shift b right for next bit
  
'Get ACK bit from EEPROM
DIRA[_SDA]~                  'Let SDA line driven by slave or 10K
OUTA[_SCL]~~                 'Start a pulse on SCL
aCK := INA[_SDA]             'Read ACK bit from EEPROM
OUTA[_SCL]~                  'Stop SCL pulse
OUTA[_SDA]~                  'Set SDA output state to LOW
DIRA[_SDA]~~                 'Set SDA as output, line driven LOW by Prop
'-------------------------------------------------------------------------


PRI I2C_ReadEEByte : b
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ I2C_ReadEEByte │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Reads a byte from the EEPROM
' Parameters: None
'     Result: Data byte 
'+Reads/Uses: _SCL, _SDA
'    +Writes: None
'      Calls: None
'-------------------------------------------------------------------------
DIRA[_SDA]~                    'Let SDA line driven by slave or 10K  
REPEAT 8                       'Clock in the byte
  OUTA[_SCL]~~                 'Start clock pulse
  b := (b << 1) | INA[_SDA]    'Read in SDA line into LSB of input 
  OUTA[_SCL]~                  'Finish clock pulse 
'-------------------------------------------------------------------------


PRI I2C_SendACKBit(aCK)
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ I2C_SendACKBit │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Sends an ACK bit to EEPROM
' Parameters: ACKnowledge bit
'     Result: None 
'+Reads/Uses: _SCL, _SDA 
'    +Writes: None
'      Calls: None
'-------------------------------------------------------------------------
DIRA[_SDA] := !aCK             'Send the ACK or NAK
OUTA[_SCL]~~                   'Start clock pulse 
OUTA[_SCL]~                    'Stop clock pulse
'-------------------------------------------------------------------------


DAT '---------------------------MIT License-------------------------------

{{

┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}                  