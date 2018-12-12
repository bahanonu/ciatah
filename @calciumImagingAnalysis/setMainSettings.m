function obj = setMainSettings(obj)
	% Alter settings of object, in general don't need to use at the moment.
	% Biafra Ahanonu
	% branched from controllerAnalysis: 2014.08.01 [16:09:16]
	% inputs
		%
	% outputs
		%

	% changelog
		%
	% TODO
		%

	% h= uicontrol('Style','Text','String','hello: ','Position',[20 40 100 50],'BackgroundColor','white') ;
	% k = uicontrol('Style', 'popup','String', {'jet','hsv'},'Position', [100 40 200 50]);

	% the class should contain the available options as a property
	propertySettings = obj.settingOptions;

	propertyList = fieldnames(propertySettings);
	nPropertiesToChange = size(propertyList);
	% pulldownStr = '[choice] = pulldown(''settings''';

	% add current property to the top of the list
	for propertyNo = 1:nPropertiesToChange
		property = char(propertyList(propertyNo));
		propertyOptions = propertySettings.(property);
		currentProperty = obj.(property);
		propertySettings.(property) = cat(2,currentProperty,propertyOptions);
		propertySettings.(property)
	end

	uiListHandles = {};
	uiTextHandles = {};
	uiXIncrement = 0.05;
	figure(1337)
	for propertyNo = 1:nPropertiesToChange
		property = char(propertyList(propertyNo));
		uiTextHandles{propertyNo} = uicontrol('Style','Text','String',[property ': '],'Units','normalized','Position',[0.0 1-uiXIncrement*propertyNo 0.1 0.05],'BackgroundColor','white') ;
		uiListHandles{propertyNo} = uicontrol('Style', 'popup','String', propertySettings.(property),'Units','normalized','Position', [0.1 1-uiXIncrement*propertyNo 0.3 0.05]);
	end
	display('make choices then press enter...')
	pause

	for propertyNo = 1:nPropertiesToChange
		property = char(propertyList(propertyNo));
		uiListHandleData = get(uiListHandles{propertyNo});
		% uiListHandleData
		propertyOptions = propertySettings.(property);
		% obj.(property) = propertyOptions{choice(propertyNo)};
		% uiListHandleData.Value
		obj.(property) = propertyOptions{uiListHandleData.Value};
	end

	close(1337)
end