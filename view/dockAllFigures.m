function dockAllFigures()
	% Docks all the figures into the main window.
	% Biafra Ahanonu
	% started: 2013.12.09 [20:49:04]
	% adapted from mathworks site

	last_fig_no=get(0, 'Children');

	for fig_no=1:last_fig_no'
		figure(fig_no)
		set(gcf, 'WindowStyle', 'docked')
	end
	clear last_fig_no fig_no
end