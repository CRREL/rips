' Application for capturing image from FLIR A300 Camera and sending to a FTP Server using an NAL Research A3LA-RM Iridum Modem
'
' WORKFLOW
' ----------------------------------------------
' - The Basic scheduled subroutine named MANAGER must be scheduled to run
'   at the most frequent rate you wish the system to do something.
' - What the system will do depends on which options are enabled for that run.
'   Options can be enabled by scheduling a subroutines to run at
'   the same time or before MANAGER is run.
' - The subroutines which determine which options are enabled are named:
'      TakeFLIRPicture          - Instructs Manager to take a picture from the FLIR and archive it
'      TakeStarDotPicture1      - Instructs Manager to take a picture from the StarDot #1 and archive it
'      TakeStarDotPicture2      - Instructs Manager to take a picture from the StarDot #2 and archive it
'      TransferFLIRPicture      - Instructs Manager to transfer the FLIR picture to the FTP server
'      TransferStarDotPicture   - Instructs Manager to transfer the StarDot picture(s) to the FTP server
'      ArchiveMaintenance       - Instructs Manager to perform maintenance tasks
'      CheckForUpgrade          - Instructs Manager to check for a upgrade (ENABLEUPGRADE command must be issued first)
'      CheckForCommand          - Instructs Manager to check for a remote command
'
' - Here's the sequence of events that the MANAGER subroutine may perform (depending on options):
'    - Camera tasks:
'      - Turn on LAN
'      - Power on the FLIR camera using DIO-4
'      - Power on the StarDot camera using DIO-6
'      - Wait 2 minutes for the cameras to power up
'      - Using Telnet communications (port 23) to the FLIR:
'        - Tell the camera to take a picture (NUC)
'        - Remove any old pictures (del \image.jpg)
'        - Create a new image (store -j \image.jpg)
'      - Transfer image to the Xpert's flash disk folder using FTP GET (port 21)
'      - Using TCP/IP communications to StarDot #1:
'        - Perform an HTTP GET on /image.jpg (port 80)
'        - Store the image in the Xpert's flash disk folder as StartDot1.jpg
'      - Using TCP/IP communications to StarDot #2:
'        - Perform an HTTP GET on /image.jpg (port 80)
'        - Store the image in the Xpert's flash disk folder as StartDot2.jpg
'      - Power off the cameras
'      - Turn off LAN
'      - Copy the FLIR image to the SD Card in to the \SD Card\FLIR folder
'        (see ArchiveFLIRPath)
'      - Append the name of the file to \SD Card\ArchiveList.dat
'      - Copy the StarDot1 image to the SD Card in to the \SD Card\StarDot1 folder
'        (see ArchiveStarDotPath1)
'      - Append the name of the file to \SD Card\ArchiveList.dat
'      - Copy the StarDot2 image to the SD Card in to the \SD Card\StarDot2 folder
'        (see ArchiveStarDotPath2)
'      - Append the name of the file to \SD Card\ArchiveList.dat
'    - Transfer tasks:
'      - Power on the A3LA-RM Iridium Modem using DIO-5
'      - Initiate a PPP connection on A3LA using RAS API
'      - Wait for Connect
'      - Ftp the FLIR image to the Server's /FLIR folder
'        (see ServerFLIRImagePath)
'      - Ftp the StarDot1 image to the Server's /StarDot folder
'        (see ServerStarDotImagePath1)
'      - Ftp the StarDot2 image to the Server's /StarDot folder
'        (see ServerStarDotImagePath2)
'      - Check for a remote command file (command.txt) and execute it
'      - Check for an upgrade (if the ENABLEUPGRADE command has been issued)
'      - Install an upgrade (if an upgrade has transferred and the UPGRADENOW command has been issued)
'      - Disconnect PPP
'      - Power off A3LA
'    - Maintenance tasks:
'      - If the available disk space on the SD Card should fall below 10 million bytes:
'        - Retrieve the position of the name of the next file to delete from \SD Card\ArchivePos.dat
'        - Read the name of the next file to delete from \SD Card\ArchiveList.dat (using the position)
'        - Remove the indicated file from the \SD Card
'        - Update the ArchivePos.dat file with the position of the next file to delete
'        - Repeat until the free disk space is over 10 million bytes or 10,000 attempts have been made
'       - If the amount of memory in use should exceed 90% then reboot the station
'

' SOFTWARE CONFIGURATION:
' ----------------------------------------------
' - The FLIR A300 camera must be configured with the following settings:
'    static IP address of 192.168.50.120,
'    subnet: 255.255.255.0
'    gateway: 0.0.0.0
' - The StarDot NetCam SC camera must be configured with the following settings:
'    static IP address of 192.168.50.130,
'    subnet: 255.255.255.0
'    gateway: 0.0.0.0
' - Check and or modify the constants in the following sections
'    FLIR A300 Camera Settings
'    FTP Server Settings
'    A3LA Settings
'    ISP Settings
'    Direct Iridium Internet
'       ( if using the DOD gateway, the phone number to use is selected in this
'         section using the constant ISP_PhoneNumber. The default is set to
'         008816000022, but our most recent success has been with 008816000023;
'         so switch it as needed )
' - Configure the setup in the Xpert
'    - First transfer the following files to the Xpert and place them in the Flash Disk folder:
'         MANAGER.BAS
'         FLIR.BAS
'         STARDOTNETCAMSC.BAS
'         A3LA.BAS
'         FTPOPS.BAS
'    - Under Setup tab, open the Basic section, and if there isn't an entry already for the
'      MANAGER subroutine click "Add Schedule" and press Edit, for the name select 'MANAGER'
'      and assign the Interval at the fastest rate you will want to take a picture, transfer
'      a file, or perform maintenance tasks.
'    - With the same tab, add schedules for the TakeFLIRPicture, TakeStarDotPicture1, TakeStarDotPicture2,
'      TransferFLIRPicture, TransferStarDotPicture, ArchiveMaintenance subroutines.
'      (these schedules will determine which actions are performed when the MANAGER subroutine
'      runs, and should be scheduled at a multiple of the interval used to schedule MANAGER.)
'    - For instance, if you wish to take pictures hourly, transfer them every 6 hours, and
'      perform maintanence daily, you should schedule the subroutines with the following intervals:
'         Subroutine              Interval   Offset Time
'         ----------------------  --------   -----------
'         Manager                 01:00:00   00:00:00
'         TakeFLIRPicture         01:00:00   00:00:00
'         TakeStarDotPicture1     01:00:00   00:00:00
'         TakeStarDotPicture2     01:00:00   00:00:00
'         TransferFLIRPicture     06:00:00   00:00:00
'         TransferStarDotPicture  06:00:00   00:00:00
'         CheckForCommand         06:00:00   00:00:00
'         CheckForUpgrade         01:00:00   00:00:00
'         ArchiveMaintenance      24:00:00   00:00:00
' - Configuring the SD Card:
'   The SD Card should be formatted using FAT32 (NTFS is not supported by the Xpert)
'   This program will automatically create a FLIR, StartDot1 and a StarDot2 folder in the root of
'   the SD Card to store the archive files. The file ArchiveList.dat will also be created
'   in the root of the SD Card to store a list of files that have been archived, and the
'   file ArchivePos.dat will also be created to store the position of the last file from
'   the archive that had to be deleted to create more disk space.
' - Managing the SD Card:
'   The software will automatically delete the oldest file in the archive when necessary
'   to store the latest. The SD Card may be transferred to a laptop by turning off recording and
'   then pulling the SD Card from the Xpert and inserting it in to the laptop. After copying the
'   two archive folders over to the laptop, you may remove the old files from the SD Card, but this
'   is not strictly necessary. If you do so, you should also delete the ArchiveList.dat and ArchivePos.dat
'   files. The ArchiveList.dat will retain a record of every file copied to the archive, but even with hourly
'   archiving it should never consume more than a minute fraction of the card. When done, re-insert the card
'   in to the Xpert and turn recording back on.

