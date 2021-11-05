function viewVennDiagram(circleAreas,overlapAreas,totalArea,varargin)
	% Makes Venn diagram plot.
	% Biafra Ahanonu
	% originally started: 2017.03.08 [22:29:33]
		% branched 2018.04.28 [15:50:00], taken from older calciumImagingAnalysis method.
	% inputs
		% circleAreas
			% A [c1 c2 c3] integer or float vector containing the areas for each of the three circles, leave c3 blank if only two circles.
		% overlapAreas
			 % [i12 i13 i23 i123] integer or float containing intersect area of indicated circles, e.g. i12 is intersect of circles 1 and 2 or i123 is the intersect of circles 1, 2, and 3. Only input i12 if only two circles are used for circleAreas.
	% outputs
		% None, only plotting.

	% changelog
		% 2017.08.14 [11:09:32] - modified to use circles created by viscircles, which are better for editing in Adobe Illustrator.
		% 2020.09.15 [12:19:06] - Added support for colors on the overlap area text and adjustment of the location.
		% 2021.08.08 [19:30:20] - Updated to handle CIAtah v4.0 switch to all functions inside ciapkg package.
	% TODO
		%

	import ciapkg.api.* % import CIAtah functions in ciapkg package API.

	%========================
	% Binary: 1 = display text on diagrams, 0 = no display.
	options.displayText = 1;
	% Binary: 1 = round text display numbers.
	options.roundSwitch = 1;
    % Int: number of digits to round
    options.roundDigits = 2;
	% Cell array of strings or vectors: cell array where each cell contains a str or vector specifying the color for that venn diagram.
	options.fixedColors = {[0 148 68]/255, [190 30 45]/255, [0 114 189]/255}; % {'r','g','b','cyan','yellow'}; {[1 0 0],[0 1 0],[0 0 1],'cyan','yellow'};
	% Cell array of strings or vectors: cell array where each cell contains a str or vector specifying the color for that venn diagram.
    fc1 = @(x,y) (options.fixedColors{x}+options.fixedColors{y})/2;
	options.overlapColors = {fc1(1,2), fc1(1,3), fc1(2,3)}; % {'r','g','b','cyan','yellow'}; {[1 0 0],[0 1 0],[0 0 1],'cyan','yellow'};
	% Vector of integers or floats: indicate the SEM for each circle's area, not used if empty (default).
	options.circleAreasSem = [];
	% Cell array of strings: Name to place next to each Venn diagram.
	options.circleNames = {};
	% DEPRECIATED OPTIONS, DO NOT USE
	options.overlapAreasSem = [];
	options.idPairNo = [];
	options.idPairsFixed = [];
	options.nCells = [];
	options.xPlot = [];
	options.yPlot = [];
	options.circleAreasOriginal = [];
	options.overlapAreasOriginal = [];
	% Int: amount to adjust the multiple of the overlap X coordinate to put back into the same direction.
    options.overlapZoneTextAdj = 4;
	% get options
	options = getOptions(options,varargin);
	% display(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	%========================


	% subplot(xPlot,yPlot,idPairNo)
		% [c1 c2 c3]
		% [i12 i13 i23 i123]

	% make axis square so circles look proper
	axis square

	% Plot the circles using venn, mainly to get calculations and locations
	try
		[H, S] = venn(circleAreas,overlapAreas,'ErrMinMode','None');
	catch
		tmpInput = overlapAreas;
		%tmpInput = tmpInput-1;
		%tmpInput(tmpInput<1) = 1;
		try
			[H, S] = venn(circleAreas,tmpInput,'ErrMinMode','TotalError');
		catch
			[H, S] = venn(circleAreas+1,tmpInput,'ErrMinMode','TotalError');
		end
	end

	% Delete all the created circles and handle
	hh = get(gca,'child');
	delete(hh)
	% % hh
	% if length(hh)>3
	% 	delete(hh(4:end));
	% end
	% if idPairNo == 1
	% 	title(nCells)
	% end

	axis off

	% Determine limits, can change later
	sqSizes = sqrt(totalArea/pi)+3;
	xlim([-sqSizes sqSizes]);ylim([-sqSizes sqSizes]);
	centerPos = nanmean(S.Position,1);
	xlim([centerPos(1)-sqSizes centerPos(1)+sqSizes]);ylim([centerPos(2)-sqSizes centerPos(2)+sqSizes]);

	% Plot the total area circle
	% viscircles([0 0],[sqrt((totalArea)/pi)]);
	viscircles(nanmean(S.Position,1),[sqrt((totalArea)/pi)],'Color','k','EnhanceVisibility',false);

	% S.Position(1,:)
	% nanmax([S.Position(1,:); S.Position(1,:); S.Position(1,:)],[],1)

	% boxMax = max([S.Position(1,:)+S.Radius(1); S.Position(2,:)+S.Radius(2); S.Position(3,:)+S.Radius(3)],[],1);
	% boxMin = min([S.Position(1,:)-S.Radius(1); S.Position(2,:)-S.Radius(2); S.Position(3,:)-S.Radius(3)],[],1);
	% boxMax
	% boxMin
	% xlim([boxMin(1) boxMax(1)]);
	% ylim([boxMin(2) boxMax(2)]);

	% For each circle, plot it based on venn output
	for circNo = 1:length(circleAreas)
		viscircles(S.Position(circNo,:),S.Radius(circNo),'Color',options.fixedColors{circNo},'EnhanceVisibility',false);
		if ~isempty(options.circleAreasSem)
			% sRatio = S.Radius(circNo)/circleAreas(circNo);
			% S.Radius(circNo)+options.circleAreasSem(circNo)*sRatio
			radiusHigh = sqrt(S.Radius(circNo)^2+options.circleAreasSem(circNo)/pi);
			radiusLow = sqrt(S.Radius(circNo)^2-options.circleAreasSem(circNo)/pi);
			viscircles(S.Position(circNo,:),radiusHigh,'Color',brighten(options.fixedColors{circNo},0.5),'EnhanceVisibility',false);
			viscircles(S.Position(circNo,:),radiusLow,'Color',brighten(options.fixedColors{circNo},0.5),'EnhanceVisibility',false);
		end
	end

	% Plot text indicating the exact numbers for each area of overlap
	if options.displayText==1
		rdDgts = options.roundDigits;
		% str1 = sprintf('%d | %0.1f | %0.1f',idPairsFixed(idPairNo,1), circleAreasOriginal(1),circleAreas(1));
		% str2 = sprintf('%d | %0.1f | %0.1f',idPairsFixed(idPairNo,2), circleAreasOriginal(2),circleAreas(2));
		% str3 = sprintf('%d | %0.1f | %0.1f',idPairsFixed(idPairNo,3), circleAreasOriginal(3),circleAreas(3));
		roundSwitch = options.roundSwitch;
		for circNo = 1:length(circleAreas)
			if roundSwitch
				str1 = sprintf('%d',round(circleAreas(circNo)));
				if ~isempty(options.circleNames)
					str1 = [options.circleNames{circNo} ' | ' str1];
				end
				if ~isempty(options.circleAreasSem)
					str1 = sprintf(['%s ' char(177) ' %d'],str1,round(options.circleAreasSem(circNo),rdDgts));
				end
			else
				str1 = sprintf('%0.2f',circleAreas(circNo));
                if ~isempty(options.circleNames)
					str1 = [options.circleNames{circNo} ' | ' str1];
				end
				if ~isempty(options.circleAreasSem)
					str1 = sprintf(['%s ' char(177) ' %0.1f'],str1,options.circleAreasSem(circNo));
				end
			end
			if length(circleAreas)==3
				text(S.Position(circNo,1), S.Position(circNo,2), str1,'Color',options.fixedColors{circNo});
			else
				text(S.ZoneCentroid(circNo,1), S.ZoneCentroid(circNo,2), str1,'Color',options.fixedColors{circNo});
			end
		end
		hold on;

		% if roundSwitch
		% 	str1 = sprintf('%d',round(circleAreas(1)));
		% 	str2 = sprintf('%d',round(circleAreas(2)));
		% 	str3 = sprintf('%d',round(circleAreas(3)));
		% 	if ~isempty(options.circleAreasSem)
		% 		str1 = sprintf('%s ± %d',str1,round(circleAreasSem(1)));
		% 		str2 = sprintf('%s ± %d',str2,round(circleAreasSem(2)));
		% 		str3 = sprintf('%s ± %d',str3,round(circleAreasSem(3)));
		% 		% overlapAreasSem
		% 	end
		% else
		% 	str1 = sprintf('%0.1f',circleAreas(1));
		% 	str2 = sprintf('%0.1f',circleAreas(2));
		% 	str3 = sprintf('%0.1f',circleAreas(3));
		% 	if ~isempty(options.circleAreasSem)
		% 		str1 = sprintf('%s ± %0.1f',str1,circleAreasSem(1));
		% 		str2 = sprintf('%s ± %0.1f',str2,circleAreasSem(2));
		% 		str3 = sprintf('%s ± %0.1f',str3,circleAreasSem(3));
		% 		% overlapAreasSem
		% 	end
		% end


		% text(S.Position(1,1), S.Position(1,2), str1);
		% text(S.Position(2,1), S.Position(2,2), str2);
		% text(S.Position(3,1), S.Position(3,2), str3);
		% text(-sqSizes*.80, -sqSizes*.66, str1);
		% text(sqSizes*.66, -sqSizes*.66, str2);
		% text(0, sqSizes*.95, str3);
		% text(0, 8, ['2-' num2str(c2)]);
		% text(5, -5, ['3-' num2str(c3)]);

		% set(H(1),'FaceColor',fixedColors{idPairsFixed(idPairNo,1)});
		% set(H(2),'FaceColor',fixedColors{idPairsFixed(idPairNo,2)});
		% set(H(3),'FaceColor',fixedColors{idPairsFixed(idPairNo,3)});

		% i12 = overlapAreasOriginal(1);
		% i13 = overlapAreasOriginal(2);
		% i23 = overlapAreasOriginal(3);
		% i123 = overlapAreasOriginal(4);

		% Plot additional details if there is a third circle in the diagram
        rdDgts = options.roundDigits;
		if length(circleAreas)==3
			i12 = overlapAreas(1);
			i13 = overlapAreas(2);
			i23 = overlapAreas(3);
			i123 = overlapAreas(4);
            strD = ['%0.' num2str(rdDgts) 'f | %0.' num2str(rdDgts) 'f'];
            strD
			str1 = sprintf(strD,round(circleAreas(1),rdDgts),round(circleAreas(1)-(i12-i123)-(i13-i123)-i123,rdDgts));
			str2 = sprintf(strD,round(circleAreas(2),rdDgts),round(circleAreas(2)-(i12-i123)-(i23-i123)-i123,rdDgts));
			str3 = sprintf(strD,round(circleAreas(3),rdDgts),round(circleAreas(3)-(i23-i123)-(i13-i123)-i123,rdDgts));

			text(-sqSizes*.80, -sqSizes*.66, str1,'Color',options.fixedColors{1});
			text(sqSizes*.66, -sqSizes*.66, str2,'Color',options.fixedColors{2});
			text(0, sqSizes*.95, str3,'Color',options.fixedColors{3});

            S.ZoneCentroid
			text(S.ZoneCentroid(4,1)/options.overlapZoneTextAdj, S.ZoneCentroid(4,2), [num2str(i12) ' | ' num2str(round(i12-i123,rdDgts))],'Color',options.overlapColors{1});
			text(S.ZoneCentroid(5,1)/options.overlapZoneTextAdj, S.ZoneCentroid(5,2), [num2str(i13) ' | ' num2str(round(i13-i123,rdDgts))],'Color',options.overlapColors{2});
			text(S.ZoneCentroid(6,1)/options.overlapZoneTextAdj, S.ZoneCentroid(6,2), [num2str(i23) ' | ' num2str(round(i23-i123,rdDgts))],'Color',options.overlapColors{3});
			text(S.ZoneCentroid(7,1)/options.overlapZoneTextAdj, S.ZoneCentroid(7,2), [num2str(i123) ' | ' num2str(round(i123,rdDgts))]);
		else
			i12 = overlapAreas(1);
			text(S.ZoneCentroid(3,1), S.ZoneCentroid(3,2), [num2str(i12) ' | ' num2str(round(i12,rdDgts))]);
		end
	end
	% adjust to make sure all are in range
	% axis([-7 7 -7 7])
	% axis off;
end