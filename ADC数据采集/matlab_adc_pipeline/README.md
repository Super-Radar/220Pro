# CTSAI-A100 MATLAB ADC signal-processing example

This example provides one reproducible entry point from the public CTSAI-A100
ADC text files to range and raw-Doppler diagnostic results. It loads the
repository HXX configuration and prevents unsupported physical velocity or angle
claims when DDMA metadata is incomplete.

## Features

- reads all four public RX files and validates their lengths;
- unpacks two signed 16-bit ADC samples from every stored 32-bit word;
- loads the public near- and far-range HXX profile parameters;
- performs DC removal, Hann windowing, Range FFT and Doppler FFT;
- integrates the four RX channels noncoherently;
- detects targets with a toolbox-independent 2-D CA-CFAR implementation;
- validates RX-file count and payload dimensions against the selected profile;
- exports raw Doppler bins while DDMA phase/offset metadata is unavailable;
- keeps physical velocity and angle as `NaN` instead of reporting undecoded data;
- exports PNG figures, a CSV target table, configuration report and MAT file.

## Requirements

- MATLAB R2020b or later is recommended;
- only base MATLAB functions are used;
- no absolute paths and no private data are used.

## Run

Add this directory to the MATLAB path or make it the current directory, then run:

```matlab
run_ctsai_a100_demo('near');
run_ctsai_a100_demo('far');
```

Results are written to `results/near/` and `results/far/`:

- `01_range_spectrum.png`
- `02_raw_range_doppler_map.png`
- `03_raw_cfar_detections.png`
- `04_processing_status.png`
- `detections.csv`
- `configuration_report.txt`
- `processing_result.mat`

## Configuration consistency and DDMA boundary

The public HXX files expose TDM-style `tx_groups`, while review feedback
identified DDMA structure in the public captures. Correct DDMA separation and
physical velocity/angle recovery require TX masks, per-chirp phase coding,
Doppler-bin offsets, initial phase, DDMA chirp timing, ambiguity-resolution
rules, virtual-channel ordering and TX/DDMA calibration status.

Those fields are not present in the public repository. Consequently, the second
FFT axis is currently exported as raw Doppler bins. CA-CFAR is applied as a
spectrum diagnostic; `velocity_mps`, `angle_deg` and `kinematics_valid` clearly
show that calibrated kinematics were not produced.

## Known limitations

- The public capture is processed as one frame; multi-frame tracking is not
  implemented.
- DDMA decoding and calibrated virtual-array angle output are disabled until
  the required metadata is publicly available.
- Static-clutter suppression uses slow-time mean subtraction.
- This example does not implement proprietary interference cancellation,
  phase calibration, velocity ambiguity resolution or product firmware logic.

See `../../docs/CTSAI-A100_MATLAB_ADC_processing.md` for algorithm details.
Independent NumPy reference results are documented under `validation/`.
