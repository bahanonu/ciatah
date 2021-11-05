function [validFoldersIdx] = pipelineFolderFilter(obj,useAltValid,validFoldersIdx)
	% DESCRIPTION
	% Biafra Ahanonu
	% started: 2014.07.31 - branch from calciumImagingAnalysis 2020.05.07 [15:47:29]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	switch useAltValid
		case 'manual index entry'
		theseSettings = inputdlg({...
				'list (separated by commas) of indexes'
				},...
					'Folders to process',1,...
				{...
					'1'
				}...
			);
		validFoldersIdx = str2num(theseSettings{1});
		case 'missing extracted cells'
			switch obj.signalExtractionMethod
				case 'PCAICA'
					missingRegexp = {obj.rawPCAICAStructSaveStr,obj.rawICfiltersSaveStr};
				case 'EM'
					missingRegexp = obj.rawEMStructSaveStr;
				case 'EXTRACT'
					missingRegexp = obj.rawEXTRACTStructSaveStr;
				case 'CNMF'
					missingRegexp = obj.rawCNMFStructSaveStr;
				case 'CNMFE'
					missingRegexp = obj.extractionMethodStructSaveStr.(obj.signalExtractionMethod);
				otherwise
					missingRegexp = obj.extractionMethodStructSaveStr.(obj.signalExtractionMethod);
			end
			missingRegexp = strrep(missingRegexp,'.mat','');
			validFoldersIdx2 = [];
			for folderNo = 1:length(obj.dataPath)
				filesToLoad = getFileList(obj.dataPath{folderNo},missingRegexp);
				if isempty(filesToLoad)
					disp(['no extracted signals: ' obj.dataPath{folderNo}])
					validFoldersIdx2(end+1) = folderNo;
				end
			end
			validFoldersIdx = intersect(validFoldersIdx,validFoldersIdx2);
		case 'has extracted cells'
			switch obj.signalExtractionMethod
				case 'PCAICA'
					cellRegexp = {obj.rawPCAICAStructSaveStr,obj.rawICfiltersSaveStr};
				case 'EM'
					cellRegexp = obj.rawEMStructSaveStr;
				case 'EXTRACT'
					cellRegexp = obj.rawEXTRACTStructSaveStr;
				case 'CNMF'
					cellRegexp = obj.rawCNMFStructSaveStr;
				case 'CNMFE'
					cellRegexp = obj.extractionMethodStructSaveStr.(obj.signalExtractionMethod);
				otherwise
					% cellRegexp = {obj.rawPCAICAStructSaveStr,obj.rawICfiltersSaveStr};
					cellRegexp = obj.extractionMethodStructSaveStr.(obj.signalExtractionMethod);
			end
			cellRegexp = strrep(cellRegexp,'.mat','');
			validFoldersIdx2 = [];
			for folderNo = 1:length(obj.dataPath)
				filesToLoad = getFileList(obj.dataPath{folderNo},cellRegexp);
				if ~isempty(filesToLoad)
					disp(['has extracted signals: ' obj.dataPath{folderNo}])
					validFoldersIdx2(end+1) = folderNo;
				end
			end
			validFoldersIdx = intersect(validFoldersIdx,validFoldersIdx2);
		case 'movie file'
			movieRegexp = obj.fileFilterRegexp;
			validFoldersIdx2 = [];
			for folderNo = 1:length(obj.dataPath)
				filesToLoad = getFileList(obj.dataPath{folderNo},movieRegexp);
				if ~isempty(filesToLoad)
					disp(['has movie file: ' obj.dataPath{folderNo}])
					validFoldersIdx2(end+1) = folderNo;
				end
			end
			validFoldersIdx = intersect(validFoldersIdx,validFoldersIdx2);
		case 'fileFilterRegexp'
			validFoldersIdx2 = [];
			for folderNo = 1:length(obj.dataPath)
				filesToLoad = getFileList(obj.dataPath{folderNo},obj.fileFilterRegexp);
				if isempty(filesToLoad)
					validFoldersIdx2(end+1) = folderNo;
					disp(['missing dfof: ' obj.dataPath{folderNo}])
				end
			end
			validFoldersIdx = intersect(validFoldersIdx,validFoldersIdx2);
		case 'valid auto'
			validFoldersIdx = find(cell2mat(cellfun(@isempty,obj.validAuto,'UniformOutput',0)));
		case 'not manually sorted folders'
			switch obj.signalExtractionMethod
				case 'PCAICA'
					missingRegexp = obj.sortedICdecisionsSaveStr;
				case 'EM'
					missingRegexp = obj.sortedEMStructSaveStr;
				case 'EXTRACT'
					missingRegexp = obj.sortedEXTRACTStructSaveStr;
				case 'CNMF'
					missingRegexp = obj.sortedCNMFStructSaveStr;
				otherwise
					missingRegexp = obj.extractionMethodSortedSaveStr.(obj.signalExtractionMethod);
			end
			validFoldersIdx = [];
			missingRegexp = strrep(missingRegexp,'.mat','');
			disp(['missingRegexp: ' missingRegexp])
			for folderNo = 1:length(obj.inputFolders)
				filesToLoad = getFileList(obj.inputFolders{folderNo},missingRegexp);
				% filesToLoad
				%filesToLoad
				if isempty(filesToLoad)
					validFoldersIdx(end+1) = folderNo;
					disp(['not manually sorted: ' obj.dataPath{folderNo}])
				else
					disp(['manually sorted: ' obj.dataPath{folderNo}])
				end
			end
		case 'manually sorted folders'
			switch obj.signalExtractionMethod
				case 'PCAICA'
					missingRegexp = obj.sortedICdecisionsSaveStr;
				case 'EM'
					missingRegexp = obj.sortedEMStructSaveStr;
				case 'EXTRACT'
					missingRegexp = obj.sortedEXTRACTStructSaveStr;
				case 'CNMF'
					missingRegexp = obj.sortedCNMFStructSaveStr;
				otherwise
					missingRegexp = obj.extractionMethodSortedSaveStr.(obj.signalExtractionMethod);
			end
			validFoldersIdx = [];
			missingRegexp = strrep(missingRegexp,'.mat','');
			disp(['missingRegexp: ' missingRegexp])
			for folderNo = 1:length(obj.inputFolders)
				filesToLoad = getFileList(obj.inputFolders{folderNo},missingRegexp);
				%filesToLoad
				if ~isempty(filesToLoad)
					validFoldersIdx(end+1) = folderNo;
					disp(['manually sorted: ' obj.dataPath{folderNo}])
				end
			end
		case 'manual classification already in obj'
			validFoldersIdx = find(arrayfun(@(x) ~isempty(x{1}),obj.validManual));
		otherwise
			% body
	end
end