' REMOTE COMMANDS:
' ----------------------------------------------
' - Remote commands may placed in a file called "command.txt" in a folder
'   named after the station on the FTP Server. Typically this file is
'   transferred to the Xpert in to the "\Flash Disk" folder and run
'   as a batch file. In order for this to work, a user name and password
'   must be supplied to grant access rights. The variables RemoteCommandUser
'   and RemoteCommandPassword contain the values which will be used.
' - The result of any remote commands are placed in the file "results.txt"
'   and command.txt will be removed.
' - The batch language used by the Xpert is a simplified version of the MS-DOS
'   batch language and supports the following commands:
'      @ECHO OFF                   Suppresses echo of the command being run
'      ECHO ON                     Re-enables the echo of commands
'      ECHO string                 Displays string
'      command                     Runs the command as-if entered at the Flash Disk prompt.
'      @command                    Runs the command but suppresses echo
'      DEBUG ON                    Allows debug commands to be issued
'      EXIT                        Stops processing the batch file (*)
'   - A LOGOUT is automatically appended to the batch file to speed up detection
'     of the end of execution. Use of the EXIT (*) command will prevent this LOGOUT
'     from being executed, and will cause a delay in processing the command.
'   - There are a few special commands which are processed seperately if they are detected
'     at the start of the command.txt file:
'     - ENABLEUPGRADE              Allows upgrade detection and transfers to begin
'     - DISABLEUPGRADE             Disables upgrade detection and transfers
'     - UPGRADENOW                 Powers an upgrade after it's been transferred and may
'                                  be placed after an ENABLEUPGRADE to install the upgrade
'                                  immediately after downloading it without intervention.
'     - CONNECT url:port           Connects to the specified URL and port, and presents an
'                                  an SSP/CL (CL stands for Command Line) session. This may
'                                  be used to communicate with XTerm or Telnet, but only if
'                                  a redirector is used to "glue" the two clients together.
'
'           /XTERM                 The optional /XTERM flag may be used to indicate that
'                                  a raw TCPIP session is desired (such as XTerm uses)
'
'           /TELNET                The optional /TELNET flag may be use to indicate that
'                                  the telnet protocol is desired (such as HyperTerminal uses)
'
'                                  If neither /XTERM nor /TELNET are selected then the SSP/CL
'                                  session will attempt to auto-detect the connection, but if
'                                  the latency is too long, it will tend to end up not detecting
'                                  TELNET and defaulting to XTERM.
'

' REMOTE UPGRADES:
' ----------------------------------------------
' - Remote ugprades are placed in an "Upgrade" folder placed inside the station folder
'   on the FTP Server. An upgrade is started by issuing the command ENABLEUPGRADE,
'   and then at each interval, the system will try to FTP more and more of the upgrade
'   files from the FTP Server to the Xpert until everything has been transferred.
' - As each file/folder is transferred, it is removed from the FTP Server and placed
'   in an Upgrade folder in the Flash Disk of the Xpert.
' - A Cleanup.bat file is automatically generated to remember which files should be
'   deleted after the upgrade has been installed.
' - Once the files have been transferred a message is appended to the "results.txt"
'   file to indicate the status and the UPGRADENOW command may be issued when you're
'   ready to complete the upgrade.
' - The upgrade process will look for an Xpert2____.upg file. This is used to direct
'   the upgrade process and is always included with an Xpert upgrade package.
' - If using a Sutron upgrade package, be sure to use the one meant for a Storage Card
'   (_SC).
' - Before copying any files to the FTP Server, you should prepare the upgrade in a folder
'   with only the files that will be needed, and an edited version of the supplied .upg file
'   that will only install the files which are needed. For instance, you do not need to transfer
'   all the Extra SLL files or perhaps any of the speech files.
' - The ugprade files from Sutron are typically compressed with PKZIP. In the root of the Upgrade
'   folder you create,  you may wish to include the Xpert2.ker and Xpert2.fil files if you want
'   to perform a Kernel upgrade. The hand edited Xpert2____.upg file must be placed in the root
'   of the new Upgrade folder you're creating.
'   Then take any files or sub-folders you may require from the Upgrade folder in the PKZIP image and
'   copy them in to the root of the new Upgrade folder you are creating.
' - The final result should look something like this:
'      [Upgrade]
'         Xpert2 v3.14.0.0 SC.upg
'         Xpert2.ker
'         Xpert2.fil
'         Autoexec.bat
'         Basic.sll
'         Coms.sll
'         Xpert.exe
'         ...
'         [Extra SLLs]
'            IMD.sll         <- This is just an example (the project is not currently using any Extra SLL files)
'            Modbus.sll
'            ...
' - Be sure to edit the .upg file to include only the files you need to upgrade
' - Copy the Upgrade folder structure you've created to the Station folder on the FTP Server
' - It's possible to create an upgrade that will only upgrade a Basic program or even a data file,
'   here are the steps:
'     - Create an Xpert2.upg file to copy each file to where it belongs. It will typically look something like this:
'          s "Upgrade\Manager.bas" "\Flash Disk\Manager.bas"
'          s "Upgrade\FtpOps.bas" "\Flash Disk\FtpOps.bas"
'          etc.
'     - Place the files to be updated in the Upgrade folder on the FTP Server under the Station you wish
'       to update.
'          [Upgrade]
'             Manager.bas
'             FtpOps.bas
'             Xpert2.upg
'      - Issue the ENABLEUPGRADE command, and once the files have been copied down issue the UPGRADENOW command to complete.
'      - The Xpert will reboot, copy the files to their new location, startup the application, and cleanup the old upgrade files.

' DIAGNOSTICS:
' ----------------------------------------------
' - FTPTEST.BAS is an optional seperate program that adds a few tags
'   and allows some diagnostic checks to be made.
'   - Using XTerm you may view the Data tab and access various tags.
'        You can set the value of a tag in this menu by pressing
'        the Change button.
'        These tags also be displayed using Hyperterminal and the Flash
'        Disk command prompt using the SHOW command. They can be changed
'        using the SET comamnd (ex: SET Modem 1).
'   - Here's what these tags can do:
'        Camera:    Displays the current power state of the camera, can also
'                   be used to force the camera on by setting to 1, or off
'                   by setting to 0.
'        Modem:     Displays the current power state of the modem, can also
'                   be used to force the modem on by setting to 1, or off
'                   by setting to 0.
'        FtpStatus: Displays the progress of the Iridium file transfer (# bytes sent).
'   - Displaying Network Status:
'        Under the Status tab, or by issuing the "IPCONFIG /ALL" command at the
'        Flash Disk command prompt you may view the current network setting.
' - Monitoring the system
'       You may view how the system is performing by examining the System.log
'       using the Log tab, or you may see what's happening in real-time by
'       issuing the command "REPORT HIGH" at the Flash Disk command prompt.
' - Starting the transfers
'       This can be done by turning recording ON or issuing the "Recording ON"
'       command at the Flash Disk command prompt.
' - Stoping the transfers
'       This can be done by turning recording OFF or issuing the "Recording OFF"
'       command at the Flash Disk command prompt.
' - Verifying the SD Card:
'       The SD Card can be viewed using the File Transfer button of XTerm. When you double
'       click [..] the "\" root folder should be displayed. Within the root should be an entry
'       for [SD Card]. If you don't see this, then the card was unable to mount. If you double
'       click the [SD Card] the folders and files on the card should be displayed. The program
'       will automatically create a FLIR and a StarDot folder on the SD Card to store the
'       archived files. It will also create the files ArchiveList.dat and ArchiveList.pos to
'       remember which files have been archived. When the archive files are moved off the card,
'       these files should be deleted. The SD Card may also be viewed from the Xpert's command
'       prompt using the DIR command:
'           \Flash Disk> dir \sd card
'           \Flash Disk> type "\sd card\archivelist.dat"

