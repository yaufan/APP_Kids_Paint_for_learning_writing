"""字母寵物 (Letter Pets): every sound in the app, made here from sine waves
and noise, so every one is ours: nothing recorded, nothing downloaded, and
every tune written for this app.

- Music (WAV, 16,000 Hz): one tune for each situation. Each tune is as long
  as its bars, and what still rings at the end is carried round to the start,
  so it loops without a seam. Gentle and quiet, never shrill.
- Short sounds and the pets' calls (WAV, 22,050 Hz).
- Animal voices are a buzz through formant filters, as in 畫畫小鎮.
- Every random choice uses a fixed seed, so each run writes the same files.

The helpers (env, bell, marimba, place, triangle, lowpass, bandpass,
tune_loop, music_box_note, voice, resonator, NOTE) are copied from
畫畫小鎮's docs/design/sounds/make_sounds.py; the tunes and sounds are new.

    python3 design/sounds/make_sounds.py    # writes app/assets/sounds/*.wav
"""
import pathlib
import wave

import numpy as np
from scipy.signal import lfilter

OUT = pathlib.Path(__file__).resolve().parents[2] / "app" / "assets" / "sounds"
SR = 22050       # short sounds and calls
LOOP_SR = 16000  # music

# Notes (Hz), with flats as well as sharps.
NOTE = {f"{n}{o}": 440 * 2 ** ((k - 9) / 12 + o - 4)
        for o in range(2, 8) for k, n in enumerate("C C# D D# E F F# G G# A A# B".split())}
for _o in range(2, 8):
    for _flat, _sharp in (("Db", "C#"), ("Eb", "D#"), ("Gb", "F#"), ("Ab", "G#"), ("Bb", "A#")):
        NOTE[f"{_flat}{_o}"] = NOTE[f"{_sharp}{_o}"]

# Chords: their notes as names without an octave.
CHORD = {"C": "C E G", "Dm": "D F A", "Em": "E G B", "F": "F A C", "G": "G B D", "Am": "A C E",
         "Bb": "Bb D F", "Gm": "G Bb D", "D": "D F# A", "A": "A C# E", "Bm": "B D F#", "F#m": "F# A C#"}
CHORD = {k: v.split() for k, v in CHORD.items()}


# ---------------------------------------------------------------- helpers (from 畫畫小鎮)


def t_of(dur, sr=SR):
    return np.arange(int(dur * sr)) / sr


def env(n, attack=0.005, release=0.05, sr=SR):
    """Up quickly, down smoothly: no clicks at either end."""
    e = np.ones(n)
    a, r = max(1, min(n, int(attack * sr))), max(1, min(n, int(release * sr)))
    e[:a] = np.linspace(0, 1, a) ** 2
    e[-r:] *= np.linspace(1, 0, r) ** 2
    return e


def sweep(f, sr=SR):
    """A sine whose frequency follows the array [f] (Hz per sample)."""
    return np.sin(2 * np.pi * np.cumsum(f) / sr)


def decay(n, tau, sr=SR):
    return np.exp(-np.arange(n) / (tau * sr))


def lowpass(x, cutoff, sr=SR):
    spec = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), 1 / sr)
    spec *= 1 / (1 + (freqs / cutoff) ** 4)
    return np.fft.irfft(spec, len(x))


def bandpass(x, lo, hi, sr=SR):
    spec = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), 1 / sr)
    spec *= 1 / (1 + (lo / np.maximum(freqs, 1)) ** 4) / (1 + (freqs / hi) ** 4)
    return np.fft.irfft(spec, len(x))


def partial(freq, t, sr):
    """A sine at [freq], or silence if it is too high for [sr] (it would fold
    back down as a wrong note)."""
    return np.sin(2 * np.pi * freq * t) if freq < 0.45 * sr else np.zeros_like(t)


def bell(freq, dur=0.5, sr=SR, bright=1.0):
    """A soft glockenspiel note: a few partials, the high ones dying first."""
    t = t_of(dur, sr)
    x = (partial(freq, t, sr) * np.exp(-t / (dur * 0.35))
         + 0.35 * bright * partial(freq * 2.76, t, sr) * np.exp(-t / (dur * 0.12))
         + 0.15 * bright * partial(freq * 5.4, t, sr) * np.exp(-t / (dur * 0.06)))
    return x * env(len(t), 0.002, 0.03, sr)


def marimba(freq, dur=0.5, sr=SR):
    t = t_of(dur, sr)
    x = partial(freq, t, sr) * np.exp(-t / (dur * 0.3)) + 0.2 * partial(freq * 4, t, sr) * np.exp(-t / (dur * 0.05))
    return x * env(len(t), 0.003, 0.03, sr)


def triangle(freq, dur, sr=SR):
    t = t_of(dur, sr)
    return 2 / np.pi * np.arcsin(np.sin(2 * np.pi * freq * t))


def place(total, parts, sr=SR):
    """[parts]: (start seconds, signal) mixed into [total] seconds."""
    out = np.zeros(int(total * sr))
    for start, sig in parts:
        i = int(start * sr)
        j = min(len(out), i + len(sig))
        out[i:j] += sig[: j - i]
    return out


def tune_loop(seconds, notes, sr=LOOP_SR):
    """[notes]: (start seconds, signal); what rings past [seconds] wraps to the start."""
    n = int(round(seconds * sr))
    tail = max(len(sig) + int(start * sr) for start, sig in notes) - n
    out = np.zeros(n + max(0, tail))
    for start, sig in notes:
        i = int(start * sr)
        out[i:i + len(sig)] += sig
    loop = out[:n].copy()
    if tail > 0:
        loop[:tail] += out[n:]
    return loop


