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

public declare sub puck_server(socket, udp_buffer, client_ip, server_port, client_port)

static puck_tmp_semaphore
static outfile = 0

public sub sched_puck_measure
  packets_read = 0
  on error resume next
  kill PUCK_TMP
  on error goto 0
  lock puck_tmp_semaphore, LOCK_TIMEOUT
  outfile = freefile
  open PUCK_TMP for output as outfile
  unlock puck_tmp_semaphore

  statusmsg "[Puck] Powering on the puck and ethernet switch"
  digital DIGITAL_TERMINAL_STRIP, PUCK_CHANNEL, DIGITAL_ON
  sleep PUCK_STARTUP_WAIT_TIME
  
  statusmsg "[Puck] Turning on the LAN"
  turn "LAN", "ON"
  sleep LAN_STARTUP_WAIT_TIME
  sleep MEASURE_TIME
  statusmsg "[Puck] Turning off the LAN" 
  turn "LAN", "OFF"
  statusmsg "[Puck] Powering off the puck and ethernet switch"
  digital DIGITAL_TERMINAL_STRIP, PUCK_CHANNEL, DIGITAL_OFF

  lock puck_tmp_semaphore, LOCK_TIMEOUT
  close outfile

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
  for packet_number = 1 to 2
    statusmsg packet_number
  next
  close infile
  unlock puck_tmp_semaphore
end sub

public sub puck_server(_socket, udp_buffer, _client_ip, _server_port, _client_port)
  on error resume next
  lock puck_tmp_semaphore, LOCK_TIMEOUT
  bytes_written = writeb(outfile, udp_buffer, len(udp_buffer))
  if err <> 0 then
    errormsg "[Puck] Puck temporary pcap file not open, dropping packet"
  end if
  unlock puck_tmp_semaphore
end sub

webserver puck_server, PUCK_DATA_PORT, UDP