function obj = changeCaxis(obj)
	% Biafra Ahanonu
	% Started: 2021.03.25 [22:11:25] (branched from ciatah.m)

	userInput = inputdlg('CAXIS min max');str2num(userInput{1});
	S = findobj(gcf,'Type','Axes');
	% C = cell2mat(get(S,'Clim'));
	C = str2num(userInput{1});
	% C = [-1 7];
	set(S,'CLim',C);
end