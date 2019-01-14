function [alignedSignal] = alignSignal(responseSignal, alignmentSignal,timeSeq,varargin)
	% Aligns values in a response signal (can be multiple response signals) to binary points in an alignment signal (e.g. 1=align to this time-point, 0=don't align).
	% Biafra Ahanonu
	% started: 2013.11.13 [23:47:34]
	% inputs
		% responseSignal = MxN matrix of M signals over N points
		% alignmentSignal = a 1xN vector of 0s and 1s, where 1s will be alignment points
		% timeSeq = 1xN sequence giving time around alignments points to process, e.g. -2:2.
	% options
		% overallAlign = align all response signals to alignmentSignal pts
	% outputs
		% alignedSignal = a matrix of size 1xlength(timeSeq) if sum all signals or Mxlength(timeSeq) if keep the sums for each signal separate
	% TODO
		% got around looping over alignment points, but there must be a way to skip looping over the input signals...DONE
		% parfor this...DONT NEED TO!
	% changelog
		% 2013.11.14 [00:45:17] initial unit tests show that it's complete, sick
		% 2013.11.14 - finished bsxfun-ing the loop over the signal, haven't speed-tested to see if it is faster...should be. Keeping for-loop code in case need to add some sort of processing there later.
		% 2014.01.11 [19:49:33] now pad the end of responseSignal with NaNs and idx these if the alignment idx falls outside the responseSignal range, more elegant than previous solution.

	%========================
	% sum alignment over all signals
	options.overallAlign = 0;
	% return the per stimulus response for each signal
	options.returnTrialAlign = 0;
	% meanResponseAll, perStimSignalResponse, perSignalStimResponseMean
	options.returnFormat = '';
	% get options
	options = getOptions(options,varargin);
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%     eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================
	% check that inputs are correct
	if isempty(responseSignal)|isempty(alignmentSignal)|isempty(timeSeq)
		alignedSignal = [];
		return
	end
	% force timeSeq to correct format
	timeSeq = timeSeq(:)';
	% attempt to align the input signals to the alignment points
	try
		% note: we do this to avoid a for-loop over all alignment indices. this allows us to create a large matrix containing all the indices that need to be aligned, this can later be reshaped
		% create a function to do the outer product...same as @plus, keeping for now
		% outerFun = @(x,y) x+y;
		% get number of signals to analyze
		nSignals = size(responseSignal,1);
		nPoints = size(responseSignal,2);
		% pad end rows with NaNs
		responseSignal(:,end+1) = NaN;
		% number of points
		nTimeSeqPoints = length(timeSeq);
		% pre-allocate the aligned signal
		alignedSignal = zeros(nSignals,nTimeSeqPoints);
		% find the locations to align
		alignIndicies = find(alignmentSignal==1);
		% number of alignment points in alignmentSignal
		nAlignmemts = length(alignIndicies);
		% outer the time sequence and the current indices to get a MxN matrix of M indices before/after N alignment points
		alignIdx = bsxfun(@plus,timeSeq',alignIndicies);
		% point idx to NaNs if outside responseSignal's range
		alignIdx(find((alignIdx<1))) = nPoints+1;
		alignIdx(find((alignIdx>nPoints))) = nPoints+1;
		% get the indices as a [nSignals (nTimeSeqPoints*nAlignmemts)]
		alignedSignal = responseSignal(:,alignIdx);

		% alignIdx
		% size(alignedSignal)
		% pause;


		% backward compatibility
		if options.returnTrialAlign==1
			options.returnFormat = 'perStimSignalResponse';
		end
		switch options.returnFormat
			case 'perStimSignalResponse'
				% return matrix of all trials aligned for each signal
				% display('returning all trials...')
				A = reshape(alignedSignal', [nAlignmemts nTimeSeqPoints nSignals]);
				C = permute(A,[1 3 2]);
				C = reshape(C,[],size(A,2),1);
				alignedSignal = C;
			case '[nSignals nAlignmemts nTimeSeqPoints]'
				% return matrix of all trials aligned for each signal
				% display('returning all trials...')
				A = reshape(alignedSignal', [nTimeSeqPoints nAlignmemts nSignals]);
				C = permute(A,[3 2 1]);
				% C = reshape(C,[],size(A,2),1);
				alignedSignal = C;
			case 'max:[nSignals nAlignmemts]'
				% [nSignals nAlignmemts]
				alignedSignal = reshape(alignedSignal', [nTimeSeqPoints nAlignmemts nSignals]);
				alignedSignal = squeeze(nanmax(alignedSignal,[],1))';
			case 'mean:[nSignals nAlignmemts]'
				% [nSignals nAlignmemts]
				alignedSignal = reshape(alignedSignal', [nTimeSeqPoints nAlignmemts nSignals]);
				alignedSignal = squeeze(nanmean(alignedSignal,1))';
			case 'sum:[nSignals nAlignmemts]'
				% [nSignals nAlignmemts]
				alignedSignal = reshape(alignedSignal', [nTimeSeqPoints nAlignmemts nSignals]);
				alignedSignal = squeeze(nansum(alignedSignal,1))';
			case 'std:[nSignals nAlignmemts]'
				% [nSignals nAlignmemts]
				alignedSignal = reshape(alignedSignal', [nTimeSeqPoints nAlignmemts nSignals]);
				alignedSignal = squeeze(nanstd(alignedSignal,[],1))';
			case 'count:[nSignals nAlignmemts]'
				% [nSignals nAlignmemts]
				alignedSignal = reshape(alignedSignal', [nTimeSeqPoints nAlignmemts nSignals]);
				alignedSignal = squeeze(nansum(alignedSignal,1))';
			case 'normcount:[nSignals nAlignmemts]'
				alignedSignal = reshape(alignedSignal', [nTimeSeqPoints nAlignmemts nSignals]);
				a = squeeze(nansum(alignedSignal,1))';
				% size(a)
				maxA = max(a,[],1);
				minA = min(a,[],1);
				[row,col] = size(a);
				% outputVector = (inputVector-minVec)./(maxVec-minVec);
				alignedSignal = (a-repmat(minA,row,1))./repmat(maxA-minA,row,1);
				% alignedSignal = alignedSignal';
				% size(alignedSignal)
			case 'meanTrialIdx:[nSignals nAlignmemts]'
				% [nSignals nTimeSeqPoints]
				alignedSignal = reshape(alignedSignal', [nTimeSeqPoints nAlignmemts nSignals]);
				% add indicies
				alignIdxNums = repmat(timeSeq(:),[1 nAlignmemts nSignals]);
				alignedSignal = alignedSignal.*alignIdxNums;
				% get the mean response index for each trial
				alignedSignal(alignedSignal==0) = NaN;
				alignedSignal = squeeze(nanmean(alignedSignal,1))';
			case 'perSignalStimResponseCount'
				% [nSignals nTimeSeqPoints*nAlignmemts]
				% alignedSignal = alignedSignal;
				alignedSignal = nansum(reshape(alignedSignal', [nTimeSeqPoints nAlignmemts nSignals]),2);
				% % squeeze to 2D, flip so have [nSignals nTimeSeqPoints] matrix
				alignedSignal = squeeze(alignedSignal);
				% if nTimeSeqPoints~=1
				% 	alignedSignal = alignedSignal';
				% end
			case 'perSignalStimResponseMean'
				% [nSignals nTimeSeqPoints]
				% mean responses across all stimuli for each signal
				alignedSignal = nanmean(reshape(alignedSignal', [nTimeSeqPoints nAlignmemts nSignals]),2);
				% squeeze to 2D, flip so have [nSignals nAlignPoints] matrix
				alignedSignal = squeeze(alignedSignal);
				if nTimeSeqPoints~=1
					alignedSignal = alignedSignal';
				end
			case 'perSignalStimResponseStd'
				% [nSignals nTimeSeqPoints]
				% mean responses across all stimuli for each signal
				alignedSignal = nanstd(reshape(alignedSignal', [nTimeSeqPoints nAlignmemts nSignals]),[],2);
				% squeeze to 2D, flip so have [nSignals nAlignPoints] matrix
				alignedSignal = squeeze(alignedSignal);
				if nTimeSeqPoints~=1
					alignedSignal = alignedSignal';
				end
			case 'totalStimResponseCount'
				% [1 stimulusPoints]
				% giving the total summed response in responseSignal at each alignment point
				alignedSignal = nansum(alignedSignal,1);
			case 'totalStimAlignedResponseMean'
				% [1 stimulusPoints]
				alignedSignal = nansum(reshape(alignedSignal', [nTimeSeqPoints nAlignmemts nSignals]),2);
				% squeeze to 2D, flip so have [nSignals nTimeSeqPoints] matrix
				alignedSignal = squeeze(alignedSignal);
				%
				alignedSignal = alignedSignal/nAlignmemts;
				% mean response of all signals aligned to stimulus points
				alignedSignal = nanmean(alignedSignal,1);
			case 'totalStimResponseMean'
				% [1 stimulusPoints]
				alignedSignal = nanmean(reshape(alignedSignal', [nTimeSeqPoints nAlignmemts nSignals]),2);
				% squeeze to 2D, flip so have [nSignals nTimeSeqPoints] matrix
				alignedSignal = squeeze(alignedSignal);
				%
				% alignedSignal = alignedSignal/nAlignmemts;
				% mean response of all signals aligned to stimulus points
				alignedSignal = nanmean(alignedSignal,1);
			case 'mean[1 nTimeSeqPoints]'
				% [1 stimulusPoints]
				alignedSignal = nanmean(reshape(alignedSignal', [nTimeSeqPoints nAlignmemts nSignals]),2);
				% squeeze to 2D, flip so have [nSignals nTimeSeqPoints] matrix
				alignedSignal = squeeze(alignedSignal);
				% alignedSignal = alignedSignal/nAlignmemts;
				% mean response of all signals aligned to stimulus points
				alignedSignal = nanmean(alignedSignal,2);
			case 'mean-sum[1 nTimeSeqPoints]'
				% [1 stimulusPoints]
				alignedSignal = nanmean(reshape(alignedSignal', [nTimeSeqPoints nAlignmemts nSignals]),2);
				% squeeze to 2D, flip so have [nSignals nTimeSeqPoints] matrix
				alignedSignal = squeeze(alignedSignal);
				% alignedSignal = alignedSignal/nAlignmemts;
				% mean response of all signals aligned to stimulus points
				alignedSignal = nansum(alignedSignal,2);
			otherwise
				% reshape so have all alignment points as own 2D matrix
				% sum responses across all stimuli
				alignedSignal = nansum(reshape(alignedSignal', [nTimeSeqPoints nAlignmemts nSignals]),2);
				% squeeze to 2D, flip so have [nSignals nTimeSeqPoints] matrix
				alignedSignal = squeeze(alignedSignal);
				% if user wants summed alignment over all signals
				if options.overallAlign==1
					% alignedSignal = nansum(alignedSignal,2);
					alignedSignal = nanmax(alignedSignal,[],2);
				end
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
		alignedSignal=[];
	end

% OLD CODE - for reference
	% for signalNum = 1:nSignals
	% 	thisSignal = responseSignal(signalNum,:);
	% 	% get the indices and then just sum over N dimension to get total response at each time-point before/after alignment points
	% 	thisAlignedSignal = sum(thisSignal(alignIdx),2);
	% 	% all to alignedSignal matrix
	% 	alignedSignal(signalNum,:) = thisAlignedSignal;
	% end