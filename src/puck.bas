const PUCK_DATA_PORT = 2368
const UDP = 1
const PUCK_STARTUP_WAIT_TIME = 10.000
const LAN_STARTUP_WAIT_TIME = 5.000
const MEASURE_TIME = 20.000
const PACKET_SIZE = 1206

public declare sub puck_server(socker, udp_buffer, client_ip, server_port, client_port)
declare sub puck_handle_packets(packets)
declare sub puck_handle_packet(packet)

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

  infile = freefile
  open "puck.pcap" for input as infile
  packets = ""
  bytes_read = readb(infile, packets, filelen(infile))
  close infile

  call puck_handle_packets(packets)
end sub

public sub puck_handle_udp_packet(_socket, udp_buffer, _client_ip, _server_port, _client_port)
  packets_read = packets_read + 1
  bytes_written = writeb(outfile, udp_buffer, len(udp_buffer))
end sub

sub puck_handle_packets(packets)
  for start = 0 to len(packets) step PACKET_SIZE
    packet = mid(packets, start, PACKET_SIZE)
    call puck_handle_packet(packet)
  next start
end sub

sub puck_handle_packet(packet)
  for index = 0 to 11
    azimuths(index * 2) = puck_data_block_azimuth(packet, index)
  next index
  for index = 1 to 23 step 2
    azimuths(index) = puck_interpolate_azimuth(azimuths, index)
  next index
  for index = 0 to 11
    call puck_handle_data_block(packet, index, azimuths(index * 2), azimuths(index * 2 + 1))
  next index
end sub

webserver puck_server, PUCK_DATA_PORT, UDP