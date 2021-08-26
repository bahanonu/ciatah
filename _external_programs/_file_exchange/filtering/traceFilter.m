
LowCutOff = 10000;
HighCutOff = 1000;
%FrequencySample = 1/(thisTrace(2) - thisTrace(1));

TracesToApply = 1;

Order = 2;

FiltBH=zeros(Order+1, length(TracesToApply));
FiltAH=zeros(Order+1, length(TracesToApply));
FiltBL=zeros(Order+1, length(TracesToApply));
FiltAL=zeros(Order+1, length(TracesToApply));

FiltType = 'Butterworth';

for k=TracesToApply
    FrequencySample=1/(SpikeTraceData(k).XVector(2)-SpikeTraceData(k).XVector(1));
    %FrequencySample=1/0.200;
    
%     FNyquist=FrequencySample/2;
%     
%     Wn=FCutOff/FNyquist;

    if strcmp(FiltType, 'Butterworth')
        %see end of file for butterhigh2 function
        [FiltBH(:,k),FiltAH(:,k)] = butterhigh2(LowCutOff/FrequencySample);
        %see end of file for butterlow2 function
        [FiltBL(:,k),FiltAL(:,k)] = butterlow2(HighCutOff/FrequencySample); 
    end
end

for k=TracesToApply
    OriginalClass=class(thisTrace);
    
    % highpass filter first 
    %ResultFiltered=single(filtfilt(double(FiltBH(:,k)),double(FiltAH(:,k)),double(thisTrace)));
    ResultFiltered=single(filter(double(FiltBH(:,k)),double(FiltAH(:,k)),double(thisTrace)));
    % In any case, we want to keep the baseline value the same.
    % We also go back to the original data class
    thisTrace2=cast(ResultFiltered(:),OriginalClass);
    
    % lowpass filter next
    %ResultFiltered=single(filtfilt(double(FiltBL(:,k)),double(FiltAL(:,k)),double(thisTrace2)));
    ResultFiltered=single(filter(double(FiltBL(:,k)),double(FiltAL(:,k)),double(thisTrace2)));

    % In any case, we want to keep the baseline value the same.
    % We also go back to the original data class
    thisTrace3=cast(ResultFiltered(:),OriginalClass);
end

figure(42);
subplot(3,1,1)
plot(thisTrace)
subplot(3,1,2)
plot(thisTrace2)
subplot(3,1,3)
plot(thisTrace3)