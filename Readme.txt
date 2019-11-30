---------------------------------------------------------------------------------------

    CRT Emudriver 2.0 beta 15 (based on Catalyst 12.6, Crimson 16.2.1, Adrenalin 18.5.1)
       for Windows 7/8/10 64-bit

    CRT Tools 2.0 beta 15 (VMMaker & Arcade OSD)

    by Calamity - January 2019

    for further documentation, visit: http://geedorah.com/eiusdemmodi/

---------------------------------------------------------------------------------------

[to be documented...]


Catalyst 12.6  (Windows 7/8/10): AMD Radeon™ HD 2000, HD 3000, HD 4000, HD 5000, HD 6000, HD 7000 Series

Crimson 16.2.1 (Windows 7/8/10 non-GCN* cards):
                        Desktop: AMD Radeon™ HD 5000, HD 6000 Series, HD 7000-7600, HD 8000-8400 Series
                                 AMD Radeon™ R5 235X, R5 235, R5 230, R5 220 Series
             All-in-One Desktop: AMD Radeon™ HD 6350A, HD 6600A, HD 7450A, HD 7600A Series
                            APU: AMD Radeon™ HD 6000D, HD 7000D, HD 8000D, HD 6000G, HD 7000G, HD 8000G Series
	               Mobility: AMD Radeon™ HD 5000M, HD 6000M Series

Crimson 16.2.1 (Windows 7/8/10 for GCN* cards):
                        Desktop: AMD Radeon™ HD 7700-7900, HD 8500-8900 Series
                                 AMD Radeon™ R7 200, R7 300, R9 200, R9 300, R9 Nano, R9 Fury Series
                            APU: AMD A-Series APUs with Radeon™ R4, R5, R6, or R7 Graphics	
                                 AMD Pro A-Series APUs with Radeon™ R5 or R7 Graphics	
                                 AMD Athlon™ Series APUs with Radeon™ R3 Graphics	
                                 AMD Sempron™ Series APUs with Radeon™ R3 Graphics	
                                 AMD A-Series APUs with Radeon™ R3, R4, R5, R6, R7, or R8 Graphics
                                 AMD Pro A-Series APUs with Radeon™ R5, R6, or R7 Graphics
                                 AMD FX-Series APUs with Radeon™ R7 Graphics
                                 AMD E-Series APUs with Radeon™ R2 Graphics
                                 AMD Radeon™ HD 8180 - HD 8400 Series Graphics
                       Mobility: AMD Radeon™ R9 M300, R7 M300, R9 M200, R7 M200, R5 M200 Series           
                                 AMD Radeon™ HD 7700M-7900M, HD 8500M-8900M Series

Adrenalin 18.5.1 (Windows 7/8/10 for GCN* cardsfor GCN* cards):
                        Desktop: Radeon RX Vega Series Graphics
                                 Radeon™ RX 500 Series Graphics
                                 Radeon™ RX 400 Series Graphics
                                 AMD Radeon™ Pro Duo
                                 AMD Radeon™ R7 300 Series Graphics
                                 AMD Radeon™ R7 200 Series Graphics
                                 AMD Radeon™ R9 Fury Series Graphics
                                 AMD Radeon™ R5 300 Series Graphics
                                 AMD Radeon™ R9 Nano Series Graphics
                                 AMD Radeon™ R5 200 Series Graphics
                                 AMD Radeon™ R9 300 Series Graphics
                                 AMD Radeon™ HD 8500 - HD 8900 Series Graphics
                                 AMD Radeon™ R9 200 Series Graphics
                                 AMD Radeon™ HD 7700 - HD 7900 Series Graphics
                          Ryzen: AMD Ryzen 5 2400G
                                 AMD Ryzen 3 2200G
                       Mobility: AMD Radeon™ R9 M300 Series Graphics
                                 AMD Radeon™ R7 M200 Series Graphics
                                 AMD Radeon™ R7 M300 Series Graphics
                                 AMD Radeon™ R5 M200 Series Graphics
                                 AMD Radeon™ R5 M300 Series Graphics
                                 AMD Radeon™ HD 8500M - HD 8900M Series Graphics
                                 AMD Radeon™ R9 M200 Series Graphics
                                 AMD Radeon™ HD 7700M - HD 7900M Series Graphics
                            APU: AMD A-Series APUs with Radeon™ R4, R5, R6, or R7 Graphics
                                 AMD A-Series APUs with Radeon™ R3, R4, R5, R6, R7, or R8 Graphics
                                 AMD Pro A-Series APUs with Radeon™ R5 or R7 Graphics
                                 AMD Pro A-Series APUs with Radeon™ R5, R6, or R7 Graphics
                                 AMD Athlon™ Series APUs with Radeon™ R3 Graphics
                                 AMD FX-Series APUs with Radeon™ R7 Graphics
                                 AMD Sempron™ Series APUs with Radeon™ R3 Graphics
                                 AMD E-Series APUs with Radeon™ R2 Graphics
                                 AMD Radeon™ HD 8180 - HD 8400 Series Graphics

