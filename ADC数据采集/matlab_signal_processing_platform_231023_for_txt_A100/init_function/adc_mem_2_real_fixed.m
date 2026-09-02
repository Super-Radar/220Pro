function ADC = adc_mem_2_real_fixed (ADC_mem)
  % Descriptions:
  % Convert 32bit ADC data read from memory to 2 consecutive real valued fixed 16bit point data. 
  % 32bit memory data : earlier 16bit signed sample data + later 16bit signed sample data.
  
  [chirp_num, sample_num_div_2, channel_num] = size(ADC_mem); % Get size of 2 dimensional data matrix
  sample_num = sample_num_div_2*2;
  ADC = zeros(chirp_num, sample_num, channel_num);
  
  for channel_ind = 1:channel_num
    for chirp_ind = 1:chirp_num
      for sample_ind = 2:2:sample_num    
        raw_32b = ADC_mem(chirp_ind, ceil(sample_ind/2), channel_ind);    
        H_16b  = floor( raw_32b/2^16 ); % high 16 bits 
        L_16b  = mod( raw_32b, 2^16 ); % low 16 bits
        
        if (H_16b < 2^15)
            H_16b_sign = H_16b; % positive value
        else
            H_16b_sign = H_16b - 2^16; % negative value, 2's complement
        end
        if (L_16b < 2^15)
            L_16b_sign = L_16b; % positive value
        else
            L_16b_sign = L_16b - 2^16; % negative value, 2's complement
        end
        
        ADC(chirp_ind, sample_ind - 1, channel_ind) = H_16b_sign;
        ADC(chirp_ind, sample_ind, channel_ind) = L_16b_sign;
      end
    end
  end
  
end