' HARDWARE CONFIGURATION:
' ----------------------------------------------
' - Ethernet Switch (low-power,  wide temperature, 12V compatible) for connecting the devices
' - FLIR A300 Infrared Camera connected to the switch using a standard ethernet patch cable
' - StarDot NetCam SC Visible Light Camera  connected to the switch using a standard ethernet patch cable
' - Sutron 9210B with 3.13.0.15 firmware (or later) connected to the switch using a standard ethernet patch cable
' - 2GB SD Card formatted with FAT32. SDHC cards are not supported by the Xpert. NTFS format is not supported.
' - NAL Research A3LA-RM Iridium Modem connected to 9210B via RS232 cable from COM2:
' - The jumper settings for COM2: must be configured to connect PIN 9 to RI  (J901, 1-2, 5-6, 9-10)
'      This should be the default for COM2:, but COM3: has PIN 9 wired to 5V
' - Connect DIO-4 to a relay that controls power to the FLIR A300
'      The DIO will ground (open-collector output) the signal when enabled
'      so it would normally be wired to the (-) side of the relay's input
'      and protected 12V from the Xpert may be wired to both the (+) side
'      of the relay's input, and jumpered to the (+) side of the relay's
'      output. Use as short of a cable/wire as possible with thick wires a
'      as reasonable, otherwise significant power will be lost due to
'      wire resistance. One option is to run the PROT+12V and GND wires
'      seperately with thicker wires, or double up smaller wires.
' - Connect DIO-5 to a relay that controls power to the NAL Research A3LA-RM modem
'      See notes for DIO-4.
' - Connect DIO-6 to a relay that controls power to the StarDot NetCAM SC camera
'      See notes for DIO-4.
'
' SPECIAL REGISTRY SETTINGS (THIS SECTION MAY BE IGNORED):
' - These settings relax TCP/IP settings and may make it possible to connect
'   over PPP through the A3LA in situations where the latency of the Iridium
'   connection may cause a problem, or where the fact that the A3LA reports
'   a "CONNECT 19200" message before it's trained modem tones may interfere
'   with negotiation.
' - These DO NOT SEEM to be needed when using the DOD Gateway
' - These commands need only be issued once on a new system and then should
'   be retained in the registry.
' - Access the "\Flash Disk>" prompt of the 9210B and issue the following commands (paste recommended)
'     \Flash Disk> Debug On
'         (help for DEBUG commands will display)
'     \Flash Disk> REGW HKLM\Comm\PPP\Parms RestartTimer 30
'         (increase PPP negotiation timeout from 3sec to 30sec)
'     \Flash Disk> REGR HKLM\Comm\PPP\Parms RestartTimer
'         (verify the change)
'     \Flash Disk> REGW HKLM\Comm\PPP\Parms DHCPMaxTries 0
'         (disables DHCPINFORM messages which can speed up PPP negotation)
'     \Flash Disk> REGR HKLM\Comm\PPP\Parms DHCPMaxTries
'         (verify the change)
'     \Flash Disk> REGW HKLM\Comm\PPP-COM2\Parms\Tcpip TcpInitialRtt 10000
'          (increases the initial timeout for a TCP transmit from 3000ms to 10000ms)
'     \Flash Disk> REGR HKLM\Comm\PPP-COM2\Parms\Tcpip TcpInitialRtt
'         (verify the change)
'     \Flash Disk> REGW HKLM\Comm\PPP-COM2\Parms\Tcpip TcpWindowSize 4096
'          (decreases the TcpWindowSize down to 4096 bytes or about what can be sent in a second)
'     \Flash Disk> REGR HKLM\Comm\PPP-COM2\Parms\Tcpip TcpWindowSize
'         (verify the change)

' Declarations for using Sutron's FTP source code (FtpOps.bas):
Public Declare Function FtpPut(URL, UserName, Password, FileType, SourceFile, DestFile, AutoResume)
Public Declare Function FtpGet(URL, UserName, Password, FileType, SourceFile, DestFile, AutoResume)
Public Declare Function FtpAppend(URL, UserName, Password, Buffer, DestFile, FileToDeleteAfter)
Public Declare Function FtpGetBytesSent
Public Declare Function FtpUpgrade(URL, UserName, Password, SourcePath, DestPath, nFiles)
Public Declare Sub FtpCancel
Declare Function Ftp_GetErrorStr Lib "\Windows\Utils.dll" (iError) As String


' List of error codes for WinInet functions:
' http://support.microsoft.com/kb/193625

' Declarations for taking picture with the FLIR and StarDot:
Public Declare Function TakePicture_FLIR
Public Declare Function TakePicture_StarDot(StarDotIPAddress, LocalStarDotImageFile)

' Local Settings
Static LocalFLIRImageFile
Static LocalStarDotImageFile1
Static LocalStarDotImageFile2
Static StarDotIPAddress1      ' StarDot1
Static StarDotIPAddress2      ' StarDot2

' Declarations for accessing functions for connecting to the internet with the A3LA:
Public Declare Function OpenA3LA(Port, PhoneNumber, UserName, Password, InitStr, TimeoutSeconds)
Public Declare Sub CloseA3LA(Handle)
Declare Function Ras_GetState Lib "\Windows\Utils.dll" (iHandle) As String
Declare Function Ras_IsConnected Lib "\Windows\Utils.dll" (iHandle) As Integer

' Camera Settings
Const FLIRDIGIO = 4
Const StarDotDIGIO = 6 ' Note the dual camera system uses one power relay on this channel to power both cameras and the network switch
Const CameraWarmupDelay = 25  ' Warmup Camera for 2 minutes (120 sec) before taking a picture

' Station variables that are intialized in the "InitStationVars" subroutine because they
' incorporate the "StationName" in to their value:
Dim StationName
' FTP Server Settings
Dim ServerRoot
Dim ServerFLIRImagePath
Dim ServerStarDotImagePath1
Dim ServerStarDotImagePath2
' Remote Command Settings
Dim RemoteCommandFile
Dim RemoteResultsFile
' Automatic Upgrade Settings
Dim RemoteUpgradePath

' FTP Server Settings
Const ServerIP = "64.223.182.130"
Const ServerFtpUser = "iridiumcam"
Const ServerFtpPassword = "ExecuteTransportBroadBeach"

' A3LA Settings
Const ModemPort = "COM2:"
Const ModemDIGIO = 4
Const ModemWarmupDelay = 60.0  ' Warmup Modem for 1 minute (60 sec) before trying to connect

' Archive Settings
Const ArchiveFLIRPath = "\SD Card\FLIR"
Const ArchiveStarDotPath1 = "\SD Card\StarDot1"
Const ArchiveStarDotPath2 = "\SD Card\StarDot2"
Const ArchiveListFile = "\SD Card\ArchiveList.dat"
Const ArchivePosFile = "\SD Card\ArchivePos.dat"
Const ArchiveSpace = 10000000  ' Number of bytes to ensure is free after performing archive maintenance

' Remote Command Settings
Const LocalCommandFile = "\Flash Disk\command.bat"           ' Must be a .bat file or the command prompt will not be able to run it
Const RemoteCommandUser = ""        ' Must be a valid user name that can be used to login to the RTU with (or "" if no users are defined)
Const RemoteCommandPassword = ""    ' Must be a valid password that can be used to login to the RTU with (or "" if no users are defined)

' Automatic Upgrade Settings
Const LocalUpgradePath  = "\Flash Disk\Upgrade"

' Debugging Settings
SIMULATE = False ' Set this to TRUE in order to work without the A3LA modem hardware (uses LAN)

