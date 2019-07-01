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
const ELEVATION_ANGLES = array(-15, 1, -13, -3, -11, 5, -9, 7, -7, 9, -5, 11, -3, 13, -1, 15) ' from puck documentation
const BE_MKDIR_FAILED = 3 ' from sutron basic documentation

public declare sub puck_server(socket, udp_buffer, client_ip, server_port, client_port)
declare sub puck_take_measurement
declare sub puck_convert_measurement
declare function puck_interpolate_azimuth(azimuths, data_block_number)
declare function puck_extrapolate_last_azimuth(azimuths)
declare function puck_elevation_angle(channel)

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

public sub sched_puck_measure
  call puck_take_measurement
  call puck_convert_measurement
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
  open "puck.csv" for output as outfile
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
        elevation = puck_elevation_angle(channel)
        range = bitconvert(mid(packet, offset + channel * 3, 2) + chr(0) + chr(0), 1) * 0.002
        reflectivity = bitconvert(mid(packet, offset + channel * 3 + 2, 1) + chr(0) + chr(0) + chr(0), 1)
        if range > 0 then
          print outfile, format("%.3f,%d,%.3f,%d", azimuths(data_block_number * 2), elevation, range, reflectivity)
        end if
        range = bitconvert(mid(packet, offset + 3 * NUM_CHANNELS + channel * 3, 2) + chr(0) + chr(0), 1) * 0.002
        reflectivity = bitconvert(mid(packet, offset + 3 * NUM_CHANNELS + channel * 3 + 2, 1) + chr(0) + chr(0) + chr(0), 1)
        if range > 0 then
          print outfile, format("%.3f,%d,%.3f,%d", azimuths(data_block_number * 2 + 1), elevation, range, reflectivity)
        end if
      next
    next
  next
  close outfile
  close infile
  goto cleanup

cleanup:
  if err <> 0 then
    errormsg "[Puck] Cleaning up after error: " + error
  end if
  unlock puck_tmp_semaphore
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

public sub puck_server(_socket, udp_buffer, _client_ip, _server_port, _client_port)
  on error resume next
  lock puck_tmp_semaphore, LOCK_TIMEOUT
  bytes_written = writeb(outfile, udp_buffer, len(udp_buffer))
  if err <> 0 then
    statusmsg "[Puck] Puck temporary pcap file not open, dropping packet"
  end if
  unlock puck_tmp_semaphore
end sub

webserver puck_server, PUCK_DATA_PORT, UDP

public sub start_recording
  call puck_convert_measurement
end sub