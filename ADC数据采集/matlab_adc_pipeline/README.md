# CTSAI-A100 MATLAB ADC signal-processing example

This example provides one reproducible entry point from the public CTSAI-A100
ADC text files to range, velocity, CA-CFAR and teaching-level angle results.

## Features

- reads all four public RX files and validates their lengths;
- unpacks two signed 16-bit ADC samples from every stored 32-bit word;
- supports the public near- and far-range profiles;
- performs DC removal, Hann windowing, Range FFT and Doppler FFT;
- integrates the four RX channels noncoherently;
- detects targets with a toolbox-independent 2-D CA-CFAR implementation;
- estimates a teaching-level arrival angle with a four-RX spatial FFT;
- exports PNG figures, a CSV target table and a MAT result file.

## Requirements

- MATLAB R2020b or later is recommended;
- only base MATLAB functions are used;
- no absolute paths and no private data are used.

## Run

1. Open `run_ctsai_a100_demo.m` in MATLAB.
2. Set `profileName` to `near` or `far`.
3. Click **Run**.

The script resolves every path relative to its own location, so MATLAB's
working directory does not need to be changed. Generated files are placed in
`results/`:

- `01_range_spectrum.png`
- `02_range_doppler_map.png`
- `03_cfar_detections.png`
- `04_angle_range.png`
- `detections.csv`
- `processing_result.mat`

## Parameter tuning

CFAR parameters are in `functions/ctsai_config.m`. The defaults are intended
for demonstrating the processing chain rather than claiming product-level
detection performance. For a real scene, tune training cells, guard cells,
false-alarm probability and valid range while keeping an untouched evaluation
capture.

## Known limitations

- The public capture is processed as one frame; multi-frame tracking is not
  implemented.
- Angle estimation assumes four uniformly spaced RX elements at half a
  wavelength. The repository does not currently publish the full calibrated
  virtual-array geometry, so angle output is an educational estimate, not a
  calibrated CTSAI-A100 product measurement.
- Static-clutter suppression uses slow-time mean subtraction.
- This example does not implement proprietary interference cancellation,
  phase calibration, velocity ambiguity resolution or product firmware logic.

See `../../docs/CTSAI-A100_MATLAB_ADC_processing.md` for algorithm details.
