function [psth, binT] = psth(spikeTS, eventTS, minT, maxT, binWidth, make_firing_rate)

if ( nargin < 6 )
  make_firing_rate = true;
end

% GKA 6/2011  -- originally named looplessPSTH

spikeTS = spikeTS(:);
% Reshape eventTS into a row vector:
eventTS = eventTS(:)';
% Compute a matrix of spike times relative to each event time:
alignTS = bsxfun(@minus, spikeTS, eventTS);
% Get a vector of the bin left edges, plus one extra bin at maxT:
binT = minT:binWidth:maxT;
% Compute a histogram for our analysis epoch:
psth = histc(alignTS(:)', binT);
% Convert the histogram to a firing rate:
if ( make_firing_rate )
  psth = psth/numel(eventTS)/binWidth;
end
% Discard extra bins:
binT = binT(1:end-1);
psth = psth(1:end-1);

end