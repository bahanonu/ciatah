function [success] = manageParallelWorkers(varargin)
	% manageParallelWorkers(varargin)
	% 
	% manageParallelWorkers(nWorkers,varargin)
	% 
	% Manages loading and stopping of parallel processing workers.
	% 
	% Biafra Ahanonu
	% started: 2015.12.01
	% 
	% Inputs (all Name-Value)
	% 	<strong>openCloseParallelPool</strong> - Str: options to open/close parpool: 'open' or 'close'
	% 	<strong>parallel</strong> - Binary: 1 = open parallel pool, 0 = do not open parallel pool
	% 	<strong>maxCores</strong> - Int: maximum number of logical cores and hence workers to start
	% 	<strong>setNumCores</strong> - Int: maximum number of logical cores and hence workers to start
	% 	<strong>parallelProfile</strong> - Str: which profile to use when launching workers
	% 	<strong>disableParallelPoolAutoload</strong> - Binary: 1 = disable parallel pool automatic loading (by parfor or parent functions using manageParallelWorkers), 0 = use Parallel Toolbox like normal
	% 	<strong>forceParpoolStart</strong> - Binary: 1 = bypass all checks and force parallel pool to be created.
	% 	<strong>nCoresFree</strong> - Int: default number of logical cores that will remain free (e.g. number of workers to load will be nLogicalCores - options.nCoresFree).
	% 
	% Outputs
	% 	<strong>success</strong> - whether parallel workers were loaded or shut down properly.

	% changelog
		% 2016.11.29 - change to use java.lang to query directly the number of logical cores available to make compatible with hyperthreaded and non-hyperthreaded CPUs.
		% 2019.10.18 [11:26:41] - Added ability to disable automatic loading of parallel pool when parfor is called combined with option for user to disable loading of parallel pool.
		% 2019.10.29 [13:33:20] - Added check for user setting to auto-load parallel pool, if they have disabled then do not load pool using manageParallelWorkers.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
        % 2022.02.09 [19:03:24] - Added nCoresFree option for users to set the number of cores to remain free.
		% 2022.02.28 [18:36:15] - Added ability to input just the number of workers to open as 1st single input argument that aliases for the "setNumCores" Name-Value input, still support other input arguments as well.
		% 2022.06.27 [19:40:56] - Added displayInfo option.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	% If user inputs the number of cores requested 1st, add that to the Name-Value pair inputs.
	if nargin==1
		if isnumeric(varargin{1})==1
			varargin = {'setNumCores',varargin{1}};
		end
	elseif mod(length(varargin),2)==1 % If odd number of workers
		varargin = [{'setNumCores',varargin{1}} varargin(2:end)];
	end

	%========================
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
	% Binary: 1 = bypass all checks and force parallel pool to be created.
	options.forceParpoolStart = 0;
    % Int: default number of logical cores that will remain free (e.g. number of workers to load will be nLogicalCores - options.nCoresFree).
    options.nCoresFree = 1;
    % Binary: 1 = whether to display info on command line.
    options.displayInfo = 1;
	% get options
	options = getOptions(options,varargin);
	% options = getOptions(options,varargin,'getFunctionDefaults',1);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	try
		success = 0;

		% Check if already inside a parallel loop, exit since can't open parpool on workers
		if ~isempty(getCurrentTask())==1
			% display('Already inside parfor loop')
			return;
		end
		if options.forceParpoolStart==1
		else
			if options.disableParallelPoolAutoload==1
				% parSet = parallel.Settings;
				% parSet.Pool.AutoCreate = false;
				% return;
			else
				% Check whether user has disabled auto-load, if so, they do not run manageParallelWorkers
				parSet = parallel.Settings;
				if parSet.Pool.AutoCreate==false
					if options.displayInfo==1
						disp('User has set parSet.Pool.AutoCreate to false, DO NOT auto-start parallel pool. Use Name-Value input "forceParpoolStart=1" to force starting of parallel pool.')
					end
					return;
				end
			end
		end

		switch options.openCloseParallelPool
			case 'open'
				if ~isempty(gcp('nocreate')) || ~options.parallel
					% fprintf('===\nParallel pool already open, returning...\n===\n');
					return;
				end
				if options.setNumCores==0
					return;
				end
				disp('Opening new parallel worker pool...')
				% check maximum number of LOGICAL cores available
				numPhysicalCores = feature('numCores');
				numLogicalCores = java.lang.Runtime.getRuntime().availableProcessors;
				% leave set number of logical cores free for system processes
				numWorkersToOpen = numLogicalCores-options.nCoresFree;
				% numWorkersToOpen = numPhysicalCores;

				% user manually sets number workers
				if ~isempty(options.setNumCores)
					numWorkersToOpen = options.setNumCores;
				end
				% user sets max num cores
				if ~isempty(options.maxCores)
					if numWorkersToOpen>options.maxCores
						numWorkersToOpen = options.maxCores;
					end
				end

				% check that local matlabpool configuration is correct
				myCluster = parcluster('local');
				% delete(myCluster.Jobs)
				if myCluster.NumWorkers~=numWorkersToOpen
					myCluster.NumWorkers = numWorkersToOpen; % 'Modified' property now TRUE
					saveProfile(myCluster);   % 'local' profile now updated
				end

				% poolobj = gcp('nocreate');
				% if isempty(poolobj)
				%     poolsize = 0;
				% else
				%     poolsize = poolobj.NumWorkers
				% end

				% check whether matlabpool is already open
				if ~isempty(gcp('nocreate')) || ~options.parallel
				else
					fprintf('=== manageParallelWorkers ===\n# Physical Cores: %d\n# Logical Cores: %d\nUser set cores: %d\nMax cores: %d\n# workers to open: %d\n',numPhysicalCores,numLogicalCores,options.setNumCores,options.maxCores,numWorkersToOpen);
					% matlabpool('open',maxCores-1);
					parpool(options.parallelProfile,numWorkersToOpen,'IdleTimeout', Inf);
					fprintf('===\n');
				end

				% multi-thread workers
				% pctRunOnAll maxNumCompThreads(4)
			case 'close'
				if ~isempty(gcp('nocreate'))
					delete(gcp)
				end
				% %Close the workers
				% if matlabpool('size')&options.closeMatlabPool
				% 	matlabpool close
				% end
			otherwise
				% do nothing
		end
		success = 1;
	catch err
		success = 0;
		display(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		display(repmat('@',1,7))
	end
end