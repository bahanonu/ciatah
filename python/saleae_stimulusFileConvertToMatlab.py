#!/usr/bin/env python3

# Biafra Ahanonu
# 2018.05.13 [17:05:22]
# Loads Saleae files and converts them to either all digital or mixed digital/analog Matlab output files

# Import needed packages
import os
import re
from os import listdir
from os.path import isfile, join
from os.path import basename
import time
# See https://github.com/ppannuto/python-saleae
import saleae

# folder = time.strftime('%Y-%m-%d--%H-%M-%S')
# os.mkdir(folder)

# Instance of Saleae API interface class
sObj = saleae.Saleae()

# Paths for files and export
# rootFilePath = r'\\171.65.115.78\pain\data\behavior\p700\SNI'
rootFilePath = r'INPUTPATH'
rootExportPath = r'OUTPUTPATH'
os.makedirs(rootExportPath, exist_ok=True)

# sessionName = '2018_04_25_p700_m608_preSNI01'
# listFileNames = ['01habit', '02lickSession', '03thresholds', '04stimuliBlockOne', '05stimuliBlockTwo', '06stimuliBlockThree', '07stimuliBlockFour', '08stimuliBlockFive','09lickSession']

# Salaea channels for logicdata files with both digital and analog data
cDigitalChans = [0, 4, 5]
cAnalogChans = [1, 2, 3]

# Regexp for digital only and mixed digital/analog files
digitalFileRegexp = '.*_stimuli.*'
digitalAnalogFileRegexp = '.*_accelerometerLick.*'

# get list of files
directoryFiles = [f for f in listdir(rootFilePath) if isfile(join(rootFilePath, f))]
nFiles = len(directoryFiles)
# for i in range(len(listFileNames)):
for i in range(nFiles):
	thisPath = directoryFiles[i]
	thisPath = rootFilePath+'\\'+thisPath
	fileName = basename(thisPath)
	thisExportPath = rootExportPath+'\\'+os.path.splitext(fileName)[0]+'.mat'
	dispStr = str(i+1)+'\\'+str(nFiles)+' | '
	if os.path.isfile(thisPath):
		if os.path.isfile(thisExportPath):
			print(dispStr+'Already converted: '+thisExportPath)
		else:
			print(dispStr+'Loading: '+thisPath)
			sObj.load_from_file(thisPath)
			# determine type of export based on end file name
			# digital only
			if re.match(digitalFileRegexp, fileName) is not None:
				sObj.export_data2(thisExportPath, digital_channels=None, analog_channels=None, time_span=None, format='matlab')
			# digital/analog only
			elif re.match(digitalAnalogFileRegexp, fileName) is not None:
				sObj.export_data2(thisExportPath, digital_channels=cDigitalChans, analog_channels=cAnalogChans, time_span=None, format='matlab')
			# close tab to reduce any possibility of incorrect export
			print('\tExported: '+thisExportPath)
			sObj.close_all_tabs()
	else:
		print(dispStr+'No file: '+thisPath)