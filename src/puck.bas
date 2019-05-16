const PUCK_DATA_PORT = 2368
const UDP = 1
const LAN_STARTUP_WAIT_TIME = 5.000
const MEASURE_TIME = 10.000

public declare sub puck_handle_udp_packet(socker, udp_buffer, client_ip, server_port, client_port)

record_data = 0

public sub puck_measure
  turn "LAN", "ON"
  sleep LAN_STARTUP_WAIT_TIME
  webserver puck_handle_udp_packet, PUCK_DATA_PORT, UDP
  sleep MEASURE_TIME
  webserver puck_handle_udp_packet
  turn "LAN", "OFF"
end sub

public sub puck_handle_udp_packet(socket, udp_buffer, client_ip, server_port, client_port)
  statusmsg "UDP buffer length: " + len(udp_buffer)
end sub

public sub start_recording
  call puck_measure
end sub