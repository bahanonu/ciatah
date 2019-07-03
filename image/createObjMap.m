function [cellmap] = createObjMap(inputImages,varargin)
	% Creates a cellmap from a ZxXxY input matrix of input images.
	% Biafra Ahanonu
	% started: 2013.10.12
	% inputs
		%
	% outputs
		%
	% changelog
		% 2013.12.15 [22:43:23] converted to a matrix operation, much faster...
		% 2016.09.06 [01:37:12] add option to do max or add object map creation
		% 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
	% TODO
		%

	%========================
	% max, sum
	options.mapType = 'max';
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	%   eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================

	if isempty(inputImages)
		cellmap = [];
	else
		display(['cellmap type: ' options.mapType])
		switch options.mapType
			case 'max'
				cellmap = squeeze(max(inputImages,[],3));
			case 'sum'
				cellmap = squeeze(sum(inputImages,3));
			otherwise
				% body
		end
	end

	% OLD CODE
	% cellmap = [];
	% icstocheck = size(IcaFilters,1);
	% for i = 1:icstocheck
	%     if ~isempty(IcaFilters(i,:,:))
	%         if isempty(cellmap)
	%             cellmap = squeeze(IcaFilters(i,:,:));;
	%         else
	%             cellmap = max(cellmap,squeeze(IcaFilters(i,:,:)));
	%         end
	%     end
	% end
end