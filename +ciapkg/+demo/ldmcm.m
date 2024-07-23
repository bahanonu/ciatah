% LD-MCM motion correction using deep learning and control point registration
%
% Biafra Ahanonu
% started: 2022.10.29 [13:57:45]
% Changelog
% 	2024.03.05 [10:15:28] - Updated for CIAtah repo

%% =================================
% Settings
opts = struct;
% Int: frame to use for registering images
opts.refFrameNo = 1;
% Binary: 1 = make plots useful for debugging
opts.debugPlotFlag = 1;
% Str: full path to control point tracking (e.g. DeepLabCut) CSV
opts.dlcCsvPath = 'PATH_TO_CSV';
% Str: full path to input movie
opts.inputMoviePath = 'PATH_TO_MOVIE_FILE';
% Int: if movie used for tracking if downsampled X amount from movie being registered
opts.dsSpace = 1;
% Int: folder number, keep 1 for now.
opts.folderNo = 1;

% Automatically create output file name, else directly change below.
[pathT, nameT, extT] = fileparts(opts.inputMoviePath);
opts.outputMoviePath = fullfile(pathT,[nameT '_lcmcm_detrend' extT]);
opts.outputMoviePath_dfof = fullfile(pathT,[nameT '_lcmcm_detrend_dfof' extT]);

% This will be filled with a spatially filtered movie if user requests it
inputMovieNorm = [];
disp('Done!')

%% =================================
% Import DLC CSV data file. Load the dlcTensor to give to LD-MCM function as an input
[dlcStruct,dlcTensor,dlcCell] = ciapkg.behavior.importDeepLabCutData(opts.dlcCsvPath);
disp('Done!')

%% =================================
% Load movie
inputMovie = ciapkg.io.loadMovieList(opts.inputMoviePath,'frameList',frameList);
inputMovie = single(inputMovie);
disp('Done!')

%% =================================
% Overlay features on the reference frame from the input movie.
thisFrame = squeeze(inputMovie(:,:,opts.refFrameNo));
folderInfo = ciapkg.io.getFileInfo(opts.inputMoviePath);
figure
localfxn_overlayFeaturesMovie(thisFrame,dlcTensor*opts.dsSpace,opts.refFrameNo,opts.debugPlotFlag,opts.folderNo,folderInfo)
disp('Done!')

%% =================================
% Get the crop coordinates for rigid registration
thisFrame = squeeze(inputMovie(:,:,opts.refFrameNo));
[~,cropCoordsInSession{opts.folderNo}] = ciapkg.image.cropMatrix(thisFrame,'cropOrNaN','crop','inputCoords',[]);
disp('Done!')

%% =================================
% [OPTIONAL] Normalize movie now (normalizing after registration can lead to artifacts)
inputMovieNorm = ciapkg.movie_processing.normalizeMovie(...
	inputMovie,...
	'normalizationType','lowpassFFTDivisive',...
	'freqLow',0,'freqHigh',4,...
	'bandpassMask','gaussian');
disp('Done!')

%% =================================
% Run LD-MCM control point motion correction followed by rigid motion correction
% maxDist will help determine the max distance to motion correct, it can be limited by determining the maximal rostrocaudal displacement between frames
mt_inputMovie = ciapkg.motion_correction.ldmcm(inputMovie,dlcTensor,...
	'cropCoordsInSession',cropCoordsInSession{opts.folderNo},...
	'maxDist',50,...
	'refFrame',opts.refFrameNo,...
	'rotateImg',0,...
	'dsSpace',1,...
	'runPostReg',1,...
    'inputMovie2',inputMovieNorm,...
	'dimToFix',[]);
disp('Done!')

%% =================================
% View motion-corrected movie
ciapkg.view.playMovie(mt_inputMovie,'extraMovie',inputMovie);
disp('Done!')

%% =================================
% Create a border around the edges of the movie to handle uneven edges created by movement
mt_inputMovie = ciapkg.image.cropMatrix(mt_inputMovie,'cropType','auto','autoCropType','perSide');
ciapkg.view.playMovie(mt_inputMovie,'extraMovie',inputMovie);
disp('Done!')

%% =================================
%% Detrend movie if needed (3rd order fit often works well)
mt_inputMovie_dt = ciapkg.movie_processing.detrendMovie(mt_inputMovie,'detrendDegree',3);

% Make plot of mean frame intensity before and after detrending
figure; plot(squeeze(mean(mt_inputMovie,[1 2],'omitnan')));
hold on; plot(squeeze(mean(mt_inputMovie_dt,[1 2],'omitnan'))); ylabel('Intensity'); xlabel('Frame')
box off; legend({'Raw','Detrended'}); legend boxoff; ciapkg.view.changeFont(20)
disp('Done!')

%% =================================
%% Compute dF/F movie
mt_inputMovie_dt_dfof = ciapkg.movie_processing.dfofMovie(mt_inputMovie_dt,'dfofType','dfof');
disp('Done!')

%% =================================
% View processed and dF/F movie
ciapkg.view.playMovie(mt_inputMovie_dt_dfof,'extraMovie',mt_inputMovie_dt);
disp('Done!')

%% =================================
% Save motion corrected movie
ciapkg.io.saveMatrixToFile(mt_inputMovie_dt,opts.outputMoviePath);
% Save dF/F movie
ciapkg.io.saveMatrixToFile(mt_inputMovie_dt_dfof,opts.outputMoviePath_dfof);
disp('Done!')

%% Local functions
function localfxn_overlayFeaturesMovie(thisFrame,dlcTensor,refFrameNo,debugPlotFlag,folderNo,folderInfo)
	% Overlay the features for a given frame from the movie.
	if debugPlotFlag==1
		imagesc(thisFrame)
		axis image
		axis tight
		box off
		colormap gray
		hold on;
		title(['Movie #' num2str(folderNo) ' | ref frame #' num2str(refFrameNo) 10 strrep([folderInfo.date '_' folderInfo.protocol '_' folderInfo.subjectStr '_' folderInfo.trial],'_','\_')])
		plot(dlcTensor(:,2,refFrameNo),dlcTensor(:,3,refFrameNo),'y.','MarkerSize',15);
		drawnow
	end
end