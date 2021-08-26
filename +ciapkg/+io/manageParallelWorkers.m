function [success] = manageParallelWorkers(varargin)
	% Manages loading and stopping parallel processing workers.
	% Biafra Ahanonu
	% started: 2015.12.01
	% inputs
		%
	% outputs
		%

	% changelog
		% 2016.11.29 - change to use java.lang to query directly the number of logical cores available to make compatible with hyperthreaded and non-hyperthreaded CPUs.
		% 2019.10.18 [11:26:41] - Added ability to disable automatic loading of parallel pool when parfor is called combined with option for user to disable loading of parallel pool.
		% 2019.10.29 [13:33:20] - Added check for user setting to auto-load parallel pool, if they have disabled then do not load pool using manageParallelWorkers.
	% TODO
		%

	success = 0;
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
					disp('User has set parSet.Pool.AutoCreate to false, DO NOT auto-start parallel pool.')
					return;
				end
			end
		end

		switch options.openCloseParallelPool
			case 'open'
				if ~isempty(gcp('nocreate')) | ~options.parallel
					% fprintf('===\nParallel pool already open, returning...\n===\n');
					return;
				end
				if options.setNumCores==0
					return;
				end
				% check maximum number of LOGICAL cores available
				numPhysicalCores = feature('numCores');
				numLogicalCores = java.lang.Runtime.getRuntime().availableProcessors;
				% leave one logical cores free for system processes
				numWorkersToOpen = numLogicalCores-1;
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
				if ~isempty(gcp('nocreate')) | ~options.parallel
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