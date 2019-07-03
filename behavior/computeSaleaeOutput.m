function [outputData] = computeSaleaeOutput(matfile,varargin)
	% Processes Saleae output files.
	% Biafra Ahanonu
	% started: 2014.01.03 [19:13:01]
	% inputs
		% matfile - Str: path to Mat-file with Salaea outputs
	% outputs
		% outputData - table consisting of session times, frame clock (digital channel 0), and events in each channel or analog values in that frame.

	% changelog
		% 2018.05.14 [15:31:03] - fixed digital channel cumsum issue so frames where slightly mis-aligned
		% 2018.06.04 [14:50:06] - updated to filter the sync digital channel to filter out voltage spikes there as well
		% 2018.07.06 [16:26:16] - Addition to deal with sync TTLs that occur way after trial has ended
	% TODO
		%

	%========================
	options.analysisType = 'digital';
	% Str: table or struct
	options.outputType = 'table';
	% Vector: list of channels to analyze, empty is all
	options.digitalChannelList = [];
	% Float: seconds below which to filter voltage spikes in digital data, empty to not use
	options.filterVoltageSpikes = 1e-6;
	% Float: For digital channel 0 (or sync) seconds below which to filter voltage spikes in digital data, empty to not use
	options.filterVoltageSpikesSyncCh = 24.5/1000; %this is dynamically determined now
	options.filterVoltageSpikesSyncChHigh = 1000/1000;
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
		display(repmat('-',1,7))
		fprintf('Loading: %s\n',matfile)
		load(matfile);

		if strcmp(options.analysisType,'digital')
			digital_channel_0 = digital_channel_0(1:end-1);
			clockTimes = digital_channel_0/digital_sample_rate_hz;
			clockTimesOriginal = clockTimes;
			clockTimes = cumsum(clockTimes);

			% Remove spikes, not actual data
			[clockTimes] = subfxn_filterSyncSpikes(clockTimes,clockTimesOriginal,options.filterVoltageSpikesSyncCh,options.filterVoltageSpikesSyncChHigh);

			initialClockState = digital_channel_initial_bitstates(1);
			if initialClockState==0
				clockFrameTimes = clockTimes(1:2:end);
				% clockFrameDurations = clockTimes(2:2:end);
				clockFrameCount = 1:length(clockFrameTimes);
			end
			nFrames = length(clockFrameCount);

			if isempty(options.digitalChannelList)
				nChannels = 7;
				digitalChannelList = 1:7;
			else
				nChannels = length(options.digitalChannelList);
				digitalChannelList = options.digitalChannelList;
			end

			dcFrStateMatrix = NaN([nFrames, 7+2]);
			dcFrStateMatrix(:,1) = clockFrameTimes(:);
			dcFrStateMatrix(:,2) = clockFrameCount(:);
			for digitalChannelNo = 1:nChannels
				dChan = digitalChannelList(digitalChannelNo);
				% dc1FrameState = zeros([nFrames 1]);
				eval(sprintf('digital_channel = digital_channel_%d(1:end-1);',dChan));
				digital_channel = digital_channel/digital_sample_rate_hz;
				digital_channelCumsum = cumsum(digital_channel);
				dcA{1}{1} = digital_channelCumsum(1:2:end);
				dcA{1}{2} = digital_channel(2:2:end);
				for frameNo = 1:nFrames
					if frameNo==nFrames
						frameTime = [clockFrameTimes(frameNo) Inf];
					else
						frameTime = [clockFrameTimes(frameNo) clockFrameTimes(frameNo+1)];
					end
					% frameTime
					fvs = options.filterVoltageSpikes;
					dcFrStateMatrix(frameNo,2+dChan) = subfxn_xsum(dcA{1},frameTime,fvs);
				end
				if strcmp(options.outputType,'table')
					outputData = array2table(dcFrStateMatrix,'VariableNames',{...
						'clockFrameTimes',...
						'clockFrameCount',...
						'digital_channel_1',...
						'digital_channel_2',...
						'digital_channel_3',...
						'digital_channel_4',...
						'digital_channel_5',...
						'digital_channel_6',...
						'digital_channel_7'});
				else
					% outputData.nFrames = nFrames;

				end
			end
		end
		if strcmp(options.analysisType,'analog')
			digital_channel_0 = digital_channel_0(1:end-1);
			clockTimes = digital_channel_0/digital_sample_rate_hz;
			clockTimesOriginal = clockTimes;
			clockTimes = cumsum(clockTimes);

			% dynamically determine threshold to filter sync channel based on most frequent diff (e.g. framerate)
			% options.filterVoltageSpikesSyncCh
			options.filterVoltageSpikesSyncCh = median(diff(cumsum(clockTimesOriginal)));
			options.filterVoltageSpikesSyncCh = options.filterVoltageSpikesSyncCh-options.filterVoltageSpikesSyncCh*0.02;
			% options.filterVoltageSpikesSyncCh

			% Remove spikes, not actual data
			[clockTimes] = subfxn_filterSyncSpikes(clockTimes,clockTimesOriginal,options.filterVoltageSpikesSyncCh,options.filterVoltageSpikesSyncChHigh);

			% figure;plot(diff(clockTimes));zoom on

			initialClockState = digital_channel_initial_bitstates(1);
			if initialClockState==0
				clockFrameTimes = clockTimes(1:2:end);
				% clockFrameDurations = clockTimes(2:2:end);
				clockFrameCount = 1:length(clockFrameTimes);
			end
			nSamples = length(analog_channel_0);
			xcalc = @(x,y,z) nanmean(z([x>=y(1)&x<y(2)]));
			timeInterval = 1/analog_sample_rate_hz;
			totalTime = nSamples/analog_sample_rate_hz;
			acA{1} = 0:timeInterval:totalTime;
			acA{2} = 0:timeInterval:totalTime;
			acA{3} = 0:timeInterval:totalTime;
			acAAll = 0:timeInterval:totalTime;

			if nSamples<num_samples_analog
				analog_channel_0(end+1) = 0;
				analog_channel_1(end+1) = 0;
				analog_channel_2(end+1) = 0;
			end

			if length(acAAll)>length(analog_channel_0)
				acAAll = acAAll(1:length(analog_channel_0));
			end

			nFrames = length(clockFrameCount);

			% tic
			% % clockFrameGroups = [];
			% clockFrameGroups = acA{1}<clockFrameTimes(1);
			% for frameNo = 2:nFrames
			% 	if frameNo==nFrames
			% 		frameTime = [clockFrameTimes(frameNo) Inf];
			% 	else
			% 		frameTime = [clockFrameTimes(frameNo) clockFrameTimes(frameNo+1)];
			% 	end
			% 	% plot(acA{1}<clockFrameTimes(frameNo));drawnow
			% 	newVec = acA{1}<clockFrameTimes(frameNo);
			% 	clockFrameGroups = clockFrameGroups+newVec;
			% 	% [clockFrameGroups(1) clockFrameTimes(frameNo) newVec(1)]
			% end
			% newVec = acA{1}<Inf;
			% clockFrameGroups = newVec+clockFrameGroups;
			% clockFrameGroups = nanmax(clockFrameGroups(:))-clockFrameGroups+1;
			% plot(clockFrameGroups);drawnow
			% % clockFrameGroups
			% ac1FrState = splitapply(@nanmean,analog_channel_0(:),clockFrameGroups(:));
			% ac2FrState = splitapply(@nanmean,analog_channel_1(:),clockFrameGroups(:));
			% ac3FrState = splitapply(@nanmean,analog_channel_2(:),clockFrameGroups(:));

			% ac1FrState = ac1FrState(1:end-1);
			% ac2FrState = ac2FrState(1:end-1);
			% ac3FrState = ac3FrState(1:end-1);
			% toc

			tic
			% size(acAAll)
			% size(analog_channel_0)
			ac1FrState = NaN([nFrames 1]);
			ac2FrState = NaN([nFrames 1]);
			ac3FrState = NaN([nFrames 1]);

			parfor frameNo = 1:nFrames
				if frameNo==nFrames
					frameTime = [clockFrameTimes(frameNo) Inf];
				else
					frameTime = [clockFrameTimes(frameNo) clockFrameTimes(frameNo+1)];
				end
				% frameTime
				logicVec = [acAAll>=frameTime(1)&acAAll<frameTime(2)];
				% if isnan(nanmean(analog_channel_0(logicVec)))
				% 	frameNo
				% 	find(logicVec)
				% 	analog_channel_0(logicVec)
				% end
				ac1FrState(frameNo) = nanmean(analog_channel_0(logicVec));
				ac2FrState(frameNo) = nanmean(analog_channel_1(logicVec));
				ac3FrState(frameNo) = nanmean(analog_channel_2(logicVec));
				% ac1FrState(frameNo) = xcalc(acA{1},frameTime,analog_channel_0);
				% ac2FrState(frameNo) = xcalc(acA{2},frameTime,analog_channel_1);
				% ac3FrState(frameNo) = xcalc(acA{3},frameTime,analog_channel_2);
			end
			toc

			outputData = table(clockFrameTimes(:),...
				clockFrameCount(:),...
				ac1FrState(:),...
				ac2FrState(:),...
				ac3FrState(:),...
				'VariableNames',{...
				'clockFrameTimes',...
				'clockFrameCount',...
				'analog_channel_0',...
				'analog_channel_1',...
				'analog_channel_2'});
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end
%% functionname: function description
function [output] = subfxn_xsum(x,y,filterOn)
	% xsum = @(x,y) logical(sum(x{1}>=y(1)&x{1}<y(2)));
	logicalVector = x{1}>=y(1)&x{1}<y(2);
	if ~isempty(filterOn)
		% x{2}
		% Remove 1 us spikes, not actual data
		logicalVector(x{2}<=filterOn) = 0;
	end
	% xsum = @(x,y) logical(sum(logicalVector));
	output = logical(sum(logicalVector));
