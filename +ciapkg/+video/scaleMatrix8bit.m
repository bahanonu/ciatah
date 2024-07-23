function [inputMovie] = scaleMatrix8bit(inputMovie,varargin)
	% [inputMovie] = scaleMatrix8bit(inputMovie,varargin)
	% 
	% Scales an input matrix to 8-bit (256) range. Can also save video out to an AVI file.
	% 
	% Biafra Ahanonu
	% started: 2022.12.02 [10:19:00]
	% 
	% Inputs
	% 	inputMovie - [x y nFrames] tensor with movie data.
	% 
	% Outputs
	% 	inputMovie - [x y nFrames] tensor with corrected movie data.
	% 
	% Options (input as Name-Value with Name = options.(Name))
	% 	% DESCRIPTION
	% 	options.exampleOption = '';

	% Changelog
		% 2024.02.11 [15:27:08] - Updates to function and integration into CIAtah.
	% TODO
		%

	% ========================
	% Int: amount to downsample movie by. 1 = no downsampling.
	options.dsFactor = 1;
	% Binary: 1 = display plots.
	options.dispPlots = 0;
	% Str: Path to AVI to save output to
	options.savePath = '';
	% Binary: 1 = ignore zeros when calculating min/max, in cases of movies with a lot of motion (e.g. borders = 0) or other reasons for excessive zeros.
	options.ignoreZeros = 0;
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
		%%
		opts.dsFactor = options.dsFactor;

		prctileMax = 99.99;
		prctileMin = 1;
		multiRatio = 1.2;
		adjustMinus = 0.01;

	    % Normalize and correct contrast for AVI for improved DLC tracking
		inputMovie = single(inputMovie);

		if opts.dsFactor~=1
			inputMovie = ciapkg.movie_processing.downsampleMovie(inputMovie,...
				'downsampleDimension','space','downsampleFactor',opts.dsFactor);
		end

		% Obtain percentile min/max, less likely to be thrown off by extreme values
		if options.ignoreZeros==1
			movieMax = prctile(inputMovie,prctileMax,[1 2 3]);
			movieMin = prctile(inputMovie,prctileMin,[1 2 3]);
		else
			inputMovieTmp = inputMovie;
			inputMovieTmp(inputMovieTmp==0) = NaN;
			movieMax = prctile(inputMovieTmp,prctileMax,[1 2 3]);
			movieMin = prctile(inputMovieTmp,prctileMin,[1 2 3]);			
		end

		% Normalize the movie
		inputMovie = (inputMovie-movieMin)/(movieMax-movieMin);
		inputMovie = (inputMovie*multiRatio-adjustMinus)*255;
		inputMovie = uint8(inputMovie);

		if options.dispPlots==1
			figure
			    % subplot(xPlot,yPlot,i)
			        imagesc(squeeze(inputMovie(:,:,1)))
			        axis image
			        box off
			        colormap gray
			        title(i)
			        drawnow
	    end
	    if ~isempty(options.savePath)
		    % [~,saveFileName,~] = fileparts(thisMoviePath);
		    % outputSavePath = fullfile(outputPath,[saveFileName '.avi']);

		    outputSavePath = options.savePath;
		    fprintf('Save to: %s\n',outputSavePath)
		    ciapkg.io.saveMatrixToFile(inputMovie,outputSavePath);
		end

		disp('Done!')
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
% function [outputs] = localfxn_exampleFxn(arg)
% 	% Always start local functions with "localfxn_" prefix.
% 	% outputs = ;
% end	