def music_box_note(freq, dur, sr=LOOP_SR, bright=1.0):
    """A music box's comb: bright at first, then a long soft ring."""
    t = t_of(dur, sr)
    x = (partial(freq, t, sr) * np.exp(-t / 0.9)
         + 0.4 * bright * partial(freq * 3.0, t, sr) * np.exp(-t / 0.18)
         + 0.18 * bright * partial(freq * 5.2, t, sr) * np.exp(-t / 0.06))
    return x * env(len(t), 0.002, 0.08, sr)


def resonator(x, freq, bw, sr=SR, block=64):
    """A two-pole resonance at [freq] Hz (a number, or one per sample, for a
    vowel that changes) of bandwidth [bw] Hz."""
    freq = np.broadcast_to(np.asarray(freq, dtype=float), x.shape)
    y, zi = np.zeros_like(x), np.zeros(2)
    r = np.exp(-np.pi * bw / sr)
    for i in range(0, len(x), block):
        th = 2 * np.pi * freq[i] / sr
        y[i:i + block], zi = lfilter([1 - r], [1, -2 * r * np.cos(th), r * r], x[i:i + block], zi=zi)
    return y


def voice(f0, formants, rng, breath=0.03, rough=0.0, sr=SR):
    """A voice at pitch [f0] (Hz per sample) through [formants]: (Hz or Hz
    per sample, bandwidth, gain). [rough] jitters the pitch, for a growl."""
    n = len(f0)
    if rough:
        f0 = f0 * (1 + rough * lowpass(rng.standard_normal(n), 60, sr) * 3)
    buzz = 2 * (np.cumsum(f0) / sr % 1) - 1 + breath * rng.standard_normal(n)
    out = np.zeros(n)
    for f, bw, gain in formants:
        y = resonator(buzz, f, bw, sr)
        out += gain * y / max(1e-9, np.abs(y).max())
    return lowpass(out, 3800, sr)  # soft, not a kazoo


def ease(u):
    """0 to 1, smoothly, over u in 0..1."""
    u = np.clip(u, 0, 1)
    return u * u * (3 - 2 * u)


def glide(t, *points):
    """A value that moves smoothly between (time, value) [points]."""
    ts, vs = zip(*points)
    out = np.interp(t, ts, vs)
    return lowpass(out - out.mean(), 25) + out.mean() if len(t) > 64 else out


# ---------------------------------------------------------------- new instruments


def harp(freq, dur=1.6, sr=LOOP_SR, bright=1.0):
    """A plucked harp string: whole-number harmonics, the high ones fading first."""
    t = t_of(dur, sr)
    x = np.zeros_like(t)
    for k, a in ((1, 1.0), (2, 0.5), (3, 0.22), (4, 0.1), (5, 0.05)):
        x += (a if k == 1 else a * bright) * partial(freq * k, t, sr) * np.exp(-t / (dur * 0.36 / k ** 0.8))
    return x * env(len(t), 0.004, 0.06, sr)


def soft_piano(freq, dur=2.5, sr=LOOP_SR):
    """A felt piano: a marimba's warm knock and a bell's soft ring, blended,
    over a plain tone that rings a little longer."""
    t = t_of(dur, sr)
    body = (partial(freq, t, sr) * np.exp(-t / (dur * 0.32))
            + 0.25 * partial(freq * 2, t, sr) * np.exp(-t / (dur * 0.12)))
    x = 0.45 * marimba(freq, dur, sr) + 0.3 * bell(freq, dur, sr, bright=0.25) + 0.5 * body
    return x * env(len(t), 0.006, 0.08, sr)


def xylo(freq, dur=0.5, sr=LOOP_SR):
    """A wooden xylophone bar: the marimba's knock with a little ring on top."""
    wood = 0.8 * marimba(freq, dur, sr)
    ring = 0.15 * bell(freq, dur * 0.8, sr, bright=0.3)
    wood[:len(ring)] += ring
    return wood


def brass(freq, dur, sr=SR):
    """A soft toy trumpet: every harmonic, the high ones quieter; a slow
    vibrato comes in on long notes."""
    t = t_of(dur, sr)
    vib = 1 + 0.007 * np.sin(2 * np.pi * 5.5 * t) * ease((t - 0.2) / 0.3)
    ph = 2 * np.pi * np.cumsum(freq * vib) / sr
    x = np.zeros_like(t)
    for k in range(1, 9):
        if k * freq * 1.01 < 0.45 * sr:
            x += np.sin(k * ph) / k ** 1.4
    return lowpass(x, 3200, sr) * env(len(t), 0.015, min(0.15, dur * 0.4), sr)


def bubble(rng, sr=LOOP_SR, low=(300, 550), rise=(2.2, 3.2), dur=(0.04, 0.08)):
    """One little bubble: a quick rising blip that starts and ends at zero."""
    d = rng.uniform(*dur)
    t = t_of(d, sr)
    f0 = rng.uniform(*low)
    f = np.geomspace(f0, f0 * rng.uniform(*rise), len(t))
    return sweep(f, sr) * np.sin(np.pi * t / d)


def above(name, low):
    """The note called [name] (no octave) at or just above the note [low]."""
    for o in range(2, 8):
        if NOTE[f"{name}{o}"] >= NOTE[low] * 0.999:
            return f"{name}{o}"
    raise ValueError(name)


