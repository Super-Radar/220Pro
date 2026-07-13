# Independent numerical validation

`run_reference_validation.py` mirrors the documented unpacking, Range FFT,
Doppler FFT, four-RX integration, 2-D CA-CFAR and spatial FFT equations with
NumPy. It processes both public profiles and writes deterministic reference
figures and detection tables under `results/near/` and `results/far/`.

This is deliberately labelled as an independent reference check. It validates
data dimensions, axes, finite numerical output and end-to-end processing, but
does not claim that MATLAB itself was executed.

Run from the repository root:

```powershell
python "ADC数据采集/matlab_adc_pipeline/validation/run_reference_validation.py"
```

Validated environment for the committed results:

- Python 3.12.13
- NumPy 2.3.5
- Pillow 12.2.0

Expected cube dimensions:

| Profile | ADC cube | Range-Doppler cube |
|---|---:|---:|
| near | 2048 x 128 x 4 | 1024 x 128 x 4 |
| far | 1024 x 256 x 4 | 512 x 256 x 4 |
