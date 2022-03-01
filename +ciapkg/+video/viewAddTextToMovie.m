function [movieTmp] = viewAddTextToMovie(movieTmp,inputText,fontSize,varargin)
	% Adds text to movie matrix.
	% Biafra Ahanonu
	% inputs
		% inputSignal - input signal (or matrix)
	% outputs
		%

	% changelog
		% 2016.07.01 [15:05:03] - improved
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
        % 2022.01.26 [15:16:20] - Added varargin for future additions.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	nFrames = size(movieTmp,3);
	maxVal = nanmax(movieTmp(:));
	minVal = nanmin(movieTmp(:));
	% minVal = NaN;
	reverseStr = '';
	% create a frame, put text on it, and then directly replace all sections of the movie with that text
	movieTmpTwo = minVal*ones([size(movieTmp,1) size(movieTmp,2)]);
	movieTmpTwo = squeeze(nanmean(...
		insertText(movieTmpTwo,[0 0],inputText,...
		'BoxColor',[maxVal maxVal maxVal],...
		'TextColor',[minVal minVal minVal],...
		'AnchorPoint','LeftTop',...
		'FontSize',fontSize,...
		'BoxOpacity',1)...
	,3));
	% imagesc(movieTmpTwo);pause
	% [i, j] = ind2sub(size(movieTmpTwo),find(movieTmpTwo==maxVal));
	% [i, j] = ind2sub(size(movieTmpTwo),find(movieTmpTwo==maxVal));
	midVal = (minVal+maxVal)/2;
	[i, j] = ind2sub(size(movieTmpTwo),find(movieTmpTwo>midVal));
	movieTmpTwo = repmat(movieTmpTwo,[1 1 size(movieTmp,3)]);
	% movieTmpTwo(movieTmpTwo<maxVal*0.6) = NaN;
	% movieTmpTwo(movieTmpTwo>=maxVal*0.6) = maxVal;
	movieTmp(min(i):max(i),min(j):max(j),:) = movieTmpTwo(min(i):max(i),min(j):max(j),:);

	% for frameNo = 1:nFrames
	% 	movieTmp(:,:,frameNo) = squeeze(nanmean(...
	% 		insertText(movieTmp(:,:,frameNo),[0 0],inputText,...
	% 		'BoxColor',[maxVal maxVal maxVal],...
	% 		'TextColor',[minVal minVal minVal],...
	% 		'AnchorPoint','LeftTop',...
	% 		'FontSize',fontSize,...
	% 		'BoxOpacity',1)...
	% 	,3));
	% 	reverseStr = cmdWaitbar(frameNo,nFrames,reverseStr,'inputStr','adding text to movie','waitbarOn',1,'displayEvery',10);
	% end
	% maxVal = nanmax(movieTmp(:))
	% movieTmp(movieTmp==maxVal) = 1;
	% 'BoxColor','white'

end