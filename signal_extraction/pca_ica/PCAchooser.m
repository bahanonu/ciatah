function [filtersSavestring, tracesSavestring] = PCAchooser(inputDir,inputID,varargin)
%This function displays the first X PCA filters from a given day and asks
%for user feedback on whether or not these are valid PCs. All invalid PCs
%are removed.

%Inputs
%inputDir: Path to the animals data
%inputID: Animal's name
%days: Experimental days to be processed.

%Options:
%nPCs: number of PCs to display for each day. Default = 15.

%TODO: input of location of PCA filters/traces

%Set default options
nPCs = 15;

for i = 1:2:length(varargin)
    val = lower(varargin{i});
    switch val
        case 'npcs'
            nPCs = varargin{i+1};
        otherwise
            disp('Warning: Option is not defined');
    end
end
clear varargin i

%Load filters and traces
filesToLoad={};
filesToLoad{1} = [inputDir filesep inputID '_PCAfilters' '.mat'];
filesToLoad{2} = [inputDir filesep inputID '_PCAtraces' '.mat'];
for i=1:length(filesToLoad)
    display(['loading: ' filesToLoad{i}]);
    load(filesToLoad{i})
end

% setup the figure and get values to resize figures
fig1 = figure(1);
subplot(2,1,1)
colormap gray
scnsize = get(0,'ScreenSize');
position = get(fig1,'Position');
outerpos = get(fig1,'OuterPosition');
borders = outerpos - position;
edge = -borders(1)/2;
pos1 = [scnsize(3)/2 + edge, scnsize(4)/3, scnsize(3)/2 - edge, scnsize(4)*(2/3)];
pos2 = [scnsize(3)/2 + edge, 0, scnsize(3)/2 - edge, scnsize(4)/3];
set(fig1,'OuterPosition',pos1);

% bad PCs
invalid = zeros(size(PcaFilters,1),1);
%Determine whether the first nPCs is valid or invalid
for i = 1:nPCs
    % display the current filter
    subplot(2,1,1)
    thisFilter = squeeze(PcaFilters(:,:,i))*256;
    h = imagesc(thisFilter);
    % alter the range to increase contrast
    caxis(quantile(thisFilter(:), [0.01 0.99]));
    % make a contrast adjust figure
    contrastFig = imcontrast(h);
    % resize and move the figure
    set(contrastFig,'OuterPosition',pos2);
    title(['PC #' num2str(i) '/' num2str(nPCs)])

    % plot the current trace
    subplot(2,1,2)
    plot(PcaTraces(:,i));
    title(['trace #' num2str(i) '/' num2str(nPCs)])

    % reply = input('valid PC? y/n:','s');
    [x,y,reply]=ginput(1);
    % if isequal(lower(reply),'n')
    if isequal(reply, 3)
        set(fig1,'Color',[0.8 0 0]);
        display('invalid PC');
        invalid(i) = 1;
    elseif isempty(reply)
        keyboard
    else
        set(fig1,'Color',[0 0.8 0]);
        display('valid PC');
    end
end
close(1)
%Remove invalid PCs
PcaFilters(:,:,logical(invalid)) = [];
PcaTraces(:,logical(invalid)) = [];

%Save PCA Filters and Traces
filtersSavestring = [inputDir filesep inputID '_PCAfilters_clean' '.mat'];
display(['saving: ' filtersSavestring])
save(filtersSavestring,'PcaFilters'); clear PcaFilters

tracesSavestring = [inputDir filesep inputID '_PCAtraces_clean' '.mat'];
display(['saving: ' tracesSavestring])
save(tracesSavestring,'PcaTraces'); clear PcaTraces