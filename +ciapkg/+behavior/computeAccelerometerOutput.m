function [acceleration outputStruct] = computeAccelerometerOutput(x,y,z,varargin)
	% Takes xyz accelerometer input and process total acceleration.
	% Biafra Ahanonu
	% started: 2018.04.17 [16:26:03]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% options.medianFilterLength = 600;
	options.medianFilterLength = 300;
	options.frameRate = 20;
	% Float: raw value to g force conversion
	options.rawToGfactor = 1/0.3; % g/300mV or 3.33 g/V
	% options.rawToGfactor =  (5/1024)*(1/0.3); % 5V/1024 units * g/0.001 V
	% Whether to show the plots
	options.showPlots = 0;
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
		outputStruct.null = NaN;
		% at = accelerometerTable;

		%

		x(isnan(x)) = nanmean(x(:));
		y(isnan(y)) = nanmean(y(:));
		z(isnan(z)) = nanmean(z(:));

		useJerk = 0;
		if useJerk==1
			at.x = abs([0; diff(x)]);
			at.y = abs([0; diff(y)]);
			at.z = abs([0; diff(z)]);
		else
			at.x = x*options.rawToGfactor;
			at.y = y*options.rawToGfactor;
			at.z = z*options.rawToGfactor;
		end

		% total_acceleration = sqrt(ax^2+ay^2+az^2)
		% totalAccerleration = sqrt((at.x-nanmean(at.x(:))).^2+(at.y-nanmean(at.y(:))).^2+(at.z-nanmean(at.z(:))).^2);

		% METHOD 1
		mx = @(x) (x-nanmean(x(:))).^2;
		totAccMeanSub = sqrt(mx(at.x)+mx(at.y)+mx(at.z));
		totAccMeanSub(isnan(totAccMeanSub)) = nanmean(totAccMeanSub(:));
		totAccMedian = medfilt1(totAccMeanSub(:),options.medianFilterLength,'omitnan','truncate');

		% METHOD 2
		fc = 0.5; % Cut off frequency
		fn = options.frameRate/2; % Nyquist frequency = sample frequency/2;
		bworder = 3; % 3rd order filter, high pass
		[b,a]=butter(bworder,(fc/fn),'high');
		medFiltBins = round(options.frameRate/5);

		mx = @(x) (filtfilt(b,a,medfilt1(x,medFiltBins,'omitnan','truncate'))).^2;

		% mx = @(x) (x-medfilt1(x(:),options.medianFilterLength,'omitnan','truncate')).^2;
		totAccMedianSub = sqrt(mx(at.x)+mx(at.y)+mx(at.z));

		totalAccerlerationOld = totAccMeanSub;
		% downsample to rate of movie

		% 1Hz cutoff
		[b,a] = butter(3,1/(options.frameRate/2),'low');
		totAccMeanSub = filtfilt(b,a,totAccMeanSub);
		totAccMedianSub = filtfilt(b,a,totAccMedianSub);
		% medianAjudt

		outputStruct.totalAccerlerationFinal = totAccMedianSub(:);

		outputStruct.totAccMedianSub = totAccMedianSub(:);
		outputStruct.totAccMeanSub = totAccMeanSub;

		outputStruct.totalAccerleration = totAccMeanSub(:);
		outputStruct.totalAccerleration2 = totAccMedianSub(:);
		outputStruct.totalAccerleration3 = totAccMeanSub(:) - totAccMedian(:);
		outputStruct.totalAccerleration4 = totAccMeanSub(:) - totAccMedian(:);
		outputStruct.totalAccerlerationMedian = totAccMedian(:);

		acceleration = totAccMeanSub;
		outputStruct.x = x;
		outputStruct.y = y;
		outputStruct.z = z;
		return;

		if options.showPlots==1
			% figure;
			[~, ~] = openFigure(88569, '');
			[pxx,f] = periodogram(totalAccerlerationOld,[],[],20);
			plot(f,10*log10(pxx./f),'r');hold on;
			[pxx,f] = periodogram(totalAccerleration,[],[],20);
			plot(f,10*log10(pxx./f),'b');
			legend('filtered','normal')
			title(obj.folderBaseDisplayStr{obj.fileNum})
		end

		[totalAccerleration] = computeResampledMatrix(totalAccerleration(:)', 4,'binType','mean');
		[totalAccerleration2] = computeResampledMatrix(totalAccerleration2(:)', 4,'binType','mean');
		[totalAccerleration3] = computeResampledMatrix(totalAccerleration3(:)', 4,'binType','mean');
		[totalAccerlerationOld] = computeResampledMatrix(totalAccerlerationOld(:)', 4,'binType','mean');

		% movAvgFiltSize = 5;
		% totalAccerleration = filtfilt(ones(1,movAvgFiltSize)/movAvgFiltSize,1,totalAccerleration);
		if options.showPlots==1
			[~, ~] = openFigure(45645, '');
			plot(totalAccerleration,'LineWidth',3)
			hold on;
			plot(totalAccerleration2);
			plot(totalAccerleration3);
			plot(totalAccerlerationOld);
			legend('filtered','median filtered','median filtered sub','normal')
			title(obj.folderBaseDisplayStr{obj.fileNum})
			zoom on
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end