def bass_of(chord):
    """The chord's root, between C3 and B3."""
    return above(CHORD[chord][0], "C3")


def fifth_below(note):
    return NOTE[note] / 2 ** (5 / 12)


def spans(bars, beats_per_bar):
    """Bars like "F" or "Bb-C" (two chords, half a bar each) -> (beat, length in beats, chord)."""
    out = []
    for i, bar in enumerate(bars):
        parts = bar.split("-")
        each = beats_per_bar / len(parts)
        out += [(i * beats_per_bar + k * each, each, c) for k, c in enumerate(parts)]
    return out


def melody(tune, beat, start=0.0):
    """[tune]: (note or None for a rest, beats) one after another -> (seconds, note, beats)."""
    out, at = [], start
    for name, beats in tune:
        if name:
            out.append((at, name, beats))
        at += beats * beat
    return out


# ---------------------------------------------------------------- music


def music_home_land():
    """The land pets' home: a happy tune in F on a xylophone, a music box
    singing along; then the music box takes the tune and the xylophone plays
    the chords. Twelve bars of four, bass on the beat, chords off it."""
    beat = 0.45
    bars = ["F", "C", "Bb", "C", "F", "Dm", "Bb-C", "F", "Dm", "Bb", "Gm-C", "C"]
    tune_a = [  # bars 1-8, the xylophone (and the music box, softly)
        ("C5", 1), ("F5", .5), ("G5", .5), ("A5", 1), ("F5", 1),
        ("E5", 1), ("G5", .5), ("A5", .5), ("G5", 2),
        ("F5", 1), ("Bb5", .5), ("A5", .5), ("G5", 1), ("D5", 1),
        ("E5", 1), ("F5", .5), ("E5", .5), ("C5", 2),
        ("C5", 1), ("F5", .5), ("G5", .5), ("A5", 1), ("C6", 1),
        ("D6", 1), ("C6", .5), ("A5", .5), ("F5", 2),
        ("Bb5", 1), ("A5", .5), ("G5", .5), ("E5", 1), ("G5", 1),
        ("F5", 1), ("C5", 1), ("F5", 2)]
    tune_b = [  # bars 9-12, the music box
        ("A5", 1.5), ("F5", .5), ("D5", 1), ("F5", 1),
        ("Bb5", 1.5), ("A5", .5), ("G5", 1), ("F5", 1),
        ("G5", 1), ("Bb5", 1), ("C6", 1), ("Bb5", 1),
        ("A5", .5), ("G5", .5), ("E5", 1), ("G5", 1), (None, 1)]
    notes = []
    for at, name, _ in melody(tune_a, beat):
        notes += [(at, 0.8 * xylo(NOTE[name])), (at, 0.3 * music_box_note(NOTE[name], 1.4))]
    for at, name, _ in melody(tune_b, beat, 32 * beat):
        notes.append((at, 0.85 * music_box_note(NOTE[name], 1.8)))
    for b, length, chord in spans(bars, 4):
        root = bass_of(chord)
        notes.append((b * beat, 0.5 * marimba(NOTE[root], 0.8, LOOP_SR)))
        if length == 4:
            notes.append(((b + 2) * beat, 0.42 * marimba(fifth_below(root), 0.8, LOOP_SR)))
        late = b >= 32  # the xylophone has the chords in bars 9-12
        for off in ((1, 3) if length == 4 else (1,)):
            for name in CHORD[chord]:
                f = NOTE[above(name, "G4" if late else "G3")]
                sig = 0.2 * xylo(f, 0.35) if late else 0.17 * marimba(f, 0.3, LOOP_SR)
                notes.append(((b + off) * beat, sig))
    x = tune_loop(len(bars) * 4 * beat, notes)
    return lowpass(x, 4500, LOOP_SR)


def music_home_sea():
    """The sea pets' home: a harp in D rolling up and down like waves (six
    notes a bar), a slow tune on top, and soft bubbles rising."""
    eighth = 0.3
    bars = ["D", "Bm", "G", "A", "D", "F#m", "G", "A", "Bm", "G", "Em", "A"]
    tune = [  # in eighths, six a bar
        ("A4", 3), ("D5", 2), ("E5", 1),
        ("F#5", 4), ("D5", 2),
        ("G5", 3), ("F#5", 2), ("E5", 1),
        ("E5", 6),
        ("A4", 3), ("D5", 2), ("E5", 1),
        ("F#5", 3), ("A5", 3),
        ("B5", 2), ("A5", 2), ("G5", 2),
        ("A5", 6),
        ("B5", 3), ("A5", 2), ("F#5", 1),
        ("G5", 3), ("E5", 2), ("D5", 1),
        ("E5", 3), ("G5", 2), ("F#5", 1),
        ("E5", 4), ("C#5", 2)]
    notes = [(at, 0.8 * harp(NOTE[name], 2.4)) for at, name, _ in melody(tune, eighth)]
    for i, chord in enumerate(bars):
        root = NOTE[above(CHORD[chord][0], "E2")]
        third = 3 if chord.endswith("m") else 4
        steps = [0, 7, 12, 12 + third, 19, 12 + third]  # up and back down: a wave
        for k, (s, a) in enumerate(zip(steps, (0.5, 0.32, 0.32, 0.28, 0.28, 0.25))):
            notes.append(((i * 6 + k) * eighth, a * harp(root * 2 ** (s / 12), 1.8)))
    seconds = len(bars) * 6 * eighth
    rng = np.random.default_rng(31)
    k = 0.4
    while k < seconds:
        for j in range(rng.integers(1, 4)):
            notes.append((k + j * rng.uniform(0.06, 0.11), rng.uniform(0.1, 0.22) * bubble(rng)))
        k += rng.uniform(0.6, 1.4)
    x = tune_loop(seconds, notes)
    # The sea's soft hush: filtered noise exactly as long as the loop (the
    # filter goes round, so it joins up), swelling three times per loop.
    n = len(x)
    t = np.arange(n) / LOOP_SR
    hush = lowpass(rng.standard_normal(n), 320, LOOP_SR)
    hush *= 0.05 / np.sqrt(np.mean(hush ** 2)) * (0.7 + 0.3 * np.sin(2 * np.pi * 3 * t / seconds))
    return lowpass(x + hush, 4000, LOOP_SR)


