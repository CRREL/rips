# rips
RIver Profiler System, to be installed July 2019 in Inglefield Land, Greenland (78° north)

## Network

The network is operating on the `192.168.0.XXX` space, with network mask of `255.255.255.0`.
The network is run through the powered ethernet switch, which is on digital IO 5.

## Data logger

The Sutron 9210 XLite is set up with station name `rips`.
The logger IP address is `192.168.0.80`.

### Analog module

The analog module is located in terminal strip `A` and has two functions:

1. Take power through terminals 21 and 22.
2. Take in light sensor input through terminals 10, 11, and 12.

### Digital module

The digital module is located in terminal strip `B` and has three functions:

1. Control the Iridium modem through terminal 6, channel 4 I/O.
2. Control the ethernet switch and the Velodyne puck through terminal 8, channel 5 I/O.
3. Control the camera through terminal 9, channel 6 I/O.

## Puck

The lidar sensor is a Velodyne VLP-16 with the following attributes:

- Model: VLP-16M12-0.3M-A
- Serial number: 11001191157192
- MAC: 60-76-88-38-18-c0
- IP address: 192.168.1.201