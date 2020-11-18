function [idNumIdxArray, validFoldersIdx, ok] = calciumImagingAnalysisMainGui(obj,fxnsToRun,inputTxt,currentIdx)
	% Main GUI for calciumImagingAnalysis startup
	% Biafra Ahanonu
	% started: 2020.03.23 [22:36:36] - branch from calciumImagingAnalysis 2020.05.07 [15:47:29]
	% inputs
		%
	% outputs
		%

	% changelog
		% 2020.05.07 [17:36:12] - Selection of NWB format forces user to give information on NWB.
	% TODO
		%

	try
		ok = 0;
		tooltipStruct = obj.tts;
		% Enable key check
		checkEnabled = 1;
		% Switch to only show setMovieInfo once with NWB
		nwbSetMovieInfoSwitch = 0;

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

		useAltValid = {'no additional filter','manually sorted folders','not manually sorted folders','manual classification already in obj',['has ' obj.signalExtractionMethod ' extracted cells'],['missing ' obj.signalExtractionMethod ' extracted cells'],'fileFilterRegexp','valid auto',['has ' obj.fileFilterRegexp ' movie file'],'manual index entry'};
		useAltValidStr = {'no additional filter','manually sorted folders','not manually sorted folders','manual classification already in obj',['has extracted cells'],'missing extracted cells','fileFilterRegexp','valid auto','movie file','manual index entry'};

		hFig = figure;
		hListboxS = struct;
		set(hFig,'Name','CIAtah: start-up GUI','NumberTitle','off')
		uicontrol('Style','text','String',['CIAtah'],'Units','normalized','Position',[1 97.5 20 2.5]/100,'BackgroundColor','white','HorizontalAlignment','Left','ForegroundColor','black','FontWeight','bold','FontAngle','italic');
		uicontrol('Style','text','String',[inputTxt 10 'Press TAB to select next section, ENTER to continue, and ESC to exit.'],'Units','normalized','Position',[10 92 90 8]/100,'BackgroundColor','white','HorizontalAlignment','Left','ForegroundColor','black');

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
		selBoxInfo.guiEnabled.Tag = 'folders';

		selBoxInfo.methods.Value = currentIdx;
		selBoxInfo.cellExtract.Value = currentCellExtIdx;
		if obj.nwbLoadFiles==1;ggg=2;else;ggg=1;end;
		selBoxInfo.cellExtractFiletype.Value = ggg;
		selBoxInfo.folderFilt.Value = 1;
		selBoxInfo.subject.Value = 1:length(subjectStrUnique);
		selBoxInfo.assay.Value = 1:length(assayStrUnique);
		selBoxInfo.folders.Value = 1:length(selectList);
		if obj.guiEnabled==1;ggg=1;else;ggg=2;end;
		selBoxInfo.guiEnabled.Value = ggg;

		selBoxInfo.methods.string = fxnsToRun;
		selBoxInfo.cellExtract.string = usrIdxChoiceDisplay;
		selBoxInfo.cellExtractFiletype.string = {'CIAtah format','NeuroDataWithoutBorders (NWB) format'};
		selBoxInfo.folderFilt.string = useAltValid;
		selBoxInfo.subject.string = subjectStrUnique;
		selBoxInfo.assay.string = assayStrUnique;
		selBoxInfo.folders.string = selectList;
		selBoxInfo.guiEnabled.string = {'GUI in methods enabled','GUI in methods disabled'};

		selBoxInfo.methods.title = 'Select a CIAtah method:';
		selBoxInfo.cellExtract.title = 'Cell-extraction method:';
		selBoxInfo.cellExtractFiletype.title = 'Cell-extraction file format:';
		selBoxInfo.folderFilt.title = 'Folder select filters:';
		selBoxInfo.assay.title = 'Folder assay names:';
		selBoxInfo.subject.title = 'Animal IDs:';
		selBoxInfo.folders.title = 'Loaded folders:';
		selBoxInfo.guiEnabled.title = 'GUI (for methods that ask for options):';

		mt = -10;
		selBoxInfo.methods.loc = [0,8,38,83];
		selBoxInfo.cellExtract.loc = [50+mt,77,24-mt/2,14];
		selBoxInfo.cellExtractFiletype.loc = [50+mt,68,24-mt/2,7];
		selBoxInfo.folderFilt.loc = [75+mt-mt/2,68,25-mt/2,22];
		selBoxInfo.subject.loc = [50+mt,47,24-mt/2,18];
		selBoxInfo.assay.loc = [75+mt-mt/2,47,25-mt/2,18];
		selBoxInfo.folders.loc = [50+mt,0,50-mt,44];
		selBoxInfo.guiEnabled.loc = [0,0,38,5];

		tmpList2 = fieldnames(selBoxInfo);
		for ff = 1:length(tmpList2)
			try
				hListboxS.(tmpList2{ff}) = uicontrol(hFig, 'style','listbox','Units','normalized','position',selBoxInfo.(tmpList2{ff}).loc/100, 'string',selBoxInfo.(tmpList2{ff}).string,'Value',selBoxInfo.(tmpList2{ff}).Value,'Tag',selBoxInfo.(tmpList2{ff}).Tag);
				if strcmp('methods',tmpList2{ff})==1
					set(hListboxS.(tmpList2{ff}),'background',[0.8 0.9 0.8]);
				end

				selBoxInfo.(tmpList2{ff}).titleLoc = selBoxInfo.(tmpList2{ff}).loc;
				selBoxInfo.(tmpList2{ff}).titleLoc(2) = selBoxInfo.(tmpList2{ff}).loc(2)+selBoxInfo.(tmpList2{ff}).loc(4);
				selBoxInfo.(tmpList2{ff}).titleLoc(4) = 2;

				hListboxT.(tmpList2{ff}) = uicontrol('Style','Text','String',selBoxInfo.(tmpList2{ff}).title,'Units','normalized','Position',selBoxInfo.(tmpList2{ff}).titleLoc/100,'BackgroundColor','white','HorizontalAlignment','Left','FontWeight','Bold');
				set(hListboxS.(tmpList2{ff}),'Max',2,'Min',0);
			catch
			end
		end
		hListbox = hListboxS.methods;
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
		for ff = 1:length(tmpList1)
			jScrollPane = findjobj(hListboxS.(tmpList1{ff}));
			jListbox = jScrollPane.getViewport.getComponent(0);
			set(jListbox, 'FocusGainedCallback',{@onFocusGain});
			set(jListbox, 'FocusLostCallback',{@onFocusLost});
			% set(jListbox, 'FocusGainedCallback',@(src,evnt) onFocusGain(src,evnt,get(hListboxS.(tmpList1{ff}),'Tag')));
			% set(jListbox, 'PropertyChangeCallback',@(src,evnt) onPropertyChange(src,evnt,get(hListboxS.(tmpList1{ff}),'Tag')));
			% jListbox
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


		figure(hFig)
		uicontrol(hListbox)
		% set(hFig, 'KeyPressFcn', @(src,event) onFigKeyPress(src,event,hListboxS));
		hListboxStruct = [];
		hListboxStruct.ValueFolder = get(hListboxS.folders,'Value');
		hListboxStruct.Value = hListbox.Value;
		hListboxStruct.guiIdx = get(hListboxS.guiEnabled,'Value');
		hListboxStruct.nwbLoadFiles = get(hListboxS.cellExtractFiletype,'Value');
		if hListboxStruct.nwbLoadFiles==1;hListboxStruct.nwbLoadFiles=0;else;hListboxStruct.nwbLoadFiles=1;end
		% Make sure GUI is up-to-date on first display.
		onKeyPressRelease([],[],'press',hFig);

		uiwait(hFig)
		commandwindow
		% disp(hListboxStruct)
		% fxnsToRun{hListboxStruct.Value}
		if isempty(hListboxStruct)
			uiwait(msgbox('Please re-select a module then press enter. Do not close figure manually.'))
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
		% idNumIdxArray = get(hListboxS.folders,'Value');
	catch err
		ok = 0;
		idNumIdxArray = 1;
		validFoldersIdx = 1;
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end

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

			[validFoldersIdx] = pipelineFolderFilter(obj,useAltValid,validFoldersIdx);

			if strcmp(get(src,'Tag'),'folders')~=1
				set(hListboxS.folders,'Value',validFoldersIdx);
			end

			useAltValid = {'no additional filter','manually sorted folders','not manually sorted folders','manual classification already in obj',['has ' obj.signalExtractionMethod ' extracted cells'],['missing ' obj.signalExtractionMethod ' extracted cells'],'fileFilterRegexp','valid auto',['has ' obj.fileFilterRegexp ' movie file'],'manual index entry'};
			set(hListboxS.folderFilt,'string',useAltValid);
			% assayStrUnique = unique(obj.assay(subjToAnalyze));
			% set(hListboxS.assay,'string',assayStrUnique);
		% else

		% end

		% If NWB chosen as file-type, verify user has correct NWB inputs
		if any(strcmp('cellExtractFiletypeBox',get(src,'Tag')))&nwbSetMovieInfoSwitch==0
			get(hListboxS.cellExtractFiletype,'Value')
			if get(hListboxS.cellExtractFiletype,'Value')==2
				nwbSetMovieInfoSwitch = 1;
				checkEnabled = 0;
				uiwait(msgbox(['Please enter information for NWB cell-extraction and imaging movie regular expressions (for locating files) and whether cell-extraction files are located in a sub-folder within each folder.' 10 10 'Press OK/enter to continue.'],'Note to user','modal'));
				obj.setMovieInfo;
				pause(0.1);
				checkEnabled = 1;
			end
		end

		try
			evnt.Key;
			keyCheck = 1;
		catch
			keyCheck = 0;
		end
		if keyCheck==1&checkEnabled==1
			if strcmp(evnt.Key,'return')
				% hListboxStruct.Value = hListbox.Value;
				hListboxStruct.ValueFolder = get(hListboxS.folders,'Value');
				hListboxStruct.Value = hListbox.Value;
				hListboxStruct.guiIdx = get(hListboxS.guiEnabled,'Value');
				hListboxStruct.nwbLoadFiles = get(hListboxS.cellExtractFiletype,'Value');
				% hListboxStruct = struct(hListbox);
				close(hFig)
			else
				% disp('Check')
			end
			% If escape, close.
			if strcmp(evnt.Key,'escape')
				hListboxStruct = [];
				close(hFig)
			end
		end
		% catch
		% end
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
			msgStr = sprintf('<html><b>No tooltip.</b></html>', hoverValue, hoverValue);
		end
		set(hListbox, 'TooltipString',msgStr);
	end
end