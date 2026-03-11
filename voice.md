# Claude Code WSL2 — Voice Mode

## Problem

`/voice` shows ALSA errors and the microphone doesn't work:

```
ALSA lib confmisc.c:855:(parse_card) cannot find card '0'
ALSA lib conf.c:5727:(snd_config_expand) Evaluate error: No such file or directory
ALSA lib pcm.c:2721:(snd_pcm_open_noupdate) Unknown PCM default
```

WSL2 has no direct access to audio hardware, so ALSA can't find a sound card.

---

## How It Works

WSLg (included in Windows 11 WSL2) ships a PulseAudio server that bridges to the Windows
audio stack. The fix has two parts:

1. **ALSA → PulseAudio**: `~/.asoundrc` tells ALSA to use the `pulse` plugin as its default
   PCM device, routing all audio through PulseAudio instead of looking for hardware directly.
2. **PulseAudio → WSLg**: `PULSE_SERVER` points to the WSLg Unix socket so PulseAudio
   clients connect to the correct server.

---

## Setup

Install the required packages:

```bash
sudo apt-get install -y pulseaudio-utils libasound2-plugins
```

Create `~/.asoundrc`:

```
pcm.!default {
    type pulse
    server unix:/mnt/wslg/runtime-dir/pulse/native
}
ctl.!default {
    type pulse
    server unix:/mnt/wslg/runtime-dir/pulse/native
}
```

Add to `~/.zshrc`:

```bash
export PULSE_SERVER=unix:/mnt/wslg/runtime-dir/pulse/native
```

Reload your shell:

```bash
source ~/.zshrc
```

---

## Result

`/voice` works without ALSA errors. Audio routes through WSLg's PulseAudio server to your
Windows microphone and speakers.

---

## Troubleshooting

**Still getting ALSA errors**
- Make sure you opened a fresh terminal (or ran `source ~/.zshrc`) so `PULSE_SERVER` is set.
- Verify the WSLg PulseAudio socket exists: `ls /mnt/wslg/runtime-dir/pulse/native`
- Test the PulseAudio connection: `pactl info`

**`pactl` not found**
- Run `sudo apt-get install -y pulseaudio-utils`

**`/mnt/wslg` doesn't exist**
- WSLg requires Windows 11 (or Windows 10 Build 21362+). Check with: `wsl --version`
- Make sure your WSL2 distro is up to date: `wsl --update` (from PowerShell)

**Microphone not working / wrong device**
- List audio sources: `pactl list sources short`
- You should see `RDPSource` — this is your Windows microphone routed through WSLg.
