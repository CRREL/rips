' A3LA.BAS - control making an internet connecting using the NAL Research A3LA-RM Iridium modem
' and the Xpert's RAS API ... requires firmware 3.13 and later.

' Parameter that begin with "s" are strings, "i" are integers, and "b" are boolean

' This function intializes a RAS API session
Declare Function Ras_Open Lib "\Windows\Utils.dll" As Integer
' Parameters
'    None
' Return Value
'    A handle value that must be passed to the other RAS API functions

' This function terminates a RAS API session
Declare Function Ras_Close Lib "\Windows\Utils.dll" (iHandle) As Integer
' Parameters
'    iHandle
'       value returned by Ras_Open
' Return Value
'    1 indicates success, 0 failure

' One of these functions must be called before a RAS connection can be established. The settings
' are stored in the registry and hence once called, they do not need to be called again.
' CreateModemSettings is used with a dial-up modem while CreateAPNSettings is used with a cell modem.
Declare Function Ras_CreateModemSettings Lib "\Windows\Utils.dll" (iHandle, sPort, sDialStr, sInitStr, bFullAT) As Integer
Declare Function Ras_CreateAPNSettings Lib "\Windows\Utils.dll" (iHandle, sPort, sAPN, sInitStr, bFullAT) As Integer
' Parameters
'    iHandle
'       Value returned by Ras_Open
'    sPort
'       Serial port to configure (ex: "COM2:")
'    sDialStr or sAPN
'       sDialStr contains AT commands to be issued before dialing (ex: "E0")
'       sAPN contains the Cellular Access Point Name to connect to (ex: "telargo.t-mobile.com")
'    sInitStr
'       contains AT commands to be issued to the modem during initialization (ex: "E0V1&C1&D2&K3")
'    bFullAT
'       True when using a modem with support for AT command set, otherwise try False if the modem has
'       very limited support.
' Return Value
'    1 indicates success, 0 failure

' This function dials a PPP provider or ISP to establish a dial-up network connection
' Before a connection can be made, phone book entries must be created by calling
' either Ras_CreateModemSettings or Ras_CreateAPNSettings
Declare Function Ras_Dial Lib "\Windows\Utils.dll" (iHandle, sPort, sPhoneNumber, sUserName, sPassword,
              bUseSlip, iBaudRate, bUseHardFlow, sIpAddr, sDNS, iRasOptions, iTimeoutSeconds) As Integer
' Parameters
'    iHandle
'       Value returned by Ras_Open
'    sPort
'       Serial port to connect with (ex: "COM2:")
'    sPhoneNumber
'       Phone number to dial (ex: "555-555-5555")
'    sUserName
'       User name to use for authentication
'    sPassword
'       Password to use for authentication
'    bUseSlip
'       True to use SLIP protocol, False for PPP. SLIP is a simpler protocol than PPP and cannot
'       obtain an IpAddr or DNS settings from the provider, hence they must be specified.
'    iBaudRate
'       Baud rate to use (ex: 115200)
'    bUseHardwareFlow
'       Prevent buffer over-runs by using RTS/CTS flow control (ex: True)
'    sIpAddr
'       Specify a static IP address (ex: "1.2.3.4")
'    sDNS
'       Specify a DNS server to use (ex: "1.2.3.5")
'    iRasOptions
'       A bit mask of options to use when making the connections The RASEO constants may be "or'd" together.
'       0 is the same as passing (RASEO_NetworkLogon Or RASEO_SwCompression Or RASEO_IpHeaderCompression Or RASEO_RemoteDefaultGateway)
' Return Value
'    0 indicates success, anything else is a "RAS error" and the code can be
'    looked up on the internet by searching for "RAS error xxx" where xxx is the code
'    or by referring to this document: http://support.microsoft.com/kb/163111

' This function can be called to connect to an existing PPP connection
' in order to monitor its status, retrieve statistics, or force it to hangup
Declare Function Ras_ManageExisting Lib "\Windows\Utils.dll" (iHandle, sPort) As Integer
' Parameters
'    iHandle
'       Value returned by Ras_Open
'    sPort
'       Serial port to configure (ex: "COM2:")
' Return Value
'    1 indicates success, 0 failure

' This function may be called to hangup on an established connection
Declare Function Ras_Hangup Lib "\Windows\Utils.dll" (iHandle) As Integer
' Parameters
'    iHandle
'       Value returned by Ras_Open
' Return Value
'    1 indicates success, 0 failure

' This function may be called to check if a reboot is needed after changing
' the modem or APN settings. A reboot is required when a "phone book entry" did not
' already exist in the registry for a given COM port in order for the new settings to
' take effect.
Declare Function Ras_NeedReboot Lib "\Windows\Utils.dll" (iHandle) As Integer
' Parameters
'    iHandle
'       Value returned by Ras_Open
' Return Value
'    1 indicates that a reboot is needed, 0 indicates a reboot is not needed.

' This function checks to see if the RAS connection has been established
' and hence TCP/IP operations can be performed.
Declare Function Ras_IsConnected Lib "\Windows\Utils.dll" (iHandle) As Integer
' Parameters
'    iHandle
'       Value returned by Ras_Open
' Return Value
'    1 indicates that a connection has been established, 0 indicates that
'    either the connection was never established or that it was dropped.

