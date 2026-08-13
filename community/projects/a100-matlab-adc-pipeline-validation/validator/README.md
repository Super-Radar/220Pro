# Independent numerical validation

`run_reference_validation.py` loads the repository HXX files and mirrors the
guarded MATLAB ADC unpacking, Range FFT, raw Doppler FFT, four-RX integration
and CA-CFAR equations with NumPy.

The validation deliberately does not turn unresolved DDMA bins into physical
velocity or angle. Generated CSV files retain raw Doppler bins and leave
`velocity_mps` and `angle_deg` empty with `kinematics_valid=False`.

Run from the repository root:

```powershell
python "community/projects/a100-matlab-adc-pipeline-validation/validator/run_reference_validation.py"
```

Validated environment for the committed results:

- Python 3.12.13
- NumPy 2.3.5
- Pillow 12.2.0

Expected cube dimensions:

| Profile | HXX source | ADC cube | Raw Range-Doppler cube |
|---|---|---:|---:|
| near | `sensor_config_init1.hxx` | 2048 x 128 x 4 | 1024 x 128 x 4 |
| far | `sensor_config_init0.hxx` | 1024 x 256 x 4 | 512 x 256 x 4 |
