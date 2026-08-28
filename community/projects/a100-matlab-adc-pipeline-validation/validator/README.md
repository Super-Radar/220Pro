# Independent numerical validation

`run_reference_validation.py` loads the repository HXX files and mirrors the
guarded MATLAB ADC unpacking, Range FFT, raw Doppler FFT, four-RX integration
and CA-CFAR equations with NumPy.

The validation deliberately does not turn unresolved DDMA bins into physical
velocity or angle. Generated CSV files retain raw Doppler bins and leave
`velocity_mps` and `angle_deg` empty with `kinematics_valid=False`.
It also performs no slow-time mean subtraction or center-bin suppression,
because unresolved DDMA coding means the combined spectrum center is not a
known physical zero-velocity location.

The validator includes a regression check for a target on the periodic Doppler
boundary. Range-of-interest filtering is applied only after the CFAR noise map
has been estimated.

Run from the repository root:

```powershell
python "community/projects/a100-matlab-adc-pipeline-validation/validator/run_reference_validation.py"
```

Validated environment for the committed results:

- Python 3.10.12
- NumPy 2.2.6
- Pillow 12.3.0

Expected cube dimensions:

| Profile | HXX source | ADC cube | Raw Range-Doppler cube |
|---|---|---:|---:|
| near | `sensor_config_init1.hxx` | 2048 x 128 x 4 | 1024 x 128 x 4 |
| far | `sensor_config_init0.hxx` | 1024 x 256 x 4 | 512 x 256 x 4 |

## Native MATLAB cross-validation

MATLAB R2026a completed `main('near')` and `main('far')` on a GitHub-hosted
Ubuntu runner. The resulting detection rows were compared against these NumPy
reference CSV files: raw Doppler bins matched exactly, while maximum range and
power differences were below `5e-14 m` and `5e-13 dB`. Run metadata and the
public workflow URL are recorded in `results/matlab-r2026a-validation.txt`.
