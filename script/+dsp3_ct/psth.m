function [psth, labels, out_t, raster_times] = psth(spikes, events, min_t, max_t, bin_width, include_raster)

if ( nargin < 5 )
  bin_width = [];
end

if ( nargin < 6 )
  include_raster = false;
end

assert_ispair( spikes );
assert_ispair( events );

validateattributes( events.data, {'double'}, {'column'}, mfilename, 'event times' );

psth = {};
labels = {};
ts = {};
binned_ts = {};

spike_dat = spikes.data;
event_dat = events.data;

spike_labels = spikes.labels;
event_labels = events.labels;

num_spike_dat = numel( spike_dat );

parfor i = 1:num_spike_dat
  session_id = cellstr( spike_labels, 'session_ids', i );
  
  spike_ts = spike_dat{i}(:);
  
  event_ind = find( event_labels, session_id );
  event_ts = event_dat(event_ind, :);
  
  if ( isscalar(min_t) )
    use_min_t = min_t;
  else
    use_min_t = min_t(event_ind);
  end
  
  if ( isscalar(max_t) )
    use_max_t = max_t;
  else
    use_max_t = max_t(event_ind);
  end
  
  if ( isempty(bin_width) )
    tmp_psth = arrayfun( @(min, max) sum(spike_ts >= min & spike_ts < max) ...
      , event_ts+use_min_t, event_ts+use_max_t );
    t = [];
  else
    [tmp_psth, t] = bfw.trial_psth( spike_ts, event_ts, min_t, max_t, bin_width );
  end
  
  is_nan_event = isnan( event_ts );     
  tmp_psth(is_nan_event, :) = nan;
  
  evt_labels = prune( event_labels(event_ind) );
  spk_labels = prune( spike_labels(i) );
  join( evt_labels, spk_labels );
  
  psth{i} = tmp_psth;
  labels{i} = evt_labels;
  ts{i} = t;
  
  if ( include_raster )
    binned_ts{i} = ...
      arrayfun( @(x) spike_ts(spike_ts >= min_t+x & spike_ts <= max_t+x) - x, event_ts, 'un', 0 );
  end
end

psth = vertcat( psth{:} );
labels = vertcat( fcat, labels{:} );
out_t = vertcat( ts{:} );
raster_times = vertcat( binned_ts{:} );

assert_ispair( psth, labels );

end