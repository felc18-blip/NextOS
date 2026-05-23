#!/bin/bash
. /etc/profile
set_kill set "-9 biginstinct"
if echo ${HW_DEVICE} | grep -q "Amlogic-nxtos"; then
  export SDL_VIDEODRIVER=wayland
  export SDL_AUDIODRIVER=pulseaudio
  cd /usr/bin/biginstinct
  # gptokeyb mode 1 Select+Start kill (igual bigpemu)
  if [ -x /usr/bin/gptokeyb ]; then
    pkill -9 -f "gptokeyb.*biginstinct" 2>/dev/null
    cat > /tmp/biginstinct-kill.gptk <<GPTK
up    = up
down  = down
left  = left
right = right
GPTK
    env -u EMUELEC /usr/bin/gptokeyb 1 biginstinct -c /tmp/biginstinct-kill.gptk &
    trap "pkill -9 -f \"gptokeyb.*biginstinct\" 2>/dev/null; true" EXIT INT TERM HUP
    sleep 0.3
  fi
  LD_PRELOAD=/usr/lib/gl4es/libGL.so.1 ./biginstinct "$1"
else
  cd /usr/bin/biginstinct
  ./biginstinct "$1"
fi
