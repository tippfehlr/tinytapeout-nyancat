#!/usr/bin/env python3
"""
Render the Nyan Cat lead+harmony ROM to a WAV file for audio verification.
Run from anywhere:  python3 render_audio.py
Output: nyan_cat.wav  (one full loop, ~34.6 s at 10 MHz / 600,000-cycle unit)
"""
import struct, wave, math

SAMPLE_RATE = 44100   # Hz for the output WAV
UNIT_S      = 0.060   # 60 ms per unit

NOTE_NAMES = {
    0: 'REST',  1: 'A#5', 2: 'A#6',
    3: 'B2',    4: 'B3',  5: 'B5',    6: 'B6',
    7: 'C#3',   8: 'C#4', 9: 'C#6',  10: 'C#7',
   11: 'D#3',  12: 'D#4',13: 'D#5',  14: 'D#6',  15: 'D#7',
   16: 'D6',
   17: 'E3',   18: 'E4', 19: 'E5',   20: 'E6',   21: 'E7',
   22: 'F#3',  23: 'F#4',24: 'F#5',  25: 'F#6',
   26: 'G#3',  27: 'G#4',28: 'G#5',  29: 'G#6',
   30: 'B4',
}

# Frequencies in Hz for each note ID
FREQ = {
    0: 0,
    1: 932.33,  2: 1864.66,
    3: 123.47,  4: 246.94,  5: 987.77,   6: 1975.53,
    7: 138.59,  8: 277.18,  9: 1108.73, 10: 2217.46,
   11: 155.56, 12: 311.13, 13: 622.25,  14: 1244.51, 15: 2489.02,
   16: 1174.66,
   17: 164.81, 18: 329.63, 19: 659.25,  20: 1318.51, 21: 2637.02,
   22: 184.99, 23: 369.99, 24: 739.99,  25: 1479.98,
   26: 207.65, 27: 415.30, 28: 830.61,  29: 1661.22,
   30: 493.88,
}

def parse_seq(notation):
    notes = []
    for token in notation.strip().split():
        note, dur_ms = token.split('/')
        note_id = 0 if note == '@' else next(k for k, v in NOTE_NAMES.items() if v == note)
        units = round(int(dur_ms) / 60)
        notes.append((note_id, units))
    return notes

INTRO_LEAD   = "D#6/115 E6/115 F#6/115 @/115 B6/115 @/115 D#6/115 E6/115 F#6/115 B6/115 C#7/115 D#7/115 C#7/115 A#6/115 B6/115 @/115 F#6/115 @/115 D#6/115 E6/115 F#6/115 @/115 B6/115 @/115 C#7/115 A#6/115 B6/115 C#7/115 E7/115 D#7/115 E7/115 C#7/115"
THEME_LEAD   = "F#6/173 @/60 G#6/173 @/60 D#6/60 @/60 D#6/120 @/120 B5/120 D6/120 C#6/120 B5/120 @/120 B5/120 @/120 C#6/120 @/120 D6/173 @/60 D6/120 C#6/120 B5/120 C#6/120 D#6/120 F#6/120 G#6/120 D#6/120 F#6/120 C#6/120 D#6/120 B5/120 C#6/120 B5/120 D#6/120 @/120 F#6/120 @/120 G#6/120 D#6/120 F#6/120 C#6/120 D#6/120 B5/120 D6/120 D#6/120 D6/120 C#6/120 B5/120 C#6/120 D6/173 @/60 B5/120 C#6/120 D#6/120 F#6/120 C#6/120 D#6/120 C#6/120 B5/120 C#6/173 @/60 B5/173 @/60 C#6/240"
VERSE_LEAD   = "B5/173 @/60 F#5/120 G#5/120 B5/173 @/60 F#5/120 G#5/120 B5/120 C#6/120 D#6/120 B5/120 E6/120 D#6/120 E6/120 F#6/120 B5/173 @/60 B5/173 @/60 F#5/120 G#5/120 B5/120 F#5/120 E6/120 D#6/120 C#6/120 B5/120 F#5/120 D#5/120 E5/120 F#5/120 B5/173 @/60 F#5/120 G#5/120 B5/173 @/60 F#5/120 G#5/120 B5/60 @/60 B5/120 C#6/120 D#6/120 B5/120 F#5/120 G#5/120 F#5/120 B5/173 @/60 B5/120 A#5/120 B5/120 F#5/120 G#5/120 B5/120 E6/120 D#6/120 E6/120 F#6/120 B5/173 @/60 C#6/180 @/60"
THEME_HARM   = "E3/240 E4/240 F#3/240 F#4/240 D#3/240 D#4/240 G#3/240 G#4/240 C#3/240 C#4/240 F#3/240 F#4/240 B2/240 B3/240 B2/240 B3/240"
VERSE_HARM   = "E4/230 G#4/230 B4/230 E5/230 D#4/230 F#4/230 B4/230 D#5/230 C#4/230 E4/230 G#4/230 B4/230 B3/230 D#4/230 F#4/230 B4/230"

intro_lead  = parse_seq(INTRO_LEAD)
theme_lead  = parse_seq(THEME_LEAD)
verse_lead  = parse_seq(VERSE_LEAD)
theme_harm  = parse_seq(THEME_HARM)
verse_harm  = parse_seq(VERSE_HARM)

lead_rom   = intro_lead + theme_lead + theme_lead + verse_lead + verse_lead
harm_rom   = [(0,4)]*16 + theme_harm*4 + verse_harm*4

# Expand ROMs into (note_id, duration_in_samples) pairs
def expand(rom):
    result = []
    for nid, units in rom:
        samples = round(units * UNIT_S * SAMPLE_RATE)
        result.append((nid, samples))
    return result

lead_exp = expand(lead_rom)
harm_exp = expand(harm_rom)

def render(expanded_seq, volume=0.3):
    out = []
    for nid, n_samples in expanded_seq:
        freq = FREQ[nid]
        if freq == 0:
            out.extend([0.0] * n_samples)
        else:
            period = SAMPLE_RATE / freq
            for i in range(n_samples):
                # Square wave
                out.append(volume if (i % period) < (period / 2) else -volume)
    return out

lead_audio = render(lead_exp, volume=0.35)
harm_audio = render(harm_exp, volume=0.25)

# Mix
total = max(len(lead_audio), len(harm_audio))
lead_audio  += [0.0] * (total - len(lead_audio))
harm_audio  += [0.0] * (total - len(harm_audio))
mixed = [max(-1.0, min(1.0, l + h)) for l, h in zip(lead_audio, harm_audio)]

# Write WAV
with wave.open('/tmp/nyan_cat.wav', 'w') as wf:
    wf.setnchannels(1)
    wf.setsampwidth(2)
    wf.setframerate(SAMPLE_RATE)
    for s in mixed:
        wf.writeframes(struct.pack('<h', int(s * 32767)))

total_s = total / SAMPLE_RATE
print(f"Written /tmp/nyan_cat.wav  ({total} samples, {total_s:.1f} s)")
