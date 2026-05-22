# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Frank Hartung (supervisedthinking@gmail.com)
# Modifications by Shanti Gilbert (shantic@gmail.com) to work on EmuELEC Copyright (C) 2019-present
#
# V14 Amlogic-no per-device override do rr_audio.sh:
#  - Fix awk syntax bug: 2 chamadas com ${1} e ${4} dentro de awk script.
#    Awk não suporta a sintaxe shell `${N}` pra campos — só `$N`. Resultado
#    no journal/stderr a cada chamada do rr_audio.sh:
#       awk: cmd. line:1: Unexpected token
#       awk: cmd. line:1: Unexpected token
#    Linha 69:  awk '{print ${1};}'           → awk '{print $1}'
#    Linha 79:  awk '${0}~/%/{print ${4}}'    → awk '$0~/%/{print $4}'
#  - Aplicado SÓ em Amlogic-no per-device. Amlogic-old/ng/nxtos/ne continuam
#    usando o global (warnings cosméticos lá ficam pendentes pra fix V15 do
#    package master quando Felipe autorizar).

. /etc/profile

AUDIO_LOG="/emuelec/logs/rr_audio.log"

echo "Set Audio: Log" > ${AUDIO_LOG} 2>&1

# Set common paths and defaults
export PULSE_RUNTIME_PATH=/run/pulse
	RR_AUDIO_DEVICE="hw:$(get_ee_setting ee_audio_device)"
	[ ${RR_AUDIO_DEVICE} = "hw:" ] && RR_AUDIO_DEVICE="hw:0"
	echo "Set-Audio: Using audio device ${RR_AUDIO_DEVICE}" >> ${AUDIO_LOG} 2>&1
	RR_PA_UDEV="false"
    RR_PA_TSCHED="true"
    RR_AUDIO_VOLUME="$(get_ee_setting audio.volume)"
    RR_AUDIO_BACKEND="PulseAudio"

[[ -z "${RR_AUDIO_VOLUME}" ]]	&& RR_AUDIO_VOLUME="100"

pulseaudio_sink_load() {

  if [ ${RR_AUDIO_BACKEND} = "PulseAudio" ];then
    if [ "${RR_PA_TSCHED}" = "false" ]; then
      TSCHED="tsched=0"
      echo "Set-Audio: PulseAudio will disable timer-based audio scheduling" >> ${AUDIO_LOG} 2>&1
    else
      TSCHED="tsched=1"
      echo "Set-Audio: PulseAudio will enable timer-based audio scheduling" >> ${AUDIO_LOG} 2>&1
    fi

    if [ ! -z "$(pactl list modules short | grep module-null-sink)" ];then
      if [ "${RR_PA_UDEV}" = "true" ]; then
        pactl load-module module-udev-detect ${TSCHED} > /dev/null
        pactl set-sink-volume "$(pactl info | grep 'Default Sink:' | cut -d ' ' -f 3)" ${RR_AUDIO_VOLUME}% >> ${AUDIO_LOG} 2>&1
        if [ ! -z "$(pactl list modules short | grep module-alsa-card)" ];then
          echo "Set-Audio: PulseAudio module-udev-detect loaded, setting a volume of "${RR_AUDIO_VOLUME}"%" >> ${AUDIO_LOG} 2>&1
          echo "Set-Audio: PulseAudio will use sink "$(pactl list sinks short) >> ${AUDIO_LOG} 2>&1
        else
          echo "Set-Audio: PulseAudio module-udev-detect failed to load" >> ${AUDIO_LOG} 2>&1
        fi
      else
        pactl load-module module-alsa-sink device="${RR_AUDIO_DEVICE}" name="temp_sink" ${TSCHED} > /dev/null
        pactl set-sink-volume alsa_output.temp_sink ${RR_AUDIO_VOLUME}%  >> ${AUDIO_LOG} 2>&1
        if [ ! -z "$(pactl list modules short | grep module-alsa-sink)" ];then
          echo "Set-Audio: PulseAudio module-alsa-sink loaded, setting a volume of "${RR_AUDIO_VOLUME}"%"  >> ${AUDIO_LOG} 2>&1
          echo "Set-Audio: PulseAudio will use sink "$(pactl list sinks short)  >> ${AUDIO_LOG} 2>&1
        else
          echo "Set-Audio: PulseAudio module-alsa-sink failed to load"  >> ${AUDIO_LOG} 2>&1
        fi
      fi
    fi
  fi
}

