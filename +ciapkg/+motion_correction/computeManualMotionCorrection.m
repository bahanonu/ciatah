function [inputImagesTranslated, outputStruct] = computeManualMotionCorrection(inputImages,varargin)
	% Translates a marker image relative to a cell map and then allows the user to click for marker positive cells or runs automated market detection and alignment to actual cells
	% Biafra Ahanonu
	% started: 2017.12.05 [17:02:58] - branched from getMarkerLocations.m
	% inputs
		% inputImages
			% [x y z] 3D matrix where z = individual frames with image to register. By default the first frame is used as the "reference" image in green.
			% {nSessions 1} cell where each cell contains [x y z].
	% outputs
		% outputStruct.registeredMarkerImage
		% outputStruct.translationVector = {1 z} cell array containing inputs for imtranslate so users can manually correct if needed.
		% outputStruct.rotationVector = {1 z} cell array containing inputs for imrotate so users can manually correct if needed.
		% outputStruct.gammaCorrection
		% outputStruct.inputImagesCorrected
		% outputStruct.inputImagesOriginal

	% changelog
		% 2020.04.07 [19:39:24] - Updated to allow just using the register aspect of the function. Also made registering callback based.
		% 2020.04.08 [10:35:49] - Added support for rotation.
		% 2020.05.28 [08:48:57] - Slight update.
		% 2021.04.16 [10:31:29] - Add default gamma option.
		% 2021.04.27 [16:26:14] - Update to fix issue of prior figure (even after clf) maintaining previous key press and exiting, causing uiwait to fail.
		% 2021.08.06 [09:43:53] - Added acceleration based on rapid user clicks or holding down direction keys
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2021.10.13 [21:20:04] - Add support for 90 degree quick rotation, fix passing of flip dims.
		% 2021.10.29 [12:45:48] - Change number of pixels to translate per click and UI improvements.
		% 2021.11.01 [11:44:01] - Improved pre-allocation, minimize GUI slowdown for large inputs over time.
		% 2021.11.17 [02:30:23] - Improve speed of GUI and responsiveness.
		% 2021.12.19 [11:00:15] - Force altInputImages to initialize as input class type to avoid automatic conversion to double (save space/ram).
		% 2022.01.29 [19:13:55] - Significant speed improvements by removing certain calls to figure, axis, imagesc, etc. that slow down UI over time when many sessions aligned.
	% TODO
		% Add ability to auto-crop if inputs are not of the right size them convert back to correct size after manual correction
		% inputRegisterImage - [x y nCells] - Image to register to.
		% Add second window that shows the differences between the two images
		% Add a plot that shows the sum(diff(imgA-imgB)) to give users a metric.

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Int: frame to use in inputImages for register in default mode
	options.refFrame = 1;
	% Figure number for
	options.translationFigNo = 45;
	% Float: 0 and 1, threshold for cell outlines
	options.imageThreshold = 0.2;
	% Binary: 1 = make inputImages and inputRegisterImage equal dims, 0 = do not alter inputs
	options.makeInputDimsEqual = 0;
	% Binary: 1 = only register, 0 = do all steps
	options.onlyRegister = 0;
	% Binary: 1 = use outlines when registering, 0 = do not use outlines
	options.registerUseOutlines = 1;
	% Cell array of matrices: cell array of {[x y z]} matrices that should match each Z dimension in inputImages
	options.altInputImages = {};
	% Str: max or mean
	options.cellCombineType = 'max';
	% Float: default gamma.
	options.gammaCorrection = 1;
	% Float: time (seconds) between user clicks to speed up translation.
	options.userClickTimerThreshold = 0.1;
	% Int: Amount of pixels to move image for each user x-y click
	options.translationAmt = 1;
	% Binary: 1 = include images output struct, 0 = do not include.
	options.includeImgsOutputStruct = 1;
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
		outputStruct.success = 0;

		% If user inputs a cell, convert to matrix where each z-dimension represents max projection of each cell
		if iscell(inputImages)
			disp('Converting input cells into max-projection matrix')
			disp(['inputImages: ' num2str(size(inputImages))])
			% If user has not input alternative images but input cell array of images
			if isempty(options.altInputImages)
				switchInputImagesBack = 1;
				options.altInputImages = inputImages;
			else
				switchInputImagesBack = 0;
			end
			switch options.cellCombineType
				case 'max'
					inputImages = cellfun(@(x) max(x,[],3,'omitnan'),inputImages,'UniformOutput',false);
				case 'mean'
					inputImages = cellfun(@(x) mean(x,3,'omitnan'),inputImages,'UniformOutput',false);
				otherwise
					inputImages = cellfun(@(x) max(x,[],3,'omitnan'),inputImages,'UniformOutput',false);
			end                
			inputImages = cat(3,inputImages{:});
			disp(['inputImages: ' num2str(size(inputImages))])
		else
			switchInputImagesBack = 0;
		end

		% Get register frame
		inputRegisterImage = inputImages(:,:,options.refFrame);

		% downsample marker reference image as needed
		if options.makeInputDimsEqual==1
			[inputImages] = downsampleMovie(inputImages,'downsampleX',size(inputRegisterImage,1),'downsampleY',size(inputRegisterImage,2),'downsampleDimension','space');
		end
		
		% Pre-allocate to speed up GUI especially with large number of sessions.
		nImagesRegister = size(inputImages,3);
		% for frameNo = 1:nImagesRegister
		% 	outputStruct.registeredMarkerImage{frameNo} = inputImages(:,:,frameNo)*NaN;
		% 	outputStruct.translationVector{frameNo} = NaN;
		% 	outputStruct.rotationVector{frameNo} = NaN;
		% 	outputStruct.flipDimVector{frameNo} = NaN;
		% 	outputStruct.gammaCorrection{frameNo} = NaN;
		% 	outputStruct.gammaCorrectionRef{frameNo} = NaN;
		% 	outputStruct.inputImagesCorrected{frameNo} = inputImages(:,:,frameNo)*NaN;
		% 	outputStruct.inputImagesOriginal{frameNo} = inputImages(:,:,frameNo)*NaN;
		% 	if ~isempty(options.altInputImages)
		% 		outputStruct.altInputImages{frameNo} = options.altInputImages{frameNo}*NaN;
		% 		% outputStruct.altInputImages{frameNo} = inputImages(:,:,frameNo)*NaN;
		% 	end
		% end

		% Pre-allocate arrays only but do not fill due to shared memory deep copy issue.
		% See https://www.mathworks.com/matlabcentral/answers/48807-how-preallocate-structure-for-better-memory#comment_116968.
		outputStruct.registeredMarkerImage = cell(1,nImagesRegister);
		outputStruct.translationVector = cell(1,nImagesRegister);
		outputStruct.rotationVector = cell(1,nImagesRegister);
		outputStruct.flipDimVector = cell(1,nImagesRegister);
		outputStruct.gammaCorrection = cell(1,nImagesRegister);
		outputStruct.gammaCorrectionRef = cell(1,nImagesRegister);
		outputStruct.inputImagesCorrected = cell(1,nImagesRegister);
		outputStruct.inputImagesOriginal = cell(1,nImagesRegister);
		outputStruct.altInputImages = cell(1,nImagesRegister);

		imgStruct = struct;
		imgStruct.imgHandle = [];
		imgStruct.imgHandle2 = [];
		imgStruct.imgHandle3 = [];
		imgStruct.imgTitleHandle = [];

		% Determine whether to register each inputImages frame as representative of how to translate each matrix in options.altInputImages
		tic
		if ~isempty(options.altInputImages)
			inputImagesTranslated = NaN(size(inputImages));
			for frameNo = 1:size(inputImages,3)
				display(repmat('=',1,21))
				fprintf('Running %d/%d input image...\n',frameNo,size(inputImages,3));
				disp(toc);tic
				% [outputStruct] = subfxnRegisterImage(inputImages(:,:,frameNo),inputRegisterImage,options,outputStruct,frameNo,size(inputImages,3));

				tmpStructPass = struct;
				tmpStructPass.gammaCorrection = outputStruct.gammaCorrection;
				tmpStructPass.gammaCorrectionRef = outputStruct.gammaCorrectionRef;

				[OUT1, imgStruct] = subfxnRegisterImage(inputImages(:,:,frameNo),inputRegisterImage,options,tmpStructPass,frameNo,size(inputImages,3),imgStruct);
				fprintf('Done manual translate...\n')
				disp(toc);tic
				% outputStruct.altInputImages{frameNo} = NaN(size(options.altInputImages{frameNo}),class(options.altInputImages{frameNo}));

				outputStruct.translationVector{frameNo} = OUT1.translationVector;
				outputStruct.rotationVector{frameNo} = OUT1.rotationVector;
				outputStruct.flipDimVector{frameNo} = OUT1.flipDimVector;
				outputStruct.gammaCorrection{frameNo} = OUT1.gammaCorrection;
				outputStruct.gammaCorrectionRef{frameNo} = OUT1.gammaCorrectionRef;

				if options.includeImgsOutputStruct==1
					outputStruct.registeredMarkerImage{frameNo} = OUT1.registeredMarkerImage;
					outputStruct.inputImagesCorrected{frameNo} = OUT1.inputImagesCorrected;
					outputStruct.inputImagesOriginal{frameNo} = OUT1.inputImagesOriginal;
				end

				fprintf('Translating/rotating/flipping Input images...\n')
				inputImagesTranslated(:,:,frameNo) = imtranslate(inputImages(:,:,frameNo),outputStruct.translationVector{frameNo});
				inputImagesTranslated(:,:,frameNo) = imrotate(inputImagesTranslated(:,:,frameNo),outputStruct.rotationVector{frameNo},'nearest','crop');
				inputImagesTranslated(:,:,frameNo) = subfxn_flipImage(inputImagesTranslated(:,:,frameNo),outputStruct.flipDimVector{frameNo});
				disp(toc);tic

				fprintf('Translating/rotating/flipping alt input images...\n')

				tmpAltInputImages = NaN(size(options.altInputImages{frameNo}));
				for imgNo = 1:size(tmpAltInputImages,3)
					% figure;
					% 	subplot(1,2,1)
					% 		imagesc(options.altInputImages{frameNo}(:,:,imgNo)); axis equal tight
					% 	subplot(1,2,2)
					% 		imagesc(imtranslate(options.altInputImages{frameNo}(:,:,imgNo),outputStruct.translationVector{frameNo})); axis equal tight
					% 	pause

					% TRANSLATE
					tmpAltInputImages(:,:,imgNo) = imtranslate(options.altInputImages{frameNo}(:,:,imgNo),outputStruct.translationVector{frameNo});

					% ROTATION
					tmpAltInputImages(:,:,imgNo) = imrotate(tmpAltInputImages(:,:,imgNo),outputStruct.rotationVector{frameNo},'nearest','crop');
					
					% FLIP IMAGE
					tmpAltInputImages(:,:,imgNo) = subfxn_flipImage(tmpAltInputImages(:,:,imgNo),outputStruct.flipDimVector{frameNo});
				end
				outputStruct.altInputImages{frameNo} = tmpAltInputImages;
				clear tmpAltInputImages;
				disp(toc);tic
				% figure;imagesc(max(outputStruct.altInputImages{frameNo},[],3))
			end
		else
			% First register the inputImages by moving relative to inputRegisterImage
			for frameNo = 1:size(inputImages,3)
				[OUT1, imgStruct] = subfxnRegisterImage(inputImages(:,:,frameNo),inputRegisterImage,options,outputStruct,frameNo,size(inputImages,3),imgStruct);

				outputStruct.registeredMarkerImage{frameNo} = OUT1.registeredMarkerImage;
				outputStruct.translationVector{frameNo} = OUT1.translationVector;
				outputStruct.rotationVector{frameNo} = OUT1.rotationVector;
				outputStruct.flipDimVector{frameNo} = OUT1.flipDimVector;
				outputStruct.gammaCorrection{frameNo} = OUT1.gammaCorrection;
				outputStruct.gammaCorrectionRef{frameNo} = OUT1.gammaCorrectionRef;
				outputStruct.inputImagesCorrected{frameNo} = OUT1.inputImagesCorrected;
				outputStruct.inputImagesOriginal{frameNo} = OUT1.inputImagesOriginal;


				inputImagesTranslated = NaN(size(inputImages));
				inputImagesTranslated(:,:,frameNo) = imtranslate(inputImages(:,:,frameNo),outputStruct.translationVector{frameNo});
				if outputStruct.rotationVector{frameNo}==0
				else
					inputImagesTranslated(:,:,frameNo) = imrotate(inputImagesTranslated(:,:,frameNo),outputStruct.rotationVector{frameNo},'nearest','crop');
				end
				if ~isempty(outputStruct.flipDimVector{frameNo})
					inputImages = subfxn_flipImage(inputImages,outputStruct.flipDimVector{frameNo});
				end

				outputStruct.inputImagesCorrected{frameNo} = inputImagesTranslated(:,:,frameNo);
				outputStruct.inputImagesOriginal{frameNo} = inputImages(:,:,frameNo);
			end
		end

		% Switch back to cell array of images
		if switchInputImagesBack==1
			inputImagesTranslated = outputStruct.altInputImages;
		end

		if options.onlyRegister==1
			return
		end

		outputStruct.success = 1;
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end
% function [outputStruct] = subfxnRegisterImage(inputImages,inputRegisterImage,options,outputStruct,imgNo,imgN)
function [outputStructTmp, imgStruct] = subfxnRegisterImage(inputImages,inputRegisterImage,options,inputStruct,imgNo,imgN,imgStruct)
	disp(toc);tic
	import ciapkg.api.* % import CIAtah functions in ciapkg package API.
	
	inputRegisterImageCellmap = createObjMap(inputRegisterImage);

	if options.registerUseOutlines==1
		[thresholdedImages, boundaryIndices] = thresholdImages(inputRegisterImage,'binary',1,'getBoundaryIndex',1,'threshold',options.imageThreshold,'imageFilter','median');
		inputRegisterImageOutlines = zeros(size(inputRegisterImageCellmap));
		inputRegisterImageOutlines([boundaryIndices{:}]) = 1;
	else
		inputRegisterImageOutlines = normalizeVector(single(inputRegisterImage(:,:,1)),'normRange','zeroToOne');
	end
	inputRegisterImageOutlinesOriginal = inputRegisterImageOutlines;

	[figHandle, figNo] = openFigure(options.translationFigNo, '');
	colormap(ciapkg.api.customColormap());
	% Force current character to be a new figure.
	set(gcf,'currentch','0');
	if imgNo==1
		clf
	end

	disp('Setup #1');
	disp(toc);tic

	% normalize input marker image
	inputImages = normalizeVector(single(inputImages),'normRange','zeroToOne');
	inputImagesOriginal = inputImages;
	
	% rgbImage = cat(3,inputRegisterImageOutlines,inputImages,inputRegisterImageOutlines);
	
	gammaCorrection = options.gammaCorrection;
	gammaCorrectionRef = options.gammaCorrection;
	try
		% Get prior gamma corrections
		gammaCorrection = inputStruct.gammaCorrection{imgNo-1};
		gammaCorrectionRef = inputStruct.gammaCorrectionRef{imgNo-1};
	catch
		
	end

	disp('Setup #2');
	disp(toc);tic
	
	inputImages = imadjust(inputImages,[],[],gammaCorrection);
	inputRegisterImage = imadjust(inputRegisterImage,[],[],gammaCorrectionRef);
	continueRegistering = 1;
	translationVector = [0 0];
	rotationVector = [0];
	flipDimVector = [];
	% zoom on;
	% set(figHandle, 'KeyPressFcn', @(source,eventdata) figure(figHandle));
	set(figHandle, 'KeyPressFcn', @(source,eventdata) subfxnRespondUser(source,eventdata));
	% figure(figHandle)
	
	rgbImage = subfxncreateRgbImg();

	disp('Setup #3');
	disp(toc);tic
	
	imgTitleFxn = @(imgNo,imgN,gammaCorrection,gammaCorrectionRef,translationVector,rotationVector,translationAmt) sprintf('Image %d/%d\nup/down/left/right arrows for translation | A/S = rotate +1 left/right, Q/W = rotate +90 left/right  | 5/6 = flip x/y | f to finish\n1/2 keys for image gamma down/up | gamma = %0.3f |  gamma(ref) = %0.3f | translation %d %d | rotation %d\npurple = reference image, green = image to manually translate | %d px/click',imgNo,imgN,gammaCorrection,gammaCorrectionRef,translationVector,rotationVector,translationAmt);
	
	imgTitle = imgTitleFxn(imgNo,imgN,gammaCorrection,gammaCorrectionRef,translationVector,rotationVector,options.translationAmt);

	subplotTmp = @(x,y,z) subaxis(x,y,z, 'Spacing', 0.02, 'Padding', 0.02, 'MarginTop', 0.07,'MarginBottom', 0.02,'MarginLeft', 0.03,'MarginRight', 0.02);
	subplotTmp2 = @(x,y,z) subaxis(x,y,z, 'Spacing', 0.02, 'Padding', 0.001, 'MarginTop', 0.07,'MarginBottom', 0.02,'MarginLeft', 0.03,'MarginRight', 0.02);

	horzLineMid = @(imgX,cLine) plot([1 size(imgX,2)],[size(imgX,1)/2 size(imgX,1)/2],cLine); % horizontal mid line
	vertLineMid = @(imgX,cLine) plot([size(imgX,2)/2 size(imgX,2)/2],[1 size(imgX,1)],cLine); % vertical mid line
	 
	if isempty(imgStruct.imgHandle)   
		subplotTmp(2,4,[1:3 5:7])
			imgHandle = imagesc(rgbImage);
			hold on;
			axis image;
			% axis equal tight
			box off;
			imgTitleHandle = title(imgTitle);
			horzLineMid(rgbImage,'w-');
			vertLineMid(rgbImage,'w-');

		imgStruct.imgHandle = imgHandle;
		imgStruct.imgTitleHandle = imgTitleHandle;
	else
		imgHandle = imgStruct.imgHandle;
		imgTitleHandle = imgStruct.imgTitleHandle;
		% set(imgHandle,'Cdata',rgbImage);
	end

	if isempty(imgStruct.imgHandle2)
		subplotTmp2(2,4,[4])
			imgHandle2 = imagesc(rgbImage(:,:,1));
			axis image;
			% axis equal tight
			box off;
			title('Reference')
			hold on;
			horzLineMid(rgbImage,'k-');
			vertLineMid(rgbImage,'k-');

		imgStruct.imgHandle2 = imgHandle2;
	else
		imgHandle2 = imgStruct.imgHandle2;
		% set(imgHandle,'Cdata',rgbImage(:,:,1));
	end
		
	if isempty(imgStruct.imgHandle3)
		subplotTmp2(2,4,[8])
			imgHandle3 = imagesc(rgbImage(:,:,2));	
			axis image;	
			% axis equal tight
			box off;
			title('Test')
			hold on;
			horzLineMid(rgbImage,'k-');
			vertLineMid(rgbImage,'k-');

		imgStruct.imgHandle3 = imgHandle3;
	else
		imgHandle3 = imgStruct.imgHandle3;
	end

	userClickTimer = tic;
	subfxnRespondUser([],[]);

	disp('Setup manual UI');
	disp(toc);tic

	uiwait(figHandle)

	disp('Manual translate done.')
	disp(toc);tic

	disp('Allocating output structure')
	outputStructTmp = struct;
	outputStructTmp.registeredMarkerImage = imtranslate(inputImagesOriginal,translationVector);
	outputStructTmp.translationVector = translationVector;
	outputStructTmp.rotationVector = rotationVector;
	outputStructTmp.flipDimVector = flipDimVector;
	outputStructTmp.gammaCorrection = gammaCorrection;
	outputStructTmp.gammaCorrectionRef = gammaCorrectionRef;
	outputStructTmp.inputImagesCorrected = inputImages;
	outputStructTmp.inputImagesOriginal = inputImagesOriginal;
	disp(toc);tic
	% function rgbImage = subfxncreateRgbImg()
	function rgbImage = subfxncreateRgbImg()
		rgbImage = cat(3,inputRegisterImageOutlines,inputImages,inputRegisterImageOutlines);
		
		% rgbImage(:,:,1) = inputRegisterImageOutlines; %red
		% rgbImage(:,:,2) = inputImages; %green
		% if options.registerUseOutlines==1
		% else
		% end
		% rgbImage(:,:,3) = zeros([size(rgbImage(:,:,2))]); %blue
		% rgbImage(:,:,3) = inputRegisterImageOutlines; %blue
	end

	function subfxnRespondUser(src,event)
		% figure(figHandle)
		subfxnDrawImg()
				
		% pause
		[tDelta, continueRegistering, gDelta, rDelta, gDeltaRef, flipDimHere,translationAmtTmp] = subfxnRespondToUserInputTranslation();
		
		if ~isempty(translationAmtTmp)
			options.translationAmt = options.translationAmt+translationAmtTmp;
			if options.translationAmt<0
				options.translationAmt = 1;
			end
		end
		
		userClickT = toc(userClickTimer);
		tModBase = options.translationAmt;
		tMod = tModBase*1;
		if userClickT<options.userClickTimerThreshold*4
			tMod = tModBase*2;
			if userClickT<options.userClickTimerThreshold*2
				tMod = tModBase*4;
				if userClickT<options.userClickTimerThreshold
					tMod = tModBase*8;
				end
			end
		end
		tDelta = tDelta*tMod;
		rDelta = rDelta*tMod;
		
		set(gcf,'CurrentCharacter','0');
		translationVector = translationVector+tDelta;
		rotationVector = rotationVector+rDelta;
		flipDimVector = [flipDimVector flipDimHere];
		
		gammaCorrection = subfxnGammaUpdate(gammaCorrection,gDelta);
		% gDeltaRef
		gammaCorrectionRef = subfxnGammaUpdate(gammaCorrectionRef,gDeltaRef);

		inputImages = imtranslate(inputImagesOriginal,translationVector);
		inputImages = imrotate(inputImages,rotationVector,'nearest','crop');
		% if rDelta~=0
		% end
		inputImages = imadjust(inputImages,[],[],gammaCorrection);
		inputRegisterImageOutlines = inputRegisterImageOutlinesOriginal;
		inputRegisterImageOutlines = imadjust(inputRegisterImageOutlines,[],[],gammaCorrectionRef);
		
		inputImages = subfxn_flipImage(inputImages,flipDimVector);
		
		subfxnDrawImg()
		
		if continueRegistering==0
			% Reset the figure
			% close(figHandle)
			% figure(figHandle)
			% delete(axHandle2)
			uiresume 
			% clf
			% set(gcf,'CurrentCharacter','0');
		end
		userClickTimer= tic;
	end
	function subfxnDrawImg()
		rgbImage = subfxncreateRgbImg();
		% imagesc(rgbImage);box off;
		set(imgHandle,'Cdata',rgbImage);
		imgTitle = imgTitleFxn(imgNo,imgN,gammaCorrection,gammaCorrectionRef,translationVector,rotationVector,options.translationAmt);
		set(imgTitleHandle,'String',imgTitle);
		% title(imgTitle)
		% imagesc(inputImages)

		set(imgHandle2,'Cdata',rgbImage(:,:,1));
		set(imgHandle3,'Cdata',rgbImage(:,:,2));

		% drawnow
	end