def music_write():
    """Writing time: calm and sparse on a felt piano, low and in the
    background. Eight slow bars of broken chords, a few notes on top."""
    beat = 0.66
    bars = [("F3", "A3 C4 E4"), ("E3", "G3 B3 D4"), ("D3", "F3 A3 C4"), ("C3", "E3 G3 B3"),
            ("F3", "A3 C4 E4"), ("E3", "G3 B3 D4"), ("D3", "F3 A3 C4"), ("G3", "B3 D4 G4")]
    tune = [("E5", 2), ("C5", 2),
            ("D5", 3), ("B4", 1),
            ("C5", 2), ("A4", 2),
            ("G4", 4),
            ("A4", 1), ("C5", 1), ("E5", 2),
            ("B4", 1), ("D5", 1), ("G5", 2),
            ("F5", 2), ("E5", 1), ("C5", 1),
            ("D5", 2), ("B4", 2)]
    notes = [(at, 0.5 * soft_piano(NOTE[name], 2.6)) for at, name, _ in melody(tune, beat)]
    for i, (low, rest) in enumerate(bars):
        notes.append((i * 4 * beat, 0.5 * soft_piano(NOTE[low], 3.0)))
        for k, name in enumerate(rest.split()):
            notes.append(((i * 4 + 1 + k) * beat, (0.28 - 0.02 * k) * soft_piano(NOTE[name], 2.2)))
    x = tune_loop(len(bars) * 4 * beat, notes)
    return lowpass(x, 2300, LOOP_SR)


def music_play():
    """Playing with the pet: a bouncy tune in G on the xylophone, oom-pah
    underneath, a soft drum, a shaker on the off-beats, and a bloop at the
    end of each half."""
    beat = 0.5
    bars = ["G", "C", "D", "G", "Em", "C", "Am-D", "D"]
    tune = [("G5", .5), ("B5", .5), ("D6", 1), ("B5", .5), ("G5", .5), ("A5", 1),
            ("E5", .5), ("G5", .5), ("C6", 1), ("G5", 1), ("E5", 1),
            ("F#5", .5), ("A5", .5), ("D6", .5), ("C6", .5), ("B5", .5), ("A5", .5), ("F#5", 1),
            ("G5", 1), ("D5", .5), ("G5", .5), ("B5", 2),
            ("B5", .5), ("B5", .5), ("G5", 1), ("E5", .5), ("G5", .5), ("B5", 1),
            ("C6", .5), ("B5", .5), ("A5", .5), ("G5", .5), ("E5", 1), ("G5", 1),
            ("A5", 1), ("C6", 1), ("B5", .5), ("A5", .5), ("F#5", 1),
            ("D5", .5), ("E5", .5), ("F#5", .5), ("A5", .5), ("D6", 1), (None, 1)]
    notes = [(at, 0.8 * xylo(NOTE[name], 0.4)) for at, name, _ in melody(tune, beat)]
    for b, length, chord in spans(bars, 4):
        root = bass_of(chord)
        notes.append((b * beat, 0.55 * marimba(NOTE[root], 0.45, LOOP_SR)))
        if length == 4:
            notes.append(((b + 2) * beat, 0.5 * marimba(fifth_below(root), 0.45, LOOP_SR)))
        for off in ((1, 3) if length == 4 else (1,)):
            for name in CHORD[chord]:
                notes.append(((b + off) * beat, 0.15 * marimba(NOTE[above(name, "G3")], 0.22, LOOP_SR)))
    rng = np.random.default_rng(32)
    beats = len(bars) * 4
    m = int(0.12 * LOOP_SR)
    drum = sweep(np.geomspace(150, 60, m), LOOP_SR) * decay(m, 0.045, LOOP_SR) * env(m, 0.003, 0.03, LOOP_SR)
    for b in range(0, beats, 2):
        notes.append((b * beat, 0.4 * drum))
    for b in range(beats):
        s = int(0.03 * LOOP_SR)
        tick = bandpass(rng.standard_normal(s), 2500, 6000, LOOP_SR) * decay(s, 0.006, LOOP_SR) * env(s, 0.001, 0.005, LOOP_SR)
        notes.append(((b + 0.5) * beat, 0.12 * tick))
    for at in (15.5 * beat, 31 * beat):
        notes.append((at, 0.3 * bubble(rng, low=(320, 340), rise=(2.6, 2.7), dur=(0.11, 0.12))))
    x = tune_loop(beats * beat, notes)
    return lowpass(x, 5000, LOOP_SR)


