function [success] = displacementFieldCompare(fixedTmp,movingTmp,movingReg,Dxy,varargin)
	% [output1,output2] = displacementFieldCompare(fixedTmp,movingTmp,movingReg,Dxy,varargin)
	% 
	% Displays different frames along with the displacement fields.
	% 
	% Biafra Ahanonu
	% started: 2024.03.01 [14:58:30]
	% 
	% Inputs
	% 	fixedTmp
	% 	movingTmp
	% 	movingReg
	% 	Dxy
	% 
	% Outputs
	% 	success - Binary: 1 = successfully run
	% 
	% Options (input as Name-Value with Name = options.(Name))
	% 	% DESCRIPTION
	% 	options.exampleOption = '';

	% Changelog
		% 2022.03.14 [01:47:04] - Added nested and local functions to the example function.
	% TODO
		%

	% ========================
	% DESCRIPTION
	options.frameA = 1;
	options.frameB = 2;
	% get options
	options = ciapkg.io.getOptions(options,varargin);
	% disp(options)
	% unpack options into current workspace
	% fn=fieldnames(options);
	% for i=1:length(fn)
	% 	eval([fn{i} '=options.' fn{i} ';']);
	% end
	% ========================

	try
		%% DISPLAY PLOTS
		frameA = options.frameA;
		frameB = options.frameB;
		%
		success = 0;
		subplotTmp = @(x,y,z) subaxis(x,y,z, 'Spacing', 0.005, 'Padding', 0.02, 'PaddingTop', 0.02, 'MarginTop', 0.03,'MarginBottom', 0.03,'MarginLeft', 0.01,'MarginRight', 0.01);
		figure;
			colormap gray
			xT = 4;
			axList = [];
			axList(end+1) = subplotTmp(2,xT,1);
				imagesc(fixedTmp)
				axis image
				box off;
				title(['Reference image | ' num2str(frameA)])
			axList(end+1) = subplotTmp(2,xT,2);
				imagesc(movingTmp)
				box off
				axis image
				title(['Moving image | ' num2str(frameB)])
			axList(end+1) = subplotTmp(2,xT,3);
				imshowpair(fixedTmp,movingTmp)
				axis image
				title('Overlap of reference and moving')
			axList(end+1) = subplotTmp(2,xT,4);
				imagesc(movingReg)
				box off;
				title(['Registered moving image | ' num2str(frameB)])
				axis image
			axList(end+1) = subplotTmp(2,xT,5);
				imshowpair(fixedTmp,movingReg)
				axis image
				title('Overlap of reference and registered moving')
			axList(end+1) = subplotTmp(2,xT,6);
				imagesc(Dxy(:,:,1))
				box off;
				colorbar
				axis image
				title('X-axis displacement field')
			axList(end+1) = subplotTmp(2,xT,7);
				imagesc(Dxy(:,:,2))
				box off;
				colorbar
				axis image
				title('Y-axis displacement field')
			axList(end+1) = subplotTmp(2,xT,8);
				imagesc(movingTmp)
				box off
				title(['Moving image w/ displacement fields | ' num2str(frameB)])
				hold on;
				sub1 = 5;
				Dxy_ds = ciapkg.movie_processing.downsampleMovie(Dxy,'downsampleDimension','space','downsampleFactor',sub1);
				%[Xdim,Ydim] = meshgrid(1:size(Dxy_ds,2),1:size(Dxy_ds,1));
				[Xdim,Ydim] = meshgrid(round(linspace(1,size(Dxy,2),size(Dxy,2)/sub1)),round(linspace(1,size(Dxy,1),size(Dxy,1)/sub1)));
				Udim = squeeze(Dxy_ds(:,:,1));
				Vdim = squeeze(Dxy_ds(:,:,2));
				%sub1 = 10;
				%[Xdim,Ydim] = meshgrid(1:sub1:size(Dxy,2),1:size(Dxy,1));
				% Plot the vectors, invert both U and V for proper display
				hq = quiver(Xdim,Ydim,-Udim,-Vdim,1,'-r','LineWidth',1);
				axis equal
				xlim([0 size(movingTmp,2)])
				ylim([0 size(movingTmp,1)])
			linkaxes(axList)
			ciapkg.view.changeFont(18)
		disp('Done!')
		success = 0;
	catch err
		disp(repmat('@',1,7))
		disp(getReport(err,'extended','hyperlinks','on'));
		disp(repmat('@',1,7))
	end

	% function [outputs] = nestedfxn_exampleFxn(arg)
	% 	% Always start nested functions with "nestedfxn_" prefix.
	% 	% outputs = ;
	% end	
end
% function [outputs] = localfxn_exampleFxn(arg)
% 	% Always start local functions with "localfxn_" prefix.
% 	% outputs = ;
% end	