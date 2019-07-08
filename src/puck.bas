const ANALOG_TERMINAL_STRIP = 1
const DIGITAL_TERMINAL_STRIP = 1
const MODEM_CHANNEL = 4
const PUCK_CHANNEL = 5
const CAMERA_CHANEL = 6
const DIGITAL_ON = -1
const DIGITAL_OFF = 0

const PUCK_DATA_PORT = 2368
const UDP = 1
const PUCK_STARTUP_WAIT_TIME = 10.000
const LAN_STARTUP_WAIT_TIME = 5.000
const MEASURE_TIME = 20.000
const PUCK_TMP = "puck.tmp"
const PACKET_LENGTH = 1206
const LOCK_TIMEOUT = 60
const DATA_BLOCK_LENGTH = 100
const NUM_DATA_BLOCKS = 12
const NUM_CHANNELS = 16
const ELEVATION_ANGLES = array(-15, 1, -13, 3, -11, 5, -9, 7, -7, 9, -5, 11, -3, 13, -1, 15) ' from puck documentation
const BE_MKDIR_FAILED = 3 ' from sutron basic documentation
const PI = 3.141592654
const PUCK_BINARY = 0
const PUCK_ARCHIVE_FOLDER = "\SD Card\RIPS"
const SERVER_PUCK_IMAGE_PATH = "/StarDot/INGLEFIELD_RIPS/RIPS/"
const MIN_RANGE = 5

public declare sub transferimage(handle, camera, local, remote)
public declare sub puck_server(socket, udp_buffer, client_ip, server_port, client_port)
declare sub puck_take_measurement
declare sub puck_convert_measurement
declare function puck_interpolate_azimuth(azimuths, data_block_number)
declare function puck_extrapolate_last_azimuth(azimuths)
declare function puck_elevation_angle(channel)
declare sub puck_write_point(outfile, azimuth, elevation, range, relfectivity, channel)
declare function puck_converted_filename
declare sub puck_archive_converted_data
declare function puck_suffix
declare sub puck_ftp_put

static puck_tmp_semaphore
static outfile = 0

function u8(data)
  if len(data) <> 1 then
    errormsg "Cannot create a u8 from a multi-byte string"
    exit function
  end if
  u8 = bitconvert(data + chr(0) + chr(0) + chr(0), 1)
end function

function debug(data)
  s = ""
  for i = 1 to len(data)
    s = s + hex(u8(mid(data, i, 1))) + " "
  next
  debug = s
end function

function deg2rad(degrees)
  deg2rad = degrees * PI / 180.0
end function

public sub sched_puck_measure
  call puck_take_measurement
  call puck_convert_measurement
  call puck_archive_converted_data
  call puck_ftp_put
end sub

sub puck_take_measurement
  lock puck_tmp_semaphore, LOCK_TIMEOUT
  on error resume next
  kill PUCK_TMP
  on error goto 0
  outfile = freefile
  open PUCK_TMP for output as outfile
  unlock puck_tmp_semaphore

  statusmsg "[Puck] Powering on the puck and ethernet switch"
  digital DIGITAL_TERMINAL_STRIP, PUCK_CHANNEL, DIGITAL_ON
  sleep PUCK_STARTUP_WAIT_TIME
  statusmsg "[Puck] Turning on the LAN"
  turn "LAN", "ON"
  sleep LAN_STARTUP_WAIT_TIME
  statusmsg "[Puck] Measuring..."
  sleep MEASURE_TIME
  statusmsg "[Puck] Turning off the LAN" 
  turn "LAN", "OFF"
  statusmsg "[Puck] Powering off the puck and ethernet switch"
  digital DIGITAL_TERMINAL_STRIP, PUCK_CHANNEL, DIGITAL_OFF

  lock puck_tmp_semaphore, LOCK_TIMEOUT
  close outfile
  unlock puck_tmp_semaphore
end sub