*https://en.wikipedia.org/wiki/Graphics_Core_Next

Version 2
---------

[28/01/2019][CRT Emudriver 2.0][CRT Tools 2.0][beta 15]

  - [Emudriver]  New driver packages based on Adrenalin 18.5.1. Lots of new AMD GPUs & APUs supported.
                 Fixes support for 4K custom resolutions which is broken on official AMD drivers.

  - [Arcade OSD] Implemented new rendering backend based on Direct3D9Ex. This allows fluid page
                 flipping on modern versions of Windows, making it possible to perform accurate refresh
                 measurements again. It also fixes some compatibility issues. DirectDraw now is only
                 used on Windows XP.

  - [VMMaker]    Fixed bug that caused EDID emulation device list to appear empty.

  - [VMMaker]    Fixed EDID emulation through HDMI for new GPUs, previously it caused unstability.

  - [VMMaker]    Several bugs fixed regarding internal management of mode lists.


[19/10/2018][CRT Emudriver 2.0][CRT Tools 2.0][beta 14]

  - [Emudriver]  Removed low pixel clock limitation on HDMI outputs. This allows outputting
                 15 kHz through HDMI in combination with HDMI->VGA active adapters.

  - [VMMaker]    Added support for EDID emulation on digital outputs (HDMI and DVI-D).
                 EDID emulation drop-down menu now shows outputs by type.
                 DisplayPort still not supported.

  - [VMMaker]    Support for pixelclocks up to 6 GHz.
                 Modeline generation now possible from 15 kHz up to 8K fulldome.
                 Bandwidth limitations imposed by drivers still apply.

  - [VMMaker]    Fix XML processing of newer versions of MAME.


[07/03/2018][CRT Emudriver 2.0][CRT Tools 2.0][beta 13]

  - [VMMaker]    Fix composite sync for HD 5000+ cards.


[23/12/2017][CRT Emudriver 2.0][CRT Tools 2.0][beta 12]

  - [VMMaker]    Added support for composite sync.

  - [Emudriver]  New fix to allow stable support for composite sync for legacy cards (only applies to
                 package based on Catalyst 12.6).


[24/11/2017][CRT Emudriver 2.0][CRT Tools 2.0][beta 11]

  - [Emudriver]  Disabled deflicker filter for interlaced modes. Now your interlaced modes will look
                 perfectly sharp, with all their genuine flicker intact.

  - [VMMaker]    Fixed bug that caused CRT Emudriver not being detected under Windows XP.

  - [VMMaker]    Added new preset for 15/31 kHz dual-sync monitor.


[03/03/2017][CRT Emudriver 2.0][CRT Tools 2.0][beta 10]

  - [VMMaker]    Added option to include multiple modelines in emulated EDID. When enabled, the
                 current modelist is added to the EDID definition (maximum of 20 modes supported).
                 If disabled, only a 640x480 modeline will be included, as usual.

  - [VMMaker]    Fixed bug that caused newer video cards to be incorrectly detected as legacy ones.


[08/02/2017][CRT Emudriver 2.0][CRT Tools 2.0][beta 9]

  - [Emudriver]  New driver packages based on Crimson 16.2.1. Lots of new AMD GPUs & APUs supported.
  - [VMMaker]
  - [Arcade OSD] Changes to correctly apply polarities and refresh with Crimson drivers.

  - [VMMaker]    New commands available from the application's console, to allow manual management
                 of the mode list, etc. Type "help" for details.

[01/02/2016][CRT Emudriver 2.0][CRT Tools 2.0][beta 8]

  - [Emudriver]  Fixed bug in Setup preventing the driver from getting installed depending on
                 the location of the installation files.

[26/01/2016][CRT Emudriver 2.0][CRT Tools 2.0][beta 7]

  - [Emudriver]  Forced reset of interleave flag upon device power-up. Fixes problem with ATOM-15
                 flashed cards that caused shrinked picture with progressive modes and double picture
                 with interlaced modes.

