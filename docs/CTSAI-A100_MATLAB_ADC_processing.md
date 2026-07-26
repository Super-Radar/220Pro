# CTSAI-A100 MATLAB ADC signal-processing chain

## Purpose and scope

The example under `ADC数据采集/matlab_adc_pipeline/` is a transparent,
reproducible reference implementation for learning and secondary development.
It converts the public ADC captures into a range spectrum, raw Range-Doppler
diagnostic map and CA-CFAR diagnostic detections. It does not present undecoded
DDMA bins as physical velocity or calibrated angle.

## Input data and configuration

Each profile contains four text files, one for each receive channel. A file has
one leading metadata field and 131072 payload words. Every payload word stores
two consecutive two's-complement signed 16-bit ADC samples:

```text
uint32 word = [earlier int16 sample][later int16 sample]
```

The far profile reshapes the payload as 512 packed words by 256 chirps. The near
profile uses 1024 packed words by 128 chirps. The implementation loads waveform,
FFT, TX-group and antenna fields directly from the repository's
`sensor_config_init0.hxx` and `sensor_config_init1.hxx` files. It validates the
RX-file count and payload size instead of silently truncating or padding data.

## Processing flow

```text
four RX text files + official HXX profile
  -> uint32/int16 unpacking and dimension validation
  -> per-chirp DC removal and range window
  -> Range FFT
  -> slow-time mean removal and Doppler window
  -> raw Doppler FFT and fftshift
  -> four-RX noncoherent power integration
  -> 2-D CA-CFAR and local-maximum suppression
  -> range/raw-Doppler-bin table
  -> physical velocity/angle validity guard
```

## Range FFT

For each chirp and receive channel, a Hann window reduces sidelobes before the
fast-time FFT. For a linear FMCW sweep, beat frequency is proportional to range.
With sweep bandwidth `B`, the ideal range resolution is approximately `c/(2B)`.
The plotted FFT-bin spacing also accounts for ADC sample rate, chirp slope and
FFT length. Only the positive half is retained for real ADC input.

## Doppler FFT and DDMA validity

For every range bin, the slow-time samples are mean-subtracted, windowed and
transformed. `fftshift` places the zero raw Doppler bin at the center. A nominal
TDM velocity scale can be derived from wavelength, chirp period and coherent
chirp count, but review feedback identified DDMA structure in the public capture
that is not described by the public TDM-style `tx_groups`. The example therefore
retains raw Doppler-bin indices and does not export the nominal TDM scale as
measured velocity.

Correct DDMA separation and kinematic recovery require the following public
metadata:

1. TX enable mask;
2. per-TX per-chirp phase code or phase increment;
3. DDMA Doppler-bin offset;
4. initial phase;
5. DDMA chirp repetition interval definition;
6. integer/non-integer Doppler-bin coding flag;
7. velocity ambiguity resolution design;
8. TX/RX coordinates mapped to the virtual-channel order;
9. TX/DDMA phase calibration status.

## CA-CFAR

The detector estimates local noise from a rectangular ring of training cells.
Guard cells reduce target-energy leakage. The threshold multiplier is derived
from the configured false-alarm probability. A 3-by-3 local-maximum test prevents
one response from producing a cluster of adjacent output rows. For the current
capture this is explicitly a raw-spectrum diagnostic.

## Angle FFT

`estimate_angle_fft.m` implements a generic ULA spatial FFT. It is not applied to
the public capture because a valid complex virtual-array snapshot cannot be
formed without DDMA TX separation, virtual-channel ordering and TX phase
calibration. `angle_deg` therefore remains `NaN`; this avoids presenting an
assumed four-RX array result as calibrated CTSAI-A100 azimuth.

## Outputs

The main function saves four diagnostic figures, a CSV table, a configuration
report and a MAT workspace. CSV columns are:

- `range_m`
- `doppler_bin`
- `velocity_mps` (`NaN` while DDMA is unresolved)
- `angle_deg` (`NaN` while DDMA is unresolved)
- `power_db`
- `kinematics_valid`
- `processing_status`

The configuration report records the exact HXX source, published TX groups and
missing DDMA metadata.

## Reproduction

From `ADC数据采集/matlab_adc_pipeline/`, run:

```matlab
run_ctsai_a100_demo('near');
run_ctsai_a100_demo('far');
```

Each profile writes to its own results subdirectory.

## Current implementation boundaries

Results depend on capture scene, waveform configuration, MIMO coding, mounting,
calibration and processing parameters. This reference does not claim physical
velocity, azimuth, maximum detection range, accuracy, false-alarm performance or
product firmware equivalence for the unresolved public DDMA capture.

## Extensions supported by the design

The separated configuration loader, DDMA validity flags and generic angle FFT
allow documented DDMA decoding, calibrated virtual-array formation and velocity
ambiguity resolution to be connected without changing the ADC/FFT/CFAR stages
once the required public metadata is available.

## Independent reference validation

`ADC数据采集/matlab_adc_pipeline/validation/` contains a NumPy implementation of
the same HXX loading, ADC unpacking and diagnostic FFT/CFAR equations. It checks
data shapes, configuration consistency and finite output without claiming native
MATLAB execution.
