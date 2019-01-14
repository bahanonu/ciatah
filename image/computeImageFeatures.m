function [imgStats] = computeImageFeatures(inputImages, varargin)
    % Filters large and small objects in an set of images, returns filtered matricies along with vector with decisions and sizes.
    % Biafra Ahanonu
    % 2013.10.31
    % based on SpikeE code
    % inputs
    %   inputImages - [x y nSignals]
    % outputs
    %   imgStats -
    % options
    %   minNumPixels
    %   maxNumPixels
    %   thresholdImages

    % changelog
        % updated: 2013.11.08 [09:24:12] removeSmallICs now calls a filterImages, name-change due to alteration in function, can slowly replace in codes
        % 2017.01.14 [20:06:04] - support switched from [nSignals x y] to [x y nSignals]
    % TODO
        %

    %========================
    % get options
    options.minNumPixels=25;
    options.maxNumPixels=600;
    options.makePlots=1;
    options.waitbarOn=1;
    options.thresholdImages = 1;
    options.threshold = 0.5;
    options.valid = [];
    % options.featureList = {'Eccentricity','EquivDiameter','Area','Orientation','Perimeter','Solidity',};
    options.featureList = {'Eccentricity','EquivDiameter','Area','Orientation','Perimeter'};
    % Whether to calculate non-regionprops
    options.addedFeatures = 0;
    % Input images for add features
    options.addedFeaturesInputImages = [];
    options.runRegionprops = 1;

    options.xCoords = [];
    options.yCoords = [];

    options = getOptions(options,varargin);
    % unpack options into current workspace
    fn=fieldnames(options);
    for i=1:length(fn)
        eval([fn{i} '=options.' fn{i} ';']);
    end
    %========================

    nImages = size(inputImages,3);

    reverseStr = '';
    % decide whether to threshold images
    if options.thresholdImages==1
        if options.addedFeatures==1&isempty(options.addedFeaturesInputImages)
            options.addedFeaturesInputImages = inputImages;
        end
        inputImages = thresholdImages(inputImages,'waitbarOn',1,'binary',1,'threshold',threshold);

    end

    % get the centroids and other info for movie
    if isempty(options.xCoords)
        [xCoords, yCoords] = findCentroid(inputImages,'waitbarOn',options.waitbarOn,'runImageThreshold',0);
    else
        xCoords = options.xCoords;
        yCoords = options.yCoords;
    end


    % loop over images and get their stats
    for imageNo = 1:nImages
        iImage = squeeze(inputImages(:,:,imageNo));
        % imagesc(iImage)
        % imgStats.imageSizes(imageNo) = sum(iImage(:)>0);
        if options.runRegionprops==1
            regionStat = regionprops(iImage, featureList);
            for ifeature = featureList
                % regionStat = regionprops(iImage, ifeature{1});
                try
                    % eval(['imgStats.' ifeature{1} '(imageNo) = regionStat.' ifeature{1} ';']);
                    imgStats.(ifeature{1})(imageNo) = regionStat.(ifeature{1});
                catch
                    % eval(['imgStats.' ifeature{1} '(imageNo) = NaN;']);
                    imgStats.(ifeature{1})(imageNo) = NaN;
                end
            end
        end

        if options.addedFeatures==1
            iImage2 = squeeze(options.addedFeaturesInputImages(:,:,imageNo));
            % figure(11);imagesc(iImage2);title(num2str(imageNo))
            % [imageNo xCoords(imageNo) yCoords(imageNo)]
            t1=getObjCutMovie(iImage2,iImage2,'cropSize',30,'createMontage',0,'crossHairsOn',0,'addPadding',1,'waitbarOn',0,'xCoords',xCoords(imageNo),'yCoords',yCoords(imageNo));
            t1 = t1{1};
            imgStats.imgKurtosis(imageNo) = double(kurtosis(t1(:)));
            imgStats.imgSkewness(imageNo) = double(skewness(t1(:)));
            % imgStats.imgKurtosis(imageNo) = kurtosis(iImage(:));
            % imgStats.imgSkewness(imageNo) = skewness(iImage(:));
        else

        end
        % regionStat = regionprops(iImage, 'Eccentricity','EquivDiameter','Area','Orientation','Perimeter','Solidity');
        % imgStats.Eccentricity(imageNo) = regionStat.Eccentricity;
        % imgStats.EquivDiameter(imageNo) = regionStat.EquivDiameter;
        % imgStats.Area(imageNo) = regionStat.Area;
        % imgStats.Orientation(imageNo) = regionStat.Orientation;
        % imgStats.Perimeter(imageNo) = regionStat.Perimeter;
        % imgStats.Solidity(imageNo) = regionStat.Solidity;

        if (mod(imageNo,10)==0|imageNo==nImages)&options.waitbarOn==1
            reverseStr = cmdWaitbar(imageNo,nImages,reverseStr,'inputStr','computing image features');
        end
    end

    if makePlots==1
        if isfield(imgStats,'Area')==1
            [figHandle figNo] = openFigure(1996, '');
                subplot(2,1,1)
                hist(imgStats.Area,round(logspace(0,log10(max(imgStats.Area)))));
                box off;title('distribution of IC sizes');xlabel('area (px^2)');ylabel('count');
                set(gca,'xscale','log');
                h = findobj(gca,'Type','patch');
                set(h,'FaceColor',[0 0 0],'EdgeColor','w');
        end
        if ~isempty(options.valid)
            nPts = 2;
        else
            options.valid = ones(1,nImages);
            nPts = 1;
        end
        pointColors = ['g','r'];
        [figHandle figNo] = openFigure(1997, '');
            for pointNum = 1:nPts
                pointColor = pointColors(pointNum);
                if pointNum==1
                    valid = logical(options.valid);
                else
                    valid = logical(~options.valid);
                end
                [figHandle figNo] = openFigure(1997, '');
                fn=fieldnames(imgStats);
                for i=1:length(fn)
                    subplot(2,ceil(length(fn)/2),i)
                    eval(['iStat=imgStats.' fn{i} ';']);
                    plot(find(valid),iStat(valid),[pointColor '.'])
                    title(fn{i})
                    hold on;box off;
                    xlabel('rank'); ylabel(fn{i})
                    hold off
                end

                % subplot(2,1,1)
                % scatter3(imgStats.Eccentricity(valid),imgStats.Perimeter(valid),imgStats.Orientation(valid),[pointColor '.'])
                % xlabel('Eccentricity');ylabel('perimeter');zlabel('Orientation');
                % rotate3d on;hold on;
                % subplot(2,1,2)
                % scatter3(imgStats.Area(valid),imgStats.Perimeter(valid),imgStats.Solidity(valid),[pointColor '.'])
                % xlabel('area');ylabel('perimeter');zlabel('solidity');
                % rotate3d on;hold on;
            end

    end
end