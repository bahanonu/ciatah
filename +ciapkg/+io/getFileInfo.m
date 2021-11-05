function [fileInfo] = getFileInfo(fileStr, varargin)
	% Gets file information for subject based on the file path, returns a structure with various information.
	% Biafra Ahanonu
	% started: 2013.11.04 [12:38:42]
	% inputs
		% fileStr - character string
	% options
		% assayList
	% outputs
		%

	% changelog
		% 2015.12.11 - Noting modifications to allow a second type of file format to be supported, mostly for antipsychotic analysis
		% 2017.04.15 - added multiplane support
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% |D
	options.assayList = {...
	'MAG|PAV(|-PROBE)|(Q|)EXT|REN|REINST|S(HC|CH)|SUL(|P)|SAL|TROP|epmaze|OFT|HAL',...
	'|formalin|hcplate|hotplate|vonfrey|acetone|pinprick|habit|noiseCheck',...
	'|postSNI|preSNI|postCNO|painAversion|preFear',...
	'|OFT|roto|oft|openfield|homecage|runningWheel|liquidOpenfield|check|groombox|socialcpp',...
	'|mag|reversalPre|reversalPost|reversalTraining|revTrain|reversalAcq|reversalRevOne|reversalRevTwo|reversalRevThree|reversalRevFour|reversalExtOne|reversalRenOne',...
	'|fear|SNIday|day|Session|mount|mountCheck|doubleCheck|miniOptoTest|auditoryStimuli|sucroseTest|linearTrack|ledTest|thermalTrack|isoflurane|pzmTwentyOne|pzmTwentyOneHabit|vehicle',...
	'|NSFTest|twoBottleTest|sucroseAir|lickSession|twoPhotonRotoRun',...
	'|vehicle_ldopa|vehicle_skf|vehicle_quinpirole',...
	'|habita|habitb|fc|contextrecall|recall|renewal',...
	'|unc9975|unc|ari|hal|ketamine|unca\d+_unca|prePD|postPD|activeAvoidance|passiveAvoidance|baseline',...
	'|sncEighty|ram|sl|set|D',...
	'|epi|2p|mini'};
	% second list of assays to search for
	% options.assayListPre = {...
	% 'veh(|icle)_unc\d+_amph|veh(|icle)_ari\d+_amph|veh(|icle)_hal\d+_amph',...
	% '|veh(|icle)-unc\d+-amph|veh(|icle)-ari\d+-amph|veh(|icle)-hal\d+-amph',...
	% '|veh(|icle)_unc\d+_pcp|veh(|icle)_ari\d+_pcp|veh(|icle)_hal\d+_pcp',...
	% '|veh(|icle)-unc\d+-pcp|veh(|icle)-ari\d+-pcp|veh(|icle)-hal\d+-pcp|veh_pcp',...
	% '|unc\d+_unc\d+|ari\d+_ari\d+|hal\d+_hal\d+'};
	options.assayListPre = {...
	'_unc\d+_amph|','_ari\d+_amph|','_hal\d+_amph|',...
	'-unc\d+-amph|','-ari\d+-amph|','-hal\d+-amph|',...
	'_unc\d+_pcp|','_ari\d+_pcp|','_hal\d+_pcp|',...
	'-unc\d+-pcp|','-ari\d+-pcp|','-hal\d+-pcp|','_pcp|',...
	'-mk801-\d+|','_mk801_\d+|',...
	'unca\d+_unca\d+'};
	options.assayListPre = strcat('veh(|icle)',options.assayListPre);
	options.assayListPre = {[options.assayListPre{:} '|unc\d+_unc\d+|ari\d+_ari\d+|hal\d+_hal\d+']};
	% {'MAG|PAV(|-PROBE)|(Q|)EXT|REN|REINST|S(HC|CH)|SUL(|P)|SAL|TROP|epmaze|OFT|','formalin|hcplate|vonfrey|acetone|pinprick|habit|','OFT|roto|oft|openfield'};
	options.subjectRegexp = '(m|M|f|F|Mouse|mouse|Mouse_|mouse_)\d+';
	options.originalStr = {'PAV-PROBE','SAL','SULP','SHC','REINST','EXT'};
	options.replaceStr = {'PAVQ','SCH','SUL','SCH','REN','EXT'};
	options.dateRegexp = '(\d{8}|\d{6}|\d+_\d+_\d+)';
	% regular expression for different layers in 2P or related data
	options.planeRegexp = 'plane\d+';

	options.trialList = {...
	'01habit|02lickSession|03thresholds|04stimuliBlockOne|05stimuliBlockTwo|06stimuliBlockThree|07stimuliBlockFour|08stimuliBlockFive|baseline1|baseline2|baseline3|baseline4|baseline5|trial'};

	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	% get the subject name/ID
	fileInfo.subject = regexp(fileStr,options.subjectRegexp, 'match');
	if ~isempty(fileInfo.subject)
		fileInfo.subject = lower(fileInfo.subject{1});
	else
		fileInfo.subject = 'm000';
	end
	fileInfo.subjectStr = fileInfo.subject;
	% get subject number
	tmpMatch = regexp(fileInfo.subject,options.subjectRegexp, 'tokens');
	fileInfo.subjectNum = regexp(fileInfo.subject,'\d+', 'match');
	fileInfo.subjectNum = str2num(fileInfo.subjectNum{1});
	% if iscell(fileInfo.subjectNum)
	% 	fileInfo.subjectNum = str2num(cell2mat(fileInfo.subjectNum));
	% end
	%fileInfo.subjectNum = str2num(char(strrep(fileInfo.subject,tmpMatch{1},'')));

	% get protocol, if no protocol, send to graveyard of 000
	fileInfo.protocol = regexp(fileStr,'p\d+', 'match');
	if ~isempty(fileInfo.protocol)
		fileInfo.protocol = fileInfo.protocol{1};
	else
		fileInfo.protocol = 'p000';
	end

	% get the assay used
	assayListOriginal = ['(' options.assayList{:} ')'];
	assayList = strcat(assayListOriginal, '\d+');
	fileInfo.assay = regexp(fileStr,assayList, 'match');
	assay2 = regexp(fileStr,[options.assayListPre{:}], 'match');
	if ~isempty(assay2)
		fileInfo.assay = assay2;
	end
	% correct inconsistencies in naming

	for i=1:length(options.originalStr)
		fileInfo.assay = strrep(fileInfo.assay,options.originalStr{i},options.replaceStr{i});
	end
	% add NULL string if no assay found
	if ~isempty(fileInfo.assay)
		fileInfo.assay = fileInfo.assay{1};
	else
		fileInfo.assay = 'NULL000';
	end
	% % get out the assay name
	fileInfo.assayType = regexp(fileInfo.assay,'\D+','match');
	% strfind(fileInfo.assay,assayListOriginal)
	fileInfo.assayType = [fileInfo.assayType{:}];
	% % get out the assay number
	try
		tokenMatches = regexp(fileInfo.assay,'\d+','match');
		fileInfo.assayNum = str2num(cell2mat(tokenMatches(end)));
	catch
		fileInfo.assayNum = 0;
	end
	% get trial
	trialListOriginal = ['(' options.trialList{:} ')'];
	trialList = strcat(trialListOriginal, '\d+');
	fileInfo.trial = regexp(fileStr,trialListOriginal, 'match');
	% add NULL string if no assay found
	if ~isempty(fileInfo.trial)
		fileInfo.trial = fileInfo.trial{1};
	else
		fileInfo.trial = 'NULL000';
	end

	% date
	fileInfo.date = regexp(fileStr,options.dateRegexp, 'match');
	if ~isempty(fileInfo.date)
		fileInfo.date = fileInfo.date{1};
		% correct date inconsistency
		% length(fileInfo.date)
		if length(fileInfo.date)==6&~isempty(fileInfo.date)
			fileInfo.date = ['20' fileInfo.date(1:2) '_' fileInfo.date(3:4) '_' fileInfo.date(5:6)];
		elseif length(fileInfo.date)==8
			fileInfo.date = [fileInfo.date(1:4) '_' fileInfo.date(5:6) '_' fileInfo.date(7:8)];
		else
			% fileInfo.date = [fileInfo.date(1:4) '_' fileInfo.date(5:6) '_' fileInfo.date(7:8)];
		end
	else
		fileInfo.date = '0000_00_00';
	end

	% get the imaging plane if multiplane
	fileInfo.imagingPlane = regexp(fileStr,options.planeRegexp, 'match');
	fileInfo.imagingPlaneNum = regexp(fileInfo.imagingPlane,'\d+', 'match');
	if ~isempty(fileInfo.imagingPlane)
		fileInfo.imagingPlane = fileInfo.imagingPlane{1};
		fileInfo.imagingPlaneNum = str2num(cell2mat(fileInfo.imagingPlaneNum{1}));
	else
		fileInfo.imagingPlane = 'plane0';
		fileInfo.imagingPlaneNum = 0;
	end
end