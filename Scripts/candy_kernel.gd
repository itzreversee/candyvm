extends Node

signal setup_output(mode, device)

var _devices = {}

func _get_devices():
  _device_gpu._tty_write_line("[candy] setting up devices")
  _device_gpu._tty_write_line("machine_display => ../VM/Display")
  _devices.set("machine_display", get_node("../VM/Display"))

  _device_gpu._tty_write_line("machine_clear => ../VM/Background")
  _devices.set("machine_clear", get_node("../VM/Background"))
  for d in get_node("../Devices").get_children():
    _devices.set("device_" + d.name, d)
    _device_gpu._tty_write_line("device_" + d.name + " => " + str(d))

var _device_gpu = null
var _device_keyboard = null

func _run(framebuffer):
  _device_gpu = framebuffer
  _get_devices()
  self.setup_output.connect(_devices["device_gpu"]._setup_output_handler)
  _device_gpu._tty_write_line("<signal> setup_output => device_gpu")

  setup_output.emit("tty", _devices["machine_display"])
  _device_gpu = _devices["device_gpu"]
  _device_keyboard = _devices["device_keyboard"]

  _device_keyboard.keyboard_key.connect(_on_keyboard_key)
  _device_gpu._tty_write_line("<signal> device_keyboard => _on_keyoard_key")

  _device_gpu._tty_write_line("CandyKernel v1.0")
  _device_gpu._tty_new_line()

  kernel_init()

func kernel_init():
  vtty_create("1")
  vtty_switch("1")

# vtty
const TTY_COLS = 160
const TTY_ROWS = 45
const TTY_FONT_SIZE = 16
var vtty_greeter = "CandyKernel v1.0 | on vtty %%"
var vtty = {}
var vtty_selected = ""
func vtty_write_char(c):
  _device_gpu._tty_write_char(c)

func vtty_write_line(s):
  _device_gpu._tty_write_line(s)

func vtty_erase_char():
  _device_gpu._tty_erase_char()

func vtty_new_line():
  _device_gpu._tty_new_line()

func vtty_enter_line(s):
  vtty_write_line(s)
  vtty_new_line()

func vtty_clear():
  _device_gpu._tty_clear_buffer()

func vtty_reset():
  vtty = {}
  vtty_selected = ""

func vtty_switch(id):
  if id in vtty:
    vtty.set(vtty_selected, _device_gpu._tty_buffer)
    _device_gpu._tty_buffer = vtty[id]
    vtty_selected = id

func vtty_destroy(id):
  vtty.erase(id)

func vtty_create(id):
  var vtty_temp = []
  for i in TTY_ROWS - 2:
    vtty_temp.append("")
  vtty_temp.append(vtty_greeter.replace("%%", id))
  vtty_temp.append("")
  vtty.set(id, vtty_temp)


func vtty_get_line():
  return _device_gpu._tty_get_line()

# -- bios remnants

func kernel_command(cmd):
  match cmd[0]:
    "vtty":
      if not cmd.size() > 1:
        return
      match cmd[1]:
        "switch":
          if not cmd.size() > 2:
            return
          if not cmd[2] in vtty:
            vtty_create(cmd[2])
          vtty_switch(cmd[2])
        "reset":
          vtty_reset()
          vtty_create("1")
          vtty_switch("1")

    "gpu":
      if not cmd.size() > 1:
        return
      match cmd[1]:
        "setup":
          if not cmd.size() > 1:
            return
          match cmd[2]:
            "tty":
              setup_output.emit("tty", _devices["machine_display"])
            "cgl":
              print("cgl")
              setup_output.emit("cgl", _devices["machine_display"])
        "modes":
          vtty_enter_line("available gpu modes: tty, cgl")
    "help":
      vtty_write_line("- vtty <reset|swtich> [id]")
      vtty_enter_line("- gpu <modes|setup> [mode]")

var command_buffer = ""
func parse_command_buffer():
  lock_input = true
  vtty_enter_line("=> " + command_buffer)
  var cmd = command_buffer.split(' ')
  kernel_command(cmd)
  command_buffer = ""
  lock_input = false

var lock_input = false
var command_mode = true
var _keyboard_shift = false
func _on_keyboard_key(keycode, pressed, echo):
  if keycode == KEY_SHIFT and not pressed:
    _keyboard_shift = false
  if lock_input:
    return
  if pressed and not echo:
    var queue_action = "wc"
    var queue_code = ''
    if keycode >= KEY_A and keycode <= KEY_Z:
      if _keyboard_shift:
        queue_code = char(keycode)
      else:
        queue_code = char(keycode + 32) # make lowercase
    elif keycode >= KEY_0 and keycode <= KEY_9:
      if _keyboard_shift:
        match keycode:
          KEY_1:
            queue_code = "!"
          KEY_2:
            queue_code = "@"
          KEY_3:
            queue_code = "#"
          KEY_4:
            queue_code = "$"
          KEY_5:
            queue_code = "%"
          KEY_6:
            queue_code = "^"
          KEY_7:
            queue_code = "&"
          KEY_8:
            queue_code = "*"
          KEY_9:
            queue_code = "("
          KEY_0:
            queue_code = ")"
      else:
        queue_code = char(keycode)
    else:
      match keycode:
        KEY_ENTER, KEY_KP_ENTER:
          queue_action = "nl"
        KEY_BACKSPACE:
          queue_action = "dc"
        KEY_SHIFT:
          _keyboard_shift = not _keyboard_shift
        KEY_SPACE:
          queue_code = " "
        KEY_SEMICOLON:
          queue_code = ";"
          if _keyboard_shift:
            queue_code = ":"
        KEY_EQUAL:
          queue_code = "="
          if _keyboard_shift:
            queue_code = "+"
        KEY_BACKSLASH:
          queue_code = "\\"
          if _keyboard_shift:
            queue_code = "|"
        KEY_MINUS:
          queue_code = "-"
          if _keyboard_shift:
            queue_code = "_"
        KEY_SLASH:
          queue_code = "/"
          if _keyboard_shift:
            queue_code = "?"
        KEY_COMMA:
          queue_code = ","
          if _keyboard_shift:
            queue_code = "<"
        KEY_PERIOD:
          queue_code = "."
          if _keyboard_shift:
            queue_code = ">"
        KEY_APOSTROPHE:
          queue_code = "'"
          if _keyboard_shift:
            queue_code = "\""
        KEY_BRACKETLEFT:
          queue_code = "["
          if _keyboard_shift:
            queue_code = "{"
        KEY_BRACKETRIGHT:
          queue_code = "]"
          if _keyboard_shift:
            queue_code = "}"
        _:
          pass

    match queue_action:
      "wc":
        _device_gpu._tty_write_char(queue_code)
        command_buffer += queue_code
      "dc":
        _device_gpu._tty_erase_char()
        command_buffer = command_buffer.left(-1)
      "nl":
        if not command_mode:
          _device_gpu._tty_new_line()
        else:
          parse_command_buffer()
    queue_code = ""
    queue_action = ""
