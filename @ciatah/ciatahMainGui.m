function [idNumIdxArray, validFoldersIdx, ok] = ciatahMainGui(obj,fxnsToRun,inputTxt,currentIdx)
	% Main GUI for calciumImagingAnalysis startup
	% Biafra Ahanonu
	% started: 2020.03.23 [22:36:36] - branch from calciumImagingAnalysis 2020.05.07 [15:47:29]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2020.05.07 [17:36:12] - Selection of NWB format forces user to give information on NWB.
		% 2021.06.30 [00:10:53] - Updated to add support for viewing from disk a section of the movie if a single folder is selected. Will preview both raw and processed movies if available based on regular expressions. Users can change several options on the fly to select ones that work for their dataset.
		% 2021.06.30 [11:27:17] - Changed interface to black and changed several options to popupmenu since they only allow a single input, so listbox was not necessary. Users can also run methods or exit the GUIs using push buttons.
		% 2021.06.30 [11:27:17] - Update to ensure NWB switch is made after user selects it.
		% 2021.07.01 [08:04:59] - Updated cell extraction loading and allow a cache for faster loading if user switches between methods in the same GUI load.
		% 2021.07.01 [15:38:18] - Added support for folder loading button and some other additional improvements.
		% 2021.07.06 [11:33:22] - Cell extraction now thresholded for cleaner visuals.
		% 2021.07.07 [17:26:20] - Add sliders to allow users to quickly scroll through both movies.
		% 2021.07.13 [13:18:45] - Updated to ensure movie callback playback loop operations only occur if handles to movies are still valid, e.g. if main GUI figure is still open.
		% 2021.07.20 [13:43:50] - Update to improve handling of output variables when figure closes to avoid calling invalid handles.
		% 2021.08.10 [09:57:36] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
		% 2021.09.10 [03:02:08] - Added support for file list when selecting a specific folder.
		% 2021.10.20 [21:46:35] - Font scaling support.
        % 2022.01.04 [12:15:56] - Additional check only for movie previews of supported movie files. "Folder files" list selection additional regexp support.
        % 2022.01.25 [19:30:58] - Changed so that 'Start selected method' button selects the correct folders like occurs when pressing enter.
        % 2022.02.25 [13:06:09] - The folder list will no longer reset when selecting certain GUI elements that should not impact folder list.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	try

		%% ==========================================
		% CONSTANTS AND VARIABLES
		ok = 0;
		tooltipStruct = obj.tts;
		% Enable key check
		checkEnabled = 1;
		% Switch to only show setMovieInfo once with NWB
		nwbSetMovieInfoSwitch = 0;
		
		% Temporary store of cell-extraction images for faster loading
		signalExtImageCache = {};

		% Binary: 1 = exit without running any functions, 0 = run functions
		exitFlag = 0;

		idNumIdxArray = currentIdx;

		% Binary: 1 = run method, 0 = skip running methods
		startMethodFlag = 0;

		colorStruct = struct;
		colorStruct.red = [255 153 153]/255;
		colorStruct.yellow = [255, 255, 153]/255;

		defaultFontSize = obj.fontSizeGui;

		% How much to scale GUI font sizes.
		fontScale = obj.fontSizeGuiScale;

		% Output structure
		hListboxStruct = [];

		opts = struct;
		% Use to stop the current movie looping
		breakMovieLoop = 0;
        % Binary: 1 = enable preview of movies, 0 = do not preview movies
		enableMoviePreview = 0;
		% Binary: 1 = overlay cell-extraction outputs on the movie
		opts.overlayCellExtraction = 0;

		movieImgHandle = plot([],[],'-');
		movieAxes = plot([],[],'-');
		titleHandle = plot([],[],'-');

		excludeList = obj.methodExcludeList;
		excludeListVer2 = obj.methodExcludeListVer2;

		subjectStrUnique = unique(obj.subjectStr);
		assayStrUnique = unique(obj.assay);
		usrIdxChoiceStr = obj.usrIdxChoiceStr;
		usrIdxChoiceDisplay = obj.usrIdxChoiceDisplay;
		% use current string as default
		currentCellExtIdx = find(strcmp(usrIdxChoiceStr,obj.signalExtractionMethod));
		folderNumList = strsplit(num2str(1:length(obj.inputFolders)),' ');
		try
			selectList = strcat(folderNumList(:),'/',num2str(length(obj.inputFolders)),' | ',obj.date(:),' _ ',obj.protocol(:),' _ ',obj.fileIDArray(:),' | ',obj.inputFolders(:));
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
			selectList = obj.inputFolders(:);
		end

		%% ==========================================
		% SETUP FIGURE
		useAltValid = {'no additional filter','manually sorted folders','not manually sorted folders','manual classification already in obj',['has ' obj.signalExtractionMethod ' extracted cells'],['missing ' obj.signalExtractionMethod ' extracted cells'],'fileFilterRegexp','valid auto',['has ' obj.fileFilterRegexp ' movie file'],'manual index entry'};
		useAltValidStr = {'no additional filter','manually sorted folders','not manually sorted folders','manual classification already in obj','has extracted cells','missing extracted cells','fileFilterRegexp','valid auto','movie file','manual index entry'};

		hFig = figure;
		figBackgroundColor = [0 0 0];
		buttonBackgroundColor = [255, 255, 153]/255;
		figTextColor = [1 1 1];
		set(hFig,'color', figBackgroundColor);
		hListboxS = struct;
		set(hFig,'Name',[ciapkg.pkgName ': start-up GUI'],'NumberTitle','off')
		% [x0 y0 width height]
		uicontrol('Style','text','String',[ciapkg.pkgName],'Units','normalized','Position',[1 96 20 3]/100,'BackgroundColor',figBackgroundColor,'HorizontalAlignment','Left','ForegroundColor',figTextColor,'FontWeight','bold','FontAngle','italic','FontSize',defaultFontSize*fontScale);
		uicontrol('Style','text','String',[inputTxt ' Press TAB to select next section, ENTER to continue, and ESC to exit.'],'Units','normalized','Position',[10 96 90 3]/100,'BackgroundColor',figBackgroundColor,'HorizontalAlignment','Left','ForegroundColor',figTextColor,'FontSize',9*fontScale);


		%% ==========================================
		% SETUP MAIN GUI ELEMENTS
		[selBoxInfo] = subfxn_guiElementSetupInfo();
		
		tmpList2 = fieldnames(selBoxInfo);
		for guiElNo = 1:length(tmpList2)
			try
				bName = tmpList2{guiElNo};
				hListboxS.(bName) = uicontrol(hFig, 'style',selBoxInfo.(bName).uiType,'Units','normalized',...
					'position',selBoxInfo.(bName).loc/100,...
					'string',selBoxInfo.(bName).string,...
					'Value',selBoxInfo.(bName).Value,...
					'Tag',selBoxInfo.(bName).Tag);
				if strcmp('methods',bName)==1
					set(hListboxS.(bName),'background',[0.8 0.9 0.8]);
				end

				selBoxInfo.(bName).titleLoc = selBoxInfo.(bName).loc;
				selBoxInfo.(bName).titleLoc(2) = selBoxInfo.(bName).loc(2)+selBoxInfo.(bName).loc(4);
				selBoxInfo.(bName).titleLoc(4) = 2;

				hListboxT.(bName) = uicontrol('Style','Text','String',selBoxInfo.(bName).title,'Units','normalized','Position',selBoxInfo.(bName).titleLoc/100,'BackgroundColor',figBackgroundColor,'ForegroundColor',figTextColor,'HorizontalAlignment','Left','FontWeight','Bold','FontSize',defaultFontSize*fontScale);
				set(hListboxS.(bName),'Max',2,'Min',0);
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
		end
		hListbox = hListboxS.methods;

		set(hListboxS.folderFiles,'FontSize',8*fontScale);
		set(hListboxS.folderFiles,'Enable','inactive');

		%% ==========================================
		% SETUP MAIN GUI BUTTONS
		startMethodHandle = uicontrol('style','pushbutton','Units', 'normalized','position',[1 94 38 2]/100,'FontSize',9*fontScale,'string','Start selected method (or press enter)','BackgroundColor',[153 255 153]/255,'callback',@startMethodCallback);
		exitHandle = uicontrol('style','pushbutton','Units', 'normalized','position',[40 94 10 2]/100,'FontSize',9*fontScale,'string','Exit','BackgroundColor',[255 153 153]/255,'callback',@exitCallback);

		% [x0 y0 width height]
		addFoldersLoc = hListboxT.folders.Position;
		addFoldersLoc(3) = 0.30;
		addFoldersLoc(1) = 0.69;
		addFoldersHandle = uicontrol('style','pushbutton','Units', 'normalized','position',addFoldersLoc,'FontSize',9*fontScale,'string','Click to add folders.','BackgroundColor',[153 153 153]/255,'callback',@callback_addFolders);
		

		%% ==========================================
		% ADD CALLBACKS TO GUI ELEMENTS

		% set(hListbox,'KeyPressFcn',@(src,evnt)onKeyPressRelease(src,evnt,'press',hFig))
		% jTmp = findjobj(hListboxS.cellExtract);jTmp.setSelectionAppearanceReflectsFocus(0);

		fxnToAttach = {'KeyReleaseFcn','Callback'};%, 'ButtonDownFcn' KeyReleaseFcn
		for fxnNo = 1:length(fxnToAttach)
			set(hListbox,fxnToAttach{fxnNo},@(src,evnt) onKeyPressRelease(src,evnt,'press',hFig))
			set(hListboxS.cellExtract,fxnToAttach{fxnNo},@(src,evnt) onKeyPressRelease(src,evnt,'press',hFig))
			set(hListboxS.cellExtractFiletype,fxnToAttach{fxnNo},@(src,evnt) onKeyPressRelease(src,evnt,'press',hFig))
			set(hListboxS.assay,fxnToAttach{fxnNo},@(src,evnt) onKeyPressRelease(src,evnt,'press',hFig))
			set(hListboxS.subject,fxnToAttach{fxnNo},@(src,evnt) onKeyPressRelease(src,evnt,'press',hFig))
			set(hListboxS.folderFilt,fxnToAttach{fxnNo},@(src,evnt) onKeyPressRelease(src,evnt,'press',hFig))
			set(hListboxS.folders,fxnToAttach{fxnNo},@(src,evnt) onKeyPressRelease(src,evnt,'press',hFig))
		end

		% Assign focus lost callbacks to each selection box
		tmpList1 = fieldnames(hListboxS);
		nwbSetMovieInfoSwitch = 1;
		for jNo = 1:length(tmpList1)
			if strcmp(hListboxS.(tmpList1{jNo}).Style,'listbox')
				jScrollPane = findjobj(hListboxS.(tmpList1{jNo}));
				jListbox = jScrollPane.getViewport.getComponent(0);
				set(jListbox, 'FocusGainedCallback',{@onFocusGain});
				set(jListbox, 'FocusLostCallback',{@onFocusLost});
				% set(jListbox, 'FocusGainedCallback',@(src,evnt) onFocusGain(src,evnt,get(hListboxS.(tmpList1{ff}),'Tag')));
				% set(jListbox, 'PropertyChangeCallback',@(src,evnt) onPropertyChange(src,evnt,get(hListboxS.(tmpList1{ff}),'Tag')));
				% jListbox
			end
		end
		nwbSetMovieInfoSwitch = 0;

		% set(gcf,'WindowKeyPressFcn',@(src,evnt) onKeyPressRelease(src,evnt,'press',hFig));

		% See http://undocumentedmatlab.com/articles/setting-listbox-mouse-actions/.
		% set(hListbox,'KeyPressFcn',@(src,evnt)onKeyPressRelease(evnt,'press',hFig))
		% Get the listbox's underlying Java control
		jScrollPane = findjobj(hListbox);
		% We got the scrollpane container - get its actual contained listbox control
		jListbox = jScrollPane.getViewport.getComponent(0);
		% Convert to a callback-able reference handle
		jListbox = handle(jListbox, 'CallbackProperties');
		% set(hListbox, 'TooltipString','sss');
		% Set the mouse-movement event callback
		set(jListbox, 'MouseMovedCallback', {@mouseMovedCallback,hListbox,tooltipStruct});

		% [guiIdx, ok] = obj.pipelineListBox({'Yes','No'},['GUI Enabled?'],1);
		% if ok==0; return; end
		% idNumIdxArray
		% turn off gui elements, run in batch

		%% ==========================================
		% CREATE MOVIE INFO
		[movieAxes, movieAxesTwo, cellExtAxes, frameSlider, frameSliderTwo] = subfxn_movieAxesCreate();

		[runMoviesToggleHandle, fileFilterRegexpHandle, fileFilterRegexpRawHandle, FRAMES_PER_SECONDHandle, inputDatasetNameHandle] = subfxn_movieOptionsCreate();

		%% ==========================================
		% FINAL SETUP
		figure(hFig)
		uicontrol(hListbox)
		% set(hFig, 'KeyPressFcn', @(src,event) onFigKeyPress(src,event,hListboxS));
		subfxn_setOutputVars();
		% Make sure GUI is up-to-date on first display.
		onKeyPressRelease([],[],'press',hFig);

		%% ==========================================
		% WAIT FOR USER INPUT
		try
			uiwait(hFig)
		catch
		end

		%% ==========================================
		% EXIT AND SET VARIABLES BASED ON USER INPUT
		if exitFlag==1
			% idNumIdxArray = 1;
			ok = 0;
			if isvalid(hFig)
				subfxn_setOutputVars()
				close(hFig)
			end
			commandwindow
			return;
		end
		% disp(hListboxStruct)
		% fxnsToRun{hListboxStruct.Value}
		if isempty(hListboxStruct)
			uiwait(ciapkg.overloaded.msgbox('Please re-select a module then press enter. Do not close figure manually.'))
			idNumIdxArray = 1;
			ok = 0;
		else
			idNumIdxArray = hListboxStruct.Value;
			validFoldersIdx = hListboxStruct.ValueFolder;
			obj.guiEnabled = hListboxStruct.guiIdx==1;
			if hListboxStruct.nwbLoadFiles==1;hListboxStruct.nwbLoadFiles=0;else;hListboxStruct.nwbLoadFiles=1;end
			obj.nwbLoadFiles = hListboxStruct.nwbLoadFiles;
			ok = 1;
		end
		if isvalid(hFig)
			subfxn_setOutputVars()
			close(hFig)
		end
		validFoldersIdx
		return;
		% idNumIdxArray = get(hListboxS.folders,'Value');
	catch err
		ok = 0;
		idNumIdxArray = 1;
		validFoldersIdx = 1;
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end

	%% ==========================================
	% SUB-FUNCTIONS

	function onPropertyChange(src,event,inputTag)
		% If NWB chosen as file-type, verify user has correct NWB inputs
		% if any(strcmp('cellExtractFiletypeBox',inputTag))&nwbSetMovieInfoSwitch==0
		% 	get(hListboxS.cellExtractFiletype,'Value')
		% 	if get(hListboxS.cellExtractFiletype,'Value')==2
		% 		nwbSetMovieInfoSwitch = 1;
		% 		obj.setMovieInfo;
		% 		pause(0.1);
		% 	end
		% end
		% set(src,'selectionBackground',javax.swing.plaf.ColorUIResource(0.9,0.8,0.8));
	end
	% function onFigKeyPress(source,eventdata,hListboxS)
	% function onFocusGain(src,event,inputTag)
	function onFocusGain(src,event)
		% disp('ddd')
		% figure(hFig)
		tmpList = fieldnames(hListboxS);
		for ff = 1:length(tmpList)
			% jScrollPane = findjobj(hListboxS.(tmpList1{ff}));
			% jListbox = jScrollPane.getViewport.getComponent(0);
			% set(src,'background',javax.swing.plaf.ColorUIResource(0.8,0.8,0.8));
			% set(jListbox, 'selectionForeground',javax.swing.plaf.ColorUIResource(0.9,0.1,0.1));
			% set(jListbox, 'selectionForeground',javax.swing.plaf.ColorUIResource(0.9,0.1,0.1));
			% set(hListboxS.(tmpList{ff}),'background',[1 1 1]);
		end
		% set(src,'selectionBackground',javax.swing.plaf.ColorUIResource(0.9,0.1,0.1));
		set(src,'background',javax.swing.plaf.ColorUIResource(0.8,0.9,0.8));

		% % If NWB chosen as file-type, verify user has correct NWB inputs
		% if any(strcmp('cellExtractFiletypeBox',inputTag))&nwbSetMovieInfoSwitch==0
		% 	get(hListboxS.cellExtractFiletype,'Value')
		% 	if get(hListboxS.cellExtractFiletype,'Value')==2
		% 		nwbSetMovieInfoSwitch = 1;
		% 		checkEnabled = 0;
		% 		obj.setMovieInfo;
		% 		pause(0.1);
		% 		checkEnabled = 1;
		% 	end
		% end
		% gco
		% set(gco,'background',[1 1 1]*0.9);
	end
	function onFocusLost(src,event)
		% disp('ddd')
		% figure(hFig)
		% tmpList = fieldnames(hListboxS);
		% for ff = 1:length(tmpList)
		% 	set(hListboxS.(tmpList{ff}),'background',[1 1 1]);
		% end
		% set(src,'background',javax.swing.plaf.ColorUIResource(1,1,1));
		set(src,'background',javax.swing.plaf.ColorUIResource(0.2,0.2,0.2));
		% set(src,'selectionBackground',javax.swing.plaf.ColorUIResource(0.9,0.1,0.1));
		% gco
		% set(gco,'background',[1 1 1]*0.9);
	end
	function onMousePress(evnt,pressRelease,hFig)
		%
	end
	function onKeyPressRelease(src, evnt, pressRelease,hFig)
		% disp(evnt)
		% disp(pressRelease)
		% disp('ddd')
		figure(hFig)
		% breakMovieLoop = 0;
		obj.currentMethod = hListbox.String{hListbox.Value};
		try
			if breakMovieLoop==1
				delete(movieAxes)
				delete(movieAxesTwo)
				warning on;
			end
		catch
		end
		tmpList = fieldnames(hListboxS);
		for ff = 1:length(tmpList)
			set(hListboxS.(tmpList{ff}),'background',[1 1 1]);
		end
		% set(gco,'background',[1 1 1]*0.9);

		if isempty(intersect(fxnsToRun{get(hListbox,'Value')},excludeList))
			set(hListboxS.cellExtract,'Enable','on');
			set(hListboxS.assay,'Enable','on');
			set(hListboxS.subject,'Enable','on');
			set(hListboxS.folderFilt,'Enable','on');
			set(hListboxS.folders,'Enable','on');
		else
			set(hListboxS.cellExtract,'Enable','off');
			set(hListboxS.assay,'Enable','off');
			set(hListboxS.subject,'Enable','off');
			set(hListboxS.folderFilt,'Enable','off');
			set(hListboxS.folders,'Enable','off');
		end

		if isempty(intersect(fxnsToRun{get(hListbox,'Value')},excludeListVer2))

		else
			set(hListboxS.cellExtract,'Enable','off');
			% set(hListboxS.assay,'Enable','off');
			% set(hListboxS.subject,'Enable','off');
			% set(hListboxS.folderFilt,'Enable','off');
			% set(hListboxS.folders,'Enable','off');
		end

		% if any(strcmp('methodBox',get(src,'Tag')))

			obj.signalExtractionMethod = usrIdxChoiceStr{get(hListboxS.cellExtract,'Value')};
			% currentCellExtIdx = find(strcmp(usrIdxChoiceStr,obj.signalExtractionMethod));

			% filter for folders chosen by the user
			subjToAnalyze = subjectStrUnique(get(hListboxS.subject,'Value'));
			subjToAnalyze = find(ismember(obj.subjectStr,subjToAnalyze));

			assayToAnalyze = assayStrUnique(get(hListboxS.assay,'Value'));
			assayToAnalyze = find(ismember(obj.assay,assayToAnalyze));

			validFoldersIdx = intersect(subjToAnalyze,assayToAnalyze);

			% if ok==1
				useAltValid = useAltValidStr{get(hListboxS.folderFilt,'Value')};
			% else
				% useAltValid = 0;
			% end
			
			
			% if any(strcmp({'subjectBox','assayBox'},get(src,'Tag')))

			% end
			
			[validFoldersIdx] = pipelineFolderFilter(obj,useAltValid,validFoldersIdx);

			% validFoldersIdx = hListboxStruct.ValueFolder;

			% if strcmp(get(src,'Tag'),'folders')~=1

			if any(strcmp({'methodBox','cellExtractionBox','cellExtractFiletypeBox','guiEnabled','folders'},get(src,'Tag')))==0
				if length(get(hListboxS.folders,'Value'))==1
				else
					set(hListboxS.folders,'Value',validFoldersIdx);				
				end
			end

			useAltValid = {'no additional filter','manually sorted folders','not manually sorted folders','manual classification already in obj',['has ' obj.signalExtractionMethod ' extracted cells'],['missing ' obj.signalExtractionMethod ' extracted cells'],'fileFilterRegexp','valid auto',['has ' obj.fileFilterRegexp ' movie file'],'manual index entry'};
			set(hListboxS.folderFilt,'string',useAltValid);
			% assayStrUnique = unique(obj.assay(subjToAnalyze));
			% set(hListboxS.assay,'string',assayStrUnique);
		% else

		% end

		% If NWB chosen as file-type, verify user has correct NWB inputs
		if any(strcmp('cellExtractFiletypeBox',get(src,'Tag')))&&nwbSetMovieInfoSwitch==0
			disp(['cellExtractFiletype: ' num2str(get(hListboxS.cellExtractFiletype,'Value'))])
			if get(hListboxS.cellExtractFiletype,'Value')==2
				nwbSetMovieInfoSwitch = 1;
				% Set class to know that it should load NWB files.
				obj.nwbLoadFiles = 1;
				checkEnabled = 0;
				dispStr = 'Please enter information for NWB cell-extraction and imaging movie regular expressions (for locating files) and whether cell-extraction files are located in a sub-folder within each folder.';
				disp(dispStr)
				disp('If Matlab UI is non-responsive, make sure you have checked for and closed pop-up dialog boxes.')
				uiwait(ciapkg.overloaded.msgbox([dispStr 10 10 'Press OK/enter to continue.'],'Note to user','modal'));
				obj.setMovieInfo;
				disp(['NWB information set! Remember to select the ' ciapkg.pkgName ' GUI then press Enter to start a module.'])
				pause(0.1);
				checkEnabled = 1;
			else
				obj.nwbLoadFiles = 0;
			end
		end

		try
			eventKey = evnt.Key;
			keyCheck = 1;
        catch
            eventKey = '';
			keyCheck = 0;
		end
		if startMethodFlag==1
			keyCheck = 1;
            % Make a pseudo event key
            eventKey = 'return';
		end
		if keyCheck==1&&checkEnabled==1
			if startMethodFlag==1||strcmp(eventKey,'return')
				subfxn_returnNormal();
			else
				% disp('Check')
			end
			% If escape, close.
			if strcmp(eventKey,'escape')
				exitCallback();
				% breakMovieLoop = 1;
				% hListboxStruct = [];
				% close(hFig)
			end
		else
			breakMovieLoop = 1;
			pause(0.1);
			breakMovieLoop = 0;
			if isvalid(hFig)
				movieCallback();
			end
		end

		% catch
		% end
	end
	function subfxn_returnNormal()
		breakMovieLoop = 1;
		% hListboxStruct.Value = hListbox.Value;
		hListboxStruct.ValueFolder = get(hListboxS.folders,'Value');
		hListboxStruct.Value = hListbox.Value;
		hListboxStruct.guiIdx = get(hListboxS.guiEnabled,'Value');
		hListboxStruct.nwbLoadFiles = get(hListboxS.cellExtractFiletype,'Value');
		% hListboxStruct = struct(hListbox);
		close(hFig)
	end
	function mouseMovedCallback(jListbox, jEventData, hListbox,tooltipStruct)
		% Get the currently-hovered list-item
		mousePos = java.awt.Point(jEventData.getX, jEventData.getY);
		hoverIndex = jListbox.locationToIndex(mousePos) + 1;
		listValues = get(hListbox,'string');
		hoverValue = listValues{hoverIndex};

		% Replace odd values for the section dividers.
		hoverValue = regexprep(hoverValue,'------- | -------','');
		hoverValue = regexprep(hoverValue,':|/| |','_');

		% Modify the tooltip based on the hovered item
		if any(strcmp(fieldnames(tooltipStruct),hoverValue))
			msgStr = sprintf('<html><b>%s</b>: <br>%s</html>', hoverValue, tooltipStruct.(hoverValue));
		else
			% msgStr = sprintf('<html><b>%s</b>: %s</html>', hoverValue, hoverValue);
			msgStr = sprintf('<html><b>%s</b>: <br>No tooltip.</html>', hoverValue);
		end
		set(hListbox, 'TooltipString',msgStr);
	end
	function movieSettingsCallback(source,eventdata)
		breakMovieLoop = 1;
		obj.fileFilterRegexp = get(fileFilterRegexpHandle,'String');
		obj.fileFilterRegexpRaw = get(fileFilterRegexpRawHandle,'String');
		obj.FRAMES_PER_SECOND_PLAYBACK = str2num(get(FRAMES_PER_SECONDHandle,'String'));
		obj.inputDatasetName = get(inputDatasetNameHandle,'String');
		breakMovieLoop = 0;
		try
			delete(movieAxes)
			delete(movieAxesTwo)
			delete(cellExtAxes)
			warning on;
		catch
		end
		movieCallback();
	end

	function exitCallback(source,eventdata)
		breakMovieLoop = 1;
		exitFlag = 1;
		subfxn_setOutputVars()
		close(hFig)
		% uiresume(hFig);
	end
	function subfxn_setOutputVars()
		hListboxStruct.ValueFolder = get(hListboxS.folders,'Value');
		hListboxStruct.Value = hListbox.Value;
		hListboxStruct.guiIdx = get(hListboxS.guiEnabled,'Value');
		hListboxStruct.nwbLoadFiles = get(hListboxS.cellExtractFiletype,'Value');
		if hListboxStruct.nwbLoadFiles==1;hListboxStruct.nwbLoadFiles=0;else;hListboxStruct.nwbLoadFiles=1;end
	end
	function startMethodCallback(source,eventdata)
		breakMovieLoop = 1;
		startMethodFlag = 1;
		idNumIdxArray = hListboxStruct.Value;
		validFoldersIdx = hListboxStruct.ValueFolder;
		subfxn_returnNormal();
		% onKeyPressRelease(source, eventdata, 1,hFig)
		% close(hFig)
	end
	function runMoviesToggleCallback(source,eventdata)
		if enableMoviePreview==1
			breakMovieLoop = 1;
			enableMoviePreview = 0;
			set(runMoviesToggleHandle,'String',subfxn_previewMovieState());
			drawnow;
		elseif enableMoviePreview==0
			enableMoviePreview = 1;
			breakMovieLoop = 0;
			set(runMoviesToggleHandle,'String',subfxn_previewMovieState());
			drawnow;
			movieCallback();
		end
		% breakLoop = ~breakLoop;
    end
    function returnStr = subfxn_previewMovieState()
        if enableMoviePreview==0
            returnStr = 'Click to enable movie and cell-extraction previews';
        elseif enableMoviePreview==1
            returnStr = 'Preview movies by selecting one folder in "Loaded folders" (click to disable).';
        end
    end
	function callback_addFolders(source,eventdata)
		% Set current method to modelAddNewFolders and start method.
		hListbox.Value = 2;
		obj.currentMethod = hListbox.String{hListbox.Value};
		% breakMovieLoop = 1;
		% exitFlag = 1;
		% close(hFig)
		subfxn_returnNormal();
	end

	function [movieAxes, movieAxesTwo, cellExtAxes, frameSlider, frameSliderTwo] = subfxn_movieAxesCreate()
		warning off;
		txtW = 28;
		txtWy = 33;
		txtW2 = 28;
		spW = 10; % Spacer between plots
		dz = 2;
		dy = 40;
		dx = 3;
		fontSizeH = 7*fontScale;
		% bOff = 50+mt;
		bOff = -1;
		movieAxes = axes('units','normalized','position',[bOff+4, dx, txtW, txtWy]/100);
			ht = imagesc(1);
			colormap(movieAxes,'gray');
			box off;
			title(movieAxes,['Processed movie.' 10 'Select a single folder to view movie.'],'FontSize',7*fontScale,'Color',figTextColor);
			set(movieAxes,'FontSize',fontSizeH);

		movieAxesTwo = axes('units','normalized','position',[bOff+txtW+spW, dx, txtW, txtWy]/100); axis off;
			ht = imagesc(1);
			colormap(movieAxesTwo,'gray');
			box off;
			title(movieAxesTwo,'Raw movie.','FontSize',7*fontScale,'Color',figTextColor);
			set(movieAxesTwo,'FontSize',fontSizeH);

		cellExtAxes = axes('units','normalized','position',[bOff+txtW*2+spW*1.5, dx, txtW, txtWy]/100); axis off;
			ht = imagesc(1);
			colormap(cellExtAxes,'gray');
			box off;
			title(cellExtAxes,'Cell extraction','FontSize',7*fontScale,'Color',figTextColor);
			% title('Select a single folder to view movie.')

		% GUI ELEMENTS
		nFramesDummy = 100;
		if nFramesDummy<11
			sliderStepF = [1/(nFramesDummy) 0.05];
		else
			sliderStepF = [1/(nFramesDummy*0.1) 0.2];
		end
		frameSlider = uicontrol('style','slider','Units', 'normalized','position',[bOff+4 0 txtW 1]/100,...
			'min',1,'max',nFramesDummy,'Value',1,'SliderStep',sliderStepF,'callback',@frameCallback,'Enable','inactive','ButtonDownFcn',@pauseLoopCallback,'Tag','First');

		frameSliderTwo = uicontrol('style','slider','Units', 'normalized','position',[bOff+txtW+spW 0 txtW 1]/100,...
			'min',1,'max',nFramesDummy,'Value',1,'SliderStep',sliderStepF,'callback',@frameCallback,'Enable','inactive','ButtonDownFcn',@pauseLoopCallback,'Tag','Second');
		warning on
	end
	function pauseLoopCallback(source,eventdata)
		% disp([num2str(frame) ' - pause loop'])
		% keyIn = get(gcf,'CurrentCharacter');
		% disp(keyIn)
		switchTag = get(source,'Tag');
		switch switchTag
			case 'First'
				set(frameSlider,'Enable','on');
				% addlistener(frameSlider,'Value','PostSet',@frameCallbackChange);
			case 'Second'
				set(frameSliderTwo,'Enable','on');
				% addlistener(frameSliderTwo,'Value','PostSet',@frameCallbackChange);
			otherwise
				return;
		end
		% pauseLoop = 1;
		% pauseLoop = 0;
		% if pauseLoop==1
		%     pauseLoop = 0;
		% else
		%     pauseLoop = 1;
		% end
	end
	function frameCallbackChange(source,eventdata)
		switchTag = get(source,'Tag');
		switch switchTag
			case 'First'
				i = max(1,round(get(frameSlider,'value')));
			case 'Second'
				i2 = max(1,round(get(frameSliderTwo,'value')));
			otherwise
				return;
		end
		% set(frameText,'visible','on','string',['Frame ' num2str(frame) '/' num2str(nFrames)])
	end
	function frameCallback(source,eventdata)
		originalPauseState = breakMovieLoop;
		breakMovieLoop = 1;
		switchTag = get(source,'Tag');
		switch switchTag
			case 'First'
				i = max(1,round(get(frameSlider,'value')));
			case 'Second'
				i2 = max(1,round(get(frameSliderTwo,'value')));
			otherwise
				return;
		end
		addlistener(frameSlider,'Value','PostSet',@blankCallback);
		set(frameSlider,'Enable','off')
		drawnow update;
		set(frameSlider,'Enable','inactive')
		breakMovieLoop = originalPauseState;
	end
	function [selBoxInfo] = subfxn_guiElementSetupInfo()
		% set(hFig,'Color',[0,0,0]);
		% currentIdx = find(strcmp(fxnsToRun,obj.currentMethod));

		% set(hListboxS.cellExtractFiletype,'Callback',@(src,evt){set(src,'background',[1 1 1]*0.9)});
		selBoxInfo.methods.Tag = 'methodBox';
		selBoxInfo.cellExtract.Tag = 'cellExtractionBox';
		selBoxInfo.cellExtractFiletype.Tag = 'cellExtractFiletypeBox';
		selBoxInfo.folderFilt.Tag = 'folderFilt';
		selBoxInfo.subject.Tag = 'subjectBox';
		selBoxInfo.assay.Tag = 'assayBox';
		selBoxInfo.folders.Tag = 'folders';
		selBoxInfo.folderFiles.Tag = 'folders';
		selBoxInfo.guiEnabled.Tag = 'guiEnabled';

		selBoxInfo.methods.uiType = 'listbox';
		selBoxInfo.cellExtract.uiType = 'popupmenu';
		selBoxInfo.cellExtractFiletype.uiType = 'popupmenu';
		selBoxInfo.folderFilt.uiType = 'popupmenu';
		selBoxInfo.subject.uiType = 'listbox';
		selBoxInfo.assay.uiType = 'listbox';
		selBoxInfo.folders.uiType = 'listbox';
		selBoxInfo.folderFiles.uiType = 'listbox';
		selBoxInfo.guiEnabled.uiType = 'popupmenu';

		selBoxInfo.methods.Value = currentIdx;
		selBoxInfo.cellExtract.Value = currentCellExtIdx;
		if obj.nwbLoadFiles==1;ggg=2;else;ggg=1;end
		selBoxInfo.cellExtractFiletype.Value = ggg;
		selBoxInfo.folderFilt.Value = 1;
		selBoxInfo.subject.Value = 1:length(subjectStrUnique);
		selBoxInfo.assay.Value = 1:length(assayStrUnique);
		selBoxInfo.folders.Value = 1:length(selectList);
		selBoxInfo.folderFiles.Value = 1;
		if obj.guiEnabled==1;ggg=1;else;ggg=2;end
		selBoxInfo.guiEnabled.Value = ggg;

		selBoxInfo.methods.string = fxnsToRun;
		selBoxInfo.cellExtract.string = usrIdxChoiceDisplay;
		selBoxInfo.cellExtractFiletype.string = {[ciapkg.pkgName ' format'],'NeuroDataWithoutBorders (NWB) format'};
		selBoxInfo.folderFilt.string = useAltValid;
		selBoxInfo.subject.string = subjectStrUnique;
		selBoxInfo.assay.string = assayStrUnique;
		selBoxInfo.folders.string = selectList;
		selBoxInfo.folderFiles.string = '';
		selBoxInfo.guiEnabled.string = {'GUI in methods enabled','GUI in methods disabled'};

		selBoxInfo.methods.title = ['Select a ' ciapkg.pkgName ' method:'];
		selBoxInfo.cellExtract.title = 'Cell-extraction method:';
		selBoxInfo.cellExtractFiletype.title = 'Cell-extraction file format:';
		selBoxInfo.folderFilt.title = 'Folder select filters:';
		selBoxInfo.assay.title = 'Folder assay names:';
		selBoxInfo.subject.title = 'Animal IDs:';
		selBoxInfo.folders.title = 'Loaded folders:';
		selBoxInfo.folderFiles.title = 'Folder files:';
		selBoxInfo.guiEnabled.title = 'GUI (methods with user options):';

		mt = -10;
		% [x0 y0 width height]
		selBoxInfo.methods.loc = [1, 71, 38, 91-71];
		selBoxInfo.cellExtract.loc = [50+mt, 89, 24-mt/2, 2];
		selBoxInfo.cellExtractFiletype.loc = [50+mt, 84, 24-mt/2, 2];
		selBoxInfo.folderFilt.loc = [75+mt-mt/2, 89, 24-mt/2, 2];
		selBoxInfo.subject.loc = [50+mt, 71, 24-mt/2, 10];
		selBoxInfo.assay.loc = [75+mt-mt/2, 71, 24-mt/2, 10];
		selBoxInfo.folders.loc = [50+mt, 48, 49-mt, 20];
		selBoxInfo.folderFiles.loc = [1, 48, 38, 20];
		selBoxInfo.guiEnabled.loc = [75+mt-mt/2, 84, 24-mt/2, 2];
	end
	function [runMoviesToggleHandle, fileFilterRegexpHandle, fileFilterRegexpRawHandle, FRAMES_PER_SECONDHandle, inputDatasetNameHandle] = subfxn_movieOptionsCreate()
		warning off;
		txtW = 24.5;
		dz = 2;
		dy = 40;
		% bOff = 50+mt;
		bOff = 1;
		fontSizeH = 11*fontScale;

		runMoviesToggleHandle = uicontrol('style','pushbutton','Units', 'normalized','position',[bOff 45 98 2]/100,'FontSize',fontSizeH,'string',subfxn_previewMovieState(),'BackgroundColor',buttonBackgroundColor,'callback',@runMoviesToggleCallback);
		
		fileFilterRegexpHandle = uicontrol('style','edit','Units', 'normalized','position',[bOff dy txtW 2]/100,'FontSize',fontSizeH,'string',obj.fileFilterRegexp,'callback',@movieSettingsCallback,'KeyReleaseFcn',@movieSettingsCallback);
			uicontrol('Style','text','String','Processed movie regular expression:','Units','normalized','Position',[bOff dy+dz txtW dz]/100,'BackgroundColor',figBackgroundColor,'ForegroundColor',figTextColor,'HorizontalAlignment','Left','FontWeight','normal','FontSize',fontSizeH);
		fileFilterRegexpRawHandle = uicontrol('style','edit','Units', 'normalized','position',[bOff+txtW dy txtW 2]/100,'FontSize',fontSizeH,'string',obj.fileFilterRegexpRaw,'callback',@movieSettingsCallback,'KeyReleaseFcn',@movieSettingsCallback);
			uicontrol('Style','text','String','Raw movie regular expression:','Units','normalized','Position',[bOff+txtW dy+dz txtW dz]/100,'BackgroundColor',figBackgroundColor,'ForegroundColor',figTextColor,'HorizontalAlignment','Left','FontWeight','normal','FontSize',fontSizeH);
		FRAMES_PER_SECONDHandle = uicontrol('style','edit','Units', 'normalized','position',[bOff+2*txtW dy txtW 2]/100,'FontSize',fontSizeH,'string',num2str(obj.FRAMES_PER_SECOND_PLAYBACK),'callback',@movieSettingsCallback,'KeyReleaseFcn',@movieSettingsCallback);
			uicontrol('Style','text','String','Playback frames per second:','Units','normalized','Position',[bOff+2*txtW dy+dz txtW dz]/100,'BackgroundColor',figBackgroundColor,'ForegroundColor',figTextColor,'HorizontalAlignment','Left','FontWeight','normal','FontSize',fontSizeH);
		inputDatasetNameHandle = uicontrol('style','edit','Units', 'normalized','position',[bOff+3*txtW dy txtW 2]/100,'FontSize',fontSizeH,'string',obj.inputDatasetName,'callback',@movieSettingsCallback,'KeyReleaseFcn',@movieSettingsCallback);
			uicontrol('Style','text','String','HDF5 dataset name:','Units','normalized','Position',[bOff+3*txtW dy+dz txtW dz]/100,'BackgroundColor',figBackgroundColor,'ForegroundColor',figTextColor,'HorizontalAlignment','Left','FontWeight','normal','FontSize',fontSizeH);
		warning on
	end
	function movieCallback(source,eventdata)
		try
			if isempty(obj.inputFolders)
				return;
			end
			FPShere = obj.FRAMES_PER_SECOND_PLAYBACK;

			folderIdx = get(hListboxS.folders,'Value');
			if length(folderIdx)>1
				set(hListboxS.folderFiles,'string','');
				return;
			end

			thisFolderPath = obj.inputFolders{folderIdx};

			% Update file list
			try
				folderFileListHere = ciapkg.api.getFileList(thisFolderPath,'.','addInputDirToPath',0);
				folderFileListHere = folderFileListHere(3:end);
				set(hListboxS.folderFiles,'string',folderFileListHere);
				set(hListboxS.folderFiles,'Value',1);
				folderFilesHighlight = cellfun(@(x) ~isempty(cell2mat(regexp(x,{obj.fileFilterRegexp,obj.fileFilterRegexpRaw}))),folderFileListHere,'UniformOutput',0);
                folderFilesHighlight = cell2mat(folderFilesHighlight);
				if any(folderFilesHighlight)
					selectFilesIdx = find(folderFilesHighlight);
					% Only update value if within range, else ignore so listbox still renders.
					if max(selectFilesIdx)<=length(get(hListboxS.folderFiles,'string'))
						set(hListboxS.folderFiles,'Value',selectFilesIdx);
					end
				end
			catch err
				disp(repmat('@',1,7))
				disp(getReport(err,'extended','hyperlinks','on'));
				disp(repmat('@',1,7))
			end
			
			if enableMoviePreview==0
				return;
			end

			obj.fileNum = folderIdx;
			expCheck = {obj.fileFilterRegexp,obj.fileFilterRegexpRaw};
			nFiles = 2;
			returnTypeTmp = 'raw'; % filtered
			fileList = cell([1 nFiles]);
			thisFrame = cell([1 nFiles]);
			nFrames = cell([1 nFiles]);
			fileName = cell([1 nFiles]);
			movieCheck = cell([1 nFiles]);
			inputMovieDims = cell([1 nFiles]);
			inputMoviePath = cell([1 nFiles]);
			inputMovieMinMax = cell([1 nFiles]);
			for zz = 1:nFiles
				fileList{zz} = getFileList(thisFolderPath,expCheck{zz});
				if isempty(fileList{zz})
					movieCheck{zz} = 0;
					continue;
				else
					movieCheck{zz} = 1;
                end
                % Check that movie is supported, remove unsupported files.
                if iscell(fileList{zz})&&length(fileList{zz})>1
                    supportedMovie = [];
                    for yy = 1:length(fileList{zz})
                        [~, supportedMovie(yy), ~] = ciapkg.io.getMovieFileType(fileList{zz}{yy});
                    end
                    fileList{zz} = fileList{zz}(logical(supportedMovie));
                end              
                fileList{zz}'
                [~, supportedMovie, ~] = ciapkg.io.getMovieFileType(fileList{zz});
                if supportedMovie==0
					movieCheck{zz} = 0;
					continue;
				else
					movieCheck{zz} = 1;
                end
				inputMoviePath{zz} = fileList{zz}{1};
				inputMovieDims{zz} = ciapkg.io.getMovieInfo(inputMoviePath{zz},'inputDatasetName',obj.inputDatasetName);
				if isempty(inputMovieDims{zz})
					movieCheck{zz} = 0;
					continue;
				end
				nFrames{zz} = inputMovieDims{zz}.three;
				inputMovieDims{zz} = [inputMovieDims{zz}.one inputMovieDims{zz}.two];
				[thisFrame{zz},~,~] = ciapkg.io.readFrame(inputMoviePath{zz},1,'inputDatasetName',obj.inputDatasetName);
				if isempty(thisFrame{zz})
					movieCheck{zz} = 0;
					continue;
				end
				[~,fileName{zz},fileExt] = fileparts(inputMoviePath{zz});
				fileName{zz} = [fileName{zz} fileExt];
				fileName{zz} = strrep(fileName{zz},'_','\_');

				inputMovieMinMax{zz}(1) = prctile(thisFrame{zz}(:),0.1);
				inputMovieMinMax{zz}(2) = prctile(thisFrame{zz}(:),99.9);
			end
			try
				delete(movieAxes)
				delete(movieAxesTwo)
				delete(cellExtAxes)
				delete(frameSlider)
				delete(frameSliderTwo)
			catch
			end
			[movieAxes, movieAxesTwo, cellExtAxes, frameSlider, frameSliderTwo] = subfxn_movieAxesCreate();
			if movieCheck{1}==1
				% [x0 y0 width height]
				% movieAxes = axes('units','normalized','position',[50+mt+4, 3, 50, 18]/100); axis off;
				tmpFrame = zeros(inputMovieDims{1}(1:2));
				movieImgHandle = imagesc(movieAxes,tmpFrame);
				% axis equal tight;colorbar
				% axis equal tight;
				axis(movieAxes,'image')
				colormap(movieAxes,'gray')
				box(movieAxes,'off');
				
				imagesc(cellExtAxes,tmpFrame);
				set(cellExtAxes,'xcolor',figTextColor);set(cellExtAxes,'ycolor',figTextColor);
				axis(cellExtAxes,'image');
				box(cellExtAxes,'off');
			end
			if movieCheck{2}==1
				movieImgHandleTwo = imagesc(movieAxesTwo,zeros(inputMovieDims{2}(1:2)));
				% axis equal tight;colorbar
				% axis equal tight;
				axis(movieAxesTwo,'image');
				colormap(movieAxesTwo,'gray')
				box(movieAxesTwo,'off');
			end

			if movieCheck{1}==1||movieCheck{2}==1
				% Get the image cut movie
				set(hFig,'CurrentAxes',movieAxes);
				% cla reset
				i = 1;
				i2 = 1;

				if movieCheck{1}==1
					titleHandle = title(movieAxes,sprintf('%s\nFrame %d/%d',fileName{1},i,nFrames{1}),'FontSize',7*fontScale,'Color',figTextColor);
					[thisFrame,~,~] = ciapkg.io.readFrame(inputMoviePath{1},i,'inputDatasetName',obj.inputDatasetName);
					set(movieImgHandle,'CData',thisFrame);
					set(movieAxes,'xcolor',figTextColor);set(movieAxes,'ycolor',figTextColor);
					caxis(movieAxes,[inputMovieMinMax{1}(1) inputMovieMinMax{1}(2)])
				end

				if movieCheck{2}==1
					titleHandleTwo = title(movieAxesTwo,sprintf('%s\nFrame %d/%d',fileName{2},i2,nFrames{2}),'FontSize',7*fontScale,'Color',figTextColor);
					[thisFrame2,~,~] = ciapkg.io.readFrame(inputMoviePath{2},i,'inputDatasetName',obj.inputDatasetName);
					set(movieImgHandleTwo,'CData',thisFrame2);
					set(movieAxesTwo,'xcolor',figTextColor);set(movieAxesTwo,'ycolor',figTextColor);
					caxis(movieAxesTwo,[inputMovieMinMax{2}(1) inputMovieMinMax{2}(2)])
                end
                
				% If so, only display a frame and then exit.
				if enableMoviePreview==0||isempty(obj.inputFolders)
					return;
				end

				boundaryIndices = [];
				try
					% obj.signalExtractionMethod
					try
						inputImages = signalExtImageCache{obj.fileNum}.(obj.signalExtractionMethod){1};
						inputSignals = signalExtImageCache{obj.fileNum}.(obj.signalExtractionMethod){2};
					catch
						[inputSignals, inputImages, signalPeaks, signalPeaksArray, valid, validType, inputSignals2] = modelGetSignalsImages(obj,'fileNum',folderIdx,'returnType','raw','loadSignalPeaks',0,'fastFileLoad',1);
                        if isempty(logical(valid))
                            
                        else
                            inputImages = inputImages(:,:,logical(valid));
                        end
						signalExtImageCache{obj.fileNum}.(obj.signalExtractionMethod) = {inputImages,inputSignals};
					end
					if isvalid(cellExtAxes)
						[inputImages, boundaryIndices] = thresholdImages(inputImages,'fastThresholding',1,'threshold',0.3,'getBoundaryIndex',1,'imageFilter','median','medianFilterNeighborhoodSize',3);
						if ~isempty(inputImages)
							imagesc(cellExtAxes,max(inputImages,[],3));
						end
						title(cellExtAxes,sprintf('%s | %d cells',obj.signalExtractionMethod,size(inputSignals,1)),'FontSize',10*fontScale,'Color',figTextColor);
						set(cellExtAxes,'xcolor',figTextColor);set(cellExtAxes,'ycolor',figTextColor);
						axis(cellExtAxes,'image');
						box(cellExtAxes,'off');
					end
				catch err
					disp(repmat('@',1,7))
					disp(getReport(err,'extended','hyperlinks','on'));
					disp(repmat('@',1,7))
                end

				for zzz = 1:length(movieCheck)
					if movieCheck{zzz}==1
						nFramesDummy = nFrames{zzz};
						if nFramesDummy<11
							sliderStepF = [1/(nFramesDummy) 0.05];
						else
							sliderStepF = [1/(nFramesDummy*0.1) 0.2];
						end
						if zzz==1
							set(frameSlider,'max',nFrames{zzz});
							set(frameSlider,'SliderStep',sliderStepF);
						elseif zzz==2
							set(frameSliderTwo,'max',nFrames{zzz});
							set(frameSliderTwo,'SliderStep',sliderStepF);
						end
					end
				end
				

				% axis equal tight;
				% colormap(movieAxes,'gray')
				% colorbar;
				% set(gca,'Color',[1 0 0])
				% box off
				% options.caxisRange
				% caxis(options.caxisRange)
				% set(pauseHandle,'String','Pause movie');
				warning off;
				while breakMovieLoop==0
					if movieCheck{1}==1
						if isvalid(movieImgHandle)
							i = round(get(frameSlider,'Value'));
							[thisFrame,~,~] = ciapkg.io.readFrame(inputMoviePath{1},i,'inputDatasetName',obj.inputDatasetName);

							if ~isempty(boundaryIndices)&opts.overlayCellExtraction==1
								thisFrame([boundaryIndices{:}]) = NaN;
							end

							set(movieImgHandle,'CData',thisFrame);
							set(titleHandle,'String',sprintf('%s\nFrame %d/%d',fileName{1},i,nFrames{1}))

							i = i+1;
							if i>nFrames{1}
								i = 1;
							end
							set(frameSlider,'Value',i);
						end
					end

					if movieCheck{2}==1
						if isvalid(movieImgHandleTwo)
							i2 = round(get(frameSliderTwo,'Value'));
							[thisFrame2,~,~] = ciapkg.io.readFrame(inputMoviePath{2},i2,'inputDatasetName',obj.inputDatasetName);

							if ~isempty(boundaryIndices)&opts.overlayCellExtraction==1
								thisFrame2([boundaryIndices{:}]) = NaN;
							end

							set(movieImgHandleTwo,'CData',thisFrame2);
							set(titleHandleTwo,'String',sprintf('%s\nFrame %d/%d',fileName{2},i2,nFrames{2}))
							
							set(frameSliderTwo,'Value',i2);
							i2 = i2+1;
							if i2>nFrames{2}
								i2 = 1;
							end
							set(frameSliderTwo,'Value',i2);
						end
					end
					% Force stop loop if axes no longer there.
					if ~isvalid(movieAxes)&~isvalid(movieAxesTwo)
						break;
					end
					if breakMovieLoop==1
						break;
					end
					pause(1/FPShere);
				end
				warning on;
				% delete(movieAxes)
				% delete(movieAxesTwo)
			end
		catch err
			disp(repmat('@',1,7))
			disp(getReport(err,'extended','hyperlinks','on'));
			disp(repmat('@',1,7))
		end
	end
end