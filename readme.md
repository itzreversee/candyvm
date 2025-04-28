# CandyVM
Small project to simulate a vm/emulator device in godot.

### How does it work.
Scene tree holds serveral objects.
- / - script emits a signal to the bios device
- /VM - frontend to the vm
- /VM/Display - here the display is drawn
- /VM/Input - script here emits InputEventKey for keyboard interaction
- /Devices - backend
- /Devices/gpu - renders things on screen, has two modes, tty - which simulates a terminal or cgl (candygl) which uses godot's nodes system to display things (so as intended for the game engine it is)
- /Devices/bios - prepares some things, hands over to CandyKernel, can be used standalone if CandyKernel will not execute
- /Devices/keyboard - keyboard handler
- /CandyKernel - the CandyKernel, which initializes it's own vtty on top of gpu's tty mode, assigns needed devices for itself, has a primitive terminal built-in, which can be used to switch gpu's modes.
