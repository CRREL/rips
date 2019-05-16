' Read, store, and use data from the VLP-16 puck lidar.

const PUCK_DATA_PORT = 2368
const UDP = 1

public sub puck_server(socket, udp_buffer, client_ip, server_port, client_port)
  statusmsg "here"
end sub

webserver puck_server, PUCK_DATA_PORT, UDP