[23/01/2016][CRT Emudriver 2.0][CRT Tools 2.0][beta 6]

  - [Emudriver]  Fixed critical bug in driver that caused the system to get frozen randomly upon
                 display device restart.
  - [VMMaker]
  - [Arcade OSD] Correctly assign sync polarity to AMD HD 5000+ cards. Because AMD documentation
                 is wrong, VMMaker where assigning the polarities the wrong way. This must be
                 the direct cause of most out-of-sync issues reported till now. What happened is
                 that GM assigned positive sync instead of negative, and vice versa. This is fixed now,
                 but you'll need to update your crt_range definitions. By default, negative sync (0)
                 is what should be used in most cases. Thanks to intealls for doing proper checks with
                 an oscilloscope and R-Typer for double-checking.

  - [VMMaker]    ATI legacy: now interlaced modes are reported with full refresh (not halved) in W7+.
                 This should solve problems with games that use a hardcoded 60 Hz refresh.

  - [VMMaker]    Better alignment of modeline generator to GroovyMAME's. 

  - [Arcade OSD] Fixed Powerstrip support.

[07/01/2016][CRT Emudriver 2.0][CRT Tools 2.0][beta 5]

  - [Emudriver]  Added missing dlls for ADL library (thanks to Fonki for reporting). Issue
                 affected HD 5xxx and newer cards. It caused VMMaker not recognizing the driver.

  - [VMMaker]    Fixed problem that forced custom modes to be 32-bit only. Solves issue with
                 ZSNES and probably others. (thanks to tom5151 for reporting).

[05/01/2016][CRT Emudriver 2.0][CRT Tools 2.0][beta 4]

  - [Emudriver]  Fixed installation in Windows 10, still may show a BSOD on install buf after that
                 it seems to work (thanks to R-Typer).
  - [VMMaker]    Ati legacy: fixed polarity settings. This reverts the fix for halved refresh
                 & interlaced modes from beta 1.
  - [VMMaker]    Ati legacy: new option to "Extend desktop automatically on device restart".
                 Meant to help users during monitor setup. (to be improved)
  - [VMMaker]    Ati legacy: now desktop layout is preseved after device restart (to be improved).

[02/01/2016][CRT Emudriver 2.0][CRT Tools 2.0][beta 3]

  - [Emudriver]  Fixed mixed-up file version in beta 2, probable cause of installation issues.
                 Now the drivers will be recognized as version 12.6.

  - [Emudriver]  Added fix for certain modes being reported as "system".

  - [VMMaker]    Version properly reported in window caption.

[31/12/2015][CRT Emudriver 2.0][CRT Tools 2.0][beta 2]

  - [Emudriver]  Fixed OpenGL support.

[30/12/2015][CRT Emudriver 2.0][CRT Tools 2.0][beta 1]

  - [Emudriver]  Added support for AMD HD 5000/6000/7000 series (Catalyst 12.6)
  - [Emudriver]  Forced monitor detection for ATI legacy cards (HD 2000/3000/4000 series)

  - [VMMaker]
    [Arcade OSD] Rewritten. Now both tools are built on top of a new shared video library.

  - [VMMaker]
    [Arcade OSD] Added support for AMD HD 5000/6000/7000 series (Catalyst 12.6)

  - [VMMaker]    New graphic user interface. Most options are now managed through a new
                 settings dialog. Support for typed commands.   
  - [VMMaker]    ATI legacy cards: fixed halved refresh of interlaced modes on vsync.
  - [VMMaker]    AMD 5000/6000/7000: new EDID emulation feature, allows arcade monitors and
                 CRT TVs to be detected as normal monitors under Windows.
  - [VMMaker]    Full implementation of GroovyMAME's "crt_range" monitor presets.
  - [VMMaker]    Automatic exportation of monitor settings to GroovyMAME.
  - [VMMaker]    Automatic selection of minimum dotclock.  
  - [VMMaker]    Automatic selection of maximum number of modes.
  - [VMMaker]    Dynamic mode list installation without rebooting (Windows 7/8/10).
  - [VMMaker]    Support for importing/exporting raw modeline lists.

  - [Arcade OSD] Copy/paste timings to/from clipboard.


Version 1 history
-----------------

[04/10/2015][CRT Emudriver 1.2b][VMMaker + Arcade OSD 1.4b]

  - [VMMaker]    XML processing adapted to MAME v.0162


[01/03/2015][CRT Emudriver 1.2b][VMMaker + Arcade OSD 1.4a]

  - [Arcade OSD] Fixed error when setting desktop resolution in Windows XP. Windows 7/8 not
                 affected.


[10/10/2014][CRT Emudriver 1.2b][VMMaker + Arcade OSD 1.4]

  - [Emudriver]  Windows 7 version promoted from beta. Based on Catalyst 13.1 "reloaded", by
                 kevsamiga1974.
  - [Emudriver]  Removed timing cache from versions 6.5 & 9.3 for XP. Now you no longer need
                 to create a minimum number of custom modes in order to get dynamic modelines. 
  - [Emudriver]  Version 9.3 for XP-32/64. Added lots of missing of PCI IDs, including the
                 "Mobility Radeon" ones. It should fix most problems with not recognized 
                 hardware.
  - [Arcade OSD] Fixed bug affecting Windows 7 where the desktop mode wouldn't be properly
                 detected.
  - [VMMaker]    
    [Arcade OSD] Full support for super resolutions. Fixed bug with dotclocks above 100 MHz.
                 Fixed font aspect ratio with ultra-wide modes.
  - [VMMaker]    
    [Arcade OSD] Full Windows 7 support.