def music_sleep():
    """Bedtime: a slow lullaby in C, three beats a bar, on a soft music box;
    a harp rocks underneath and a warm hum holds each chord."""
    beat = 0.88
    bars = ["C", "Am", "F", "G", "C", "F", "Dm", "G"]
    tune = [("E5", 2), ("D5", 1),
            ("C5", 2), ("E5", 1),
            ("A5", 2), ("G5", 1),
            ("D5", 3),
            ("E5", 2), ("D5", 1),
            ("C5", 2), ("A4", 1),
            ("F5", 2), ("E5", 1),
            ("D5", 2), ("B4", 1)]
    notes = [(at, 0.8 * music_box_note(NOTE[name], 2.6, bright=0.5)) for at, name, _ in melody(tune, beat)]
    bar = 3 * beat
    for i, chord in enumerate(bars):
        root = bass_of(chord)
        notes.append((i * bar, 0.45 * harp(NOTE[root], 2.6, bright=0.6)))
        upper = [NOTE[above(n, "E4")] for n in CHORD[chord][1:]]
        for k, a in ((1, 0.16), (2, 0.12)):
            for f in upper:
                notes.append(((i * 3 + k) * beat, a * harp(f, 1.6, bright=0.5)))
        # the hum: the chord held, swelling in and out, two tones a hair apart
        d = bar + 1.0
        t = t_of(d, LOOP_SR)
        swell = np.sin(np.pi * np.minimum(1, t / d)) ** 2
        hum = sum(np.sin(2 * np.pi * f * t) + np.sin(2 * np.pi * f * 1.002 * t)
                  for f in [NOTE[root]] + [NOTE[above(n, "C4")] for n in CHORD[chord]])
        notes.append((i * bar, 0.035 * hum * swell))
    x = tune_loop(len(bars) * bar, notes)
    return lowpass(x, 2600, LOOP_SR)


MUSIC = {
    "music_home_land": (music_home_land, 0.30),
    "music_home_sea": (music_home_sea, 0.30),
    "music_write": (music_write, 0.24),
    "music_play": (music_play, 0.30),
    "music_sleep": (music_sleep, 0.26),
}


# ---------------------------------------------------------------- short sounds


def celebrate():
    """Hatching, growing up, a reward reached: a toy-trumpet fanfare in G,
    a soft drum, a warm chord, and sparkles."""
    fan = [("D4", 0.00, 0.15), ("G4", 0.16, 0.15), ("B4", 0.32, 0.15), ("D5", 0.48, 0.42),
           ("B4", 0.95, 0.14), ("D5", 1.11, 0.14), ("G5", 1.27, 1.9)]
    parts = [(at, 0.75 * brass(NOTE[n], d)) for n, at, d in fan]
    chord = sum(brass(NOTE[n], 1.9) for n in ("G3", "B3", "D4")) / 3
    parts.append((1.27, 0.55 * chord))
    m = int(0.4 * SR)
    drum = sweep(np.geomspace(110, 70, m)) * decay(m, 0.12) * env(m, 0.003, 0.1)
    parts += [(0.48, 0.5 * drum), (1.27, 0.7 * drum)]
    run = ["D6", "E6", "G6", "A6", "B6", "D7"]
    parts += [(1.3 + 0.05 * i, 0.3 * bell(NOTE[n], 0.5)) for i, n in enumerate(run)]
    rng = np.random.default_rng(41)
    sparkle = ["G6", "A6", "B6", "D7", "E7"]
    for k in range(10):
        at = 1.7 + k * 0.13 + rng.uniform(-0.03, 0.03)
        parts.append((at, (0.28 - 0.018 * k) * bell(NOTE[sparkle[rng.integers(5)]], 0.45, bright=0.6)))
    return place(3.5, parts)


def star():
    """A star earned: a bright ding."""
    return place(0.62, [(0, bell(NOTE["E6"], 0.6)), (0.04, 0.45 * bell(NOTE["B6"], 0.5, bright=0.4))])


def letter_done():
    """A letter written: a sparkly run up, a harp chord under the top note."""
    run = ["G5", "A5", "B5", "D6", "E6", "G6", "A6", "B6"]
    parts = [(i * 0.045, (0.42 + 0.05 * i) * bell(NOTE[n], 0.45)) for i, n in enumerate(run)]
    chord = sum(harp(NOTE[n], 0.9, SR) for n in ("G4", "B4", "D5")) / 3
    return place(0.92, parts + [(0.36, 0.8 * bell(NOTE["D7"], 0.55, bright=0.5)), (0.36, 0.7 * chord)])


def stroke_done():
    """One stroke done: a soft pling."""
    return place(0.4, [(0, harp(NOTE["E6"], 0.38, SR, bright=0.5)), (0, 0.3 * bell(NOTE["E6"], 0.3, bright=0.2))])


def oops():
    """Off the path: a soft, low, springy boing that sounds curious, not wrong."""
    t = t_of(0.5)
    f = 150 * (1 + 0.6 * (1 - np.exp(-t / 0.05))) * (1 + 0.1 * np.sin(2 * np.pi * 11 * t) * np.exp(-t / 0.2))
    x = sweep(f) + 0.25 * sweep(2 * f) + 0.08 * sweep(3 * f)
    return lowpass(x * env(len(t), 0.006, 0.12) * decay(len(t), 0.2), 1500)


