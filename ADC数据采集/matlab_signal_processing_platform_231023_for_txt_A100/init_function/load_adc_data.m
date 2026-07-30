function adcData = load_adc_data(file, Cfg)
%LOAD_ADC_DATA Legacy-compatible ADC loader for SISO/TDM profiles.
% The original implementation treated header values as ADC payload and
% silently truncated/padded data. This wrapper uses the validated loader.

ioOpts.strict_header = true;
ioOpts.allow_zero_pad = false;
[adcRxCube, ~] = load_adc_dataset(file, Cfg, ioOpts);

switch upper(Cfg.mimo.mode)
    case 'SISO'
        adcData = adcRxCube;
    case 'TDM'
        % Chirp selection commutes with Range FFT for TDM, so legacy callers
        % may still organize the real ADC cube here.
        adcData = organize_virtual_array(adcRxCube, Cfg, 'block');
    otherwise
        error(['Legacy load_adc_data cannot decode %s. Run main.m so DDMA ' ...
            'demodulation occurs after Range FFT.'], Cfg.mimo.mode);
end
end
