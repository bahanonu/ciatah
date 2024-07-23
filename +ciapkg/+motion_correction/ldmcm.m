function [mtVideo] = ldmcm(inputMovie,ctrlPtTensor,varargin)
	% [mtVideo] = ldmcm(inputMovie,ctrlPtTensor,varargin)
	% 
	% Conducts LD-MCM analysis (control point registration followed by rigid or non-rigid registration).
	% 
	% Biafra Ahanonu
	% started: 2022.10.29 [13:57:45]
	% 
	% Inputs
	% 	inputMovie - [x y nFrames] tensor with movie data.
	% 	ctrlPtTensor - Tensor with tracking information for each control point
	% 		DeepLabCut - Tensor: format [nFeatures nDlcOutputs nFrames].
	% 
	% Outputs
	% 	mtVideo - [x y nFrames] tensor with motion-corrected movie data.
	% 
	% Options (input as Name-Value with Name = options.(Name))
	% 	% DESCRIPTION
	% 	options.exampleOption = '';

	% Changelog
		% 2022.03.14 [01:47:04] - Added nested and local functions to the example function.
		% 2024.02.18 [18:46:34] - Updated to function and integration within CIAtah.
	% TODO
		%

	% ========================
	% Int: reference frame number.
	options.refFrame = 1;
	% Type of input tensor with control points
	options.controlPointType = 'DeepLabCut';
	% Binary: 1 = run rigid motion correction after control point correction.
	options.runPostReg = 1;
	% Vector: Empty = use all frames input. Else int vector of frames to use.
	options.frameList = [];
	% Binary: 1 = make plots. 0 = do not plot analysis.
	options.makePlots = 0;
	% Vector: List of specific frames to analyze. Empty = analyze all frames in input movie.
	options.frameList = [];
	% Vector: Vector of coordinates in [xmin ymin xmax ymax] to crop to bypass manual.
	options.cropCoordsInSession = [];
	% Int: How much is movie downsampled? Use to compensate coordinates.
	options.dsSpace = 1;
	% DO NOT USE Binary: 1 = rotate image 90 degrees.
	options.rotateImg = 0;
	% Binary: 1 = make color video with control points overlaid.
	options.flagMakeColorVid = 0;
	% Float: Features above this confidence threshold will be incorporated
	options.confThreshold = 0.90;
	% Binary: 1 = run motion correction.
	options.correctMotion = 1;
	% Vector (int): points to explicitly include in the analysis (e.g. [1:3 12 14 16]). Empty = use all control points.
	options.filtPts =  [];
	% Int: maximum distance to allow points to move or be matched.
	options.maxDist = 200;
	% Int: if the number of points less than this value, skip registering that frame. 
	options.minPtsForReg = 2;
	% Binary: whether to pre-process movie before registration. Can prevent artifacts as in the case of FFT-based spatial filtering.
	options.preprocBeforeReg = 0;
	% Matrix: [x y nFrames] matrix for a second movie to use for the final registered movie, e.g. a preprocessed movie. Empty to skip.
	options.inputMovie2 = [];
	% Int: fix this dimension during registration so not considered when doing motion correction, e.g. 1 = x dim, 2 = y dim. Empty to register all dimensions.
	options.dimToFix = [];
	% Str: type of control point motion correction method to use. Available: "rigid", "similarity", "affine", or "projective".
	options.cpRegMethod = 'rigid';
	% Int: maximum number of trials to run control point registration for. 
	options.maxTrials = 1e4;
	% get options
	options = ciapkg.io.getOptions(options,varargin);
	% disp(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	try
		if options.preprocBeforeReg==1
			%% Detrend movie
			figure;plot(squeeze(mean(inputMovie,[1 2],'omitnan')));drawnow

			inputMovieNorm = ciapkg.movie_processing.detrendMovie(single(inputMovie),'detrendDegree',3);

			hold on; plot(squeeze(mean(inputMovie,[1 2],'omitnan')));legend({'Raw','Post-detrend'});drawnow

			disp('Done!')

			%% Normalize movie now, so don't have artifacts later.
			inputMovieNorm = ciapkg.movie_processing.normalizeMovie(...
				inputMovieNorm,...
				'normalizationType','lowpassFFTDivisive',...
				'freqLow',0,'freqHigh',4,...
				'bandpassMask','gaussian');
			disp('Done!')
		else
			if isempty(options.inputMovie2)
				inputMovieNorm = inputMovie;
			else
				inputMovieNorm = options.inputMovie2;
			end
		end

		% ========================
		%% Plot all feature control points
		if options.makePlots==1
			figure;
			imagesc(inputMovie(:,:,100))
			% imagesc(rot90(inputMovie(:,:,1),-1))
				box off
				axis image
				colormap gray
			hold on;
			opts.nFields = size(ctrlPtTensor,1);
			for iz22 = 1:length(opts.nFields)
				x11 = squeeze(featurePtsTensor(iz22,2,:));
				y11 = squeeze(featurePtsTensor(iz22,3,:));
				conf11 = squeeze(featurePtsTensor(iz22,1,:));
				plot(x11(conf11>0.99),y11(conf11>0.99),'.');
			end
		end

		% ========================
		opts.rotateImg = options.rotateImg;
		% opts.rotateImg = 1;
		opts.flagMakeColorVid = 0;
		opts.refIdx = options.refFrame;

		imgRef = inputMovie(:,:,opts.refIdx);
		if opts.rotateImg==1
			imgRef = rot90(imgRef,-1);
		end

		opts.nFramesHere = size(inputMovie,3);
		opts.nFrames = size(inputMovie,3);
		if isempty(options.frameList)
			opts.frameList = 1:opts.nFrames;
		else
			opts.frameList = options.frameList;
		end

		if opts.rotateImg==1
			mtVideo = zeros([size(inputMovie,2) size(inputMovie,1) length(opts.frameList)],class(inputMovie));
		else
			mtVideo = zeros([size(inputMovie,1) size(inputMovie,2) length(opts.frameList)],class(inputMovie));
		end

		if opts.flagMakeColorVid==1
			colorVideo = zeros([size(imgRef,1) size(imgRef,2) 3 opts.nFramesHere],'uint8');
		end

		disp('Done!')

		% ========================
		%% Run control point tracking
		opts.confThreshold = options.confThreshold;
		opts.correctMotion = options.correctMotion;
		opts.dispPlots = options.makePlots;
		frameCount = 1;
		opts.filtPts =  options.filtPts;
		opts.maxDist = options.maxDist;

		% Get the reference control points and associated confidence
		if opts.rotateImg==1
			pointsRef = ctrlPtTensor(:,[3 2],opts.refIdx);
			confRef = ctrlPtTensor(:,1,opts.refIdx);
		else
			pointsRef = ctrlPtTensor(:,[2 3],opts.refIdx);
			confRef = ctrlPtTensor(:,1,opts.refIdx);
		end
		% pointsRef = ctrlPtTensor(:,[2 3],opts.refIdx);
		% confRef = ctrlPtTensor(:,1,opts.refIdx);
		% pointsRef = featurePts{opts.refIdx}(:,[2 3]);
		% confRef = featurePts{opts.refIdx}(:,1);

		% Run on all frames requested by the user
		for fNo = opts.frameList
			if mod(fNo,100)==0
				disp(['===' 10])
			end
			disp([num2str(fNo) ' | '])
			if opts.rotateImg==1
				pointsReg = ctrlPtTensor(:,[3 2],fNo);
				confReg = ctrlPtTensor(:,1,fNo);
			else
				pointsReg = ctrlPtTensor(:,[2 3],fNo);
				confReg = ctrlPtTensor(:,1,fNo);
			end
			% pointsReg = featurePts{fNo}(:,[2 3]);
			% confReg = featurePts{fNo}(:,1);

			% Filter only features with reference and moving likelihood above threshold to avoid bad registration.
			confIdx = confReg>=opts.confThreshold & confRef>=opts.confThreshold;
			pointsRegFilt = pointsReg(confIdx,:);
			pointsRefFilt = pointsRef(confIdx,:);

			% Scale the registration points if the input movie has a different size compared to control point tracking.
			if options.dsSpace~=1
				pointsRegFilt = pointsRegFilt*options.dsSpace;
				pointsRefFilt = pointsRefFilt*options.dsSpace;
			end

			% Use normalized movie
			imgReg = inputMovieNorm(:,:,fNo);

			% If not enough registration points, skip motion correction, likely blurred movie
			if sum(confIdx)<options.minPtsForReg
				mtVideo(:,:,frameCount) = imgReg;
				continue;
			end

		    if ~isempty(opts.filtPts)
		    	filtPts = opts.filtPts;
		    	pointsReg = ctrlPtTensor(filtPts,[2 3],fNo);
		    	confReg = ctrlPtTensor(filtPts,1,fNo);

			    pointsReg = featurePts{fNo}(filtPts,[2 3]);
			    confReg = featurePts{opts.refIdx}(filtPts,1);
			    pointsRefTmpTmp = pointsRef(filtPts,:);
			    % Filter only features with reference and moving likelihood above threshold to avoid bad registration.
			    confIdx = confReg>=opts.confThreshold&confRef(filtPts)>=opts.confThreshold;
			    pointsRegFilt = pointsReg(confIdx,:);
			    pointsRefFilt = pointsRefTmpTmp(confIdx,:);
		    
		    end
		    % If requested, fix a particular dimension
		    if ~isempty(options.dimToFix)
			    pointsRegFilt(:,options.dimToFix) = pointsRefFilt(:,options.dimToFix);
			end

			if opts.rotateImg==1
				% imgReg = rot90(imgReg,-1);
				imgReg = permute(imgReg,[2 1]);

			end
			
			if opts.dispPlots==1
				% clf
				subplotTmp(2,2,1)
					localFxn_showMatchedFeaturesFast(imgRef,imgReg,pointsRefFilt,pointsRegFilt)
					box off;
					title('Overlap reference and raw')
				subplotTmp(2,2,3)
					imagesc(imgReg)
					box off
					axis image
					title('Raw image')
					colormap(gca,'gray')
			end

			if opts.correctMotion==1
				% "rigid", "similarity", "affine", or "projective"
				opts.cpRegMethod = options.cpRegMethod;
				[imgReg,pointsReg,pointsRefPlot] = localFxn_motionCorrectPtFeatures(imgRef,imgReg,pointsRefFilt,pointsRegFilt,opts.cpRegMethod,options.maxTrials,opts.maxDist);
			else
				pointsRefPlot = pointsRefFilt;
			end

			if opts.dispPlots==1
				subplotTmp(2,2,2)
					localFxn_showMatchedFeaturesFast(imgRef,imgReg,pointsRefPlot,pointsReg)
					box off;
					title('Overlap reference and registered')
					%showMatchedFeatures(rot90(imgRef,-1),rot90(imgReg,-1),pointsRefPlot,pointsReg)
					%imagesc(imgReg);axis off;box off;axis image;colormap gray;
					title(fNo)

				subplotTmp(2,2,4)
					imagesc(imgReg)
					box off
					axis image
					title('Registered image')
					colormap(gca,'gray')
				drawnow
				pause(0.01);
			end

			mtVideo(:,:,frameCount) = imgReg;
			frameCount = frameCount + 1;

			if opts.flagMakeColorVid==1
				g2 = getframe;
		    	g2 = imresize(g2.cdata,[size(imgRef,1) size(imgRef,2)]);
		    	colorVideo(:,:,:,fNo) = g2;
			end
		end

		if options.runPostReg==1
			% ========================
			%% Get TurboReg registration coordinates
			if isempty(options.cropCoordsInSession)
				[~,cropCoordsInSession] = ciapkg.image.cropMatrix(single(mtVideo(:,:,opts.refIdx)),'cropOrNaN','crop','inputCoords',[]); 
			else
				cropCoordsInSession = options.cropCoordsInSession;
			end

			% ========================
			%% Turboreg to correct affine motion after
			% Motion correction
			    toptions.cropCoords = cropCoordsInSession;
			    toptions.turboregRotation = 0;
			    toptions.removeEdges = 1;
			    toptions.pxToCrop = 10;
			    toptions.RegisType = 1;
				toptions.removeNan = 1;
				toptions.refFrame = opts.refIdx;
				toptions.refFrameMatrix = mtVideo(:,:,opts.refIdx);
			    toptions.registrationFxn = 'imwarp'; % transfturboreg has issues with NaNs in displacement field output.
			% Pre-motion correction
				toptions.complementMatrix = 1;
				toptions.meanSubtract = 1;
				toptions.meanSubtractNormalize = 1;
				toptions.normalizeType = 'matlabDisk'; % matlabDisk
			% Spatial filter
				toptions.normalizeBeforeRegister = []; %'divideByLowpass'
				toptions.freqLow = 0;
				toptions.freqHigh = 4;
			disp('Done!')

			%% Run TurboReg to correct fine remaining motion
			mtVideo = ciapkg.motion_correction.turboregMovie(mtVideo,...
				'options',toptions);
			disp('Done!')
		end

	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end

	% function [outputs] = nestedfxn_exampleFxn(arg)
	% 	% Always start nested functions with "nestedfxn_" prefix.
	% 	% outputs = ;
	% end	
end
%% HELPER FUNCTIONS
function [imgBp,pointsBmp,pointsAm] = localFxn_motionCorrectPtFeatures(imgA,imgB,pointsA,pointsB,transformType,MaxNumTrials,MaxDistance)
	[tform,inlierIdx] = estgeotform2d(pointsB,pointsA,transformType,'MaxNumTrials',MaxNumTrials,'MaxDistance',MaxDistance);
	pointsBm = pointsB(inlierIdx,:);
	pointsAm = pointsA(inlierIdx,:);
	% [tform,pointsBm,pointsAm] = estimateGeometricTransform(featurePts{2},featurePts{1},'similarity','Confidence',50);
	imgBp = imwarp(imgB,tform,'OutputView',imref2d(size(imgB)),'FillValues',NaN('single'));
	pointsBmp = transformPointsForward(tform,pointsBm);
end
function [] = localFxn_getMovieShift(imgA,imgB,pointsA,pointsB)
	localFxn_showMatchedFeaturesFast(imgA,imgBp,pointsAm,pointsBmp)
end
function localFxn_showMatchedFeaturesFast(image1,image2,matchedPoints1,matchedPoints2)
	% Modified version of showMatchedFeatures for fast plotting of comparisons.

	image1 = single(image1);
	image2 = single(image2);
	rgbImg = zeros([size(image1,1) size(image1,2) 3]);
	normImgFun = @(x) (x-min(x(:),[],'omitnan'))/(max(x(:),[],'omitnan')-min(x(:),[],'omitnan'));
	rgbImg(:,:,1) = normImgFun(image1);
	rgbImg(:,:,2) = normImgFun(image2);
	rgbImg(:,:,3) = normImgFun(image2);

	imagesc(rgbImg)
	axis image
	hold on;

	plot(matchedPoints1(:,1), matchedPoints1(:,2),'o','Color','r');
	plot(matchedPoints2(:,1), matchedPoints2(:,2),'+','Color','g');

	% Plot by using a single line object with line segments broken by using NaNs. This is more efficient and makes it easier to customize the lines.
	lineX = [matchedPoints1(:,1)'; matchedPoints2(:,1)'];
	numPts = numel(lineX);
	lineX = [lineX; NaN(1,numPts/2)];
	
	lineY = [matchedPoints1(:,2)'; matchedPoints2(:,2)'];
	lineY = [lineY; NaN(1,numPts/2)];
	
	plot(lineX(:), lineY(:), 'y-'); % line
	hold off;
end