def tap():
    """A button: a little wooden tock."""
    t = t_of(0.06)
    x = partial(1250, t, SR) * np.exp(-t / 0.012) + 0.3 * partial(2900, t, SR) * np.exp(-t / 0.004)
    return x * env(len(t), 0.001, 0.02)


def pop():
    """A pop: a quick bloop with a tiny click."""
    rng = np.random.default_rng(42)
    t = t_of(0.11)
    x = sweep(np.geomspace(380, 1400, len(t))) * env(len(t), 0.002, 0.04) * decay(len(t), 0.03)
    click = bandpass(rng.standard_normal(len(t)), 1500, 5000) * np.exp(-t / 0.003) * 0.35
    return x + click * env(len(t), 0.001, 0.02)


def cookie():
    """The letter cookie: a big crunch, then a smaller one."""
    rng = np.random.default_rng(43)

    def crunch(dur, amp):
        n = int(dur * SR)
        t = np.arange(n) / SR
        x = 0.5 * bandpass(rng.standard_normal(n), 900, 6500) * np.exp(-t / (dur * 0.35))
        for i in rng.integers(0, int(n * 0.7), 40):
            m = 90
            c = bandpass(rng.standard_normal(m), 1500, 8000) * np.exp(-np.arange(m) / 12)
            x[i:i + m] += c * rng.uniform(0.3, 1.0) * np.exp(-i / (n * 0.4))
        thump = np.sin(2 * np.pi * 110 * t) * np.exp(-t / 0.025) * 0.6
        return (x + thump) * env(n, 0.002, 0.04) * amp
    return place(0.5, [(0, crunch(0.24, 1.0)), (0.26, crunch(0.2, 0.6))])


def chew():
    """Eating: munch, munch."""
    rng = np.random.default_rng(44)

    def nom(f):
        dur = 0.17
        t = t_of(dur)
        f0 = np.linspace(f, f * 0.85, len(t))
        f1 = np.interp(t, [0, 0.06, dur], [300, 650, 320])
        mouth = voice(f0, [(f1, 110, 1.0), (1200, 200, 0.3)], rng, breath=0.08)
        mouth *= env(len(t), 0.01, 0.06) * np.sin(np.pi * t / dur) ** 0.5
        n = int(0.05 * SR)
        bite = bandpass(rng.standard_normal(n), 1200, 5000) * np.exp(-np.arange(n) / (0.01 * SR))
        return place(0.22, [(0, 0.5 * bite), (0.025, mouth)])
    return place(0.62, [(0, nom(300)), (0.28, nom(270))])


def bubbles():
    """Bath bubbles (and the sea pets blowing bubbles): blip, blip, blip."""
    rng = np.random.default_rng(45)
    parts = [(0.04 + k * 0.1 + rng.uniform(-0.03, 0.03), rng.uniform(0.5, 1.0) * bubble(rng, SR, (320, 600), (2.5, 3.2)))
             for k in range(7)]
    return place(0.8, parts)


def rinse():
    """The shower: water hissing on, little drops, then off."""
    rng = np.random.default_rng(46)
    dur = 1.0
    n = int(dur * SR)
    t = np.arange(n) / SR
    hiss = bandpass(rng.standard_normal(n), 700, 5000)
    hiss /= np.abs(hiss).max()
    flutter = lowpass(rng.standard_normal(n), 12)
    flutter = 1 + 0.25 * flutter / np.abs(flutter).max()
    drops = np.zeros(n)
    for i in rng.integers(0, n - 200, 60):
        m = 200
        tt = np.arange(m) / SR
        drops[i:i + m] += np.sin(2 * np.pi * rng.uniform(1500, 4000) * tt) * np.exp(-tt / 0.003) * rng.uniform(0.1, 0.35)
    shape = ease(t / 0.1) * (1 - ease((t - 0.62) / 0.38))
    return (0.6 * hiss * flutter + drops) * shape


def ball():
    """The ball: boink, boink, boink-boink, lower and quicker each time."""
    def bounce(amp):
        t = t_of(0.16)
        thud = sweep(np.geomspace(260, 110, len(t))) * np.exp(-t / 0.035)
        boink = sweep(np.geomspace(700, 520, len(t))) * np.exp(-t / 0.025) * 0.35
        return (thud + boink) * env(len(t), 0.001, 0.03) * amp
    times, amps = (0, 0.28, 0.48, 0.62, 0.72), (1, 0.7, 0.48, 0.32, 0.2)
    return place(0.88, [(a, bounce(m)) for a, m in zip(times, amps)])


def lights_out():
    """The moon button: a soft chime falling to sleep."""
    tune = [("G5", 0), ("E5", 0.18), ("C5", 0.36), ("G4", 0.54)]
    parts = [(at, (0.9 - 0.1 * i) * music_box_note(NOTE[n], 0.6 if i < 3 else 0.7, SR, bright=0.4))
             for i, (n, at) in enumerate(tune)]
    t = t_of(0.85)
    warm = (np.sin(2 * np.pi * NOTE["C4"] * t) + 0.5 * np.sin(2 * np.pi * NOTE["G3"] * t)) * np.sin(np.pi * t / 0.85) ** 2
    return place(1.25, parts + [(0.36, 0.18 * warm)])


