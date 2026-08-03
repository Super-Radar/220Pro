function digest = sha256_file(file_path)
%SHA256_FILE Return the lowercase SHA-256 digest of one file's exact bytes.

if ~exist(file_path, 'file')
    error('a100:HashFileNotFound', 'Cannot hash missing file: %s', file_path);
end
fid = fopen(file_path, 'rb');
if fid < 0
    error('a100:HashFileOpenFailed', 'Could not open file for hashing: %s', file_path);
end
cleanup = onCleanup(@() fclose(fid));

if usejava('jvm')
    message_digest = javaMethod('getInstance', ...
        'java.security.MessageDigest', 'SHA-256');
    while true
        bytes = fread(fid, 1024 * 1024, '*uint8');
        if isempty(bytes)
            break;
        end
        message_digest.update(typecast(bytes(:), 'int8'));
    end
    digest_bytes = typecast(message_digest.digest(), 'uint8');
    digest = lower(reshape(dec2hex(digest_bytes, 2).', 1, []));
elseif exist('OCTAVE_VERSION', 'builtin') && exist('hash', 'builtin') == 5
    bytes = fread(fid, Inf, '*uint8');
    digest = lower(hash('sha256', char(bytes.')));
else
    error('a100:Sha256Unavailable', ...
        'SHA-256 verification requires a JVM or the GNU Octave hash function.');
end
clear cleanup;
end
