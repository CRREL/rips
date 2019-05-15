' The main control file for the RIPS system.

const ANALOG_TERMINAL_STRIP = 1
const DIGITAL_TERMINAL_STRIP = 1

const MODEM_CHANNEL = 4
const PUCK_CHANNEL = 5
const CAMERA_CHANEL = 6

const DIGITAL_ON = -1
const DIGITAL_OFF = 0

public sub start_recording
  digital DIGITAL_TERMINAL_STRIP, PUCK_CHANNEL, DIGITAL_ON
end sub

public sub stop_recording
  digital DIGITAL_TERMINAL_STRIP, PUCK_CHANNEL, DIGITAL_OFF
end sub
