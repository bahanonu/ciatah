function obj = modelSaveImgToFile(obj,saveFile,thisFigName,thisFigNo,thisFileID,varargin)
	% Saves the current open figure to a file.
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2022.07.28 [17:32:57] - Update PaperPosition to auto to avoid error "Positioning Figure for ResizeFcn.  Set PaperPositionMode to 'auto' (match figure screen size) to avoid resizing and this warning."
		% 2022.09.14 [11:13:12] - Further change to PaperPositionMode to avoid errors.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	options.PaperUnits = 'inches';
	options.PaperPosition = [0 0 20 10];
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
		if obj.functionSettings.modelSaveImgToFile.showImg==0
			return
		end
		if obj.functionSettings.modelSaveImgToFile.saveImg==0
			return
		end
	catch
	end

	try
		if ~isempty(thisFigName)
			% thisFigName = 'stimTriggeredPerCell_'
			if obj.dfofAnalysis==1
				% signalPeaks = IcaTraces;
				tmpDirPath = strcat(obj.picsSavePath,filesep,thisFigName,'_dfof_',filesep);
			else
				tmpDirPath = strcat(obj.picsSavePath,filesep,thisFigName,filesep);
			end
			if ~isempty(obj.binDownsampleAmount)
				tmpDirPath = [tmpDirPath '_binAmount' num2str(obj.binDownsampleAmount) '_'];
			end
			if (~exist(tmpDirPath,'dir')) mkdir(tmpDirPath); end;
			if isempty(thisFileID)
				thisFileID = obj.fileIDArray{obj.fileNum};
				thisFileID = obj.folderBaseSaveStr{obj.fileNum};
				thisFileID = obj.folderBasePlaneSaveStr{obj.fileNum};
			end
			saveFile = strcat(tmpDirPath,filesep,thisFileID);
			% saveFile = char(strrep(strcat(tmpDirPath,thisFileID),filesep,''));
			% saveFile
			if strcmp(class(thisFigNo),'char')&strcmp(thisFigNo,'current')

			else
				try
					% set(thisFigNo,'PaperUnits',options.PaperUnits,'PaperPosition',options.PaperPosition)
					% set(thisFigNo,'PaperUnits',options.PaperUnits,'PaperPosition',options.PaperPosition)
					% set(thisFigNo,'PaperUnits',options.PaperUnits,'PaperPosition','auto');
					set(thisFigNo,'PaperUnits',options.PaperUnits,'PaperPositionMode','auto');					
					% set(thisFigNo,'PaperUnits','inches','PaperPosition',[0 0 20 20])
					set(0,'CurrentFigure',thisFigNo)
					% figure(thisFigNo)
				catch err
					display(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					display(repmat('@',1,7))
				end
			end
		end

		if strcmp(class(obj.imgSaveTypes),'char')
			obj.imgSaveTypes = {obj.imgSaveTypes};
		end
		% export_fig(sprintf('%s', saveFile), '-eps');
		% export_fig(saveFile '-eps'
		[pathstr,name,ext] = fileparts(saveFile);
		name = strrep(name,'.','_');
		saveFile = [pathstr filesep name ext];
		display(['saving img: ' saveFile])
		for imgType = 1:length(obj.imgSaveTypes)
			print(obj.imgSaveTypes{imgType},'-r100',saveFile)
		end
	catch err
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end