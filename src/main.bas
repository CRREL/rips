' The main control file for the RIPS system.

const ANALOG_TERMINAL_STRIP = 1
const DIGITAL_TERMINAL_STRIP = 1

const MODEM_CHANNEL = 4
const PUCK_CHANNEL = 5
const CAMERA_CHANEL = 6

const DIGITAL_ON = -1
const DIGITAL_OFF = 0

declare tag puck_power(3)
declare sub eval_puck_power
last_puck_power = 0

public function get_puck_power(value)
  if value = 1 then
    get_puck_power = last_puck_power
  elseif value = 2 then
    get_puck_power = 0
  elseif value = 3 then
    call eval_puck_power
    get_puck_power = last_puck_power
  end if
end function

public sub set_puck_power(value, data)
  if value = 1 then
    if data = 0 then
      last_puck_power = 0
      digital DIGITAL_TERMINAL_STRIP, PUCK_CHANNEL, DIGITAL_OFF
    elseif data = 1 then
      last_puck_power = 1
      digital DIGITAL_TERMINAL_STRIP, PUCK_CHANNEL, DIGITAL_ON
    else
      errormsg "Invalid puck power value: " + data
    end if
  end if
end sub

public sub eval_puck_power
  last_puck_power = digital(DIGITAL_TERMINAL_STRIP, PUCK_CHANNEL)
  if last_puck_power = DIGITAL_ON then
    last_puck_power = 1
  end if
end sub
