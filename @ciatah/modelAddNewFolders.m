function obj = modelAddNewFolders(obj,varargin)
	% Add folders to the class.
	% Biafra Ahanonu
	% started: 2014.12.22 (probably before)
	% changelog
		% 2019.10.09 [18:28:12] - use inputdlgcol to allow re-sizing of window
		% 2019.11.18 [15:15:47] - Add the ability for users to use GUI to add folders as alternative option.
		% 2020.01.16 [12:28:29] - Choosing how to enter files and manual enter list of files now uses uicontrol and figure to reduce number of pop-ups and increase flexibility.
		% 2020.05.07 [17:22:20] - Adding option to quickly add all the example downloaded folders.
		% 2021.01.24 [14:03:44] - Added support for direct input of method type, useful for command-line or unit testing.
		% 2021.02.02 [11:27:21] - 'Add CIAtah example folders.' now adds the absolute path to avoid path errors if user changes Matlab current directory.
		% 2021.06.01 [??15:43:11] - Add 'next' button to initial menu, in part to add MATLAB Online support.
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Cell array of folders to add, particularly for GUI-less operations
	options.folderCellArray = {};
	% Str:
	options.inputMethod = '';
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
		nExistingFolders = length(obj.inputFolders);
		if isempty(options.folderCellArray)
			sel = 0;
			if isempty(options.inputMethod)
				usrIdxChoiceStr = {...
					'manually enter folders to list',...
					'GUI select folders',...
					'Add CIAtah example folders.'};
				scnsize = get(0,'ScreenSize');
				try
					hFig = figure;
					uicontrol('Style','Text','String',['How to add folders to CIAtah?'],'Units','normalized','Position',[5 89 90 10]/100,'BackgroundColor','white','HorizontalAlignment','Left','FontWeight','bold');
					exitHandle = uicontrol('style','pushbutton','Units', 'normalized','position',[5 85 50 3]/100,'FontSize',9,'string','Click here to move to next screen','callback',@subfxnNextFig,'HorizontalAlignment','Left');
					hListbox = uicontrol(hFig, 'style','listbox','Units', 'normalized','position',[5,5,90,80]/100, 'string',usrIdxChoiceStr,'Value',1);
					set(hListbox,'Max',2,'Min',0);
					set(hListbox,'KeyPressFcn',@(src,evnt)onKeyPressRelease(evnt,'press',hFig))
					figure(hFig)
					uicontrol(hListbox)
					set(hFig, 'KeyPressFcn', @(source,eventdata) figure(hFig));
					uiwait(hFig)
				catch err
					disp(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					disp(repmat('@',1,7))

					[sel, ok] = listdlg('ListString',usrIdxChoiceStr,'ListSize',[scnsize(3)*0.3 scnsize(4)*0.3],'Name','How to add folders to CIAtah?');
				end
				inputMethod = usrIdxChoiceStr{sel};
			else
				inputMethod = options.inputMethod;
			end

			switch inputMethod
				case 'Add CIAtah example folders.'
					disp('Adding example folders to path...')
					dataDir = ciapkg.getDirPkg('data');
					newFolderList = {...
						[dataDir filesep '2014_04_01_p203_m19_check01'],...
						[dataDir filesep 'batch' filesep '2014_08_05_p104_m19_PAV08'],...
						[dataDir filesep 'batch' filesep '2014_08_06_p104_m19_PAV09'],...
						[dataDir filesep 'batch' filesep '2014_08_07_p104_m19_PAV10'],...
						[dataDir filesep 'twoPhoton' filesep '2017_04_16_p485_m487_runningWheel02']...
					};
                    disp(newFolderList)
					nNewFolders = length(newFolderList);
					fileIdxArray = (nExistingFolders+1):(nExistingFolders+nNewFolders);
					nFolders = length(fileIdxArray);
					newFolderListCell = {};
					for thisFileNumIdx = 1:nFolders
						% strtrim(newFolderList(thisFileNumIdx,:))
						% class(strtrim(newFolderList(thisFileNumIdx,:)))
						% ciapkg.getDir() filesep
						% pathToAdd = [obj.defaultObjDir filesep newFolderList{thisFileNumIdx}];
						pathToAdd = [newFolderList{thisFileNumIdx}];
						newFolderListCell{thisFileNumIdx} = strtrim(pathToAdd);
					end
					disp(nFolders)
					disp(newFolderListCell)
				case 'manually enter folders to list'
					newFolderList = '';
					try

						hFig = figure;
						figure(hFig)

						% finishMethodHandle = uicontrol('style','pushbutton','Units', 'normalized','position',[1 94 38 2]/100,'FontSize',9,'string','Start selected method (or press enter)','BackgroundColor',[153 255 153]/255,'callback',@subfxnCloseFig);

						uicontrol('Style','Text','String',['Adding folders to CIAtah object.'],'Units','normalized','Position',[5 95 90 3]/100,'BackgroundColor','white','HorizontalAlignment','Left','FontWeight','bold');
						uicontrol('Style','Text','String',['One new line per folder path. Enter folder path WITHOUT any single/double quotation marks around the path.'],'Units','normalized','Position',[5 90 90 6]/100,'BackgroundColor','white','HorizontalAlignment','Left');
						exitHandle = uicontrol('style','pushbutton','Units', 'normalized','position',[5 85 50 3]/100,'FontSize',9,'string','Click here to finish','callback',@subfxnCloseFig,'HorizontalAlignment','Left');

						hListbox = uicontrol(hFig, 'style','edit','Units', 'normalized','position',[5,5,90,80]/100, 'string','','FontSize',obj.fontSizeGui,'HorizontalAlignment','left');
						set(hListbox,'Max',2,'Min',0);
						uiwait(hFig)
						% hListboxStruct.Value = hListbox.string;
					catch err
						disp(repmat('@',1,7))
						disp(getReport(err,'extended','hyperlinks','on'));
						disp(repmat('@',1,7))

						AddOpts.Resize='on';
						AddOpts.WindowStyle='normal';
						AddOpts.Interpreter='tex';
						% inputdlg
						newFolderList = inputdlgcol('One new line per folder path. Enter folder path WITHOUT any single/double quotation marks around the path.','Adding folders to CIAtah object.',[21 150],{''},AddOpts);
						if isempty(newFolderList)
							warning('No folders given. Please re-run modelAddNewFolders.')
							return
						end
						newFolderList = newFolderList{1,1};
					end
					% size(newFolderList)
					% class(newFolderList)

					% if obj.guiEnabled==1
					% 	scnsize = get(0,'ScreenSize');
					% 	[fileIdxArray, ok] = listdlg('ListString',obj.fileIDNameArray,'ListSize',[scnsize(3)*0.2 scnsize(4)*0.25],'Name','which folders to analyze?');
					% else
					% 	fileIdxArray = 1:length(obj.fileIDNameArray);
					% end
					nNewFolders = size(newFolderList,1);
					fileIdxArray = (nExistingFolders+1):(nExistingFolders+nNewFolders);
					nFolders = length(fileIdxArray);
					newFolderListCell = {};
					for thisFileNumIdx = 1:nFolders
						% strtrim(newFolderList(thisFileNumIdx,:))
						% class(strtrim(newFolderList(thisFileNumIdx,:)))
						newFolderListCell{thisFileNumIdx} = strtrim(newFolderList(thisFileNumIdx,:));
					end
				case 'GUI select folders'
					thisFileNumIdx = 1;
					newFolderListCell = {};
					pathToAdd = '';
					while ~isempty(pathToAdd)|length(newFolderListCell)<1
						try
							if ischar(pathToAdd)
								disp('Select a folder to add. Press cancel to stop adding folders.')
								pathToAdd = uigetdir(pathToAdd,'Select a folder to add. Press cancel to stop adding folders.');
								% If user cancels, do not add folder.
								if pathToAdd~=0
									fprintf('Adding folder #%d: %s.\n',thisFileNumIdx,pathToAdd);
									newFolderListCell{thisFileNumIdx} = pathToAdd;
									thisFileNumIdx = thisFileNumIdx+1;
								end
							else
								% Force exit
								pathToAdd = [];
							end
						catch err
							disp(repmat('@',1,7))
							disp(getReport(err,'extended','hyperlinks','on'));
							disp(repmat('@',1,7))
						end
					end
					nNewFolders = length(newFolderListCell);
					fileIdxArray = (nExistingFolders+1):(nExistingFolders+nNewFolders);
				otherwise
					% body
			end
		else
			newFolderListCell = options.folderCellArray;
			nNewFolders = length(newFolderListCell);
		end

		fileIdxArray = (nExistingFolders+1):(nExistingFolders+nNewFolders);
		% obj.foldersToAnalyze = fileIdxArray;
		nFolders = length(fileIdxArray);
		display(repmat('-',1,7))
		display('Existing folders:')
		cellfun(@display,obj.inputFolders)
		display(repmat('-',1,7))
		display(['Number new folders:' num2str(nFolders) ' | New folder indices: ' num2str(fileIdxArray)]);
		for thisFileNumIdx = 1:nFolders
			fileNum = fileIdxArray(thisFileNumIdx);
			obj.fileNum = fileNum;
			obj.inputFolders{obj.fileNum,1} = newFolderListCell{thisFileNumIdx};
			obj.dataPath{obj.fileNum,1} = newFolderListCell{thisFileNumIdx};
			% display(repmat('=',1,21))
			% display([num2str(fileNum) '/' num2str(nFolders) ': ' obj.fileIDNameArray{obj.fileNum}]);
		end
		display('Folders added:')
		cellfun(@display,obj.inputFolders((end-nFolders+1):end));
		display('Adding file info to class...')
		obj.modelGetFileInfo();
		% display('Getting model variables...')
		% obj.modelVarsFromFiles();
		% display('Running pipeline...')
		% obj.runPipeline();

		% Reset folders to analyze
		obj.foldersToAnalyze = [];
	catch err
		obj.foldersToAnalyze = [];
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
	function subfxnCloseFig(src,event)
		newFolderList = hListbox.String;
		close(hFig)
	end
	function subfxnNextFig(src,event)
		sel = hListbox.Value;
		close(hFig)
	end
	function onKeyPressRelease(evnt, pressRelease,hFig)
		% disp(evnt)
		% disp(pressRelease)
		if strcmp(evnt.Key,'return')
			sel = hListbox.Value;
			% hListboxStruct = struct(hListbox);
			close(hFig)
		end
		% If escape, close.
		if strcmp(evnt.Key,'escape')
			sel = 1;
			close(hFig)
		end
	end
end