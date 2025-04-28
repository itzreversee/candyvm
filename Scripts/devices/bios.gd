extends Node

@export var _devices_path : NodePath
@export var _vm_path: NodePath
@export var _candy_kernel_path: NodePath

signal setup_output(mode, display)
signal destroy_output

signal input_event(e)

var _device_gpu = null
var _device_keyboard = null

func _run():
  setup_output.emit("tty", get_node(str(_vm_path) + "/Display"))
  _device_gpu = get_node(str(_devices_path) + "/gpu")
  _device_keyboard = get_node(str(_devices_path) + "/keyboard")

  _device_gpu._tty_write_line("CandyVM BIOS v1.0")
  _device_gpu._tty_new_line()
  
  _device_keyboard.keyboard_key.disconnect(_on_keyboard_key)
  get_node(_candy_kernel_path)._run(_device_gpu)

var command_buffer = ""
func parse_command_buffer():
  lock_input = true
  _device_gpu._tty_write_line("=> " + command_buffer)
  _device_gpu._tty_new_line()
  if command_buffer == "candy":
    get_node(_candy_kernel_path)._run()
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
        command_buffer.erase(len(command_buffer) - 1, 1)
      "nl":
        if not command_mode:
          _device_gpu._tty_new_line()
        else:
          parse_command_buffer()
    queue_code = ""
    queue_action = ""
