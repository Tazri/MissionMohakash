"""
Generates the placeholder audio used by the menu (no downloads needed).
Run:  python3 tools/generate_audio.py
Output: assets/audio/music/menu_theme.wav, assets/audio/sfx/hover.wav, click.wav

Replace these files with your own .wav/.ogg later - just keep the same file
names (or change the paths in autoload/audio_manager.tscn).
"""
import os, wave
import numpy as np

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SR = 22050
rng = np.random.default_rng(7)


def write_wav(path, data, sr=SR):
    data = np.atleast_2d(data)
    ch = data.shape[0]
    pcm = (np.clip(data.T, -1, 1) * 32767).astype("<i2")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(ch)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())
    print("wrote", os.path.relpath(path, ROOT), f"{os.path.getsize(path)/1024:.0f} KB")


def env_exp(n, attack, decay):
    t = np.arange(n) / SR
    a = np.minimum(t / max(attack, 1e-4), 1.0)
    return a * np.exp(-t / decay)


# ------------------------------------------------------------------ SFX
def make_hover():
    n = int(SR * 0.11)
    t = np.arange(n) / SR
    f = 700 + 500 * (t / t[-1])                    # soft upward chirp
    phase = 2 * np.pi * np.cumsum(f) / SR
    s = np.sin(phase) * 0.7 + np.sin(phase * 2) * 0.15
    s *= env_exp(n, 0.004, 0.035)
    return s * 0.6


def make_click():
    n = int(SR * 0.22)
    t = np.arange(n) / SR
    thunk = np.sin(2 * np.pi * np.clip(180 - 90 * t / 0.06, 60, None) * t) * env_exp(n, 0.001, 0.035)
    tick = np.sin(2 * np.pi * 1900 * t) * env_exp(n, 0.0005, 0.012)
    blip = np.zeros(n)
    for start, freq in ((0.02, 880), (0.07, 1320)):
        i = int(start * SR)
        m = n - i
        tt = np.arange(m) / SR
        blip[i:] += np.sin(2 * np.pi * freq * tt) * env_exp(m, 0.002, 0.05) * 0.5
    s = thunk * 0.8 + tick * 0.35 + blip * 0.55
    return s * 0.7


# ---------------------------------------------------------------- MUSIC
def make_music():
    seconds_per_chord = 8
    chords = [  # Am - F - C - G, slow cinematic space pad
        [110.00, 164.81, 220.00, 261.63, 329.63],
        [87.31, 130.81, 174.61, 220.00, 261.63],
        [130.81, 196.00, 261.63, 329.63, 392.00],
        [98.00, 146.83, 196.00, 246.94, 293.66],
    ]
    bells = [
        [440.00, 523.25, 659.25, 880.00],
        [349.23, 440.00, 523.25, 698.46],
        [523.25, 659.25, 783.99, 1046.50],
        [392.00, 493.88, 587.33, 783.99],
    ]
    total = seconds_per_chord * len(chords)
    N = SR * total
    L = np.zeros(N)
    R = np.zeros(N)

    def add_circular(buf, start, sig):
        idx = (start + np.arange(len(sig))) % N
        np.add.at(buf, idx, sig)

    # pads (written circularly so the loop is seamless)
    for ci, chord in enumerate(chords):
        dur = seconds_per_chord + 5
        n = int(dur * SR)
        t = np.arange(n) / SR
        env = np.minimum(t / 3.0, 1) * np.clip((dur - t) / 4.0, 0, 1) ** 1.5
        for f in chord:
            for det, pan in ((-0.25, 0.3), (0.25, 0.7)):
                ff = f * (1 + det / 100)
                s = (np.sin(2 * np.pi * ff * t) + 0.35 * np.sin(2 * np.pi * ff * 2 * t)
                     + 0.12 * np.sin(2 * np.pi * ff * 3 * t))
                s *= env * (0.05 if f > 200 else 0.07)
                add_circular(L, ci * seconds_per_chord * SR, s * (1 - pan))
                add_circular(R, ci * seconds_per_chord * SR, s * pan)

    t = np.arange(N) / SR
    swell = 0.6 + 0.4 * np.sin(2 * np.pi * t / total * 2 - 1.2)
    drone = (np.sin(2 * np.pi * 55 * t) * 0.10 + np.sin(2 * np.pi * 110.1 * t) * 0.04) * swell
    L += drone
    R += drone

    # sparse bell notes
    for ci, notes in enumerate(bells):
        for step in range(16):
            if rng.random() < 0.38:
                f = notes[rng.integers(len(notes))]
                start = int((ci * seconds_per_chord + step * 0.5) * SR)
                n = int(3.2 * SR)
                tt = np.arange(n) / SR
                mod = np.sin(2 * np.pi * f * 2.0 * tt) * 1.2 * np.exp(-tt / 0.4)
                s = np.sin(2 * np.pi * f * tt + mod) * np.exp(-tt / 0.9) * 0.05
                s[:50] *= np.linspace(0, 1, 50)
                pan = rng.uniform(0.2, 0.8)
                add_circular(L, start, s * (1 - pan))
                add_circular(R, start, s * pan)

    # airy noise bed
    for buf in (L, R):
        noise = rng.standard_normal(N)
        spec = np.fft.rfft(noise)
        freqs = np.fft.rfftfreq(N, 1 / SR)
        spec *= np.exp(-(freqs / 900.0) ** 2) * (freqs > 120)
        air = np.fft.irfft(spec, N)
        air /= np.abs(air).max()
        am = 0.5 + 0.5 * np.sin(2 * np.pi * t / total * 4 + rng.uniform(0, 6))
        buf += air * am * 0.025

    # circular reverb
    def reverb(x, seed):
        r = np.random.default_rng(seed)
        m = int(3.5 * SR)
        ir = r.standard_normal(m) * np.exp(-np.arange(m) / SR / 1.1)
        ir[: int(0.02 * SR)] *= np.linspace(0, 1, int(0.02 * SR))
        ir /= np.sqrt((ir ** 2).sum())
        irp = np.zeros(N)
        irp[:m] = ir
        wet = np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(irp), N)
        return x * 0.55 + wet * 0.9

    L = reverb(L, 1)
    R = reverb(R, 2)
    trem = 0.92 + 0.08 * np.sin(2 * np.pi * t / total * 8)
    out = np.vstack([L * trem, R * trem])
    out /= np.abs(out).max()
    return out * 0.8


if __name__ == "__main__":
    write_wav(os.path.join(ROOT, "assets/audio/sfx/hover.wav"), make_hover())
    write_wav(os.path.join(ROOT, "assets/audio/sfx/click.wav"), make_click())
    write_wav(os.path.join(ROOT, "assets/audio/music/menu_theme.wav"), make_music())
