extends Node

var _output_device = null
var _device_mode = ""

func _setup_output_handler(mode, device):
  _destroy_output()
  print("[gpu] setting up output: ", mode)
  _output_device = device
  _device_mode = mode
  if _output_device.draw.is_connected(_tty_draw):
    _output_device.draw.disconnect(_tty_draw)
  match mode:
    "tty":
      _setup_output_tty()
    "cgl":
      _setup_output_cgl()
  print("[gpu] device ", device, " ready in ", mode, " mode")

func _setup_output_tty():
  _output_device.draw.connect(_tty_draw)
  _tty_clear_buffer()

func _setup_output_cgl():
  var cgl_base_node = Control.new()
  cgl_base_node.size.x = SCREEN_WIDTH
  cgl_base_node.size.y = SCREEN_HEIGHT
  cgl_base_node.name = "cgl_renderer"
  CGL_NODE = cgl_base_node
  add_child(cgl_base_node)
  var cgl_clear_rect = ColorRect.new()
  cgl_clear_rect.set_color(Color(0.25, 0.1, 0.2, 1.0))
  cgl_clear_rect.set_anchors_preset(15)
  CGL_NODE.add_child(cgl_clear_rect)

func _destroy_output():
  if _device_mode == "cgl":
    CGL_NODE.queue_free()
  _output_device = null
  _device_mode = null

func _change_clear_color(color):
  #_output_device.
  pass

# GPU => candygl
var SCREEN_WIDTH = 1280
var SCREEN_HEIGHT = 720

var CGL_NODE = null

# GPU => TTY mode

const TTY_COLS = 160
const TTY_ROWS = 45
const TTY_FONT_SIZE = 16

var _tty_buffer = []
var _tty_font = preload("res://Assets/Fonts/Px437_IBM_VGA_8x16.ttf")

func _tty_write_char(c):
  if _tty_buffer.is_empty():
    _tty_buffer.append("")
  var current_line = _tty_buffer[_tty_buffer.size() - 1]
  if current_line.length() >= TTY_COLS:
    _tty_new_line()
    current_line = ""
  _tty_buffer[_tty_buffer.size() - 1] = current_line + str(c)

func _tty_new_line():
  if _tty_buffer.size() >= TTY_ROWS:
      _tty_buffer.pop_front()
  _tty_buffer.append("")

func _tty_erase_char():
  if _tty_buffer.is_empty():
    return
  var line_idx = _tty_buffer.size() - 1
  var current_line = _tty_buffer[line_idx]
  if current_line.length() > 0:
    _tty_buffer[line_idx] = current_line.substr(0, current_line.length() - 1)

func _tty_write_line(s):
  s = s.substr(0, TTY_COLS)
  _tty_new_line()
  _tty_buffer[_tty_buffer.size() - 1] = s

func _tty_get_line():
  return _tty_buffer[_tty_buffer.size() - 1]

func _tty_clear_buffer():
  _tty_buffer.clear()
  for i in TTY_ROWS:
    _tty_buffer.append("")

func _tty_draw():
  var y = 0
  for line in _tty_buffer:
    _output_device.draw_string(
      _tty_font,
      Vector2(0, y * TTY_FONT_SIZE), # position
      line, # line buffer
      HORIZONTAL_ALIGNMENT_LEFT, 
      1280, # max width
      TTY_FONT_SIZE, # font size
    )
    y += 1

# ===============================

func _process(_delta) -> void:
  _output_device.queue_redraw()
