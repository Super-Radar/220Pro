function ensure_directory(folderPath)
%ENSURE_DIRECTORY Create a folder when it does not exist.
if ~isfolder(folderPath)
    mkdir(folderPath);
end
end