# Unload PulseAudio sink
pulseaudio_sink_unload() {

  if [ ${RR_AUDIO_BACKEND} = "PulseAudio" ]; then
    if [ "${RR_PA_UDEV}" = "true" ] && [ ! -z "$(pactl list modules short | grep module-alsa-card)" ]; then
      pactl set-sink-volume "$(pactl info | grep 'Default Sink:' | cut -d ' ' -f 3)" 100%   >> ${AUDIO_LOG} 2>&1
      pactl unload-module module-udev-detect  >> ${AUDIO_LOG} 2>&1
      pactl unload-module module-alsa-card  >> ${AUDIO_LOG} 2>&1
      echo "Set-Audio: PulseAudio module-udev-detect unloaded"  >> ${AUDIO_LOG} 2>&1
    elif [ "${RR_PA_UDEV}" = "false" ] && [ ! -z "$(pactl list modules short | grep module-alsa-sink)" ]; then
      pactl set-sink-volume alsa_output.temp_sink 100%  >> ${AUDIO_LOG} 2>&1
      # V14 fix: era awk '{print ${1};}' — ${1} é sintaxe shell, awk usa $1
      NUMBER="$(pactl list modules short | grep "name=temp_sink" | awk '{print $1}')"
      if [ -n "${NUMBER}" ]; then
        pactl unload-module "${NUMBER}"  >> ${AUDIO_LOG} 2>&1
      fi
      echo "Set-Audio: PulseAudio module-alsa-sink unloaded"  >> ${AUDIO_LOG} 2>&1
    else
      echo "Set-Audio: neither the PulseAudio module module-alsa-card or module-alsa-sink was found. Nothing to unload"  >> ${AUDIO_LOG} 2>&1
    fi

    # Restore ALSA Master volume to 100%
    # V14 fix: era awk '${0}~/%/{print ${4}}' — ${0}/${4} é sintaxe shell, awk usa $0/$4
    # V14.2.1 fix: amixer Master em SoCs com 2 canais (Valhall S905X5/X5M) retorna
    # Front Left + Front Right em linhas separadas → awk imprime "100% 100%" → test
    # [ ! 100% 100% = "100" ] falha com "[: too many arguments". Adicionado | head -1
    # pra pegar só primeiro valor + aspas no test pra robustez.
    MASTER_VOL="$(amixer get Master 2>/dev/null | awk '$0~/%/{print $4}' | tr -d '[]%' | head -1)"
    if [ ! -z "$(amixer | grep "'Master',0")" ] && [ "${MASTER_VOL}" != "100" ]; then
      amixer -q set Master,0 100% unmute
      echo "Set-Audio: ALSA mixer restore volume to 100%"  >> ${AUDIO_LOG} 2>&1
    fi
  fi
}

# Start FluidSynth
fluidsynth_service_start() {

  if [ ${RR_AUDIO_BACKEND} = "PulseAudio" ] && [ ! "$(systemctl is-active fluidsynth)" = "active" ]; then
    systemctl start fluidsynth
    if [ "$(systemctl is-active fluidsynth)" = "active" ]; then
      echo "Set-Audio: FluidSynth service loaded successfully"  >> ${AUDIO_LOG} 2>&1
    else
      echo "Set-Audio: FluidSynth service failed to load"  >> ${AUDIO_LOG} 2>&1
    fi
  fi
}

# Stop FluidSynth
fluidsynth_service_stop() {


  if [ "$(systemctl is-active fluidsynth)" = "active" ]; then
    systemctl stop fluidsynth
    if [ ! "$(systemctl is-active fluidsynth)" = "active" ]; then
      echo "Set-Audio: FluidSynth service successfully stopped"  >> ${AUDIO_LOG} 2>&1
    else
      echo "Set-Audio: FluidSynth service failed to stop"  >> ${AUDIO_LOG} 2>&1
    fi
  fi
}

# SDL2: Set audio driver to Pulseaudio or ALSA
set_SDL_audiodriver() {

  if [ ${RR_AUDIO_BACKEND} = "PulseAudio" ]; then
    export SDL_AUDIODRIVER=pulseaudio
  else
    export SDL_AUDIODRIVER=alsa
  fi
  echo "Set-Audio: SDL2 set environment variable SDL_AUDIODRIVER="${SDL_AUDIODRIVER}  >> ${AUDIO_LOG} 2>&1
}

# RETROARCH: Set audio & midi driver
set_RA_audiodriver() {

  RETROARCH_HOME=/storage/.config/retroarch
  RETROARCH_CONFIG=${RETROARCH_HOME}/retroarch.cfg

  if [ -f ${RETROARCH_CONFIG} ]; then
    if [ ${RR_AUDIO_BACKEND} = "PulseAudio" ]; then
      sed -e "s/audio_driver = \"alsathread\"/audio_driver = \"pulse\"/" -i ${RETROARCH_CONFIG}
      sed -e "s/midi_driver = \"null\"/midi_driver = \"alsa\"/" -i          ${RETROARCH_CONFIG}
      sed -e "s/midi_output = \"Off\"/midi_output = \"FluidSynth\"/" -i     ${RETROARCH_CONFIG}
      echo "Set-Audio: Retroarch force audio driver to PulseAudio & MIDI output to FluidSynth"
    else
      sed -e "s/audio_driver = \"pulse\"/audio_driver = \"alsathread\"/" -i ${RETROARCH_CONFIG}
      sed -e "s/midi_driver = \"alsa\"/midi_driver = \"null\"/" -i          ${RETROARCH_CONFIG}
      sed -e "s/midi_output = \"FluidSynth\"/midi_output = \"Off\"/" -i     ${RETROARCH_CONFIG}
      echo "Set-Audio: Retroarch force audio driver to ALSA & disable MIDI output"
    fi
  fi
}

case "${1}" in
	"pulseaudio")
		pulseaudio_sink_unload
		fluidsynth_service_stop
		pulseaudio_sink_load
	;;
	"fluidsynth")
		pulseaudio_sink_unload
		pulseaudio_sink_load
		fluidsynth_service_stop
		fluidsynth_service_start
	;;
	"alsa")
		pulseaudio_sink_unload
		fluidsynth_service_stop
		RR_AUDIO_BACKEND="alsa"
	;;
esac
		set_SDL_audiodriver

if [ "$EE_DEVICE" == "OdroidGoAdvance" ] || [ "$EE_DEVICE" == "GameForce" ]; then
	# For some reason the audio is being reseted to 100 at boot, so we reaply the saved settings here
	odroidgoa_utils.sh vol ${RR_AUDIO_VOLUME}
else
	#amixer set 'DAC Digital' "${RR_AUDIO_VOLUME}%"
	amixer set Master "${RR_AUDIO_VOLUME}%"  >> ${AUDIO_LOG} 2>&1
fi
