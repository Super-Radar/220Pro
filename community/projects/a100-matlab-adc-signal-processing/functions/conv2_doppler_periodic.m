function result = conv2_doppler_periodic(data, kernel)
%CONV2_DOPPLER_PERIODIC 仅在 Doppler 维周期延拓后执行二维卷积。
% Range 维仍使用 conv2 的零填充边界，避免把不同距离端点相连。
halfD = floor(size(kernel,2) / 2);
numDoppler = size(data,2);
wrappedDoppler = mod((-halfD:numDoppler+halfD-1), numDoppler) + 1;
padded = data(:, wrappedDoppler);
convolved = conv2(padded, kernel, 'same');
result = convolved(:, halfD+(1:numDoppler));
end