end
function [clockTimes] = subfxn_filterSyncSpikes(clockTimes,clockTimesOriginal,filterVoltageSpikesSyncCh,filterVoltageSpikesSyncChHigh)

	digitalState = repmat([1 0],1,round(length(clockTimesOriginal)/2));

	% clockTimesOriginal

	% Remove spikes, not actual data
	if ~isempty(filterVoltageSpikesSyncCh)
		% Filter both fall and rise spike
		logicalVector = clockTimesOriginal<=filterVoltageSpikesSyncCh|clockTimesOriginal>=filterVoltageSpikesSyncChHigh;
		logicalVectorAbove = clockTimesOriginal>filterVoltageSpikesSyncCh&clockTimesOriginal<filterVoltageSpikesSyncChHigh;
		spikeFilter1 = find(logicalVector);
		spikeFilter1(spikeFilter1==1) = [];

		% Remove spikes taking place in middle of up miniscope state
		spikeFilter1(logicalVectorAbove(spikeFilter1-1)) = [];

		% check that t - 1 state is 1
		digitalStateFilt = digitalState==1;
		% filter out spikes past main clock times
		spikeFilter1(spikeFilter1>length(digitalStateFilt)) = [];
		digitalStateFilt = digitalStateFilt(spikeFilter1-1);
		spikeFilter1 = spikeFilter1(digitalStateFilt);

		spikeFilter2 = spikeFilter1-1;
		spikeFilter1 = [spikeFilter1(:);spikeFilter2(:)];

		% clockTimes(end-10:end)
		% clockTimesOriginal(end-10:end)
		% spikeFilter1

		clockTimes(spikeFilter1) = [];

		% clockTimes
	end
end