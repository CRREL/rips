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

public declare sub puck_server(socket, udp_buffer, client_ip, server_port, client_port)
declare sub puck_take_measurement
declare sub puck_convert_measurement

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
  for packet_number = 1 to num_packets
    packet = ""
    bytes_read = readb(infile, packet, PACKET_LENGTH)
    if bytes_read <> PACKET_LENGTH then
      errormsg "[Puck] Expected to read " + PACKET_LENGTH + " bytes, instead read " + bytes_read
      exit sub
    end if

    for data_block_number = 1 to NUM_DATA_BLOCKS
      data_block = mid(packet, DATA_BLOCK_LENGTH * (data_block_number - 1) + 1, DATA_BLOCK_LENGTH)
      flag = left(data_block, 2)
      if flag <> chr(&hff) + chr(&hee) then
        errormsg "[PUCK] Invalid flag: " + debug(flag)
        exit sub
      end if

      azimuth = bitconvert(mid(data_block, 3, 2) + chr(0) + chr(0), 1) / 100
    next
  next
  close infile

  unlock puck_tmp_semaphore
end sub

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