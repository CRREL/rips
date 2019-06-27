Public Declare Function FtpPut(URL, UserName, Password, FileType, SourceFile, DestFile, AutoResume)
' Parameters
'    URL
'       a URL/IP Address, ex: "ftp.test.com"
'    UserName
'       User name for logging in to the FTP server
'    Password
'       Password for logging in to the FTP server (clear text password)
'    FileType
'       "An" - ASCII, where n may be omitted, N, T, or C (see FTP TYPE command doc)
'       "En" - EBCDIC, where n may be omitted, N, T, or C (see FTP TYPE command doc)
'       "I"  - IMAGE (binary data)
'       "Ln" - local format, where n is the number of bits per byte
'    SourceFile
'       name & path of a file to send to the server, ex: "\Flash Disk\image.jpg"
'    DestFile
'       name & path of the file to store on the server, ex: "//home/usr/sutron/image.jpg"
'    AutoResume
'       Pass 'true' to cause the transfer to try to pick up where a previous left off
' Return value
'    0: Success
'    1: Could not connect
'    2: Could not login
'    3: File does not exist
'    4: Command denied
'    5: Could not rename .partial file to final name
'    6: Could not establish data channel
'    7: Could not connect to data channel
'    8: Could not initiate store to destination file
'    9: Could not open sourcefile
'   10: Could not create destination
'   11: Could not read from source
'   12: Could not write to destination
'   13: Failure while sending data
'   14: Server did not report success
'   15: Operation was cancelled with the CancelEvent, or a system shutdown

Public Declare Function FtpGet(URL, UserName, Password, FileType, SourceFile, DestFile, AutoResume)
' Parameters
'    URL
'       a URL/IP Address, ex: "ftp.test.com"
'    UserName
'       User name for logging in to the FTP server
'    Password
'       Password for logging in to the FTP server (clear text password)
'    FileType
'       "An" - ASCII, where n may be omitted, N, T, or C (see FTP TYPE command doc)
'       "En" - EBCDIC, where n may be omitted, N, T, or C (see FTP TYPE command doc)
'       "I"  - IMAGE (binary data)
'       "Ln" - local format, where n is the number of bits per byte
'    SourceFile
'       name & path of a file to get from the server, ex: "//home/usr/sutron/image.jpg"
'    DestFile
'       name & path of the file to store on the RTU, ex: "\Flash Disk\image.jpg"
'    AutoResume
'       Pass 'true' to cause the transfer to try to pick up where a previous left off
' Return value
'    0: Success
'    1: Could not connect
'    2: Could not login
'    3: File does not exist
'    4: Command denied
'    5: Could not rename .partial file to final name
'    6: Could not establish data channel
'    7: Could not connect to data channel
'    8: Could not initiate store to destination file
'    9: Could not open sourcefile
'   10: Could not create destination
'   11: Could not read from source
'   12: Could not write to destination
'   13: Failure while sending data
'   14: Server did not report success
'   15: Operation was cancelled with the CancelEvent, or a system shutdown

Public Declare Function FtpAppend(URL, UserName, Password, Buffer, DestFile, FileToDeleteAfter)
' Parameters
'    URL
'       a URL/IP Address, ex: "ftp.test.com"
'    UserName
'       User name for logging in to the FTP server
'    Password
'       Password for logging in to the FTP server (clear text password)
'    Buffer
'       String to append to the DestFile
'    DestFile
'       File to append the Buffer to - it must already exist.
'    FileToDeleteAfter
'       A file to delete on the FTP server after the append assuming it succeeded
'       and the specified file is not blank ("")
' Return value
'    0: Success
'    1: Could not connect
'    2: Could not login
'    3: File does not exist
'    4: Command denied
'    5: Could not rename .partial file to final name
'    6: Could not establish data channel
'    7: Could not connect to data channel
'    8: Could not initiate store to destination file
'    9: Could not open sourcefile
'   10: Could not create destination
'   11: Could not read from source
'   12: Could not write to destination
'   13: Failure while sending data
'   14: Server did not report success
'   15: Operation was cancelled with the CancelEvent, or a system shutdown

Public Declare Function FtpUpgrade(URL, UserName, Password, SourcePath, DestPath, nFiles)
' Parameters
'    URL
'       a URL/IP Address, ex: "ftp.test.com"
'    UserName
'       User name for logging in to the FTP server
'    Password
'       Password for logging in to the FTP server (clear text password)
'    SourcePath
'       A folder on the FTP Server to check for upgrade files (ex: "/myserver/download")
'    DestPath
'       A folder on the Xpert to place the upgrade files (ex: "\Flash Disk\Upgrade")
'    nFiles
'       Number of files transferred
' Return value
'    0: Success
'    1: Could not connect
'    2: Could not login
'    3: File does not exist
'    4: Command denied
'    5: Could not rename .partial file to final name
'    6: Could not establish data channel
'    7: Could not connect to data channel
'    8: Could not initiate store to destination file
'    9: Could not open sourcefile
'   10: Could not create destination
'   11: Could not read from source
'   12: Could not write to destination
'   13: Failure while sending data
'   14: Server did not report success
'   15: Operation was cancelled with the CancelEvent, or a system shutdown

