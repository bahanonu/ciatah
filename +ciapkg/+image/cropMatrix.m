function [inputMatrix, coords] = cropMatrix(inputMatrix,varargin)
	% Crops a matrix either by removing rows or adding NaNs to where data was previously.
	% Automatic version to detect boundaries after motion correction and add borders accordingly.
	% Biafra Ahanonu
	% 2014.01.23 [16:06:01]
	% inputs
		% inputMatrix - a [m n p] matrix of any class type.
	% outputs
		% inputMatrix - cropped or NaN'd matrix, same name to reduce memory usage.
	% changelog
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals].
		% 2021.04.18 [14:42:53] - Updated to make imrect the default method of selecting the coordinates.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2021.09.28 [10:37:12] - Updated to allow specifying the size of the rectangle.
		% 2023.10.01 [22:32:11] - Update to callback.
		% 2024.03.11 [21:04:57] - Added support for automatic detection of crop borders from main pre-processing functions. Remove workspace unpacking of options.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Str: 'manual' or 'auto'
	options.cropType = 'manual';
	% Str: 'NaN' to add a NaN border, 'crop' to reduce the dimensions of the input matrix.
	options.cropOrNaN = 'NaN';
	% Int vector: input coordinates as [left-column top-row right-column bottom-row]
	options.inputCoords = [];
	% Int: amount of pixels around the border to crop in primary movie
	options.pxToCrop = 0;
    % Str: title to add.
    options.title = 'Select a region';
    % Int: figure number to open for GUI cropping.
    options.figNo = 142568;
    % Vector: [xmin ymin xmax ymax]
    options.rectPos = [];
    % Str: 'NaN' or 'zero' for type of value used by registration function to fill space after motion correction.
    options.registrationFillValue = 'NaN';
    % Str: 'identical' = all dimensions get cropped to the max movement in any one side, 'perSide' = crop only to max movement on a given side.
    options.autoCropType = 'perSide';
    % 
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	if strcmp(options.cropType,'auto')
		removeInputMovieEdges();
		return;
	end

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
		% [coords] = getCropCoords(thisFrame,options)

		h = subfxn_getImRect(thisFrame,options.title,options);
		p = round(wait(h));

		% Get the x and y corner coordinates as integers
		coords(1) = p(1); %xmin
		coords(2) = p(2); %ymin
		coords(3) = p(1)+p(3); %xmax
		coords(4) = p(2)+p(4); %ymax
	else
		coords = options.inputCoords;
	end
	disp('cropping matrix...');
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
	function removeInputMovieEdges()
		% turboreg outputs 0s where movement goes off the screen
		thisMovieMinMask = zeros([size(inputMatrix,1) size(inputMatrix,2)]);
		switch options.registrationFillValue
			case 'NaN'
				reverseStr = '';
				for row=1:size(inputMatrix,1)
					% thisMovieMinMask(row,:) = logical(max(isnan(squeeze(inputMatrix(3,:,:))),[],2,'omitnan'));
					thisMovieMinMask(row,:) = logical(max(isnan(squeeze(inputMatrix(row,:,:))),[],2,'omitnan'));
					reverseStr = cmdWaitbar(row,size(inputMatrix,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
				end
			case 'zero'
				reverseStr = '';
				for row=1:size(inputMatrix,1)
					thisMovieMinMask(row,:) = logical(min(squeeze(inputMatrix(row,:,:))~=0,[],2,'omitnan')==0);
					reverseStr = cmdWaitbar(row,size(inputMatrix,1),reverseStr,'inputStr','getting crop amount','waitbarOn',1,'displayEvery',5);
				end
			otherwise
				% do nothing
		end
		topVal = sum(thisMovieMinMask(1:floor(end/4),floor(end/2)));
		bottomVal = sum(thisMovieMinMask(end-floor(end/4):end,floor(end/2)));
		leftVal = sum(thisMovieMinMask(floor(end/2),1:floor(end/4)));
		rightVal = sum(thisMovieMinMask(floor(end/2),end-floor(end/4):end));
		tmpPxToCrop = max([topVal bottomVal leftVal rightVal]);
		pxToCropPreprocess = tmpPxToCrop;
		display(['[topVal bottomVal leftVal rightVal]: ' num2str([topVal bottomVal leftVal rightVal])])

		% Get the crop regions.
		switch options.autoCropType
			case 'perSide'
				topRowCrop = topVal; % top row
				leftColCrop = leftVal; % left column
				bottomRowCrop = size(inputMatrix,1)-bottomVal; % bottom row
				rightColCrop = size(inputMatrix,2)-rightVal; % right column
			case 'identical'
				topRowCrop = pxToCropPreprocess; % top row
				leftColCrop = pxToCropPreprocess; % left column
				bottomRowCrop = size(inputMatrix,1)-pxToCropPreprocess; % bottom row
				rightColCrop = size(inputMatrix,2)-pxToCropPreprocess; % right column
			otherwise
				% do nothing
		end

		% rowLen = size(inputMatrix,1);
		% colLen = size(inputMatrix,2);
		% set leftmost columns to NaN
		inputMatrix(1:end,1:leftColCrop,:) = NaN;
		% set rightmost columns to NaN
		inputMatrix(1:end,rightColCrop:end,:) = NaN;
		% set top rows to NaN
		inputMatrix(1:topRowCrop,1:end,:) = NaN;
		% set bottom rows to NaN
		inputMatrix(bottomRowCrop:end,1:end,:) = NaN;
	end
end
function [coords] = getCropCoords(thisFrame,options)
	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	figure(options.figNo);
	subplot(1,2,1);
	imagesc(thisFrame);
    axis image;
    colormap parula;
    title('Select a region. Double click region to continue.')
    box off;

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
function h = subfxn_getImRect(thisFrame,titleStr,options)
	import ciapkg.api.* % import CIAtah functions in ciapkg package API.
	
	% close(142568)
	figure(options.figNo);
	clf
	subplot(1,2,1);
		imagesc(thisFrame);
		axis image;
		% colormap parula;
		title(titleStr)
        box off;

	if isempty(options.rectPos)
		h = imrect(gca);
	else
		% [xmin ymin width height]
		pos = options.rectPos;
		h = imrect(gca,[pos(1) pos(2) pos(3)-pos(1) pos(4)-pos(2)]);
	end
	addNewPositionCallback(h,@(p) title([titleStr 10 mat2str(p,5) ' | ' num2str([p(3)-p(1) p(4)-p(2)])]));
	fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));
	setPositionConstraintFcn(h,fcn);
end