def crack():
    """The egg: crk, crk, crrrk, and the shell comes open with a pok."""
    rng = np.random.default_rng(47)

    def crk(clicks, length, amp):
        n = int(length * SR)
        x = np.zeros(n)
        for i in rng.integers(0, n - 120, clicks):
            c = bandpass(rng.standard_normal(120), 1800, 7500) * np.exp(-np.arange(120) / 14)
            x[i:i + 120] += c * rng.uniform(0.4, 1.0)
        shell = bandpass(rng.standard_normal(n), 600, 3000) * np.exp(-np.arange(n) / (0.02 * SR)) * 0.4
        return (x + shell) * env(n, 0.001, 0.01) * amp
    t = t_of(0.1)
    pok = (sweep(np.geomspace(520, 260, len(t))) + 0.3 * sweep(np.geomspace(1040, 520, len(t)))) * np.exp(-t / 0.03) * env(len(t), 0.002, 0.03)
    return place(0.82, [(0, crk(4, 0.06, 0.6)), (0.22, crk(5, 0.07, 0.75)), (0.45, crk(12, 0.16, 1.0)), (0.68, 0.8 * pok)])


def giggle():
    """Tickles: hee-hee-hee-hee, a little lower each time."""
    rng = np.random.default_rng(48)
    pitches = [560, 530, 575, 515, 490, 465, 440]
    parts = []
    for k, f in enumerate(pitches):
        dur = 0.075 if k < len(pitches) - 1 else 0.13
        t = t_of(dur)
        f0 = np.linspace(f * 1.07, f * 0.9, len(t))
        x = voice(f0, [(560, 130, 1.0), (2050, 240, 0.5), (2900, 300, 0.15)], rng, breath=0.12)
        x *= np.sin(np.pi * t / dur) ** 0.8
        m = int(0.03 * SR)
        h = bandpass(rng.standard_normal(m), 1500, 5000) * np.hanning(m) * 0.2
        at = 0.012 + k * 0.11 + rng.uniform(-0.01, 0.01)
        parts += [(at, h), (at + 0.02, x)]
    return place(0.92, parts)


def happy():
    """Petting: a happy little "u-wee!"."""
    rng = np.random.default_rng(49)
    dur = 0.26
    t = t_of(dur)
    f0 = np.interp(t, [0, 0.18, dur], [420, 640, 600])
    f2 = np.interp(t, [0, 0.15, dur], [900, 2100, 2200])
    x = voice(f0, [(np.interp(t, [0, dur], [330, 380]), 110, 1.0), (f2, 200, 0.55), (3000, 300, 0.1)], rng, breath=0.06)
    x *= env(len(t), 0.02, 0.08)
    d2 = 0.09
    t2 = t_of(d2)
    y = voice(np.linspace(660, 800, len(t2)), [(380, 110, 1.0), (2300, 220, 0.55)], rng, breath=0.06)
    y *= np.sin(np.pi * t2 / d2)
    return place(0.45, [(0, x), (0.3, 0.7 * y)])


# ---------------------------------------------------------------- the pets' calls


def woof(rng, high=1.0, times=2):
    """A dog: woof woof; [high] up for a puppy's yip."""
    def one():
        dur = 0.16 / high ** 0.3
        t = t_of(dur)
        f0 = glide(t, (0, 330), (0.04, 380), (dur, 220)) * high
        x = voice(f0, [(520 * high ** 0.5, 160, 1.0), (1350 * high ** 0.4, 220, 0.5), (2600, 300, 0.1)], rng, breath=0.35, rough=0.06)
        return x * env(len(t), 0.004, 0.06) * decay(len(t), 0.09)
    return place(0.23 * times + 0.1, [(0.23 * i, one()) for i in range(times)])


def call_puppy():
    """The puppy: arf-arf!"""
    return woof(np.random.default_rng(61), high=1.5, times=2)


def call_kitten():
    """The kitten: a small mew, mi-a-ow."""
    rng = np.random.default_rng(62)
    dur = 0.6
    t = t_of(dur)
    f0 = glide(t, (0, 650), (0.22, 950), (dur, 620))
    f1 = glide(t, (0, 340), (0.2, 900), (dur, 480))
    f2 = glide(t, (0, 2300), (0.25, 1550), (dur, 1000))
    return voice(f0, [(f1, 120, 1.0), (f2, 180, 0.6), (3000, 300, 0.1)], rng, breath=0.05) * env(len(t), 0.04, 0.18)


def call_bunny():
    """The bunny: sniff-sniff, then two tiny squeaks."""
    rng = np.random.default_rng(63)

    def squeak(dur, f):
        t = t_of(dur)
        fr = np.interp(t, [0, 0.4 * dur, dur], [f, f * 1.35, f * 1.1])
        return (sweep(fr) + 0.15 * sweep(2 * fr)) * np.sin(np.pi * t / dur) ** 1.2
    m = int(0.04 * SR)
    sniff = bandpass(rng.standard_normal(m), 2000, 6000) * np.hanning(m) * 0.35
    return place(0.46, [(0, sniff), (0.07, sniff), (0.17, squeak(0.1, 1500)), (0.31, squeak(0.13, 1650))])


def call_dino(low=2.5, dur=0.55):
    """The baby dinosaur: a tiny, cute rawr."""
    rng = np.random.default_rng(64)
    t = t_of(dur)
    f0 = glide(t, (0, 120), (0.2 * dur, 175), (0.6 * dur, 150), (dur, 95)) * low
    growl = 1 - 0.3 * (0.5 + 0.5 * np.sin(2 * np.pi * 28 * t))
    x = voice(f0, [(720 * low ** 0.4, 160, 1.0), (1150 * low ** 0.4, 200, 0.7), (2500, 300, 0.2)], rng, breath=0.45, rough=0.07)
    return x * growl * env(len(t), 0.05, 0.25)