Public Declare Function FtpGetBytesSent
' Return value
'    the number of bytes that have been transmitted over FTP (or 0 a transfer is not in progress)

Public Declare Sub FtpCancel
' Cancels an FTP operation that's in progress

' Reference
'   I found this web page useful for learning the syntax of FTP commands:
'      http://www.nsftools.com/tips/RawFTP.htm
'
Declare Function Ftp_Open Lib "\Windows\Utils.dll" (sURL, iPort, sUserName, sPassword) As Integer
Declare Function Ftp_Close Lib "\Windows\Utils.dll" (iHandle) As Integer
Declare Function Ftp_Connect Lib "\Windows\Utils.dll" (iHandle) As Integer
Declare Sub Ftp_SetFileType Lib "\Windows\Utils.dll" (iHandle, sFileType)
Declare Function Ftp_GetBytesSent Lib "\Windows\Utils.dll" (iHandle) As Integer
Declare Function Ftp_GetBytesRetrieved Lib "\Windows\Utils.dll" (iHandle) As Integer
Declare Sub Ftp_Cancel Lib "\Windows\Utils.dll" (iHandle)
Declare Function Ftp_Put Lib "\Windows\Utils.dll" (iHandle, sSourceFile, sDestFile, bAutoResume) As Integer
Declare Function Ftp_Get Lib "\Windows\Utils.dll" (iHandle, sSourceFile, sDestFile, bAutoResume) As Integer
Declare Function Ftp_Append Lib "\Windows\Utils.dll" (iHandle, sBuffer, sDestFile) As Integer
Declare Function Ftp_DELE Lib "\Windows\Utils.dll" (iHandle, sParm) As Integer
Declare Function Ftp_NLST Lib "\Windows\Utils.dll" (iHandle, sParm) As String
Declare Function Ftp_RMD Lib "\Windows\Utils.dll" (iHandle, sParm) As Integer

FtpSession = 0
FtpLock = 0
nBytesSent = 0
nBytesRetrieved = 0

Public Function FtpGetBytesSent
   FtpGetBytesSent = nBytesSent
   Lock FtpLock, 0
   If FtpSession <> 0 Then
      FtpGetBytesSent = Ftp_GetBytesSent(FtpSession)
   End If
   UnLock FtpLock
End Function

Public Function FtpGetBytesRetrieved
   FtpGetBytesRetrieved = nBytesRetrieved
   Lock FtpLock, 0
   If FtpSession <> 0 Then
      FtpGetBytesRetrieved = Ftp_GetBytesRetrieved(FtpSession)
   End If
   UnLock FtpLock
End Function

Public Sub FtpCancel
   Lock FtpLock, 0
   If FtpSession <> 0 Then
      Call Ftp_Cancel(FtpSession)
   End If
   UnLock FtpLock
End Sub

Public Function FtpPut(URL, UserName, Password, FileType, SourceFile, DestFile, AutoResume)
   Lock FtpLock, 0
   FtpSession = 0 ' Keep track of the current session
   nBytesSent = 0
   UnLock FtpLock
   FtpPut = 1 ' Could not connect
   Handle = Ftp_Open(URL, 21, UserName, Password)
   If Handle Then
      Result = Ftp_Connect(Handle)
      If Result <> 0 Then
         FtpPut = Result
      Else
         Call Ftp_SetFileType(Handle, FileType)
         Lock FtpLock, 0
         FtpSession = Handle
         UnLock FtpLock
         Result = Ftp_Put(Handle, SourceFile, DestFile, AutoResume)
         FtpPut = Result
         Lock FtpLock, 0
         nBytesSent =  Ftp_GetBytesSent(FtpSession)
         FtpSession = 0
         UnLock FtpLock
      End If
      Result = Ftp_Close(Handle)
   End If
End Function

Public Function FtpGet(URL, UserName, Password, FileType, SourceFile, DestFile, AutoResume)
   Lock FtpLock, 0
   FtpSession = 0 ' Keep track of the current session
   nBytesRetrieved = 0
   UnLock FtpLock
   FtpGet = 1 ' Could not connect
   Handle = Ftp_Open(URL, 21, UserName, Password)
   If Handle Then
      Result = Ftp_Connect(Handle)
      If Result <> 0 Then
         FtpGet = Result
      Else
         Call Ftp_SetFileType(Handle, FileType)
         Lock FtpLock, 0
         FtpSession = Handle
         UnLock FtpLock
         Result = Ftp_Get(Handle, SourceFile, DestFile, AutoResume)
         FtpGet = Result
         Lock FtpLock, 0
         nBytesRetrieved =  Ftp_GetBytesRetrieved(FtpSession)
         FtpSession = 0
         UnLock FtpLock
      End If
      Result = Ftp_Close(Handle)
   End If
End Function

