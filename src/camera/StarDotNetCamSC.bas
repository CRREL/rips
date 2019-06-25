 ' This will work with a StarDot SC Internet Camera
' The program will capture a single .JPG image ' and save it out to \Flash Disk\ directory

'************* User-defined constants ********************
Static StarDotIPAddress1 = "192.168.50.130:80" ' StarDot1
Static StarDotIPAddress2 = "192.168.50.132:80" ' StarDot2
Static LocalStarDotImageFile1 = "\Flash Disk\stardot1.jpg"
Static LocalStarDotImageFile2 = "\Flash Disk\stardot2.jpg"
Const LightChannel = 6       : ' Channel number Light Sensor is connected to
                             : ' The 9210B and 8310 use VRef, so this
Const LightRef = 6           : ' actually just needs to be any valid
                             : ' channel number for those loggers
Const LightWarmup = 100      : ' Warmup time in milli-seconds
Const LightRefVolt = 2.0     : ' Use a 2v reference voltage (ignored by 8310 & 9210B)
Const LightThreshold = 0.00028 : ' Reading below this value and we will not take a picture

' WIRING:
' Analog CH6 : emitter of Vishay TEPT5700 (Yellow wire)
' Analog CH6 : one side of 10K resistor
' Analog Gnd : other side of 10K resistor
' Analog VRef: collector of Vishay TEPT5700 (Red wire)

'******************************************************************
Public Function TakePicture_StarDot(StarDotIPAddress, LocalStarDotImageFile)
   TakePicture_StarDot = False

    On Error Resume Next
   ConfigAd 1, LightChannel, 60, LightWarmup, 0
   LightLevel = Ad(1, LightChannel, LightRef, LightRefVolt)
   If Err = 0 Then
      Log "ssp.log", Now, "LightLevel", LightLevel, "G", "volts"
   Else
      WarningMsg "Failed to read light level due to " & Error
      Log "ssp.log", Now, "LightLevel", LightLevel, "B", "volts"
      LightLevel = 2.5 : ' Act like the light level was actually ok
   End If
   On Error Goto 0
   If LightLevel < LightThreshold Then
      StatusMsg "Insufficient light to take picture: " & LightLevel & " volts"
      Exit Function
   End If

   GetImageTries = 0
   OpenIPTries = 0
   On Error Resume Next

GetImage:
   F1 = FreeFile
   TextStr = ""
   A = ""

OpenIPAddress:
   Open StarDotIPAddress As F1
   If Err<>0 Then
      ErrorMsg "StarDot: Could not open com port."
      If OpenIPTries < 3 Then
         Sleep 10
         OpenIPTries = OpenIPTries + 1
         GoTo OpenIPAddress
      Else
         Exit Sub
      End If
   End If

   SetTimeout F1, 10.0
   StatusMsg "StarDot: Port opened"

   CRLF = Chr(13) & Chr(10)
   Print F1, "GET /image.jpg" & CRLF & CRLF;
   StatusMsg "StarDot: Sent Get"

   ' Read until we hit a blank line: this is just header info before the image
   ' (Some cameras do not output a header and this loop should be commented out)
   A = ""
   Do
      Line Input F1, A
   Loop While (Err = 0) And (Len(A) > 0)

   ' We expect a final LF character regardless of whether there's a header or not
   N = ReadB(F1, A, 1)

   ReadBytes = 0
   WriteBytes = 0
   F2 = FreeFile
   Open LocalStarDotImageFile For Output As F2
   If Err<>0 Then
      ErrorMsg "StarDot: Could not create file "+ LocalStarDotImageFile
      Exit Function
   End If
   'StatusMsg "StarDot: Numbytes = " & Loc(F1)
   Do
      N = ReadB(F1, A, 8192)
      ReadBytes = ReadBytes + N
      'StatusMsg "StarDot: ReadB Numbytes = " + str(N)
      If N>0 Then
         wA = WriteB(F2, A, N)
         'StatusMsg "StarDot: WriteB Numbytes = " + str(wA)
         WriteBytes = WriteBytes + wA
      End If
      'N = Loc(F1)
      If Timeout(F1) Then
         StatusMsg "StarDot: Port Timeout"
         Exit Do
      End If
      'StatusMsg "StarDot: Loc in Loop - " + str(N)
   Loop Until N <> 8192
   StatusMsg "StarDot: Total Read - " + str(ReadBytes)
   StatusMsg "StarDot: Total Write - " + str(WriteBytes)
   Close F1
   StatusMsg "StarDot: Image file - "+LocalStarDotImageFile
   Close F2
   If WriteBytes = 0 Then
      StatusMsg "StarDot: Zero bytes received from images...retrying"
      Kill LocalStarDotImageFile
      If Err <> 0 Then
        StatusMsg "StarDot: Unable to delete :"+LocalStarDotImageFile
      End If
      If (GetImageTries < 3) Then
          GetImageTries = GetImageTries + 1
          Sleep 10
          Goto GetImage
      End If
   Else
      TakePicture_StarDot = True
   End If
End Function

