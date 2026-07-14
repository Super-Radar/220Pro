# CTSAI-A100 MATLAB ADC signal-processing chain

## Purpose and scope

The example under `ADC数据采集/matlab_adc_pipeline/` is a transparent,
reproducible reference implementation for learning and secondary development.
It turns the repository's public ADC captures into a range spectrum,
Range-Doppler map, CFAR detections and a basic angle estimate. It is not a
replacement for production firmware and its output is not a product-performance
commitment.

## Input data

Each profile contains four text files, one for each receive channel. A file has
one leading metadata field and 131072 payload words. Every payload word stores
two consecutive two's-complement signed 16-bit ADC samples:

```text
uint32 word = [earlier int16 sample][later int16 sample]
```

The far profile reshapes the payload as 512 packed words by 256 chirps. The
near profile uses 1024 packed words by 128 chirps. Unpacking doubles the sample
dimension. The loader checks the exact payload size and fails explicitly rather
than truncating or zero-padding a malformed capture.

## Processing flow

```text
four RX text files
  -> uint32/int16 unpacking
  -> per-chirp DC removal and range window
  -> Range FFT
  -> slow-time mean clutter removal and Doppler window
  -> Doppler FFT and fftshift
  -> four-RX noncoherent power integration
  -> 2-D CA-CFAR and local-maximum suppression
  -> range/velocity table and four-RX spatial-FFT angle estimate
```

### Range FFT

For each chirp and receive channel, a Hann window reduces sidelobes before the
fast-time FFT. For a linear FMCW sweep, beat frequency is proportional to
range. With sweep bandwidth `B`, the ideal range resolution is approximately
`c/(2B)`. The plotted FFT-bin spacing additionally accounts for ADC sample
rate, chirp slope and zero padding. Only the positive half of the FFT is
retained for real ADC input.

### Doppler FFT

For every range bin, the slow-time samples across chirps are mean-subtracted,
windowed and transformed. `fftshift` places zero radial velocity at the center.
The velocity scale follows wavelength, chirp repetition period and coherent
chirp count.

### CA-CFAR

The detector estimates local noise from a rectangular ring of training cells.
Guard cells around the cell under test reduce target-energy leakage. The
threshold multiplier is derived from the requested false-alarm probability.
After thresholding, a 3-by-3 local-maximum test prevents one target from
producing a cluster of adjacent output rows.

### Angle estimate

The example takes the complex values from four RX channels at a detected range
cell and applies a spatial FFT. In the absence of published calibrated virtual
array geometry, it explicitly assumes a uniform half-wavelength four-RX array.
Consequently, this column demonstrates the processing interface but must not be
interpreted as calibrated product azimuth.

## Outputs

The main script saves four figures, a CSV detection table and a MAT file. The
CSV columns are range in metres, radial velocity in metres per second, estimated
angle in degrees and integrated power in dB. Saving the full intermediate MAT
structure makes parameter changes and regression comparisons easier.

## Reproduction

Call `run_ctsai_a100_demo('near')` and `run_ctsai_a100_demo('far')` from the
`ADC数据采集/matlab_adc_pipeline/` directory. Each profile writes to a separate
results subdirectory containing figures, a detection table and the saved
processing workspace.

## Boundaries

Results depend on the capture scene, waveform configuration, mounting,
calibration and processing parameters. This reference deliberately avoids
claims about maximum detection range, accuracy, false-alarm rate or field
performance.

## Independent reference validation

The `ADC数据采集/matlab_adc_pipeline/validation/` directory contains a NumPy
implementation of the same public-data unpacking and signal-processing equations.
It is intended to catch data-shape, axis and finite-value regressions when MATLAB
is unavailable. Its output is independent reference evidence and is not described
as native MATLAB execution.