Public Function FtpAppend(URL, UserName, Password, Buffer, DestFile, FileToDeleteAfter)
   Lock FtpLock, 0
   FtpSession = 0 ' Keep track of the current session
   nBytesSent = 0
   UnLock FtpLock
   FtpAppend = 1 ' Could not connect
   Handle = Ftp_Open(URL, 21, UserName, Password)
   If Handle Then
      Result = Ftp_Connect(Handle)
      If Result <> 0 Then
         FtpAppend = Result
      Else
         Call Ftp_SetFileType(Handle, "A")
         Lock FtpLock, 0
         FtpSession = Handle
         UnLock FtpLock
         Result = Ftp_Append(Handle, Buffer, DestFile)
         FtpAppend = Result
         Lock FtpLock, 0
         nBytesSent =  Ftp_GetBytesSent(FtpSession)
         FtpSession = 0
         UnLock FtpLock
         If (Result = 0) And (Len(FileToDeleteAfter) > 0) Then
            Result = Ftp_DELE(Handle, FileToDeleteAfter)
            If Result <> 1 Then
               FtpAppend = 14 ' There is not an error code for could not delete file, so use "Server did not report success"
            End If
         End If
      End If
      Result = Ftp_Close(Handle)
   End If
End Function

Sub FtpUpgradeHelper(Result, Handle, FileList, SourcePath, DestPath, nFiles)
   Result = 0
   On Error Resume Next
   MkDir DestPath
   On Error Goto 0
   p0 = 1
   p = Instr(p0, FileList, Chr(13) & Chr(10))
   Do While p > 0
      FileName = Mid(FileList, p0, p-p0)
      StatusMsg "FtpOps: Retrieving upgrade file: " & FileName
      IsFolder = False
      DestFile = DestPath & "\" & Mid(FileName, Len(SourcePath)+2)
      Res = Ftp_Get(Handle, FileName, DestFile, True)
      If Res = 0 Then
         ' Remember the files we've transfered in Cleanup.bat so we can remove them later
         On Error Resume Next
         F = FreeFile
         Open "\Flash Disk\Cleanup.bat" For Append As F
         Print F, "@del """ & DestFile & """"
         Close F
         On Error Goto 0
      Else
         ' Check for file does not exist code as this could be a folder
         If Res = 3 Then
            NewList = Ftp_NLST(Handle, FileName & "/*")
            If NewList <> "" Then
               ' Find the name of the folder
               e0 = 0
               Do
                  e = e0
                  e0 = Instr(e+1, FileName, "/")
               Loop While e0 > 0
               ' Recursively call the FtpUpgradeHelper subroutine in order to handle a sub-directory
               DestFile = DestPath & "\" & Mid(FileName, e+1)
               Call FtpUpgradeHelper(Result, Handle, NewList, FileName, DestFile, nFiles)
               ' Remember the files we've transfered in Cleanup.bat so we can remove them later
               On Error Resume Next
               F = FreeFile
               Open "\Flash Disk\Cleanup.bat" For Append As F
               Print F, "@rd """ & DestFile & """"
               Close F
               On Error Goto 0
               If Result <> 0 Then
                  Exit Do
               End If
               IsFolder = True
            Else
               Result = 3
               Exit Do
            End If
         Else
            Result = Res
            Exit Do
         End If
      End If
      If IsFolder Then
         Res = Ftp_RMD(Handle, FileName)
      Else
         Res = Ftp_DELE(Handle, FileName)
      End If
      If Res <> 1 Then
         Result = 14 ' There is not an error code for could not delete file, so use "Server did not report success"
         Exit Do
      Else
         nFiles = nFiles + 1 ' We've successfully transferred a file
      End If
      p0 = p + 2
      p = Instr(p0, FileList, Chr(13) & Chr(10))
   End Loop
   Lock FtpLock, 0
   nBytesRetrieved =  Ftp_GetBytesRetrieved(FtpSession)
   UnLock FtpLock
End Sub

Public Function FtpUpgrade(URL, UserName, Password, SourcePath, DestPath, nFiles)
   nFiles = 0
   Lock FtpLock, 0
   FtpSession = 0 ' Keep track of the current session
   nBytesRetrieved = 0
   UnLock FtpLock
   FtpUpgrade = 1 ' Could not connect
   Handle = Ftp_Open(URL, 21, UserName, Password)
   If Handle Then
      Result = Ftp_Connect(Handle)
      If Result <> 0 Then
         FtpUpgrade = Result
      Else
         Call Ftp_SetFileType(Handle, "I")
         Lock FtpLock, 0
         FtpSession = Handle
         UnLock FtpLock
         FileList = Ftp_NLST(Handle, SourcePath & "/*")
         FtpUpgrade = 0
         If FileList <> "" Then
            Call FtpUpgradeHelper(Result, Handle, FileList, SourcePath, DestPath, nFiles)
            FtpUpgrade = Result
         End If
      End If
      Lock FtpLock, 0
      FtpSession = 0
      UnLock FtpLock
      Result = Ftp_Close(Handle)
   End If
End Function

