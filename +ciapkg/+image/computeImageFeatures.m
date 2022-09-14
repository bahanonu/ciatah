function [imgStats] = computeImageFeatures(inputImages, varargin)
	% [imgStats] = computeImageFeatures(inputImages, varargin)
	% 
	% Filters large and small objects in an set of images, returns filtered matricies along with vector with decisions and sizes.
	% 
	% Biafra Ahanonu
	% 2013.10.31
	% based on SpikeE code
	% 
	% inputs
	%   inputImages - [x y nSignals]
	% 
	% outputs
	%   imgStats -
	% 
	% options
	%   minNumPixels
	%   maxNumPixels
	%   thresholdImages

	% changelog
		% updated: 2013.11.08 [09:24:12] removeSmallICs now calls a filterImages, name-change due to alteration in function, can slowly replace in codes
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
		% 2019.07.17 [00:29:16] - Added support for sparse input images (mainly ndSparse format).
		% 2019.09.10 [20:51:00] - Converted to parfor and removed unpacking options, bad practice.
		% 2019.10.02 [21:25:36] - Updated addedFeatures support for parfor and allowed this feature to be properly accessed by users.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2022.04.13 [02:28:15] - Make default thresholding fast thresholding.
		% 2022.07.20 [14:42:00] - Improved annotation of code and added options.fastThresholding. Also by default plots are not made. Refactored extra features code and finding centroid to avoid unnecessary function calls, speeding up code.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% get options
	options.minNumPixels = 25;
	options.maxNumPixels = 600;
	options.makePlots = 0;
	options.waitbarOn = 1;
	options.thresholdImages = 1;
	options.threshold = 0.5;
	options.valid = [];
	% options.featureList = {'Eccentricity','EquivDiameter','Area','Orientation','Perimeter','Solidity',};
	options.featureList = {'Eccentricity','EquivDiameter','Area','Orientation','Perimeter'};
	% Whether to calculate non-regionprops
	options.addedFeatures = 0;
	% Input images for add features
	options.addedFeaturesInputImages = [];
	options.runRegionprops = 1;
	% 
	options.xCoords = [];
	options.yCoords = [];
	% 
	options.parforAltSwitch = 0;
	% Binary: 1 = fast thresholding (vectorized), 0 = normal thresholding
	options.fastThresholding = 1;
	% image filter: none, median,
	options.imageFilter = 'none';

	% Binary: 1 = whether to display info on command line.
	options.displayInfo = 1;

	options = getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	parforAltSwitch = options.parforAltSwitch;
	% switch nargin
	% 	case 2
	% 		parforAltSwitch = 1;
	% 	case 1
	% 		% do nothing
	% 	otherwise
	% 		% do nothing
	% end

	nImages = size(inputImages,3);

	% reverseStr = '';
	% decide whether to threshold images
	if options.thresholdImages==1
		if options.addedFeatures==1&&isempty(options.addedFeaturesInputImages)
			options.addedFeaturesInputImages = inputImages;
		end
		inputImages = thresholdImages(inputImages,'waitbarOn',1,'binary',1,'threshold',options.threshold,'fastThresholding',options.fastThresholding,'removeUnconnected',1,'imageFilter',options.imageFilter);
	end

	% Only implement in Matlab 2017a and above
	if ~verLessThan('matlab', '9.2')
		D = parallel.pool.DataQueue;
		afterEach(D, @nUpdateParforProgress);
		p = 1;
		% N = nSignals;
	end
	nInterval = round(nImages/20);

	options_runRegionprops = options.runRegionprops;
	options_featureList = options.featureList;
	options_waitbarOn = options.waitbarOn;

	% loop over images and get their stats
	if options.displayInfo==1
		disp('Computing image features...')
	end
	regionStat = cell([nImages 1]);
	if options_runRegionprops==1
		% ticBytes(gcp)
		parfor imageNo = 1:nImages
			% iImage = squeeze(inputImages(:,:,imageNo));
			% imagesc(iImage)
			% imgStats.imageSizes(imageNo) = sum(iImage(:)>0);
			thisFilt = inputImages(:,:,imageNo);
			if issparse(thisFilt)
				thisFilt = full(thisFilt);
			end
			regionStat{imageNo} = regionprops(thisFilt, options_featureList);
			if ~verLessThan('matlab', '9.2')
				send(D, imageNo); % Update
			end
		end
		% tocBytes(gcp)
		% whos

		% Add region states to the general pool
		if ~verLessThan('matlab', '9.2'); p=1;end
		if options.displayInfo==1
			disp('Adding regionprops features to output...')
		end
		for imageNo = 1:nImages
			for ifeature = options_featureList
				% regionStat = regionprops(iImage, ifeature{1});
				try
					% eval(['imgStats.' ifeature{1} '(imageNo) = regionStat.' ifeature{1} ';']);
					imgStats.(ifeature{1})(imageNo) = regionStat{imageNo}.(ifeature{1});
				catch
					% eval(['imgStats.' ifeature{1} '(imageNo) = NaN;']);
					imgStats.(ifeature{1})(imageNo) = NaN;
				end
			end
			if ~verLessThan('matlab', '9.2')
				send(D, imageNo); % Update
			end
		end
	end


	if ~verLessThan('matlab', '9.2'); p=1;end


	if options.addedFeatures==1
		% get the centroids and other info for movie
		if isempty(options.xCoords)
			[xCoords, yCoords] = findCentroid(inputImages,'waitbarOn',options.waitbarOn,'runImageThreshold',0);
		else
			xCoords = options.xCoords;
			yCoords = options.yCoords;
		end

		if parforAltSwitch==1
			imgKurtosis = NaN([1 nImages]);
			imgSkewness = NaN([1 nImages]);
			if options.displayInfo==1
				disp('Computing alternative image features with parfor...')
			end
			addedFeaturesInputImages = options.addedFeaturesInputImages;
			parfor imageNo = 1:nImages
				thisFilt = addedFeaturesInputImages(:,:,imageNo);
				if issparse(thisFilt)
					thisFilt = full(thisFilt);
				end
				if isnan(xCoords(imageNo))==0
					t1 = getObjCutMovie(thisFilt,thisFilt,'cropSize',30,'createMontage',0,'crossHairsOn',0,'addPadding',1,'waitbarOn',0,'xCoords',xCoords(imageNo),'yCoords',yCoords(imageNo));
					t1 = t1{1};
					imgKurtosis(imageNo) = double(kurtosis(t1(:)));
					imgSkewness(imageNo) = double(skewness(t1(:)));
				else
					imgKurtosis(imageNo) = NaN;
					imgSkewness(imageNo) = NaN;
				end
				if ~verLessThan('matlab', '9.2')
					send(D, imageNo); % Update
				end
			end

			imgStats.imgKurtosis = imgKurtosis;
			imgStats.imgSkewness = imgSkewness;
		else
			if options.displayInfo==1
				disp('Computing alternative image features...')
			end
			for imageNo = 1:nImages
				% iImage2 = squeeze(options.addedFeaturesInputImages(:,:,imageNo));
				% figure(11);imagesc(iImage2);title(num2str(imageNo))
				% [imageNo xCoords(imageNo) yCoords(imageNo)]
				thisFilt = options.addedFeaturesInputImages(:,:,imageNo);
				if issparse(thisFilt)
					thisFilt = full(thisFilt);
				end
				if isnan(xCoords(imageNo))==0
					% t1=getObjCutMovie(options.addedFeaturesInputImages(:,:,imageNo),options.addedFeaturesInputImages(:,:,imageNo),'cropSize',30,'createMontage',0,'crossHairsOn',0,'addPadding',1,'waitbarOn',0,'xCoords',xCoords(imageNo),'yCoords',yCoords(imageNo));
					t1 = getObjCutMovie(thisFilt,thisFilt,'cropSize',30,'createMontage',0,'crossHairsOn',0,'addPadding',1,'waitbarOn',0,'xCoords',xCoords(imageNo),'yCoords',yCoords(imageNo));
					t1 = t1{1};
					imgStats.imgKurtosis(imageNo) = double(kurtosis(t1(:)));
					imgStats.imgSkewness(imageNo) = double(skewness(t1(:)));
				else
					imgStats.imgKurtosis(imageNo) = NaN;
					imgStats.imgSkewness(imageNo) = NaN;
				end
				% imgStats.imgKurtosis(imageNo) = kurtosis(iImage(:));
				% imgStats.imgSkewness(imageNo) = skewness(iImage(:));
				if ~verLessThan('matlab', '9.2')
					send(D, imageNo); % Update
				end
			end
		end
	end

	if options.makePlots==1
		if isfield(imgStats,'Area')==1
			openFigure(1996, '');
				subplot(2,1,1)
				hist(imgStats.Area,round(logspace(0,log10(max(imgStats.Area)))));
				box off;title('distribution of IC sizes');xlabel('area (px^2)');ylabel('count');
				set(gca,'xscale','log');
				h = findobj(gca,'Type','patch');
				set(h,'FaceColor',[0 0 0],'EdgeColor','w');
		end
		if ~isempty(options.valid)
			nPts = 2;
		else
			options.valid = ones(1,nImages);
			nPts = 1;
		end
		pointColors = ['g','r'];
		openFigure(1997, '');
			for pointNum = 1:nPts
				pointColor = pointColors(pointNum);
				if pointNum==1
					valid = logical(options.valid);
				else
					valid = logical(~options.valid);
				end
				openFigure(1997, '');
				fn=fieldnames(imgStats);
				for i=1:length(fn)
					subplot(2,ceil(length(fn)/2),i)
					% eval(['iStat=imgStats.' fn{i} ';']);
					% plot(find(valid),iStat(valid),[pointColor '.'])
					plot(find(valid),imgStats.(fn{i})(valid),[pointColor '.'])
					title(fn{i})
					hold on;box off;
					xlabel('rank'); ylabel(fn{i})
					hold off
				end
			end

	end
	function nUpdateParforProgress(~)
		if ~verLessThan('matlab', '9.2')
			p = p + 1;
			% if (mod(p,nInterval)==0||p==nImages)&&options_waitbarOn==1
			% 	cmdWaitbar(p,nImages,'','inputStr','','waitbarOn',1);
			% end
			if (mod(p,nInterval)==0||p==2||p==nImages)&&options_waitbarOn==1
				if p==nImages
					fprintf('%d\n',round(p/nImages*100))
				else
					fprintf('%d|',round(p/nImages*100))
				end
				% cmdWaitbar(p,nImages,'','inputStr','','waitbarOn',1);
			end
		end
	end
