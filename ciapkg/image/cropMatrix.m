function [inputMatrix] = cropMatrix(inputMatrix,varargin)
	% Crops a matrix either by removing rows or adding NaNs to where data was previously.
	% Biafra Ahanonu
	% 2014.01.23 [16:06:01]
	% inputs
		% inputMatrix - a [m n p] matrix of any class type
	% outputs
		% inputMatrix - cropped or NaN'd matrix, same name to reduce memory usage
	% changelog
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
	% TODO
		%

	%========================
	options.cropOrNaN = 'NaN';
	% input coordinates: [left-column top-row right-column bottom-row]
	options.inputCoords = [];
	% amount of pixels around the border to crop in primary movie
	options.pxToCrop = 0;

	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
		eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================

	if options.pxToCrop>0
		if size(inputMatrix,2)>=size(inputMatrix,1)
			coords(1) = options.pxToCrop; %xmin
			coords(2) = options.pxToCrop; %ymin
			coords(3) = size(inputMatrix,1)-options.pxToCrop;   %xmax
			coords(4) = size(inputMatrix,2)-options.pxToCrop;   %ymax
		else
			coords(1) = options.pxToCrop; %xmin
			coords(2) = options.pxToCrop; %ymin
			coords(4) = size(inputMatrix,1)-options.pxToCrop;   %xmax
			coords(3) = size(inputMatrix,2)-options.pxToCrop;   %ymax
		end
	elseif isempty(options.inputCoords)
        %figure(102020); colormap gray;
		thisFrame = squeeze(inputMatrix(:,:,round(end/2)));
		[coords] = getCropCoords(thisFrame)
	else
		coords = options.inputCoords;
	end
	display('cropping matrix...');
	switch options.cropOrNaN
		case 'NaN'
			rowLen = size(inputMatrix,1);
			colLen = size(inputMatrix,2);
			% a,b are left/right column values
			a = coords(1);
			b = coords(3);
			% c,d are top/bottom row values
			c = coords(2);
			d = coords(4);
			% set those parts of the movie to NaNs
			inputMatrix(1:rowLen,1:a,:) = NaN;
			inputMatrix(1:rowLen,b:colLen,:) = NaN;
			inputMatrix(1:c,1:colLen,:) = NaN;
			inputMatrix(d:rowLen,1:colLen,:) = NaN;
		case 'crop'
			inputMatrix = inputMatrix(coords(2):coords(4), coords(1):coords(3),:);
		otherwise
			return
	end
end
function [coords] = getCropCoords(thisFrame)
	figure(9);
	subplot(1,2,1);
	imagesc(thisFrame);
    axis image;
    colormap parula;
    title('select region')

	% Use ginput to select corner points of a rectangular
	% region by pointing and clicking the subject twice
	p = ginput(2);

	% Get the x and y corner coordinates as integers
	coords(1) = min(floor(p(1)), floor(p(2))); %xmin
	coords(2) = min(floor(p(3)), floor(p(4))); %ymin
	coords(3) = max(ceil(p(1)), ceil(p(2)));   %xmax
	coords(4) = max(ceil(p(3)), ceil(p(4)));   %ymax

	% Index into the original image to create the new image
	thisFrameCropped = thisFrame(coords(2):coords(4), coords(1): coords(3));

	% Display the subsetted image with appropriate axis ratio
	figure(9);subplot(1,2,2);imagesc(thisFrameCropped); axis image; colormap gray; title('cropped region');drawnow;
end