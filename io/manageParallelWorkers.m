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
	% TODO
		%

	success = 0;
	%========================
	% options to open/close parpool: 'open' or 'close'
	options.openCloseParallelPool = 'open';
	% 1 = open parallel pool, 0 = do not open parallel pool
	options.parallel = 1;
	% maximum number of logical cores and hence workers to start
	options.maxCores = [];
	% maximum number of logical cores and hence workers to start
	options.setNumCores = [];
	% which profile to use when launching workers
	options.parallelProfile = 'local';
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

		% Check if already inside a parallel loop, exit since can't open parpool on workers
		if ~isempty(getCurrentTask())==1
            % display('Already inside parfor loop')
			return;
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