function [mainTbl, mainTensor, mainCell] = importDeepLabCutData(inputPath,varargin)
	% [outputTable] = importDeepLabCutData(inputPath,varargin)
	% 
	% Loads DeepLabCut processed CSV files and loads into a table or structure for use by other functions.
	% 
	% Biafra Ahanonu
	% started: 2022.11.02 [18:48:01]
	% 
	% Inputs
	% 	inputPath - Str: path to DLC file.
	% 
	% Outputs
	% 	mainTbl - Struct: with fields named after body parts. Each field is [likelihood x y] matrix with rows equal to frames of the movie. 	
	% 	mainTensor - Tensor: format [nFeatures nDlcOutputs nFrames]. 
	%	mainCell - Cell: format {1 nFeatures} with each cell containing a [likelihood x y] matrix with rows equal to frames of the movie. 
	% 
	% Options (input as Name-Value with Name = options.(Name))
	% 	% DESCRIPTION
	% 	options.exampleOption = '';

	% Changelog
		% 2022.03.14 [01:47:04] - Added nested and local functions to the example function.
		% 2024.02.19 [09:25:58] - Added conversion to tensor and cell to the import function from other functions.
	% TODO
		%

	% ========================
	% Str: both part
	options.dispPlots = 0;
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
		mainTbl = struct;

		% If user inputs str inside a cell
		if iscell(inputPath)
			inputPath = inputPath{1};
		end
		disp('===')
		disp(inputPath)
		
		% dlcTablePath = fullfile(rootAnalysisPath,dlcFileCSV{vidNo});
		t1 = readtable(inputPath);
		t2 = readlines(inputPath);
		featuresListMain = strsplit(t2{2},',');
		featuresList = unique(featuresListMain);
		nfeaturess = length(featuresList)-1;

		if options.dispPlots==1
			figure;
			set(gcf,'Color','k')
		end

		mainCell = {};
		nFrames = length(t1{:,(1-1)*3+2});
		mainTensor = NaN([nfeaturess 3 nFrames]);

		for partX = 1:nfeaturess
			partName = featuresListMain{(partX-1)*3+4};
			if partX==nfeaturess
				fprintf('%s.\n',partName)				
			else
				fprintf('%s | ',partName)
			end
			conf1 = t1{:,(partX-1)*3+4};
			dlcX = t1{:,(partX-1)*3+2};
			dlcY = t1{:,(partX-1)*3+3};

			mainMatrix = [conf1(:) dlcX(:) dlcY(:)];

			mainTbl.(partName) = mainMatrix;

			mainCell{partX} = mainMatrix;

			mainTensor(partX,:,:) = mainMatrix';

			if options.dispPlots==1
				subplot(3,3,partX)
					plot(dlcX,dlcY,'Color','y')
					axis equal
					box off;
					set(gca,'Color','k')
					title(strrep(partName,'_','\_'))
			end
		end

		if options.dispPlots==1
			ciapkg.view.changeFont(18,'fontColor','w');
		end
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end

	function [outputs] = nestedfxn_exampleFxn(arg)
		% Always start nested functions with "nestedfxn_" prefix.
		% outputs = ;
	end	
end
% function [outputs] = localfxn_exampleFxn(arg)
% 	opts.nFrames = size(inputMovie,3);
% 	featurePts = cell([1 opts.nFrames]);
% 	opts.nFields = fieldnames(dlcData);
% 	featurePtsTensor = NaN([length(opts.nFields) 3 opts.nFrames]);

% 	for i = 1:opts.nFrames
% 		conf1 = [];
% 		dlcX = [];
% 		dlcY = [];
% 		for partX = 1:length(opts.nFields)
% 			thisField = opts.nFields{partX};
% 			dlcDataNew.(thisField) = vertcat(dlcData.(thisField));
% 			conf1(partX) = dlcDataNew.(thisField)(i,1);
% 			dlcX(partX) = dlcDataNew.(thisField)(i,2);
% 			dlcY(partX) = dlcDataNew.(thisField)(i,3);
% 		end
% 		featurePts{i} = [conf1(:) dlcX(:) dlcY(:)];
% 		featurePtsTensor(:,:,i) = featurePts{i};
% 	end
% 	disp('Done!')
% end	