' ISP Settings
Const DirectIridiumInit = "+DS=0,0,2048,20;+CBST=71,0,1"
Const DialUpModemInit = "+DS=3,0,512,6;+CBST=7,0,1"
Const ISP_ModemInit = DirectIridiumInit
'
' Direct Iridium Internet
Const ISP_PhoneNumber =  "008816000023"' change to 008816000022 if having issues
Const ISP_UserName = ""
Const ISP_Password = ""


' Event to detect a stop request
Static Shutdown = 0
ResetEvent Shutdown

' Event to force FTP transfer to cancel
Static CancelEvent = 0
ResetEvent CancelEvent

' Flags used by the manager to decide which actions to take
TakeFlirPicture = False
TakeStarDotPicture1 = False
TakeStarDotPicture2 = False
TransferFLIRPicture = False
TransferStarDotPicture1 = False
TransferStarDotPicture2 = False
PerformMaintenance = False
CheckForUpgrade = False
CheckForCommand = False
PerformReboot = False
NumFilesTransferred = 0
UpgradeComplete = False
UpgradeEnabled = False
UpgradeNow = False
NotifyStartup = 0
DeferModemOff = False

' Initialize parameters that vary with the station name
Sub InitStationVars
   NewStationName = Systat(0)
   If NewStationName <> StationName Then
      StationName = NewStationName
      ' FTP Server Settings
      ServerRoot = "/StarDot/" & StationName & "/"
      ServerFLIRImagePath = ServerRoot & "FLIR/"
      ServerStarDotImagePath1 = ServerRoot & "StarDot1/"
      ServerStarDotImagePath2 = ServerRoot & "StarDot2/"
      ' Remote Command Settings
      RemoteCommandFile = ServerRoot & "command.txt"
      RemoteResultsFile = ServerRoot & "results.txt"
      ' Automatic Upgrade Settings
      RemoteUpgradePath = ServerRoot & "Upgrade"
   End If
End Sub

' Watch the station of the A3LA RAS connection and if it goes down, abort an FTP operation in progress
Public Function WatchForDisconnect(hRas)
   If SIMULATE Then
      If (WaitEvent(0, Shutdown) < 0) Then
         WatchForDisconnect = 0     ' Reschedule for next time
      Else
         StatusMsg "Manager: RAS session droppped, aborting FTP transfer"
         SetEvent CancelEvent
         Call FtpCancel
         WatchForDisconnect = 1      ' No need to reschedule
      End If
   Else
      If (WaitEvent(0, Shutdown) < 0) And Ras_IsConnected(hRas) Then
         WatchForDisconnect = 0     ' Reschedule for next time
      Else
         StatusMsg "Manager: RAS session droppped, aborting FTP transfer"
         SetEvent CancelEvent
         Call FtpCancel
         WatchForDisconnect = 1      ' No need to reschedule
      End If
   End If
End Function

Function PutImage(hRas, LocalFile, DestFile)
   PutImage = False
   On Error Resume Next
   StartTask "WatchForDisconnect", hRas, TimeSerial(0,0,0), TimeSerial(0,0,2), TimeSerial(0,0,0)
   On Error Goto 0
   Result = FtpPut(ServerIP, ServerFtpUser, ServerFtpPassword, "I", LocalFile, DestFile, True)
   If Result = 0 Then
      PutImage = True
   Else
      StatusMsg "Manager: PutImage: failed with code " & Ftp_GetErrorStr(Result)
   End If
   On Error Resume Next
   StopTask "WatchForDisconnect"
   On Error Goto 0
End Function

' Remote a substr from a string
Function StrRemove(Text, Remove)
   p = Instr(1, Text, Remove)
   If p > 0 Then
      StrRemove = Left(Text, p-1) & Mid(Text, p+Len(Remove))
   Else
      StrRemove = Text
   End If
End Function

' Returns true if a file exists
Function FileExists(FileName)
   On Error Resume Next
   l = FileLen(FileName)
   e = Err
   On Error Goto 0
   FileExists = (e = 0)
End Function

' IssueCommand sends a command, waits timeout seconds, and returns the reply
Public Function IssueCommand(Cmd, UserName, Password, TimeoutSec)
   sCmd = Cmd
   ' If there's .BAT at the end of the command, remove it, because it won't be able to be processed
   If UCase(Right(sCmd, 4)) = ".BAT" Then
      ' Add a logout command to the end of the batch file
      F = FreeFile
      On Error Resume Next
      Open sCmd For Append As F
      e = Err
      On Error Goto 0
      If e = 0 Then
         IsBat = True
         Print F, "@Logout"
         Close F
         sCmd = Left(sCmd, Len(sCmd)-4)
         If Left(sCmd, 1) = "\" Then
            sCmd = """" & sCmd & """"
         End If
      Else
         IsBat = False
      End If
   Else
      IsBat = False
   End If
   Telnet = FreeFile
   Open "localhost:23" As Telnet
   SetTimeout Telnet, TimeoutSec
   Result = ""
   SetTimeout Telnet, 0.2
   If UserName <> "" Or Password <> "" Then
      Print Telnet, UserName & Chr(13);
      Print Telnet, Password & Chr(13);
      Count = ReadB(Telnet, Result, 10000)
      If Instr(1, Result, "Bad User Name or Password.") > 0 Then
         ErrorMsg "Manager:Unable to access command prompt to issue command due to incorrect user name or password"
         IssueCommand = "Remote Command cannot be executed due to a bad user name or password."
         Close Telnet
         Exit Function
      End If
   Else
      Count = ReadB(Telnet, Result, 10000)
      If Instr(1, Result, "Login user:") > 0 Then
         ErrorMsg "Manager:Unable to access command prompt to issue command due to login required"
         IssueCommand = "Remote Command cannot be executed due to lack of a user name or password."
         Close Telnet
         Exit Function
      End If
   End If
   SetTimeout Telnet, TimeoutSec
   If IsBat Then
      Print Telnet, sCmd & Chr(13);
   Else
      Print Telnet, "!" & sCmd & Chr(13) & "!logout" & Chr(13);
   End If
   Result = ""
   Count = ReadB(Telnet, Result, 100000)
   Close Telnet
   If IsBat Then
      Result = StrRemove(Result, sCmd & Chr(13) & Chr(10))
   Else
      Result = StrRemove(Result, "Logout accepted." & Chr(13) & Chr(10))
   End If
   IssueCommand = Result
End Function

