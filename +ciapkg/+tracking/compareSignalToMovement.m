function [outputData] = compareSignalToMovement(inputSignals,inputMovement,varargin)
	% Compares a set of input signals to a movement vector.
	% Biafra Ahanonu
	% started: 2013.10.30 [12:45:53]
	% inputs
		% inputSignals
		% inputMovement - a table containing XM, YM, Angle, Slice, and velocity.
	% outputs
		% outputData
	% changelog
		% 2014.12.15 [12:03:55] - using smooth instead of filtfilt since it handles NaNs better
	% TODO
		%

	%========================
	% number of points over which to apply the moving average
	options.movAvg = 5;
	% whether to make additional plots
	options.makePlots = 1;
	% for velocity, cm/s to use as cutoff for stimulus
	options.stimCuttof = 1.5;
	% precomputed peaks
	options.signalPeaks = [];
	options.signalPeakIdx = [];
	% get options
	options = getOptions(options,varargin);
	% display(options);
	% unpack options into current workspace
	fn=fieldnames(options);
	for i=1:length(fn)
		eval([fn{i} '=options.' fn{i} ';']);
	end
	%========================

	nPtsInputSignal = size(inputSignals,2);
	nPtsInputMovement = length(inputMovement.XM);

	% get the peaks
	if isempty(options.signalPeaks)
		[signalPeaks, signalPeakIdx] = computeSignalPeaks(inputSignals,'makePlots',0,'makeSummaryPlots',0);
	else

	end

	% obtain the velocity vectors
	xdiff = [0; diff(inputMovement.XM)];
	ydiff = [0; diff(inputMovement.YM)];
	velocity = sqrt(xdiff.^2 + ydiff.^2);
	angVel = [0; diff(inputMovement.Angle)];

	% downsample velocity so same as traces
	downsampledVelocity = downsampleVector(velocity,inputSignals);
	downsampledAngVel = downsampleVector(angVel,inputSignals);
	downsampledXM = downsampleVector(inputMovement.XM,inputSignals);
	downsampledYM = downsampleVector(inputMovement.YM,inputSignals);

	% smooth the input
	% options.movAvg=10;
	% smooth([3 4 5 2 3 2 10 1 29 1 ],7)
	avgPeaksPerPt = smooth(sum(signalPeaks,1),movAvg,'moving')';
	downsampledVelocity  = smooth(downsampledVelocity,movAvg,'moving')';
	downsampledAngVel  = smooth(downsampledAngVel,movAvg,'moving')';

	% avgPeaksPerPt = filtfilt(ones(1,movAvg)/movAvg,1,sum(signalPeaks,1));
	% downsampledVelocity  = filtfilt(ones(1,movAvg)/movAvg,1,downsampledVelocity);
	% downsampledAngVel  = filtfilt(ones(1,movAvg)/movAvg,1,downsampledAngVel);

	% sort cells by median firing rate
	medianAngleFiring = zeros(1,size(signalPeaks,1));
	medianVelocityFiring = zeros(1,size(signalPeaks,1));
	nSpikesCell = zeros(1,size(signalPeaks,1));
	for i=1:size(signalPeaks,1)
		idx = signalPeaks(i,:)>0;
		nSpikesCell(1,i) = sum(idx);
		medianAngleFiring(1,i)=median(signalPeaks(i,idx).*downsampledAngVel(idx));
		medianVelocityFiring(1,i)=median(signalPeaks(i,idx).*downsampledVelocity(idx));
	end

	outputData.avgPeaksPerPt = avgPeaksPerPt;
	outputData.downsampledVelocity = downsampledVelocity;
	outputData.downsampledAngVel = downsampledAngVel;
	outputData.medianAngleFiring = medianAngleFiring;
	outputData.medianVelocityFiring = medianVelocityFiring;
	outputData.downsampledXM = downsampledXM;
	outputData.downsampledYM = downsampledYM;
	outputData.signalPeaks = signalPeaks;
	outputData.signalPeakIdx = signalPeakIdx;
	outputData.velocity = velocity;

	%================================================
	if makePlots==1
		try
			% FIGURES
			figNo = 789;
			% look at smoothed firing rate vs. velocity
			downsampledVelocity = 5*downsampledVelocity;
			velArray = {downsampledVelocity,abs(downsampledAngVel)};
			nameArray = {'velocity','angular velocity'};
			for i=1:2
				thisVel = velArray{i};
				[figHandle figNo] = openFigure(figNo, '');
					scath = scatterhist(avgPeaksPerPt, thisVel,'Group',~(downsampledVelocity<stimCuttof),'NBins',100);
					title(['smoothed ' nameArray{i} ' vs. firing rate'])
					xlabel('firing rate (peaks/frame)')
					ylabel([nameArray{i} ' (unit/frame)'])
					hp=get(scath(1),'children'); % handle for plot inside scaterplot axes
					% set(hp,'Marker','.','MarkerSize',12);
					hold on
					% gscatter(avgPeaksPerPt, thisVel, thisVel<1)
					fitVals = polyfit(avgPeaksPerPt, thisVel,1);
					refline(fitVals(1),fitVals(2))
					set(gca,'Color','none'); box off;
					hold off;

                [figHandle figNo] = openFigure(figNo+42, '');
					scath = scatterhist(avgPeaksPerPt, thisVel,'NBins',100);
					title(['smoothed ' nameArray{i} ' vs. firing rate'])
					xlabel('firing rate (peaks/frame)')
					ylabel([nameArray{i} ' (unit/frame)'])
					hp=get(scath(1),'children'); % handle for plot inside scaterplot axes
					% set(hp,'Marker','.','MarkerSize',12);
					hold on
					% gscatter(avgPeaksPerPt, thisVel, thisVel<1)
					fitVals = polyfit(avgPeaksPerPt, thisVel,1);
					refline(fitVals(1),fitVals(2))
					set(gca,'Color','none'); box off;
					hold off;

				% %
				% figure(figNo);figNo=figNo+1;
				% 	smoothhist2D([avgPeaksPerPt; thisVel]',7,[100,100],0);
				% 	title('smoothed velocity vs. firing rate')
				% 	xlabel('firing rate (spikes/frame)')
				% 	ylabel('velocity (px/frame)')

				% plot the firing rate vs. movement parameters
				[figHandle figNo] = openFigure(figNo, '');
					plot(avgPeaksPerPt,'r')
					title([nameArray{i} ' and firing rate over trial'])
					ylabel('unit/frame');xlabel('frames')
					hold on
					plot(thisVel,'b')
					hleg1 = legend('firing rate','velocity');
					set(gca,'Color','none'); box off;
					hold off;
			end

			% sort cells based on firing rate
			[figHandle figNo] = openFigure(figNo, '');
				subplot(2,2,1)
					plot(sort(medianAngleFiring)); title('cells sorted by median ang velocity that induces spiking');
					xlabel('rank');ylabel('ang vel');
				subplot(2,2,2)
					plot(sort(nSpikesCell)); title('cells sorted by n spikes in trial');
					xlabel('rank');ylabel('peaks/trial');
				subplot(2,2,3)
					plot(nSpikesCell,medianAngleFiring, 'r.'); title('numSpikes vs. median responsive ang velocity');
					xlabel('peaks/trial');ylabel('ang vel');
				subplot(2,2,4)
					plot(nSpikesCell,medianVelocityFiring, 'r.'); title('numSpikes vs. median responsive velocity');
					xlabel('peaks/trial');ylabel('ang vel');
			drawnow
		catch err
			display(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			display(repmat('@',1,7))
		end
	end
end
function [downsampledVector1] = downsampleVector(vector1,vector2)
	% dowmsamples vector1 to have the same length as vector 2
	nPtsVector2 = length(vector2);

	downsampledVector1 = imresize(vector1(:), [nPtsVector2, 1], 'Bilinear')';

	% downsampledVector1 = interp1(1:length(vector1),vector1,linspace(1,length(vector1),nPtsVector2));
end