sub puck_convert_measurement
  on error goto cleanup
  lock puck_tmp_semaphore, LOCK_TIMEOUT

  bytes = filelen(PUCK_TMP)
  if bytes mod PACKET_LENGTH <> 0 then
    errormsg "[Puck] Invalid length of temporary packet file"
    exit sub
  else
    num_packets = int(bytes / PACKET_LENGTH)
    statusmsg "[Puck] Read " + num_packets + " packets"
  end if

  infile = freefile
  open PUCK_TMP for input as infile
  outfile = freefile
  filename = puck_converted_filename
  open filename for output as outfile
  for packet_number = 1 to num_packets
    packet = ""
    bytes_read = readb(infile, packet, PACKET_LENGTH)
    if bytes_read <> PACKET_LENGTH then
      errormsg "[Puck] Expected to read " + PACKET_LENGTH + " bytes, instead read " + bytes_read
      exit sub
    end if

    azimuths = array(0)
    for data_block_number = 0 to NUM_DATA_BLOCKS - 1
      data_block = mid(packet, DATA_BLOCK_LENGTH * data_block_number + 1, DATA_BLOCK_LENGTH)
      flag = left(data_block, 2)
      if flag <> chr(&hff) + chr(&hee) then
        errormsg "[PUCK] Invalid flag: " + debug(flag)
        exit sub
      end if

      azimuth = bitconvert(mid(data_block, 3, 2) + chr(0) + chr(0), 1) / 100
      azimuths(data_block_number * 2) = azimuth
    next
    for data_block_number = 0 to NUM_DATA_BLOCKS - 2
      azimuths(data_block_number * 2 + 1) = puck_interpolate_azimuth(azimuths, data_block_number)
    next
    azimuths(NUM_DATA_BLOCKS * 2 - 1) = puck_extrapolate_last_azimuth(azimuths)

    for data_block_number = 0 to NUM_DATA_BLOCKS - 1
      offset = data_block_number * DATA_BLOCK_LENGTH + 5
      for channel = 0 to NUM_CHANNELS - 1
        azimuth = azimuths(data_block_number * 2)
        elevation = puck_elevation_angle(channel)
        range = bitconvert(mid(packet, offset + channel * 3, 2) + chr(0) + chr(0), 1) * 0.002
        reflectivity = bitconvert(mid(packet, offset + channel * 3 + 2, 1) + chr(0) + chr(0) + chr(0), 1)
        call puck_write_point(outfile, azimuth, elevation, range, reflectivity, channel)

        azimuth = azimuths(data_block_number * 2 + 1)
        elevation = puck_elevation_angle(channel)
        range = bitconvert(mid(packet, offset + 3 * NUM_CHANNELS + channel * 3, 2) + chr(0) + chr(0), 1) * 0.002
        reflectivity = bitconvert(mid(packet, offset + 3 * NUM_CHANNELS + channel * 3 + 2, 1) + chr(0) + chr(0) + chr(0), 1)
        call puck_write_point(outfile, azimuth, elevation, range, reflectivity, channel)
      next
    next
  next
  statusmsg "[Puck] Packet conversion complete"
  close outfile
  close infile
  goto cleanup

cleanup:
  if err <> 0 then
    errormsg "[Puck] Cleaning up after error: " + error
  end if
  unlock puck_tmp_semaphore
end sub

sub puck_archive_converted_data
  on error resume next
  mkdir PUCK_ARCHIVE_FOLDER
  on error goto 0
  source = puck_converted_filename
  datetime = now
  destination = PUCK_ARCHIVE_FOLDER + "\" + format("%04d%02d%02d_%02d%02d%02d",
    year(datetime), month(datetime), day(datetime), hour(datetime), minute(datetime), second(datetime)) +
    "." + puck_suffix
  statusmsg "[Puck] Archiving to " + destination
  filecopy source, destination
end sub

sub puck_ftp_put
  on error goto 0
  handle = 0
  source = "\Flash Disk\" + puck_converted_filename
  call transferimage(handle, "puck", source, SERVER_PUCK_IMAGE_PATH)
end sub

function puck_interpolate_azimuth(azimuths, data_block_number)
  before = azimuths(data_block_number * 2)
  after = azimuths(data_block_number * 2 + 2)
  if after < before then
    after = after + 360
  end if
  azimuth = before + (after - before) / 2
  if azimuth > 360 then
    azimuth = azimuth - 360
  end if
  puck_interpolate_azimuth = azimuth
end function

function puck_extrapolate_last_azimuth(azimuths)
  two_before = azimuths(NUM_DATA_BLOCKS * 2 - 3)
  one_before = azimuths(NUM_DATA_BLOCKS * 2 - 2)
  if one_before < two_before then
    one_before = one_before + 360
  end if
  azimuth = one_before + (one_before - two_before)
  if azimuth > 360 then
    azimuth = azimuth - 360
  end if
  puck_extrapolate_last_azimuth = azimuth
end function

function puck_elevation_angle(channel)
  puck_elevation_angle = ELEVATION_ANGLES(channel)
end function

sub puck_write_point(outfile, azimuth, elevation, range, reflectivity, channel)
  if range = 0 or range < MIN_RANGE then
    exit sub
  end if
  azimuth = deg2rad(azimuth)
  elevation = deg2rad(elevation)
  x = range * cos(elevation) * sin(azimuth)
  y = range * cos(elevation) * cos(azimuth)
  z = range * sin(elevation)
  if y < 0 then
    exit sub
  end if
  if PUCK_BINARY then
    _ = writeb(outfile, bin(z, -4) + bin(y, -4) + bin(-x, -4) + bin(reflectivity, 1), 13)
  else
    print outfile, format("%.3f,%.3f,%.3f,%d,%d,%.3f,%.3f,%.3f", z, y, -x, reflectivity) ' this corresponds to a 90 degree cw rotation around the y axis
  end if
end sub

function puck_converted_filename
  puck_converted_filename = "puck." + puck_suffix
end function

function puck_suffix
  if PUCK_BINARY then
    puck_suffix = "bin"
  else
    puck_suffix = "csv"
  end if
end function

public sub puck_server(_socket, udp_buffer, _client_ip, _server_port, _client_port)
  on error resume next
  lock puck_tmp_semaphore, LOCK_TIMEOUT
  bytes_written = writeb(outfile, udp_buffer, len(udp_buffer))
  unlock puck_tmp_semaphore
end sub

declare tag Puck(3)
public function get_puck(value)
   if value = 1 or value = 3 then
      if digital(DIGITAL_TERMINAL_STRIP, PUCK_CHANNEL) then
         get_puck = 1
      else
         get_puck = 0
      end if
   else
      get_puck = 0
   end if
end function

public sub set_puck(value, data)
   If value = 1 Or value = 3 Then
      digital DIGITAL_TERMINAL_STRIP, PUCK_CHANNEL, data
   end if
end sub

webserver puck_server, PUCK_DATA_PORT, UDP