def call_dolphin():
    """The dolphin: a quick run of clicks, then a whistle, up-down-up."""
    rng = np.random.default_rng(65)
    clicks = np.zeros(int(0.28 * SR))
    for k in range(8):
        i = int(0.28 * (k / 8) ** 0.8 * SR)
        c = bandpass(rng.standard_normal(110), 2000, 7000) * np.exp(-np.arange(110) / 15)
        clicks[i:i + 110] += c * (0.6 + 0.4 * k / 8)
    t = t_of(0.48)
    f = glide(t, (0, 1700), (0.15, 2800), (0.3, 2150), (0.48, 2650))
    whistle = (sweep(f) + 0.15 * sweep(2 * f)) * env(len(t), 0.02, 0.1)
    return place(0.8, [(0, 0.45 * clicks), (0.3, whistle)])


def call_octopus():
    """The octopus: blub-blub-bloop, round and low."""
    def one(f0, f1, dur):
        t = t_of(dur)
        f = np.geomspace(f0, f1, len(t))
        return (sweep(f) + 0.3 * sweep(2 * f)) * env(len(t), 0.004, 0.04) * decay(len(t), dur * 0.5)
    return place(0.55, [(0, one(170, 480, 0.13)), (0.17, one(210, 560, 0.12)), (0.33, one(150, 430, 0.17))])


def call_turtle():
    """The turtle: a soft, happy mm-hmm, and one bubble."""
    rng = np.random.default_rng(67)

    def hum(f, dur):
        t = t_of(dur)
        f0 = glide(t, (0, f), (dur, f * 1.1)) * (1 + 0.01 * np.sin(2 * np.pi * 5 * t))
        return voice(f0, [(270, 70, 1.0), (900, 150, 0.15)], rng, breath=0.02) * env(len(t), 0.05, 0.1)
    t = t_of(0.1)
    blip = sweep(np.geomspace(300, 820, len(t))) * env(len(t), 0.004, 0.04) * decay(len(t), 0.05)
    return place(0.74, [(0, hum(175, 0.26)), (0.29, hum(215, 0.32)), (0.63, 0.5 * blip)])


SHORT = {
    "celebrate": (celebrate, 0.70), "star": (star, 0.60), "letter_done": (letter_done, 0.62),
    "stroke_done": (stroke_done, 0.50), "oops": (oops, 0.58), "tap": (tap, 0.50), "pop": (pop, 0.55),
    "cookie": (cookie, 0.72), "chew": (chew, 0.62), "bubbles": (bubbles, 0.55), "rinse": (rinse, 0.50),
    "ball": (ball, 0.72), "lights_out": (lights_out, 0.55), "crack": (crack, 0.72), "giggle": (giggle, 0.60),
    "happy": (happy, 0.60),
    "call_puppy": (call_puppy, 0.65), "call_kitten": (call_kitten, 0.60), "call_bunny": (call_bunny, 0.50),
    "call_dino": (call_dino, 0.65), "call_dolphin": (call_dolphin, 0.50), "call_octopus": (call_octopus, 0.60),
    "call_turtle": (call_turtle, 0.62),
}


# ---------------------------------------------------------------- writing and checking


def tidy(x, sr=SR):
    """A short sound: drop the silent end, then fade both ends so neither clicks."""
    x = np.asarray(x, dtype=np.float64)
    loud = np.nonzero(np.abs(x) > np.abs(x).max() * 1e-3)[0]
    x = x[: min(len(x), loud[-1] + int(0.01 * sr))]
    return x * env(len(x), 0.002, 0.012, sr)


def write(path, x, peak, sr):
    x = np.asarray(x, dtype=np.float64)
    x = x / max(1e-9, np.abs(x).max()) * peak
    data = np.round(x * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())
    return data


def report(name, data, sr, loop):
    x = data.astype(np.float64) / 32767
    peak = np.abs(x).max()
    rms = 20 * np.log10(max(1e-9, np.sqrt(np.mean(x ** 2))))
    clipped = int(np.sum(np.abs(data) >= 32767))
    steps = np.abs(np.diff(data.astype(np.int32)))
    if loop:  # the jump from the last sample back to the first, beside the usual step
        jump = abs(int(data[0]) - int(data[-1]))
        edge = f"seam jump {jump:4d} (usual step {np.median(steps):.0f}, 99% {np.percentile(steps, 99):.0f})"
    else:
        edge = f"ends {int(data[0]):+d} / {int(data[-1]):+d}"
    print(f"  {name:18s} {len(x) / sr:5.2f} s  {(len(data) * 2 + 44) / 1024:6.1f} KB  peak {peak:.2f}  "
          f"rms {rms:6.1f} dB  clipped {clipped}  {edge}")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    print("music (16,000 Hz, loops):")
    for name, (make, peak) in MUSIC.items():
        report(name, write(OUT / f"{name}.wav", make(), peak, LOOP_SR), LOOP_SR, True)
    print("short sounds (22,050 Hz):")
    for name, (make, peak) in SHORT.items():
        report(name, write(OUT / f"{name}.wav", tidy(make()), peak, SR), SR, False)
    total = sum(p.stat().st_size for p in OUT.glob("*.wav"))
    print(f"{len(MUSIC) + len(SHORT)} sounds, {total:,} bytes ({total / 1024 / 1024:.2f} MiB) in {OUT}")


if __name__ == "__main__":
    main()
