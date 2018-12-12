function [s]=saveArduinoCOMPort(ports,saveFilePaths,varargin)
    % This waits for data to become avaliable from the Arduino, which is processing the matlab data, this data is then saved and can be used for later analysis
    % Biafra Ahanonu
    % started: 07/25/11
    % inputs
        %
    % outputs
        %

    % changelog
        % 2016.03.18
    % TODO
        %

    %========================
    options.exampleOption = '';
    % get options
    options = getOptions(options,varargin);
    % display(options)
    % unpack options into current workspace
    % fn=fieldnames(options);
    % for i=1:length(fn)
    %   eval([fn{i} '=options.' fn{i} ';']);
    % end
    %========================

    try
        %Bring command window into focus
        clc;commandwindow
        fclose all;
        % Query maximum useable priorityLevel on this system:
        % priorityLevel=MaxPriority(1);
        % Priority(priorityLevel)
        %Must have MouseOver_Biafra loaded on the Arduino else it won't work
        %correctly
        nPorts = length(ports);
        for portNo = 1:nPorts
            display([ports{portNo} ' : ' saveFilePaths{portNo}]);
            delete(instrfind('Port',ports{portNo}))
            s{portNo}=serial(ports{portNo});
            s{portNo}.baudrate=115200;
            %s.baudrate=9200;
            s{portNo}.flowcontrol='none';
            s{portNo}.inputbuffersize=100000;
            s{portNo}.bytesavailablefcnmode = 'terminator';%'byte'; %'terminator';
            s{portNo}.BytesAvailableFcn = @writeDataOut;
            s{portNo}.ErrorFcn = @closeSerial;
            %s.BytesAvailableFcnCount = 1;
            %s.bytesavailablefcnmode = 'byte';%'byte'; %'terminator';
            %s{portNo}.timeout = 12; %in seconds
            %s.bytesAvailableFcnCount =  10000;
            s{portNo}.UserData = 0;
            %s.bytesavailablefcn={@receiveData,trialtime,vi};
            set(s{portNo},'Terminator','CR/LF');
            set(s{portNo},'DataBits',8);
            set(s{portNo},'StopBits',1);
            set(s{portNo},'DataTerminalReady','on');
            set(s{portNo},'Timeout',12);

            % reset arduino
            % set(s{portNo},'DataTerminalReady','on');
            %s{portNo}.timeout = 1; %in seconds
            %fopen(s{portNo});
            %fclose(s{portNo});
            s{portNo}.timeout = 12; %in seconds
            % set(s{portNo},'DataTerminalReady','off');

            %Set some parameters from database
            %raw_file_save_location='2016_03_18_p445_m0_test03.csv';
            %data_save_location='Y:\programs\arduino\data_arduino\';
            %[data_save_location '\' raw_file_save_location]
            tic
            if exist(saveFilePaths{portNo},'file')
                display(['File exists, returning....' saveFilePaths{portNo}])
                return
            end
            fileSave{portNo}=fopen(saveFilePaths{portNo},'a');
            % fopen(s{portNo});
        end
        for portNo = 1:nPorts
            fopen(s{portNo});
        end
        tic
        display('press enter when trial finished')
        %pause
        %trialtime=60*10000;
        trialTimeout=toc;
        pause
        %toc-trialTimeout>5
        %while (toc-trialTimeout)<5
        %end
        for portNo = 1:nPorts
            display('====')
            fclose(fileSave{portNo});
            fclose(s{portNo});
            s{portNo}.Port
            s{portNo}.Status
        end
        toc
    catch err
        % ensure that no open ports are left open
        fclose all;
        display(repmat('@',1,7))
        disp(getReport(err,'extended','hyperlinks','on'));
        display(repmat('@',1,7))
    end
    function writeDataOut(obj, event)
        %obj
        inputLine = fgetl(obj);
        display([obj.Port ': ' inputLine]);
        portNoHere = find(strcmp(obj.Port,ports));
        fprintf(fileSave{portNoHere},'%s\n',inputLine);
    end
    function closeSerial(obj, event)
        display([obj.Port ' test'])
    end
end