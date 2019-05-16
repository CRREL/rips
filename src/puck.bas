const PUCK_DATA_PORT = 2368
const UDP = 1
const PUCK_STARTUP_WAIT_TIME = 10.000
const LAN_STARTUP_WAIT_TIME = 5.000
const MEASURE_TIME = 20.000

public declare sub puck_handle_udp_packet(socker, udp_buffer, client_ip, server_port, client_port)

static packets_read = 0
static outfile = 0

public sub sched_puck_measure
  statusmsg "Powering on the puck and ethernet switch"
  call set_puck_power(1, 1)
  sleep PUCK_STARTUP_WAIT_TIME
  statusmsg "Turning on the LAN"
  turn "LAN", "ON"
  sleep LAN_STARTUP_WAIT_TIME
  packets_read = 0
  outfile = freefile
  open "puck.pcap" for output as outfile
  sleep MEASURE_TIME
  statusmsg "Turning off the LAN"
  turn "LAN", "OFF"
  statusmsg "Powering off the puck and ethernet switch"
  call set_puck_power(1, 0)
  statusmsg "Read " + packets_read + " packets"
  close outfile
end sub

public sub puck_handle_udp_packet(socket, udp_buffer, client_ip, server_port, client_port)
  packets_read = packets_read + 1
  bytes_written = writeb(outfile, udp_buffer, len(udp_buffer))
end sub

webserver puck_handle_udp_packet, PUCK_DATA_PORT, UDP