[16/06/2012][VMMaker 1.3c][Arcade OSD 1.3b]

  - [VMMaker]    XML processing adapted to MAME v.0146 (reported by genius77).
  - [VMMaker]    New list of video modes for emulation (ReslList.txt). By Recap. 
  - [VMMaker]    New list of main systems for MAME (MameMain.txt). By Recap.
  - [VMMaker]    Main system selection based on rom name.
  - [VMMaker]    New option "OnlyListMain", allows listing only video modes from games
                 included in MameMain.txt
  - [VMMaker]    New option "YresRound", allows asigning a rounding factor to the vertical
                 resolution, rationalizing the mode table.
  - [VMMaker]    Now options ModeTableMethod, XresMin, YresMin and YresRound have two
                 suffixes: _XML and _custom. Each one applies to a different source:
                 xml (MAME/MESS) or custom (ReslList.txt), making it possible to use
                 different criteria for each group.
  - [VMMaker]    Automatic creation of "magic" mode table (ModeTableMethod_XML/custom = 2).
                 Creates a table of dummy resolutions, in the form 1234 x (yres), allowing
                 a great reduction of the mode table size. This option can only be used
                 with GroovyMAME and Windows XP. It is meant as a workaround for a bug
                 in Hypersping that makes it crash when the mode list exceeds a certain
                 number of modes.
  - [VMMaker]    Important improvements in the generation of the mode table for multi-
                 frequency monitors.
  - [VMMaker]
    [Arcade OSD] Added support for sync polarities.
  - [Arcade OSD] Support for multiple monitors. The new option "Attach OSD to current 
                 monitor" allows selecting the active monitor by drag-and-dropping the
                 program's window over the desired monitor.
  - [Arcade OSD] The new option "Lock unsupported modes" blocks the video modes which
                 Windows considers as not supported by our monitor. Arcade monitors and
                 CRT TVs don't have an EDID, so when using these Windows will show all
                 video modes as supported, including those that are potentially dangerous.
                 Thus this option can't be used to filter out unsupported modes. It's
                 function is quite the opposite: to unlock those video modes that Windows
                 might consider as unsupported, in those monitors that have a valid EDID,


[16/04/2011][CRT Emudriver 1.2][VMMaker 1.3][Arcade OSD 1.2]

  - [Emudriver]  New version based on Catalyst 6.5 for Windows x64
  - [VMMaker]    New version 1.3, support for multi-frequency monitors (beta).


[06/03/2011][CRT Emudriver 1.2][VMMaker 1.2][Arcade OSD 1.2]

  - [Emudriver]  New version based on Catalyst 9.3 para Windows x64
  - [VMMaker]    New options VerticalAspect, ModeTableMethod, DotClockMin, AnyCatalyst
                 (view VMMaker.ini for details).
  - [Arcade OSD] Fixed problem that prevented from preserving the changes applied to the
                 desktop video mode.


[24/12/2010][CRT Emudriver 1.2][VMMaker 1.1][Arcade OSD 1.1]

  - [Emudriver]  New version based on Catalyst 9.3

  - [VMMaker]    New method for mode labelling, in order tell modes from others with similar
                 refresh. Based on using three figures to label the vertical refresh, e.g.
                 320x256@55.5 Hz would be labelled as 320x256_555. To restore old labelling
                 system use VFreqLabelx10 = 0 in vmmaker.ini.
  - [VMMaker]    Improvements to the modeline generator, so monitor timing can be stablished
                 more accurately (new options VFrontPorch, VSyncPulse, VBackPorch).
  - [Arcade OSD] Solved problen with Arcade OSD and DDraw in Catalyst 9.3.
  - [Arcade OSD] Solved problen with Arcade OSD when showing interlaced modes timing.


[05/10/2010][CRT Emudriver 1.1][VMMaker 1.0][Arcade OSD 1.0]

  - [Emudriver]  Solved problem of driver installation in cards different from the Radeon 9250,
                 due to an error in .inf file error.
  - [Emudriver]  Added support to Ati Radeon X1950 Pro (tested by ConanR).
  - [Emudriver]  Pre-installed video modes for MAME v.139


[08/09/2010][CRT Emudriver 1.0][VMMaker 1.0][Arcade OSD 1.0]

  - First full version.

