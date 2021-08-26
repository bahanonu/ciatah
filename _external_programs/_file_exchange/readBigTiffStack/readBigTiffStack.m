function imStack = readBigTiffStack(imStackFileName);
info = imfinfo(imStackFileName);
stripOffset = [info.StripOffsets];
stripByteCounts = [info.StripByteCounts];
fID = fopen (imStackFileName, 'r');
imStack = uint16(zeros([1024 1024 3000]));
startPoint = [stripOffset(1) + [0:1:2999].*stripByteCounts];
nTile = numel(info);
for iTile = 1:nTile
    fprintf ('iTile = %d\n', iTile);
    fseek (fID, startPoint(iTile)+1, 'bof'); 
    A = fread (fID, [1024 1024], 'uint16=>uint16');
    imStack(:,:,iTile) = A';
    %B = imread (imStackFileName, iTile); 
    %figure(1); imagesc (A'); figure(2); imagesc (B);
    %pause;
end
