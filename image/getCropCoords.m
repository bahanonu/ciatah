function [coords] = getCropCoords(thisFrame,varargin)
	% GUI to allow users to select crop coordinates.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
	% TODO
		%

	%========================
	% name of HDF5 dataset name to load
	options.inputDatasetName = '/1';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		% figure(1110);
		% imagesc(thisFrame);colormap gray;
		% p = ginput(2);
		% % Get the x and y corner coordinates as integers
		% coords(1) = min(floor(p(1)), floor(p(2))); %xmin
		% coords(2) = min(floor(p(3)), floor(p(4))); %ymin
		% coords(3) = max(ceil(p(1)), ceil(p(2)));   %xmax
		% coords(4) = max(ceil(p(3)), ceil(p(4)));   %ymax

		% ========================
		% get the movie
		if strcmp(class(thisFrame),'char')|strcmp(class(thisFrame),'cell')
			thisFrame = loadMovieList(thisFrame,'convertToDouble',0,'frameList',1:2,'inputDatasetName',options.inputDatasetName);
			thisFrame = squeeze(thisFrame(:,:,1));
		end

		% get a crop of the input region
		[~,~] = openFigure(9, '');
		clf;
		subplot(1,2,1);
			imagesc(thisFrame);
			axis image;
			box off
			colormap gray;
			title('Select region to crop')

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
		[~, ~] = openFigure(9, '');
			subplot(1,2,2);
			imagesc(thisFrameCropped);
			axis image;
			box off
			colormap gray;
			title('cropped region');
			drawnow;
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end