' Returns a file that matches the wild card path passed in Match
Function GetFileMatch(Match)
   Result = IssueCommand("dir """ & Match & """", RemoteCommandUser, RemoteCommandPassword, 10.0)
   CRLF(0) = -1
   For i = 1 To 4
      CRLF(i) = Instr(CRLF(i-1)+2, Result, Chr(13) & Chr(10))
   Next i
   If CRLF(4) > 0 Then
      p1 = CRLF(1)
      p2 = Instr(p1, Result, "   ")
      If (p2 > 0) And (p2 < CRLF(2)) Then
         Do While Mid(Result, p2-1) = " "
            p2 = p2 - 1
         End Loop
         GetFileMatch = Mid(Result, p1+2, p2-p1-2)
      Else
         GetFileMatch = ""
      End If
   Else
      GetFileMatch = ""
   End If
End Function

' Determines if a process is running by performing a tasks command and seeing
' if the process is in the list
Function IsProcessRunning(Match)
   Result = IssueCommand("tasks " & Match, RemoteCommandUser, RemoteCommandPassword, 10.0)
   IsProcessRunning = (Instr(1, UCase(Result), UCase(Match)) > 0)
End Function

Function RunProcess(Folder, Process, Parm, TimeoutSec)
   RunProcess = False
   If Folder = "" Then
      Cmd = Process
   Else
      Cmd = Folder & "\" & Process
   End If
   On Error Resume Next
   Shell Cmd, Parm
   e = Err
   On Error Goto 0
   If e <> 0 Then
      Exit Function
   End If
   Loops = 0
   Do
      Sleep 5.0
      Loops = Loops + 1
      If Not IsProcessRunning(Process) Then
         RunProcess = True
         Exit Do
      End If
   Loop Until (Loops > TimeoutSec) Or Abort
   Sleep 5.0
End Function

' Cleanup old upgrade files laying around on the flash disk after a reboot/re-start
Sub CleanupUpgrade
   CleanupFile = "\Flash Disk\Cleanup.bat"
   On Error Resume Next
   l = FileLen(CleanupFile)
   e = Err
   On Error Goto 0
   If (l > 0) And (e = 0) Then
      StatusMsg "Manager: Cleaning up old upgrade files after boot"
      Result = IssueCommand(CleanupFile, RemoteCommandUser, RemoteCommandPassword, 60.0)
      Sleep 1
      Kill CleanupFile
   End If
End Sub

' TalkToUser will connect a remote user to the Xpert's command prompt
Sub TalkToUser(URL)
   StatusMsg "Connecting to " & URL
   ' By default port 23 will try to autodetect Telnet or XTerm Clients
   Port = 23
   ' But an optional " /TELNET" will force telnet operations
   ' and an optional " /XTERM"  will force XTerm operation
   p = Instr(1, URL, " /")
   If p > 1 Then
      If UCase(Mid(URL, p+1)) = "/TELNET" Then
         Port = 1023
      ElseIf UCase(Mid(URL, p+1)) = "/XTERM" Then
         Port = 24
      End If
      URL = Left(URL, p-1)
   End If
   F = FreeFile
   On Error Resume Next
   Open URL As F
   e = Err
   On Error Goto 0
   If e <> 0 Then
      StatusMsg "Unable to connect to " & URL
      Exit Sub
   End If
   StatusMsg "Connected to " & URL
   Telnet = FreeFile
   Open "localhost:" & Port As Telnet
   StartTime = GetTickCount
   Reply = ""
   Do
      SetTimeout Telnet, 0.1
      Count = ReadB(Telnet, Reply, 20000)
      If Count > 0 Then
         SetTimeout F, 5  ' Allow up to 5 seconds for the data to be sent
         Print F, Reply;
         StartTime = GetTickCount
      End If
      SetTimeout F, 0.1
      Count = ReadB(F, Reply, 20000)
      If Count > 0 Then
         SetTimeout Telnet, 5  ' Allow up to 5 seconds for the data to be sent
         Print Telnet, Reply;
         StartTime = GetTickCount
      End If
      Dummy = Eof(Telnet) : ' This will clear the timeout flag and cause it to represent the connection status.
      Dummy = Eof(F) : ' This will clear the timeout flag and cause it to represent the connection status.
   Loop Until Abort Or Timeout(Telnet) Or Timeout(F) Or ((GetTickCount-StartTime) > 300000.0) Or (WaitEvent(0, CancelEvent) <> -1)
   Close F
   Close Telnet
   StatusMsg "Disconnected from " & URL
End Sub

Function InstallUpgrade
   If Not UpgradeComplete Then
      Msg = "Upgrade cannot be installed because either the last transfer failed, or one is in progress"
      StatusMsg "Manager: " & Msg
      InstallUpgrade = Msg
      Exit Function
   End If

   If NumFilesTransferred = 0 Then
      Msg = "Upgrade cannot be installed because no files were transferred on the last attempt"
      StatusMsg "Manager: " & Msg
      InstallUpgrade = Msg
      Exit Function
   End If

   NewKernel = False
   NewApg = False
   ' Detect the presence of a kernel ugprade file
   If Systat(27) < 100 Then
      StationType = "Xpert2"
   Else
      StationType = "8310"
   End If
   KernelFile = LocalUpgradePath & "\" & StationType & ".ker"

   On Error Resume Next
   l = FileLen(KernelFile)
   e = Err
   On Error Goto 0
   If (l > 9000000) And (e = 0) Then
      StatusMsg "Manager: Backing up registry to prepare for Kernel upgrade"
      FilterFile = LocalUpgradePath & "\" & StationType & ".fil"
      If FileExists(FilterFile) Then
         e = RunProcess("\Windows", "Launch.exe", "/BACKUP \Flash Disk\AutoReg.dat /FILTER " & FilterFile, 300.0)
      Else
         e = RunProcess("\Windows", "Launch.exe", "/BACKUP \Flash Disk\AutoReg.dat", 300.0)
      End If
      StatusMsg "Manager: Installing kernel upgrade, this may take a few minutes"
      ' Start the kernel upgrade process
      e = RunProcess("\Windows", "OsUpdateApp.exe", KernelFile & " /s", 300.0)
      PerformReboot = True
      NewKernel = True
   End If

   ' If there was an appropriate .upg file in the download, then copy it to the root as "Flash Disk.apg", and reboot so it will be executed by Launch
   UpgFile = GetFileMatch(LocalUpgradePath & "\" & StationType & "*.upg")
   If UpgFile <> "" Then
      On Error Resume Next
      FileCopy LocalUpgradePath & "\" & UpgFile, "\Flash Disk\Flash Disk.apg"
      e = Err
      On Error Goto 0
      If e = 0 Then
         NewApg = True
         PerformReboot = True
      End If
   End If

   Msg = "Neither a " & KernelFile & ", nor a " & LocalUpgradePath & "\" & StationType & "_vx.x.x.x.upg file were detected, so nothing to install"
   If NewKernel And NewApg Then
      Msg = "Kernel upgrade has been installed, system will be rebooted shortly to complete the App upgrade"
   ElseIf NewKernel Then
      Msg = "Kernel upgrade has been installed, system will be rebooted shortly to complete"
   ElseIf NewApg Then
      Msg = "App upgrade has been prepared, system will be rebooted shortly to complete"
   End If

   StatusMsg "Manager: " & Msg
   InstallUpgrade = Msg
End Function


Sub AppendResults(hRas, Msg)
   On Error Resume Next
   StartTask "WatchForDisconnect", hRas, TimeSerial(0,0,0), TimeSerial(0,0,2), TimeSerial(0,0,0)
   On Error Goto 0
   Reply = Chr(13) & Chr(10) & "Status Report at " & Now & ":" & Chr(13) & Chr(10) & Msg & Chr(13) & Chr(10)
   Result = FtpAppend(ServerIP, ServerFtpUser, ServerFtpPassword, Reply, RemoteResultsFile, "")
   On Error Resume Next
   StopTask "WatchForDisconnect"
   On Error Goto 0
End Sub


Function PerformRemoteCommand(hRas)
   PerformRemoteCommand = False
   ' Substitute the Station name in to the command file name and results file nmae
   On Error Resume Next
   StartTask "WatchForDisconnect", hRas, TimeSerial(0,0,0), TimeSerial(0,0,2), TimeSerial(0,0,0)
   Kill LocalCommandFile
   On Error Goto 0
   Result = FtpGet(ServerIP, ServerFtpUser, ServerFtpPassword, "I", RemoteCommandFile, LocalCommandFile, True)
   If Result = 0 Then
      ' Read the first line in the command file to look for a CONNECT command
      F = FreeFile
      Open LocalCommandFile For Input As F
      S = ""
      Line Input F, S
      ' Read the second line for a follow on command, such as UPGRADENOW
      S2 = ""
      On Error Resume Next
      Line Input F, S2
      On Error Goto 0
      Close F
      If UCase(Left(s, 8)) = "CONNECT " Then
         Reply = Chr(13) & Chr(10) & "Remote Command Execute at " & Now & ":" & Chr(13) & Chr(10) & s & " - START" & Chr(13) & Chr(10)
         Result = FtpAppend(ServerIP, ServerFtpUser, ServerFtpPassword, Reply, RemoteResultsFile, RemoteCommandFile)
         If Result <> 0 Then
            StatusMsg "Manager: PerformRemoteCommand: append failed with code " & Ftp_GetErrorStr(Result)
         End If
         Call TalkToUser(Mid(s, 9))
         Reply = Chr(13) & Chr(10) & "Remote Command Execute at " & Now & ":" & Chr(13) & Chr(10) & s & " - DONE" & Chr(13) & Chr(10)
         Result = FtpAppend(ServerIP, ServerFtpUser, ServerFtpPassword, Reply, RemoteResultsFile, RemoteCommandFile)
         If Result = 0 Then
            PerformRemoteCommand = True
         Else
            StatusMsg "Manager: PerformRemoteCommand: append failed with code " & Ftp_GetErrorStr(Result)
         End If
      ElseIf UCase(s) = "UPGRADENOW" Then
         UpgradeEnabled = False
         Reply = Chr(13) & Chr(10) & "Installing Remote Upgrade at " & Now & ":" & Chr(13) & Chr(10)
                 & InstallUpgrade & Chr(13) & Chr(10)
         Result = FtpAppend(ServerIP, ServerFtpUser, ServerFtpPassword, Reply, RemoteResultsFile, RemoteCommandFile)
         If Result = 0 Then
            PerformRemoteCommand = True
         Else
            StatusMsg "Manager: PerformRemoteCommand: append failed with code " & Ftp_GetErrorStr(Result)
         End If
      ElseIf UCase(s) = "ENABLEUPGRADE" Then
         Reply = Chr(13) & Chr(10) & "Remote Command Execute at " & Now & ":" & Chr(13) & Chr(10)
                 & "Upgrade checks are now enabled" & Chr(13) & Chr(10)
         If UCase(s2) = "UPGRADENOW" Then
            Reply = Reply & "Upgrade will be installed after download is complete." & Chr(13) & Chr(10)
            UpgradeNow = True
         Else
            UpgradeNow = False
         End If
         UpgradeEnabled = True
         CheckForUpgrade = True
         Result = FtpAppend(ServerIP, ServerFtpUser, ServerFtpPassword, Reply, RemoteResultsFile, RemoteCommandFile)
         If Result = 0 Then
            PerformRemoteCommand = True
         Else
            StatusMsg "Manager: PerformRemoteCommand: append failed with code " & Ftp_GetErrorStr(Result)
         End If
      ElseIf UCase(s) = "DISABLEUPGRADE" Then
         Reply = Chr(13) & Chr(10) & "Remote Command Execute at " & Now & ":" & Chr(13) & Chr(10)
                 & "Upgrade checks are now disabled" & Chr(13) & Chr(10)
         UpgradeEnabled = False
         CheckForUpgrade = False
         UpgradeNow = False
         Call CleanupUpgrade
         Result = FtpAppend(ServerIP, ServerFtpUser, ServerFtpPassword, Reply, RemoteResultsFile, RemoteCommandFile)
         If Result = 0 Then
            PerformRemoteCommand = True
         Else
            StatusMsg "Manager: PerformRemoteCommand: append failed with code " & Ftp_GetErrorStr(Result)
         End If
      Else
         ' Issue the command file to the command prompt
         Reply = Chr(13) & Chr(10) & "Remote Command Execute at " & Now & ":" & Chr(13) & Chr(10)
                 & IssueCommand(LocalCommandFile, RemoteCommandUser, RemoteCommandPassword, 60.0)
         Result = FtpAppend(ServerIP, ServerFtpUser, ServerFtpPassword, Reply, RemoteResultsFile, RemoteCommandFile)
         If Result = 0 Then
            PerformRemoteCommand = True
         Else
            StatusMsg "Manager: PerformRemoteCommand: append failed with code " & Ftp_GetErrorStr(Result)
         End If
      End If
   ElseIf Result = 3 Then
      PerformRemoteCommand = True
      StatusMsg "Manager: PerformRemoteCommand: new command file was not present"
   Else
      StatusMsg "Manager: PerformRemoteCommand: get failed with code " & Ftp_GetErrorStr(Result)
   End If
   On Error Resume Next
   StopTask "WatchForDisconnect"
   On Error Goto 0
End Function

Function PerformUpgrade(hRas)
   PerformUpgrade = False
   On Error Resume Next
   StartTask "WatchForDisconnect", hRas, TimeSerial(0,0,0), TimeSerial(0,0,2), TimeSerial(0,0,0)
   On Error Goto 0
   Result = 0
   Result = FtpUpgrade(ServerIP, ServerFtpUser, ServerFtpPassword, RemoteUpgradePath, LocalUpgradePath, NumFilesTransferred)
   If Result = 0 Then
      PerformUpgrade = True
      UpgradeEnabled = False
      CheckForUpgrade = False
      StatusMsg "Manager: Remote upgrade was transferred"
      Call AppendResults(hRas, "Remote upgrade has completed transfer, you may install it now.")
   Else
      StatusMsg "Manager: PerformUpgrade: failed with code " & Ftp_GetErrorStr(Result)
   End If
   On Error Resume Next
   StopTask "WatchForDisconnect"
   On Error Goto 0
End Function

Declare Tag FtpStatus(3)
Public Function Get_FtpStatus(n)
   If n = 1 Or n = 3 Then
      If WaitEvent(0, CancelEvent) <> -1 Then
         sCancel = ", Cancelled"
      Else
         sCancel = ""
      End If
      Get_FtpStatus = FtpGetBytesSent & " bytes sent" & sCancel
   Else
      Get_FtpStatus = 0
   End If
End Function

Public Sub ArchiveFileName(File)
   F = FreeFile
   On Error Resume Next
   Open ArchiveListFile For Append As F
   If Err <> 0 Then
      Open ArchiveListFile For Output As F
   End If
   If Err = 0 Then
      Print F, File
      Close F
   End If
End Sub

Public Sub ArchiveFilePos(Pos)
   F = FreeFile
   On Error Resume Next
   Open ArchivePosFile For Output As F
   Print F, Pos
   Close F
End Sub

Public Function DeleteArchiveFile
   ' Use the ArchivePosFile file to retrieve the position of the next file to be deleted
   ' from the ArchiveListFile file, and then update the ArchivePosFile file with the position
   ' of the next file to delete.
   DeleteArchiveFile = False
   S = ""
   P = 0
   F = FreeFile
   On Error Resume Next
   Open ArchivePosFile For Input As F
   If Err = 0 Then
      Input F, P
      Close F
   End If
   F = FreeFile
   Open ArchiveListFile For Input As F
   If Err = 0 Then
      Seek F, P
      Line Input F, S
      If Err = 0 Then
         P = Seek(F)
      End If
      Close F
   End If
   If S <> "" Then
      StatusMsg "Manager: Removing file from archive " & S
      Kill S
      Call ArchiveFilePos(P)
      DeleteArchiveFile = True
   End If
End Function

Sub ArchiveImage(Camera, LocalStarDotImageFile, ArchiveStarDotPath)
   On Error Resume Next
   MkDir ArchiveStarDotPath
   D = GetScheduledTime
   ' <station name>_<camera>_<yyyy><mm><dd>_<hh><mm><ss>.jpg
   DestFile = ArchiveStarDotPath & "\" & StationName & "_" & Camera & Format("_%04d%02d%02d_%02d%02d%02d.jpg", Year(D), Month(D), Day(D), Hour(D), Minute(D), Second(D))
   StatusMsg "Manager: Copying " & LocalStarDotImageFile & " to " & DestFile
   FileCopy LocalStarDotImageFile, DestFile
   e = Err
   If e = 0 Then
      StatusMsg "Manager: Copy " & Camera & " image to archive worked"
   Else
      StatusMsg "Manager: Copy " & Camera & " image to archive failed (" & Error(e) & ")"
   End If
   On Error Goto 0
   Call ArchiveFileName(DestFile)
End Sub

Sub TransferImage(Handle, Camera, LocalImageFile, ServerImagePath)
   SentPicture = False
   D = GetScheduledTime
   ' <station name>_<camera>_<yyyy><mm><dd>_<hh><mm><ss>.jpg
   DestFile = ServerImagePath & StationName & "_" & Camera & Format("_%04d%02d%02d_%02d%02d%02d.jpg", Year(D), Month(D), Day(D), Hour(D), Minute(D), Second(D))
   ' Try up to 5 times to send the picture
   For FtpAttempts = 1 To 5
      If WaitEvent(0, Shutdown) < 0 Then
         If DeferModemOff Then
            ModemReady = True
         Else
            ' Power up the modem
            StatusMsg "Manager: Powering A3LA-RM modem ON (" & FtpAttempts & "/5)"
            Digital 1, ModemDIGIO, True
            StatusMsg "Manager: Waiting for modem to power up"
            ModemReady = WaitEvent(ModemWarmupDelay, Shutdown) < 0
         End If
         If ModemReady Then
            If DeferModemOff Then
               DeferModemOff = False
            Else
               StatusMsg "Manager: Connecting to ISP using modem (" & FtpAttempts & "/5)"
               If SIMULATE Then
                  Handle = 1
               Else
                  Handle = OpenA3LA(ModemPort, ISP_PhoneNumber, ISP_UserName, ISP_Password, ISP_ModemInit, 120)
               End If
            End If
            If Handle <> 0 Then
               StatusMsg "Manager: Connected to ISP"
               If WaitEvent(0, Shutdown) < 0 Then
                  ' Transfer the image from the Xpert to the FTP Server
                  StatusMsg "Manager: Uploading picture with FTP using PutImage"
                  If PutImage(Handle, LocalImageFile, DestFile) Then
                     StatusMsg "Manager: PutImage " & Camera & " worked (" & FtpAttempts & "/5)"
                     SentPicture = True
                     DeferModemOff = True
                  Else
                     StatusMsg "Manager: PutImage " & Camera & " did not complete (" & FtpAttempts & "/5)"
                  End If
               End If
               If Not DeferModemOff Then
                  StatusMsg "Manager: Closing ISP connection"
                  If Not SIMULATE Then
                     Call CloseA3LA(Handle)
                  End If
                  ResetEvent CancelEvent
               End If
            Else
               StatusMsg "Manager: Unable to connect to ISP (" & FtpAttempts & "/5)"
            End If
         End If
         If Not DeferModemOff Then
            ' Power off the Modem
            StatusMsg "Manager: Powering A3LA-RM modem OFF"
            Digital 1, ModemDIGIO, False
         End If
      End If
      If SentPicture Then
         Exit For
      End If
      Sleep 60.0
   Next FtpAttempts
   If Not SentPicture Then
      StatusMsg "Manager: PutImage " & Camera & " failed"
   End If
End Sub

Public Sub Sched_Manager
   GotFLIRPicture = False
   GotStarDotPicture1 = False
   GotStarDotPicture2 = False
   ' Allow some time for the other scheduled routines to set flags
   Sleep 0.2
   ' Re-initialize variables that are based on the station name in case it changed
   Call InitStationVars
   '
   If TakeFLIRPicture Or TakeStarDotPicture1 Or TakeStarDotPicture2 Then
      ' Power up the relay to the Cameras
      StatusMsg "Manager: Powering Cameras ON"
      Digital 1, FLIRDIGIO, True
      Digital 1, StarDotDIGIO, True

      If Not SIMULATE Then
         Turn "ETH", "ON"
      End If

      StatusMsg "Manager: Waiting for Camera to power up"
      If WaitEvent(CameraWarmupDelay, Shutdown) < 0 Then

         If TakeFLIRPicture Then
            TakeFLIRPicture = False
            GotFLIRPicture = TakePicture_FLIR
         End If

         If TakeStarDotPicture1 Then
            TakeStarDotPicture1 = False
            GotStarDotPicture1 = TakePicture_StarDot(StarDotIPAddress1, LocalStarDotImageFile1)
         End If

         If TakeStarDotPicture2 Then
            TakeStarDotPicture2 = False
            GotStarDotPicture2 = TakePicture_StarDot(StarDotIPAddress2, LocalStarDotImageFile2)
         End If

      End If

      StatusMsg "Manager: Powering Cameras OFF"
      ' Power off the Cameras
      Digital 1, FLIRDIGIO, False
      Digital 1, StarDotDIGIO, False
      ' Power off the LAN
      If Not SIMULATE Then
         Turn "ETH", "OFF"
      End If
   End If

   ' Archive the FLIR picture to the SD Card
   If GotFLIRPicture Then
      Call ArchiveImage("FLIR", LocalFLIRImageFile, ArchiveFLIRPath)
   End If

   ' Archive the StarDot #1 picture to the SD Card
   If GotStarDotPicture1 Then
      Call ArchiveImage("StarDot1", LocalStarDotImageFile1, ArchiveStarDotPath1)
   End If

   ' Archive the StarDot #2 picture to the SD Card
   If GotStarDotPicture2 Then
      Call ArchiveImage("StarDot2", LocalStarDotImageFile2, ArchiveStarDotPath2)
   End If

   DeferModemOff = False

   ' Handle is the socket to the FTP Server. We will keep it open across transfers as long as they
   ' go through successfully
   Handle = 0

   ' See if we should transfer FLIR picture to the FTP Server
   If TransferFLIRPicture And GotFLIRPicture And (WaitEvent(0, Shutdown) < 0) Then
      TransferFLIRPicture = False
      Call TransferImage(Handle, "FLIR", LocalFLIRImageFile, ServerFLIRImagePath)
   End If

   ' See if we should transfer StarDot 1 picture to the FTP Server
   If TransferStarDotPicture1 And GotStarDotPicture1 And (WaitEvent(0, Shutdown) < 0) Then
      TransferStarDotPicture1 = False
      Call TransferImage(Handle, "StarDot1", LocalStarDotImageFile1, ServerStarDotImagePath1)
   End If

   ' See if we should transfer StarDot 2 picture to the FTP Server
   If TransferStarDotPicture2 And GotStarDotPicture2 And (WaitEvent(0, Shutdown) < 0) Then
      TransferStarDotPicture2 = False
      Call TransferImage(Handle, "StarDot2", LocalStarDotImageFile2, ServerStarDotImagePath2)
   End If

   ' See if we should check for a remote command
   If CheckForCommand And (WaitEvent(0, Shutdown) < 0) Then
      CheckForCommand = False
      CommandComplete = False
      ' Try up to 5 times to retrieve the upgrade
      For FtpAttempts = 1 To 5
         StatusMsg "Manager: Checking for Command (" & FtpAttempts & "/5)"
         If DeferModemOff Then
            ModemReady = True
         Else
            ' Power up the modem
            StatusMsg "Manager: Powering A3LA-RM modem ON (" & FtpAttempts & "/5)"
            Digital 1, ModemDIGIO, True
            StatusMsg "Manager: Waiting for modem to power up"
            ModemReady = WaitEvent(ModemWarmupDelay, Shutdown) < 0
         End If
         If ModemReady Then
            If DeferModemOff Then
               DeferModemOff = False
            Else
               StatusMsg "Manager: Connecting to ISP using modem (" & FtpAttempts & "/5)"
               If SIMULATE Then
                  Handle = 1
               Else
                  Handle = OpenA3LA(ModemPort, ISP_PhoneNumber, ISP_UserName, ISP_Password, ISP_ModemInit, 120)
               End If
            End If
            If Handle <> 0 Then
               StatusMsg "Manager: Connected to ISP"
               If WaitEvent(0, Shutdown) < 0 Then
                  If NotifyStartup <> 0 Then
                     Call AppendResults(Handle, "The station was restarted at " & NotifyStartup & " - upgrade files have been removed.")
                     NotifyStartup = 0
                  End If
                  If Not CommandComplete Then
                     StatusMsg "Manager: Checking for a remote command (" & FtpAttempts & "/5)"
                     If PerformRemoteCommand(Handle) Then
                        CommandComplete = True
                        DeferModemOff = True
                     End If
                  End If
               End If
               If Not DeferModemOff Then
                  StatusMsg "Manager: Closing ISP connection"
                  If Not SIMULATE Then
                     Call CloseA3LA(Handle)
                  End If
                  ResetEvent CancelEvent
               End If
            Else
               StatusMsg "Manager: Unable to connect to ISP (" & FtpAttempts & "/5)"
            End If
         End If
         If CommandComplete Then
            Exit For
         End If
         Sleep 60.0
      Next FtpAttempts
   End If

   ' See if we should perform an upgrade
   If CheckForUpgrade And (WaitEvent(0, Shutdown) < 0) Then
      CheckForUpgrade = False
      UpgradeComplete = False
      ' Try up to 5 times to retrieve the upgrade
      For FtpAttempts = 1 To 5
         StatusMsg "Manager: Checking for Upgrade (" & FtpAttempts & "/5)"
         If DeferModemOff Then
            ModemReady = True
         Else
            ' Power up the modem
            StatusMsg "Manager: Powering A3LA-RM modem ON (" & FtpAttempts & "/5)"
            Digital 1, ModemDIGIO, True
            StatusMsg "Manager: Waiting for modem to power up"
            ModemReady = WaitEvent(ModemWarmupDelay, Shutdown) < 0
         End If
         If ModemReady Then
            If DeferModemOff Then
               DeferModemOff = False
            Else
               StatusMsg "Manager: Connecting to ISP using modem (" & FtpAttempts & "/5)"
               If SIMULATE Then
                  Handle = 1
               Else
                  Handle = OpenA3LA(ModemPort, ISP_PhoneNumber, ISP_UserName, ISP_Password, ISP_ModemInit, 120)
               End If
            End If
            If Handle <> 0 Then
               StatusMsg "Manager: Connected to ISP"
               If WaitEvent(0, Shutdown) < 0 Then
                  If Not UpgradeComplete Then
                     ' Check for an upgrade on the FTP Server
                     StatusMsg "Manager: Checking for upgrade files (" & FtpAttempts & "/5)"
                     If PerformUpgrade(Handle) Then
                        UpgradeComplete = True
                        DeferModemOff = True
                     End If
                  End If
               End If
               If Not DeferModemOff Then
                  StatusMsg "Manager: Closing ISP connection"
                  If Not SIMULATE Then
                     Call CloseA3LA(Handle)
                  End If
                  ResetEvent CancelEvent
               End If
            Else
               StatusMsg "Manager: Unable to connect to ISP (" & FtpAttempts & "/5)"
            End If
         End If
         If UpgradeComplete Then
            If UpgradeNow And (NumFilesTransferred > 0) Then
               If SIMULATE Then
                  RasReady = True
               Else
                  RasReady = Ras_IsConnected(Handle)
               End If
               If RasReady Then
                  UpgradeEnabled = False
                  Reply = InstallUpgrade
                  Call AppendResults(Handle, Reply)
               End If
            End If
            Exit For
         End If
         Sleep 60.0
      Next FtpAttempts
   End If

   If DeferModemOff Then
      DeferModemOff = False
      Handle = 0
      StatusMsg "Manager: Closing ISP connection"
      If Not SIMULATE Then
         Call CloseA3LA(Handle)
      End If
      ResetEvent CancelEvent
      ' Power off the Modem
      StatusMsg "Manager: Powering A3LA-RM modem OFF"
      Digital 1, ModemDIGIO, False
   End If

   If PerformReboot Then
      StatusMsg "Manager: Rebooting system (in 10 seconds) to complete remote upgrade"
      Sleep 10.0
      Reboot
   End If

   If PerformMaintenance And (WaitEvent(0, Shutdown) < 0) Then
      PerformMaintenance = False
      StatusMsg "Manager: Performing Maintenance"
      SDCardSpace = Systat(24)
      FreeSpace = SDCardSpace(0)
      Loops = 0 ' Prevent an infinite loop
      If FreeSpace < ArchiveSpace Then
         StatusMsg "Manager: Delete files from archive to make space. Freespace: " & FreeSpace
         Do While (FreeSpace < ArchiveSpace) And (Loops < 10000) And DeleteArchiveFile And (WaitEvent(0, Shutdown) < 0)
            SDCardSpace = Systat(24)
            FreeSpace = SDCardSpace(0)
            Loops = Loops + 1
         End Loop
      End If
      MemoryUsage = Systat(20)
      StatusMsg "Manager: Memory usage is at " & MemoryUsage(0) & "%"
      If MemoryUsage(0) > 90 Then
         StatusMsg "Manager: Rebooting system (in 10 seconds) due to memory usage exceeding 90%"
         Sleep 10.0
         Reboot
      End If
   End If
End Sub

Public Sub SCHED_ArchiveMaintenance
   ' Schedule this routine on a periodic basis to make sure there's plenty of room in the archive
   PerformMaintenance = True
End Sub

Public Sub SCHED_CheckForUpgrade
   ' Schedule this routine on a periodic basis to check for an upgrade (assuming it's been enabled)
   If UpgradeEnabled Then
      CheckForUpgrade = True
   End If
End Sub

Public Sub SCHED_CheckForCommand
   ' Schedule this routine on a periodic basis to check for a remote command
   CheckForCommand = True
End Sub

Public Sub SCHED_TakeFLIRPicture
   TakeFLIRPicture = True
End Sub

Public Sub SCHED_TakeStarDotPicture1
   TakeStarDotPicture1 = True
End Sub

Public Sub SCHED_TakeStarDotPicture2
   TakeStarDotPicture2 = True
End Sub

Public Sub SCHED_TransferFLIRPicture
   TransferFLIRPicture = True
End Sub

Public Sub SCHED_TransferStarDotPicture
   TransferStarDotPicture1 = True
   TransferStarDotPicture2 = True
End Sub

' This creates a tag that can be used to control power to the Modem's relay (for testing)
Declare Tag Modem(3)
Public Function Get_Modem(Value)
   If Value = 1 Or Value = 3 Then
      If Digital(1, ModemDIGIO) Then
         Get_Modem = 1
      Else
         Get_Modem = 0
      End If
   Else
      Get_Modem = 0
   End If
End Function

Public Sub Set_Modem(Value, Data)
   If Value = 1 Or Value = 3 Then
      Digital 1, ModemDIGIO, Data
   End If
End Sub

' This creates a tag that can be used to control power to the Camera's relay (for testing)
Declare Tag Camera(3)
Public Function Get_Camera(Value)
   If Value = 1 Or Value = 3 Then
      If Digital(1, FLIRDIGIO) Then
         Get_Camera = 1
      Else
         Get_Camera = 0
      End If
   Else
      Get_Camera = 0
   End If
End Function

Public Sub Set_Camera(Value, Data)
   If Value = 1 Or Value = 3 Then
      Digital 1, FLIRDIGIO, Data
      Digital 1, StarDotDIGIO, Data
   End If
End Sub

Sub Start_Program
   Call InitStationVars
   NotifyStartup = Now
   ResetEvent Shutdown
   ' Power off the Camera
   Digital 1, FLIRDIGIO, False
   Digital 1, StarDotDIGIO, False
   ' Power off the Modem
   Digital 1, ModemDIGIO, False
   If Not SIMULATE Then
      ' Power off the LAN
      Turn "ETH", "OFF"
   End If
   Call CleanupUpgrade
End Sub

Sub Stop_Program
   StatusMsg "Manager: Stopping camera and modem"
   ' Setting the Shutdown event will cause sleeps warm up delays to abort and operations to cancel
   SetEvent Shutdown
   SetEvent CancelEvent
   Call FtpCancel
End Sub

If SIMULATE Then
   ErrorMsg "Manager.bas is running with simulation enabled. This should not be used on a field unit."
End If