end

% OLD code


% regionStat
% figure;imagesc(inputImages(:,:,imageNo));
% for ifeature = featureList
% 	% regionStat = regionprops(iImage, ifeature{1});
% 	try
% 		% eval(['imgStats.' ifeature{1} '(imageNo) = regionStat.' ifeature{1} ';']);
% 		imgStats.(ifeature{1})(imageNo) = regionStat.(ifeature{1});
% 	catch
% 		% eval(['imgStats.' ifeature{1} '(imageNo) = NaN;']);
% 		imgStats.(ifeature{1})(imageNo) = NaN;
% 	end
% end

% regionStat = regionprops(iImage, 'Eccentricity','EquivDiameter','Area','Orientation','Perimeter','Solidity');
% imgStats.Eccentricity(imageNo) = regionStat.Eccentricity;
% imgStats.EquivDiameter(imageNo) = regionStat.EquivDiameter;
% imgStats.Area(imageNo) = regionStat.Area;
% imgStats.Orientation(imageNo) = regionStat.Orientation;
% imgStats.Perimeter(imageNo) = regionStat.Perimeter;
% imgStats.Solidity(imageNo) = regionStat.Solidity;

% if (imageNo==1||mod(imageNo,10)==0||imageNo==nImages)&&options.waitbarOn==1
% 	reverseStr = cmdWaitbar(imageNo,nImages,reverseStr,'inputStr','computing image features');
% end

% subplot(2,1,1)
% scatter3(imgStats.Eccentricity(valid),imgStats.Perimeter(valid),imgStats.Orientation(valid),[pointColor '.'])
% xlabel('Eccentricity');ylabel('perimeter');zlabel('Orientation');
% rotate3d on;hold on;
% subplot(2,1,2)
% scatter3(imgStats.Area(valid),imgStats.Perimeter(valid),imgStats.Solidity(valid),[pointColor '.'])
% xlabel('area');ylabel('perimeter');zlabel('solidity');
% rotate3d on;hold on;