end
function gammaCorrection = subfxnGammaUpdate(gammaCorrection,gDelta)
	if gammaCorrection<=1
		gDelta = gDelta/10;
	else
		gDelta = gDelta/5;
		% gammaCorrection = gammaCorrection+round(gammaCorrection-round(gammaCorrection));
	end
	gammaCorrection = gammaCorrection+gDelta;
	if gammaCorrection<0
		gammaCorrection = 0;
	end
end
function [tDelta, continueLoop, gDelta, rDelta, gDeltaRef, flipDimHere,translationAmt] = subfxnRespondToUserInputTranslation()
	continueLoop = 1;
	% translationDirection []
	% set(gcf,'currentch','3');
	% keyIn = get(gcf,'CurrentCharacter');
	% keyIn = wait(get(gcf,'CurrentCharacter'));
	% [x,y,reply]=ginput(1);
	% pause
	% while strcmp(keyIn,'3')
		% keyIn
	% end
	% reply = double(keyIn);
	% set(gcf,'currentch','3');
	reply = get(gcf,'CurrentCharacter');
	tDelta = [0 0];
	gDelta = 0;
	gDeltaRef = 0;
	rDelta = 0;
	flipDimHere = 0;
	translationAmt = [];
	reply = double(reply);

	% decide what to do based on input (not a switch due to multiple comparisons)
	if isequal(reply, 31)
		% down key
		tDelta = [0, 1];
		% inputImages = imtranslate(inputImages,[0, 1]);
	elseif isequal(reply, 30)
		% up key
		tDelta = [0, -1];
		% inputImages = imtranslate(inputImages,[0, -1]);
	elseif isequal(reply, 28)
		% go back, left
		tDelta = [-1, 0];
		% inputImages = imtranslate(inputImages,[-1, 0]);
	elseif isequal(reply, 29)
		% go forward, right
		tDelta = [1, 0];
		% inputImages = imtranslate(inputImages,[1, 0]);
	elseif isequal(reply, 49)
		% 1 - gamma down
		gDelta = -1;
	elseif isequal(reply, 50)
		% 2 - gamma up
		gDelta = 1;
	elseif isequal(reply, 51)
		% 3 - gamma down, reference image
		gDeltaRef = -1;
	elseif isequal(reply, 52)
		% 4 - gamma up
		gDeltaRef = 1;
	elseif isequal(reply, 53)
		% 5 - flip x
		flipDimHere = 1;
	elseif isequal(reply, 54)
		% 6 - flip y
		flipDimHere = 2;
	elseif isequal(reply, 55)
		% 7 - decrease px/click
		translationAmt = -1;
	elseif isequal(reply, 56)
		% 8 - incease px/click
		translationAmt = 1;
	elseif isequal(reply, 115)
		% s - rotate right
		rDelta = -0.5;
	elseif isequal(reply, 97)
		% a - rotate left
		rDelta = 0.5;
	elseif isequal(reply, 113)
		% q - rotate left
		rDelta = 90;
	elseif isequal(reply, 119)
		% w - rotate right
		rDelta = -90;
	elseif isequal(reply, 102)
		% user clicked 'f' for finished, exit loop
		continueLoop = 0;
		% movieDecision = questdlg('Are you sure you want to exit?', ...
		%     'Finish sorting', ...
		%     'yes','no','yes');
		% if strcmp(movieDecision,'yes')
		%     saveData=1;
		% end
	else
		% forward=1;
		% valid(i) = 1;
	end
end

function inputImages = subfxn_flipImage(inputImages,flipDimVector)
	if isempty(flipDimVector)
		return;
	end
	for vecNo = 1:length(flipDimVector)
		switch flipDimVector(vecNo)
			case 1
				inputImages = flip(inputImages,1);
			case 2
				inputImages = flip(inputImages,2);
			otherwise
		end
	end
end