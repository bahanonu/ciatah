// biafra ahanonu
// started: 2013.10.04 [13:43:25]
// tracks an obj assuming it can be isolated via background subtraction and thresholding
// the resulting txt file should be filtered by finding the largest area for each Slice
// changelog
	// 2013.12.15 [19:22:11] several improvements to the workflow (now ask user to crop image, set the trheshold [the auto threshold wasn't very robust]) and a couple bug fixes.
	// 2014.05.16 - added ability to convert to 8 bit, crop using NaN as a way to remove inconvenient regions, close all windows at end, automatic thresholding, ability to load a list of files, etc..
	// 2015.05.03 - added pixel to cm conversion

//done
	// add convert to 8 bit option!!!!
	// dilation
	// use selection, inverse and set outside to NaN
	// adjust so that downsampleMovieFactor when doing virtual stack

//TODO

// start the script
// parameters = getParameters()
parameters = "";
main(parameters);

function main(parameters){

	// set the temporary directory
	saveDir = "C:\\";
	objThresHigh = 255;
	objThresLow = 62;
	// ========================================================
	// create an options dialog box
	Dialog.create("tracking parameters");
	Dialog.addNumber("number of session folders to analyze:", 1);
	Dialog.addString("tracking save path:", saveDir,80);
	Dialog.addCheckbox("set pixel to cm conversion?", true);
	Dialog.addNumber("pixel to cm conversion, distance (cm): ", 30.48);
	Dialog.addNumber("pct to add to obj mean gray value: ", 0);
	Dialog.addNumber("min pixel area for obj: ", 100);
	Dialog.addNumber("max pixel area for obj: ", 5000);
	Dialog.addNumber("spatially downsample movie (0=no downsample, 2=2x, etc.): ", 0);
	Dialog.addCheckbox("background subtract?", false);
	Dialog.addCheckbox("background average (check) max (uncheck)?", true);
	Dialog.addCheckbox("normalize stack?", false);
	Dialog.addCheckbox("crop stack?", false);
	Dialog.addCheckbox("crop selection polygon (check) or rectangle (uncheck)?", true);
	// convert to 8 bit?
	Dialog.addCheckbox("convert movie to 8-bit?", false);
	Dialog.addCheckbox("convert movie to 32-bit?", false);
	// extra invert (obj should be black on white)
	Dialog.addCheckbox("invert movie colors (obj black on white)?", true);
	// automatically threshold?
	Dialog.addCheckbox("automatically threshold?", false);
	Dialog.addString("auto threshold type (Minimum, Otsu, MaxEntropy)", "Minimum",80);
	Dialog.addNumber("slice to estimate automatic threshold: ", 200);
	Dialog.addNumber("number slices to preview: ", 500);
	Dialog.addNumber("frames to gamma adjust: ", 0);
	Dialog.addNumber("gamma adjust value (0.1-3): ", 0.1);
	Dialog.addNumber("high threshold value: ", objThresHigh);
	Dialog.addNumber("low threshold value: ", objThresLow);
	Dialog.addCheckbox("erode and dilate?", true);
	Dialog.addNumber("erode iterations: ", 1);
	Dialog.addNumber("dilate iterations: ", 3);
	// whether to look at a file containing a list of relevant movies
	Dialog.addCheckbox("analyze movies from a list file", false);
	//
	Dialog.addCheckbox("open avi dialog?", false);
	Dialog.addNumber("first frame movie (0=all): ", 0);
	Dialog.addNumber("last frame movie: ", 0);
	//
	Dialog.addCheckbox("open single frame?", false);
	Dialog.addCheckbox("close all windows?", true);
	Dialog.addCheckbox("hide loaded movie?", true);
	Dialog.addCheckbox("save in name of movie subdirectory", false);
	// display the dialog box
	Dialog.show();
	// ========================================================
	// get dialog box options
	numFiles = Dialog.getNumber();
	saveDir = Dialog.getString();
	setRealDimensions = Dialog.getCheckbox();
	setRealDimensionsNum = Dialog.getNumber();
	objMinAdd = Dialog.getNumber();
	minObjArea = Dialog.getNumber();
	maxObjArea = Dialog.getNumber();
	downsampleMovieFactor = Dialog.getNumber();
	backgroundSubtract = Dialog.getCheckbox();
	backgroundAvgOrMax = Dialog.getCheckbox();
	normalizeStackChoice = Dialog.getCheckbox();
	cropImageOption = Dialog.getCheckbox();
	polygonSelectionOption = Dialog.getCheckbox();
	checkUse8bit = Dialog.getCheckbox();
	checkUse32bit = Dialog.getCheckbox();
	extraInvert = Dialog.getCheckbox();
	//
	useAutomaticThreshold = Dialog.getCheckbox();
	thresholdMethodType = Dialog.getString();
	sliceToEstimateThreshold = Dialog.getNumber();
	numSlicesToPreview = Dialog.getNumber();
	framesToGammaAdj = Dialog.getNumber();
	gammaAdjValue = Dialog.getNumber();
	objThresHigh = Dialog.getNumber();
	objThresLow = Dialog.getNumber();
	erodeDilateStack = Dialog.getCheckbox();
	erodeIterations = Dialog.getNumber();
	dilateIterations = Dialog.getNumber();

	useListFile = Dialog.getCheckbox();
	checkUseAviDialog = Dialog.getCheckbox();
	firstFrame = Dialog.getNumber();
	lastFrame = Dialog.getNumber();
	//
	openSingleFrame = Dialog.getCheckbox();
	closeAllWindowsSwitch = Dialog.getCheckbox();
	runBatchMode = Dialog.getCheckbox();
	saveInSubdirSwitch = Dialog.getCheckbox();
	// ========================================================

	// options for analyzing the obj, centroid
	measureOptions = "area center fit stack redirect=None decimal=3";
	analyzeOptions = "size=" + minObjArea + "-" + maxObjArea + " circularity=0.00-1.00 show=Outlines display clear stack";
	print("blank space");
	print("\\Clear");
	// make sure save directory has trailing slash
	if(!endsWith(saveDir,"\\")){
		print('appending slash to save directory...');
		saveDir = saveDir + "\\";
		print(saveDir);
	}

	if(useListFile){
		fileList = File.openDialog('select file with list of movie (tiff, avi, etc.) to convert');
		listOfFiles = File.openAsString(fileList);
		listOfFiles = split(listOfFiles,"\n");
	}else{
		listOfFiles = newArray();
		for(fileNo=0; fileNo<numFiles; fileNo++){
			fileStr = "select file " + (fileNo+1) + "/" + numFiles;
			listOfFiles = Array.concat(listOfFiles,File.openDialog(fileStr));
			print("added file " + fileNo + ": " + listOfFiles[fileNo]);
			// concatName = getEndPathName(listOfFiles[i]);
		}
	}

	// test that files are correct
	print('=======');
	print('testing for file validity');
	for(fileNo=0; fileNo<listOfFiles.length; fileNo++){
		// print('=======');
		thisFile = listOfFiles[fileNo];
		IJ.redirectErrorMessages();
		print((fileNo+1)+'/'+listOfFiles.length+': '+thisFile);
		if(endsWith(thisFile, 'avi')){
			run("AVI...", "select=["+thisFile+"] first="+1+" last="+2);
		}else if(endsWith(thisFile, 'tiff')||endsWith(thisFile, 'tif')){
			// open(thisFile);
			// run("TIFF Virtual Stack...","open="+thisFile);
		}
		// close all windows
		if(closeAllWindowsSwitch){
			closeAllWindows();
		}
	}

	// GET USER INPUT BEFORE PROCESSING
	thresholdMinArray = newArray();
	thresholdMaxArray = newArray();
	// crop rectangle arrays
	cropRectArrayX = newArray();
	cropRectArrayY = newArray();
	cropRectArrayWidth = newArray();
	cropRectArrayHeight = newArray();
	// crop polygon arrays
	cropSelectionArrayIdxStart = newArray();
	cropSelectionArrayIdxEnd = newArray();
	cropSelectionArrayX = newArray();
	cropSelectionArrayY = newArray();
	// background polygon selection
	backgroundSelectionArrayIdxStart = newArray();
	backgroundSelectionArrayIdxEnd = newArray();
	backgroundSelectionArrayX = newArray();
	backgroundSelectionArrayY = newArray();
	//
	xpoints = newArray();
	xpoints = Array.concat(xpoints,0);
	ypoints = newArray();
	//
	pixelPerCm = newArray();
	objMinCrop = -1;
	objMaxCrop = -1;
	for(fileNo=0; fileNo<listOfFiles.length; fileNo++){
		print('=======');
		thisFile = listOfFiles[fileNo];
		print((fileNo+1)+'/'+listOfFiles.length+': '+thisFile);
		if(setRealDimensions){
			IJ.redirectErrorMessages();
			grabMovieFrames(thisFile,sliceToEstimateThreshold,downsampleMovieFactor,normalizeStackChoice,numSlicesToPreview);
			setTool("line");
			if(xpoints[0]==0){
				//getSelectionCoordinates(xpoints, ypoints);
			}else{
				makeLine(xpoints[0], ypoints[0], xpoints[1], ypoints[1]);
			}
			waitForUser("select a distance");
			run("Clear Results");
			getSelectionCoordinates(xpoints, ypoints);
			run("Measure");
			pixelLength = getResult("Length",0);
			// waitForUser("select a distance");
			run("Clear Results");
			// lengthLineInCm = getNumber("length of line in cm", 10);
			lengthLineInCm = setRealDimensionsNum;
			pixelPerCmTmp = pixelLength/lengthLineInCm;
			pixelPerCm = Array.concat(pixelPerCm,pixelPerCmTmp);
			// print(pixelPerCmTmp);
			print('length: '+pixelPerCmTmp+' px/cm');
			// selectWindow("Results");
			// close("Results");
			closeAllWindows();
		}
		if(cropImageOption){
			IJ.redirectErrorMessages();
			grabMovieFrames(thisFile,sliceToEstimateThreshold,downsampleMovieFactor,normalizeStackChoice,numSlicesToPreview);

			run("Threshold...");
			if(objMaxCrop!=-1){
				print('using crop threshold...');
				setThreshold(objMinCrop, objMaxCrop);
			}
			// as user to crop image
			if(polygonSelectionOption){
				setTool("polygon");
				if (fileNo!=0){
					fileNoPoly = fileNo - 1;
					startIdx = cropSelectionArrayIdxStart[fileNoPoly];
					endIdx = cropSelectionArrayIdxEnd[fileNoPoly];
					print(startIdx);
					print(endIdx);
					xcoordInput = Array.slice(cropSelectionArrayX, startIdx, endIdx);
					ycoordInput = Array.slice(cropSelectionArrayY, startIdx, endIdx);
					makeSelection("polygon", xcoordInput, ycoordInput);
				}
				waitForUser("select region to crop...");
				getSelectionCoordinates(x, y);
				Array.print(x);
				Array.print(y);
				// store location of this movies coordinates in array
				startIdx = cropSelectionArrayX.length;
				cropSelectionArrayIdxStart = Array.concat(cropSelectionArrayIdxStart,startIdx);
				endIdx = cropSelectionArrayX.length+x.length;
				print(startIdx);
				print(endIdx);
				cropSelectionArrayIdxEnd = Array.concat(cropSelectionArrayIdxEnd,endIdx);
				// add selection coordinates to array
				cropSelectionArrayX = Array.concat(cropSelectionArrayX,x);
				cropSelectionArrayY = Array.concat(cropSelectionArrayY,y);
			}else{
				setTool("rectangle");
				if (fileNo!=0){
					fileNoRect = fileNo - 1;
					makeRectangle(cropRectArrayX[fileNoRect], cropRectArrayY[fileNoRect], cropRectArrayWidth[fileNoRect], cropRectArrayHeight[fileNoRect]);
				}
				waitForUser("select region to crop...");
				getSelectionBounds(x, y, width, height);
				// getSelectionCoordinates(x, y);
				cropRectArrayX = Array.concat(cropRectArrayX,x);
				cropRectArrayY = Array.concat(cropRectArrayY,y);
				cropRectArrayWidth = Array.concat(cropRectArrayWidth,width);
				cropRectArrayHeight = Array.concat(cropRectArrayHeight,height);
			}
			getThreshold(objMinCrop,objMaxCrop);
			thresholdMinArray = Array.concat(thresholdMinArray,objMinCrop);
			thresholdMaxArray = Array.concat(thresholdMaxArray,objMaxCrop);
			closeAllWindows();
		}else{
			objMinCrop = -1;
			objMaxCrop = -1;
		}
		//
		if(backgroundSubtract){

			IJ.redirectErrorMessages();
			grabMovieFrames(thisFile,sliceToEstimateThreshold,downsampleMovieFactor,normalizeStackChoice,numSlicesToPreview);

			stackID = getTitle();
			subtractBackground(stackID,backgroundAvgOrMax,"false",0,0);

			run("Threshold...");
			if(objMaxCrop!=-1){
				print('using crop threshold...');
				setThreshold(objMinCrop, objMaxCrop);
			}

			setTool("polygon");
			waitForUser("select region to crop during background subtraction...");
			getSelectionCoordinates(x, y);
			// store location of this movies coordinates in array
			startIdx = backgroundSelectionArrayX.length;
			backgroundSelectionArrayIdxStart = Array.concat(backgroundSelectionArrayIdxStart,startIdx);
			endIdx = backgroundSelectionArrayX.length+x.length;
			backgroundSelectionArrayIdxEnd = Array.concat(backgroundSelectionArrayIdxEnd,endIdx);
			// add selection coordinates to array
			backgroundSelectionArrayX = Array.concat(backgroundSelectionArrayX,x);
			backgroundSelectionArrayY = Array.concat(backgroundSelectionArrayY,y);
			//
			getThreshold(objMinCrop,objMaxCrop);
			thresholdMinArray = Array.concat(thresholdMinArray,objMinCrop);
			thresholdMaxArray = Array.concat(thresholdMaxArray,objMaxCrop);

			closeAllWindows();
		}
		// if already did crop, ignore since get threshold from that
		if(!useAutomaticThreshold&!cropImageOption&!backgroundSubtract){
			IJ.redirectErrorMessages();
			grabMovieFrames(thisFile,sliceToEstimateThreshold,downsampleMovieFactor,normalizeStackChoice,numSlicesToPreview);

			if(framesToGammaAdj!=0){
				print('gamma correcting: '+gammaAdjValue);
				for(frameNo=1; frameNo<=framesToGammaAdj; frameNo++) {
					setSlice(frameNo);
					for(runNo=1; runNo<=3; runNo++) {
						run("Gamma...", "value="+gammaAdjValue);
					}
					// run("Gamma...", "value=0.1");
					// run("Gamma...", "value=5 slice");
					// v = getResult("Mean",i-1);
					// print(v);
					// run("Subtract...", "value=&v");
				}
			}
			setSlice(11);
			run("Threshold...");
			if(objMaxCrop!=-1){
				print('using crop threshold...');
				setThreshold(objMinCrop, objMaxCrop);
			}else{
				setAutoThreshold(thresholdMethodType);
			}
			waitForUser("select threshold, only vary min...");
			getThreshold(objMin,objMax);
			thresholdMinArray = Array.concat(thresholdMinArray,objMin);
			thresholdMaxArray = Array.concat(thresholdMaxArray,objMax);
			closeAllWindows();
		}
	}
	print('=====================');
	print('coords');
	Array.print(cropSelectionArrayX);
	Array.print(cropSelectionArrayY);
	print('=====================');
	// loop over all files and process in batch
	for(fileNo=0; fileNo<listOfFiles.length; fileNo++){
		print('=====================');
		thisFile = listOfFiles[fileNo];
		print((fileNo+1)+'/'+listOfFiles.length+': '+thisFile);
		// if user just wants to open a single frame, e.g. to measure px/cm
		if(openSingleFrame){
			open(thisFile);
			setTool("line");
			waitForUser("select threshold, only vary min...");
		}else{
			print('loading movie: '+thisFile);
			// set batch mode ON
			if(runBatchMode){
				setBatchMode(true); //batch mode on
			}
			loadMovieTime = getTime();
			if(endsWith(thisFile, 'avi')){
				if(checkUseAviDialog){
					IJ.redirectErrorMessages();
					open(thisFile);
				}else{
					if (firstFrame!=0) {
						IJ.redirectErrorMessages();
						run("AVI...", "select=["+thisFile+"] first="+firstFrame+" last="+lastFrame);
					}else{
						IJ.redirectErrorMessages();
						run("AVI...", "select=["+thisFile+"]");
					}
				}
			}else if(endsWith(thisFile, 'tiff')||endsWith(thisFile, 'tif')){
				open(thisFile);
				// run("TIFF Virtual Stack...","open="+thisFile);
			}
			loadMovieTime = (getTime()-loadMovieTime)/1000;
			print('loaded movie in ' + loadMovieTime + ' seconds');


			startTime = getTime();
			// get stackID
			stackID = getTitle();
			// DOWNSAMPLE MOVIE
			if(downsampleMovieFactor>0){
				downsampleMovie(stackID,downsampleMovieFactor);
				print((getTime()-startTime)/1000 + ' seconds');
			}
			// open(thisFile);
			if(checkUse8bit){
				run("8-bit");
			}
			if(checkUse32bit){
				run("32-bit");
			}
			// get current image directory
			stackDir = getDirectory("image");
			// ==================CROP
			// ask user to crop image
			if(cropImageOption){
				if(polygonSelectionOption){
					startIdx = cropSelectionArrayIdxStart[fileNo];
					endIdx = cropSelectionArrayIdxEnd[fileNo];
					print(startIdx);
					print(endIdx);
					xcoordInput = Array.slice(cropSelectionArrayX, startIdx, endIdx);
					ycoordInput = Array.slice(cropSelectionArrayY, startIdx, endIdx);
					Array.print(xcoordInput);
					Array.print(ycoordInput);
					cropImage(stackID,"NaN",xcoordInput,ycoordInput,0,0,polygonSelectionOption);
				}else{
					cropImage(stackID,"NaN",cropRectArrayX[fileNo],cropRectArrayY[fileNo],cropRectArrayWidth[fileNo],cropRectArrayHeight[fileNo],polygonSelectionOption);
				}
				print((getTime()-startTime)/1000 + ' seconds');
			}
			// ==================BACKGROUND
			// decide whether to subtract the background
			if(backgroundSubtract){
				startIdx = backgroundSelectionArrayIdxStart[fileNo];
				endIdx = backgroundSelectionArrayIdxStart[fileNo];
				xcoordInput = Array.slice(backgroundSelectionArrayX, startIdx, endIdx);
				ycoordInput = Array.slice(backgroundSelectionArrayY, startIdx, endIdx);
				subtractBackground(stackID,backgroundAvgOrMax,"0",xcoordInput,ycoordInput);
				print((getTime()-startTime)/1000 + ' seconds');
			}else{
				selectWindow(stackID);
				run("Invert", "stack");
				print((getTime()-startTime)/1000 + ' seconds');
			}
			if(extraInvert){
				run("Invert", "stack");
				print((getTime()-startTime)/1000 + ' seconds');
			}else{
			}
			// ==================NORMALIZE
			// normalize the image so threshold can be the same
			if(normalizeStackChoice){
				run("32-bit");
				normalizeStack(stackID);
				run("8-bit");
				print((getTime()-startTime)/1000 + ' seconds');
			}
			// ==================THRESHOLD
			// threshold the image
			if(useAutomaticThreshold){
				thresholdStack(stackID, objMinAdd,objThresHigh,objThresLow,useAutomaticThreshold,sliceToEstimateThreshold,framesToGammaAdj,gammaAdjValue,thresholdMethodType,0,0);
			}else{
				thresholdStack(stackID, objMinAdd,objThresHigh,objThresLow,useAutomaticThreshold,sliceToEstimateThreshold,framesToGammaAdj,gammaAdjValue,thresholdMethodType,thresholdMinArray[fileNo],thresholdMaxArray[fileNo]);
			}
			print((getTime()-startTime)/1000 + ' seconds');
			// ==================CROP
			// ask user to crop image
			if(cropImageOption){
				if(polygonSelectionOption){
					startIdx = cropSelectionArrayIdxStart[fileNo];
					endIdx = cropSelectionArrayIdxEnd[fileNo];
					xcoordInput = Array.slice(cropSelectionArrayX, startIdx, endIdx);
					ycoordInput = Array.slice(cropSelectionArrayY, startIdx, endIdx);
					cropImage(stackID,"0",xcoordInput,ycoordInput,0,0,polygonSelectionOption);
				}else{
					cropImage(stackID,"0",cropRectArrayX[fileNo],cropRectArrayY[fileNo],cropRectArrayWidth[fileNo],cropRectArrayHeight[fileNo],polygonSelectionOption);
				}
				print((getTime()-startTime)/1000 + ' seconds');
			}
			// if(cropImageOption){
			// 	cropImage(stackID,"0",cropRectArrayX[fileNo],cropRectArrayY[fileNo],cropRectArrayWidth[fileNo],cropRectArrayHeight[fileNo]);
			// 	print((getTime()-startTime)/1000 + ' seconds');
			// }
			// ==================ERODE AND DILATE
			// erode and dilate image, remove small objects
			if(erodeDilateStack){
				print('eroding and dilating...');
				run("Options...", "iterations="+erodeIterations+" count=1 edm=Overwrite do=Nothing");
				run("Erode", "stack");
				run("Options...", "iterations="+dilateIterations+" count=1 edm=Overwrite do=Nothing");
				run("Dilate", "stack");
				run("Options...", "iterations=1 count=1 edm=Overwrite do=Nothing");
				print((getTime()-startTime)/1000 + ' seconds');
			}
			// ==================GET COORDINATES
			// get x,y, etc.
			measureObj(stackID, measureOptions,analyzeOptions);
			print((getTime()-startTime)/1000 + ' seconds');
			// ==================RESCALE COORDINATES
			// RESCALE COORDINATES
			if(downsampleMovieFactor>0){
				print('restoring proper coordinates...');
				selectWindow(stackID);
				Stack.getDimensions(width, height, channels, slices, frames);
				// loop over each frame in movie and normalize the image values
				selectWindow(stackID);
				print(nResults);
				for(frameNo=0; frameNo<=(nResults-1); frameNo++) {
					XMvalue = getResult("XM",frameNo);
					YMvalue = getResult("YM",frameNo);
					setResult("XM", frameNo, XMvalue*downsampleMovieFactor);
					setResult("YM", frameNo, YMvalue*downsampleMovieFactor);
				}
				print((getTime()-startTime)/1000 + ' seconds');
			}
			if(setRealDimensions){
				print('adding real dimensions...');
				selectWindow(stackID);
				Stack.getDimensions(width, height, channels, slices, frames);
				// loop over each frame in movie and normalize the image values
				selectWindow(stackID);
				print(nResults);
				for(frameNo=0; frameNo<=(nResults-1); frameNo++) {
					XMvalue = getResult("XM",frameNo);
					YMvalue = getResult("YM",frameNo);
					setResult("XM_cm", frameNo, XMvalue/pixelPerCm[fileNo]);
					setResult("YM_cm", frameNo, YMvalue/pixelPerCm[fileNo]);
				}
			}
			// ==================
			// save results table
			saveSubDir = File.getName(File.getParent(thisFile));
			if(saveInSubdirSwitch){
				saveDirTmp = saveDir+File.separator+saveSubDir+File.separator;
			}else{
				saveDirTmp = saveDir+File.separator;
			}
			File.makeDirectory(saveDirTmp);
			saveResults(saveDirTmp, stackID);
			print((getTime()-startTime)/1000 + ' seconds');
		}
		// close all windows
		if(closeAllWindowsSwitch){
			closeAllWindows();
		}
		logDir = saveDir+"\\logs\\";
		File.makeDirectory(logDir);
		if (File.exists(logDir)){
			selectWindow("Log");  //select Log-window
			saveAs("Text", logDir+stackID+".log");
			// print("\\Clear");
		}else{
			selectWindow("Log");  //select Log-window
			saveAs("Text", saveDir+stackID+".log");
		}
		if(runBatchMode){
			setBatchMode(false); //exit batch mode
		}
	}
	print((getTime()-startTime)/1000 + ' seconds');
}
function grabMovieFrames(thisFile,sliceToEstimateThreshold,downsampleMovieFactor,normalizeStackChoice,numSlicesToPreview){
	if(endsWith(thisFile, 'avi')){
		run("AVI...", "select=["+thisFile+"] use");
		// run("AVI...", "select=["+thisFile+"] first="+1+" last="+numSlicesToPreview);
		// run("AVI...", "select=["+thisFile+"] first="+sliceToEstimateThreshold+" last="+(sliceToEstimateThreshold+10));
		// sliceToEstimateThresholdTwo = sliceToEstimateThreshold+1000;
		// run("AVI...", "select=["+thisFile+"] first="+sliceToEstimateThresholdTwo+" last="+(sliceToEstimateThresholdTwo+10));
		// run("Concatenate...", "all_open title=["+thisFile+"]");
		stackID = getTitle();
		// DOWNSAMPLE MOVIE
		if(downsampleMovieFactor>0){
			downsampleMovie(stackID,downsampleMovieFactor);
			selectWindow(stackID);run("In [+]");run("In [+]");
		}else{
			selectWindow(stackID);run("In [+]");
		}
		// normalize the image so threshold can be the same
		if(normalizeStackChoice){
			run("32-bit");
			normalizeStack(stackID);
			run("8-bit");
		}
		if(checkUse8bit){
			run("8-bit");
		}
		if(checkUse32bit){
			run("32-bit");
		}
	}else if(endsWith(thisFile, 'tiff')||endsWith(thisFile, 'tif')){
		run("TIFF Virtual Stack...","open="+thisFile);
		// open(thisFile);
		stackID = getTitle();
	}
}
function closeAllWindows(){
	while (nImages>0) {
		selectImage(nImages);
		close();
	}
}
function downsampleMovie(stackID,downsampleMovieFactor){
	print("---\ndownsampling...");
	selectWindow(stackID);
	Stack.getDimensions(width, height, channels, slices, frames);
	run("Size...", "width="+floor(width/downsampleMovieFactor)+" height="+floor(height/downsampleMovieFactor)+" depth="+slices+" constrain average interpolation=Bilinear");
}
function cropImage(stackID,cropValue,xcoord,ycoord,width,height,polygonSelectionOption){
	print("---\ncropping...");
	selectWindow(stackID);

	// as user to crop image
	if(polygonSelectionOption){
		setTool("polygon");
		makeSelection("polygon", xcoord, ycoord);
	}else{
		setTool("rectangle");
		makeRectangle(xcoord, ycoord, width, height);
	}
	// waitForUser("select region to crop...");

	run("Make Inverse");
	run("Set...", "value="+cropValue+" stack");
	run("Select None");

	// run("Crop");

	return true;
}
function subtractBackground(stackID,backgroundAvgOrMax,cropValue,xcoord,ycoord){
	print("---\nsubtracting background...");
	// substracts background from the input image. image must already be opened
	selectWindow(stackID);
	// get image properties
	Stack.getDimensions(width, height, channels, slices, frames);
	if(backgroundAvgOrMax){
		backgroundStackID = "AVG_" + stackID;
		// get average
		run("Z Project...", "start=1 stop=" + slices + " projection=[Average Intensity]");
	}else{
		backgroundStackID = "MAX_" + stackID;
		// get average
		run("Z Project...", "start=50 stop=" + slices + " projection=[Max Intensity]");
	}
	// invert the stack and the average
	selectWindow(stackID);
	run("Invert", "stack");
	selectWindow(backgroundStackID);
	run("Invert");
	if(cropValue=="0"){
		// set area selected to zero
		makeSelection("polygon", xcoord, ycoord);
		// makeSelection("freehand", xcoord, ycoord);
		run("Set...", "value="+cropValue+" stack");
	};

	// subtract the background
	imageCalculator("Subtract stack", stackID, backgroundStackID);
	// threshold the stack
	selectWindow(stackID);

	return true;
}
function normalizeStack(stackID){
	print("---\nnormalizing...");
	// this normalizes each stack by it's own mean then re-scales it. this allows absolute thresholding across all stacks.
	selectWindow(stackID);
	// convert to 32-bit so calculations are correct
	// run("32-bit");
	run ("Select None");
	// only measure the mean
	run("Set Measurements...", "  mean redirect=None decimal=3");
	// plot the mean for the entire stack
	run("Plot Z-axis Profile");
	// get image properties
	selectWindow(stackID);
	Stack.getDimensions(width, height, channels, slices, frames);
	// loop over each frame in movie and normalize the image values
	selectWindow(stackID);
	print(slices);
	// get the stack mean
	stackMean = 0;
	for(i=1; i<=slices; i++) {
		setSlice(i);
		stackMean = stackMean+getResult("Mean",i-1);
	}
	stackMean = stackMean/slices;
	// normalize
	for(i=1; i<=slices; i++) {
		setSlice(i);
		v = getResult("Mean",i-1)-stackMean;
		if (v<-20) {
			v = -20;
		}
		// print(v);
		run("Subtract...", "value=&v");
	}
	// reset the min-max so all images have the same range
	resetMinAndMax();
	// convert to 8-bit


	return true;
}
function thresholdStack(stackID, objMinAdd,objThresHigh,objThresLow,useAutomaticThreshold,sliceToEstimateThreshold,framesToGammaAdj,gammaAdjValue,thresholdMethodType,objMin,objMax){
	print("---\nthresholding...");
	// thresholds a stack based on the gray value of an object

	// ask user for location
	selectWindow(stackID);

	// // ask user to select obj
	// // convert tool to free-hand temporarily
	// // setTool("freehand");
	// setTool("wand");
	// waitForUser("draw region or select obj");
	// run("Set Measurements...", "mean min max redirect=None decimal=3");
	// run("Measure");
	// store mean gray value
	// objMean = getResult("Mean");
	// objMin = getResult("Min");
	// objMax = getResult("Max");
	// sliceToEstimateThreshold = 100;
	// framesToGammaAdj = 7;
	if(framesToGammaAdj!=0){
		print('gamma correcting: '+gammaAdjValue);
		for(i=1; i<=framesToGammaAdj; i++) {
			setSlice(i);
			for(ii=1; ii<=3; ii++) {
				run("Gamma...", "value="+gammaAdjValue);
			}
			// run("Gamma...", "value=0.1");
			// run("Gamma...", "value=5 slice");
			// v = getResult("Mean",i-1);
			// print(v);
			// run("Subtract...", "value=&v");
		}
		// waitForUser("select threshold, only vary min...");
	}
	if(useAutomaticThreshold){
		// setThreshold(150, 255);
		// run("Convert to Mask", "method=MaxEntropy background=Dark calculate");
		// run("Convert to Mask", "method=Otsu background=Dark calculate");
		// run("Convert to Mask", "method=Minimum background=Dark calculate");
		setSlice(sliceToEstimateThreshold);
		setAutoThreshold(thresholdMethodType);
		run("Convert to Mask", "method="+thresholdMethodType+" background=Dark");
		// run("Erode", "stack");
	}else{
		// allow the user to set the threshold to be used
		// setThreshold(150, 255);
		// start movie
		// run("Animation Options...", "speed=500 loop start");
		// run("Threshold...");
		// waitForUser("select threshold, only vary min...");
		// getThreshold(objMin,objMax);
		// set the high/low values to threshold on
		objThresHigh = objMax;
		objThresLow = objMin+objMinAdd*objMin;
		setTool("rectangle");

		// threshold the image
		setAutoThreshold("Default");
		//run("Threshold...");
		setAutoThreshold("Default");
		setThreshold(objThresLow, objThresHigh);
		setOption("BlackBackground", false);
		run("Convert to Mask", "method=Default background=Light");
		print("low threshold: "+objThresLow);
		print("high threshold: "+objThresHigh);
	}
	return true;
}
function measureObj(stackID, measureOptions,analyzeOptions){
	print("---\ngetting obj measurements...");
	// measures the location of an object based on a binary stack
	selectWindow(stackID);
	// measure results
	run("Set Measurements...", measureOptions);
	run("Analyze Particles...", analyzeOptions);

	return true;
}
function saveResults(saveDir, stackID){
	print("---\nsaving results...");
	// save results to file
	// set io to comma-delineated file
	// run("Input/Output...", "jpeg=85 gif=-1 file=.csv use_file copy_column save_column");
	run("Input/Output...", "jpeg=85 gif=-1 file=.csv use_file save_column");
	// save the results
	saveAs("Results", saveDir+stackID+".tracking.csv");
	print('saved to: ' + saveDir+stackID+".tracking.csv");

	return true;
}
function getBaseFilename(file){
	splitPath = split(path,".");
	endOfPath = splitPath[splitPath.length-1];
	return endOfPath;
}