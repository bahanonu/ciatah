function [options] = getSettings(functionName)
    % Send back default options to getOptions, users can modify settings here.
    % Biafra Ahanonu
    % started: 2014.12.10
    %
    % inputs
    %   functionName - name of function whose option should be loaded
    %
    % note
    %   don't let this function call getOptions! Else you'll potentially get into an infinite loop.

    % changelog
    %

    try
        switch functionName
            case 'modelGetStim'
                options.array = 'discreteStimulusArray';
                options.nameArray = 'stimulusNameArray';
                options.idArray = 'stimulusIdArray';
                options.stimFramesOnly = 0;
            case 'manageParallelWorkers'
                % Str: options to open/close parpool: 'open' or 'close'
                options.openCloseParallelPool = 'open';
                % Binary: 1 = open parallel pool, 0 = do not open parallel pool
                options.parallel = 1;
                % Int: maximum number of logical cores and hence workers to start
                options.maxCores = [];
                % Int: maximum number of logical cores and hence workers to start
                options.setNumCores = [];
                % Str: which profile to use when launching workers
                options.parallelProfile = 'local';
                % Binary: 1 = disable parallel pool automatic loading (by parfor or parent functions using manageParallelWorkers), 0 = use Parallel Toolbox like normal
                options.disableParallelPoolAutoload = 0;
            case 'getFileInfo'
                display(['loading default settings: ' functionName])
                options.assayList = {...
                'MAG|PAV(|-PROBE)|(Q|)EXT|REN|REINST|S(HC|CH)|SUL(|P)|SAL|TROP|epmaze|OFT|HAL|D',...
                '|formalin|hcplate|vonfrey|acetone|pinprick|habit|preSNI|postSNI',...
                '|OFT|roto|oft|openfield|liquidOpenfield|check|groombox|socialcpp',...
                '|mag|reversalPre|reversalPost|reversalTraining|revTrain|reversalAcq|reversalRevOne|reversalRevTwo|reversalRevThree|reversalRevFour|reversalExtOne|reversalRenOne',...
                '|fear|SNIday|day|Session|mount|mountCheck|doubleCheck|miniOptoTest|auditoryStimuli|sucroseTest|linearTrack|ledTest|thermalTrack|isoflurane',...
                '|NSFTest|twoBottleTest|sucroseAir|lickSession',...
                '|unc9975|unc|ari|hal|ketamine'};
                options.assayListPre = {...
                '_unc\d+_amph|','_ari\d+_amph|','_hal\d+_amph|',...
                '-unc\d+-amph|','-ari\d+-amph|','-hal\d+-amph|',...
                '_unc\d+_pcp|','_ari\d+_pcp|','_hal\d+_pcp|',...
                '-unc\d+-pcp|','-ari\d+-pcp|','-hal\d+-pcp|','_pcp'};
                options.assayListPre = strcat('veh(|icle)',options.assayListPre);
                options.assayListPre = {[options.assayListPre{:} '|unc\d+_unc\d+|ari\d+_ari\d+|hal\d+_hal\d+']};
                options.subjectRegexp = '(m|M|f|F|Mouse|mouse|Mouse_|mouse_)\d+';
                options.originalStr = {'PAV-PROBE','SAL','SULP','SHC','REINST','EXT'};
                options.replaceStr = {'PAVQ','SCH','SUL','SCH','REN','EXT'};
                options.dateRegexp = '(\d{8}|\d{6}|\d+_\d+_\d+)';
            otherwise
                options = [];
        end
    catch err
        display(repmat('@',1,7))
        disp(getReport(err,'extended','hyperlinks','on'));
        display(repmat('@',1,7))
        options = [];
    end
end