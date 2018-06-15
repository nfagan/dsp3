function [lags, crosscorr, max_crosscorr_lag, amp1, amp2]=amp_crosscorr(filtered1,filtered2,samp_freq,scaleopt, use_envelope)
% amp_crosscorr filters two eeg signals between a specified frequency band,
% calculates the crosscorrelation of the amplitude envelope of the filtered signals
% and returns the crosscorrelation as an output.
% USAGE: [lags, crosscorr, max_crosscorr_lag]=amp_crosscorr(eeg1,eeg2,samp_freq,low_freq,high_freq)
%INPUTS:
% eeg1-vector containing local field potential from brain area 1
% eeg2-vector containing local field potential from brain area 2
% samp_freq-sampling frequency, in Hz, of eeg1 and eeg2
% low_freq-low cut off, in Hz, of the band pass filter that will be applied to eeg1 and eeg2
% high_freq-high cut off, in Hz, of the band pass filter that will be applied to eeg1 and eeg2
%OUTPUTS:
% lags-vector contaning lags from -100 ms to +100 ms, over which the
% crosscorrelation was done
% crosscorr-vector with the crosscorrelation of the amplitude of eeg1 eeg2
% after being filtered between low_freq and high_freq
% max_crosscorr_lag-lag at which the crosscorrelation peaks. Negative
% max_crosscorr_lag indicates that eeg1 is leading eeg2.
% check inputs

if ( use_envelope )
  filt_hilb1 = hilbert(filtered1); %calculates the Hilbert transform of eeg1
  amp1 = abs(filt_hilb1);%calculates the instantaneous amplitude of eeg1 filtered between low_freq and high_freq
  mean1=amp1-mean(amp1); %removes mean of the signal because the DC component of a signal does not change the correlation
  filt_hilb2 = hilbert(filtered2);%calculates the Hilbert transform of eeg2
  amp2 = abs(filt_hilb2);%calculates the instantaneous amplitude of eeg2 filtered between low_freq and high_freq
  mean2=amp2-mean(amp2);
else
  mean1 = filtered1;
  mean2 = filtered2;
  amp1 = mean1;
  amp2 = mean2;
end
[crosscorr,lags]=xcorr(mean1, mean2,round(samp_freq/10),scaleopt); %calculates crosscorrelations between amplitude vectors
lags=(lags./samp_freq)*1000; %converts lags to miliseconds
g=find(crosscorr==max(crosscorr));%identifies index where the crosscorrelation peaks
max_crosscorr_lag=lags(g);%identifies the lag at which the crosscorrelation peaks

end