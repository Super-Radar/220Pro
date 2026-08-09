function adc = unpack_uint32_adc(packedWords, samplesPerChirp, chirpCount)
%UNPACK_UINT32_ADC Convert packed uint32 words to signed int16 ADC samples.
% High 16 bits are the earlier sample; low 16 bits are the later sample.

wordMatrix = reshape(packedWords, samplesPerChirp / 2, chirpCount);
highWord = double(bitshift(wordMatrix, -16));
lowWord = double(bitand(wordMatrix, uint32(65535)));
highWord(highWord >= 32768) = highWord(highWord >= 32768) - 65536;
lowWord(lowWord >= 32768) = lowWord(lowWord >= 32768) - 65536;

adc = zeros(samplesPerChirp, chirpCount);
adc(1:2:end, :) = highWord;
adc(2:2:end, :) = lowWord;
end