' This function returns the current state of the RAS connection
Declare Function Ras_GetState Lib "\Windows\Utils.dll" (iHandle) As String
' Parameters
'    iHandle
'       Value returned by Ras_Open
' Return Value
'    A string value indicating the current state and progress
'    in dialing the ISP and authenticating the connection.
'    Samples values: "Disconnected", "Opening Port", "Device Connected", "Connected"

' Removes registry entries created by Ras_CreateModemSettings or Ras_CreateAPNSettings
Declare Function Ras_CleanSettings Lib "\Windows\Utils.dll" (iHandle, sPort) As Integer
' Parameters
'    iHandle
'       Value returned by Ras_Open
' Return Value
'    0 indicates success, anything else is a "RAS error" and the code can be
'    looked up on the internet by searching for "RAS error xxx" where xxx is the code
'    or by referring to this document: http://support.microsoft.com/kb/163111

' Retrieves various statistics for an established connection
Declare Function Ras_GetStatistic Lib "\Windows\Utils.dll" (iHandle, iIndex) As Integer
' Parameters
'    iHandle
'       Value returned by Ras_Open
'    iIndex
'       The statistic to retrieve:
'         0:  BytesXmited         - The number of bytes transmitted through this connection or link.
'         1:  BytesRcved          - The number of bytes received through this connection or link.
'         2:  FramesXmited        - The number frames transmitted through this connection or link.
'         3:  FramesRcved         - The number of frames received through this connection or link.
'         4:  CrcErr              - The number of cyclic redundancy check (CRC) errors on this connection or link.
'         5:  TimeoutErr          - The number of timeout errors on this connection or link.
'         6:  AlignmentErr        - The number of alignment errors on this connection or link.
'         7:  HardwareOverrunErr  - The number of hardware overrun errors on this connection or link.
'         8:  FramingErr          - The number of framing errors on this connection or link.
'         9:  BufferOverrunErr    - The number of buffer overrun errors on this connection or link.
'         10: CompressionRatioIn  - The compression ratio for the data being received on this connection or link.
'         11: CompressionRatioOut - The compression ratio for the data being transmitted on this connection or link.
'         12: Bps                 - The speed of the connection or link, in bits per second.
'         13: ConnectDuration     - The amount of time, in milliseconds, that the connection or link has been connected.
' Return Value
'    A value depending on the value of iIndex

' Bit flags for iRasOptions:
Const RASEO_IpHeaderCompression     = &h00000008   ' Enables IP Header compression (recommended)
Const RASEO_RemoteDefaultGateway    = &h00000010   ' Routes all traffic through the RAS adapter (recommended)
Const RASEO_DisableLcpExtensions    = &h00000020   ' LCP Extensions may cause problems with some modems
Const RASEO_SwCompression           = &h00000200   ' Allows S/W compression to be negotiated (recommended)
Const RASEO_RequireEncryptedPw      = &h00000400   ' Prevents authentication methods which use PAP plain-text password
Const RASEO_RequireMsEncryptedPw    = &h00000800   ' Prevents authentication via PAP plain-text, CHAP, MS-CHAP, or SPAP
Const RASEO_RequireDataEncryption   = &h00001000   ' Requires data to be encrypted for a connection
Const RASEO_NetworkLogon            = &h00002000   ' Log on to the network (recommended)
Const RASEO_ProhibitPAP             = &h00040000   ' Prevent PAP from being used for authentication
Const RASEO_ProhibitCHAP            = &h00080000   ' Prevent CHAP from being used for authentication
Const RASEO_ProhibitMsCHAP          = &h00100000   ' Prevent MS-CHAP from being used for authentication
Const RASEO_ProhibitMsCHAP2         = &h00200000   ' Prevent MS-CHAP2 from being used for authentication
Const RASEO_ProhibitEAP             = &h00400000   ' Prevent PAP from being used for authentication

'---------------------------------------------------------------

Const DefaultModemInit = "E0V1&C1&D2&K3"

Public Sub CloseA3LA(Handle)
   x = Ras_Hangup(Handle)
   x = Ras_Close(Handle)
   Handle = 0
End Sub

Public Function OpenA3LA(Port, PhoneNumber, UserName, Password, InitStr, TimeoutSeconds)
   Handle = Ras_Open
   If Handle <> 0 Then
      If Ras_CreateModemSettings(Handle, Port, "", DefaultModemInit & InitStr, True) Then
         X = Ras_ManageExisting(Handle, Port)
         ' If there is an existing connection, Ras_Dial will hangup on it, and make a new connection
         dwOptions = RASEO_RemoteDefaultGateway Or RASEO_NetworkLogon Or RASEO_DisableLcpExtensions
         ' Or RASEO_ProhibitMsCHAP Or RASEO_ProhibitMsCHAP2 Or RASEO_ProhibitEAP
         RasErr = Ras_Dial(Handle, Port, PhoneNumber, UserName, Password, False, 19200, True, "", "", dwOptions, TimeoutSeconds)
         If RasErr <> 0 Then
            StatusMsg "Unable to connect to A3LA due to Ras Error " & RasErr
            Call CloseA3LA(Handle)
         End If
      Else
         StatusMsg "Unable to create modem settings for A3LA"
         Call CloseA3LA(Handle)
      End If
   End If
   OpenA3LA = Handle
End Function

