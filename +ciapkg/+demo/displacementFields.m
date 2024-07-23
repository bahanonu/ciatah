% Displacement field motion correction example across several images
% 
% Biafra Ahanonu
% started: 2022.12.14 [04:02:26]

%% Get data paths
inputFrames = {...
	{'dots_reference.tif','dots_template.tif'};
	{'spinalImaging01_ref.tif','spinalImaging01_template.tif'};
	{'testFace_ref.jpg','testFace_template.jpg'};
};
nTests = length(inputFrames);
mainPath = fullfile(ciapkg.getDirPkg('data'),'displacementFields');

%% Load data, run displacement field motion correction, display results
for testNo = 1:nTests
	disp('==========')
	f1 = imread(fullfile(mainPath,inputFrames{testNo}{1}));
	f2 = imread(fullfile(mainPath,inputFrames{testNo}{2}));
	inputMovie = cat(3,im2gray(f1),im2gray(f2));
	inputMovieTmp = inputMovie;
	frameA = 1;
	frameB = 2;

	if testNo==2
		inputMovieTmp = ciapkg.movie_processing.downsampleMovie(inputMovie,'downsampleDimension','space','downsampleFactor',2);
	end

	[inputMovieTmp2,ResultsOutOriginal] = ciapkg.motion_correction.turboregMovie(inputMovieTmp,...
		'mcMethod','imregdemons',...
		'refFrame',1,...
		'df_AccumulatedFieldSmoothing',0.54,... % 1.3
		'df_Niter',[500 400 200],... % [500 400 200]
		'df_PyramidLevels',3,...
		'df_DisplayWaitbar',false);
	fixedTmp = inputMovieTmp(:,:,1);
	movingTmp = inputMovieTmp(:,:,2);
	movingReg = inputMovieTmp2(:,:,2);
	Dxy = ResultsOutOriginal{2};

	ciapkg.view.displacementFieldCompare(fixedTmp,movingTmp,movingReg,Dxy);
end
disp('Done!')