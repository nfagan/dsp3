function out = cc_sfcoherence(files, spike_times, spike_labels, event_times, event_labels, varargin)

defaults = dsp3.make.defaults.cc_sfcoherence();
params = dsp3.parsestruct( defaults, varargin );

epoch = params.epoch;
chronux_params = params.chronux_params;

assert_ispair( spike_times, spike_labels );
assert_ispair( event_times, event_labels );

event_times(event_times == 0) = nan;  % 0 means no-events; convert to NaN

lfp_file = shared_utils.general.get( files, epoch );
[signals, lfp_labels] = measure_to_pair( lfp_file.measure );
signals = handle_filtering_and_referencing( signals, lfp_labels, params );

[I, C] = findall( lfp_labels, {'days', 'channels', 'regions'} );

look_back = lfp_file.measure.start;
look_ahead = lfp_file.measure.stop;
bin_size = lfp_file.measure.window_size;
step_size = lfp_file.measure.step_size;

all_coh = {};
all_coh_labels = {};
all_freqs = {};
all_times = {};

for i = 1:numel(I)  % for each day x region x channel of lfp data ...
  shared_utils.general.progress( i, numel(I) );
  
  % Index of spike times matching this lfp day.
  unit_day_ind = find( spike_labels, C{1, i} );
  % Index of event times matching this lfp day.
  event_day_ind = find( event_labels, C{1, i} );
  
  assert( numel(event_day_ind) == numel(I{i}), 'Event times and lfp data mismatch.' );
  
  % Get each channel x region combination of units, for this day
  [unit_I, unit_C] = findall( spike_labels, {'channels', 'regions'}, unit_day_ind );
  % Don't process channels that are the same between spike + lfp
  [unit_I, unit_C] = remove_matching_channels( unit_I, unit_C, unit_C(1, :), C{2, i} );

  if ( isempty(unit_I) )
    warning( 'No matching spike data for: "%s".', strjoin(C(:, i), ' | ') );
    continue;
  end
  
  matching_signals = signals(I{i}, :);
  matching_labels = prune( lfp_labels(I{i}) );
  matching_event_times = event_times(event_day_ind);
  
  windowed_signals = shared_utils.array.bin3d( matching_signals, bin_size, step_size );
  
  min_ts = (look_back:step_size:look_ahead) / 1e3;
  max_ts = min_ts + bin_size/1e3;
  
  for j = 1:numel(unit_I) % for each channel of spikes ...
    spike_times_per_unit = spike_times(unit_I{j});
    
    for k = 1:numel(spike_times_per_unit)
      spike_times_this_unit = spike_times_per_unit{k};
      % Labels corresponding to the k-th row of the j-th index into units
      % for this day; i.e., the index of one unit on one day.
      unit_labels = prune( spike_labels(unit_I{j}(k)) );
      
      [coh, freqs, any_non_nan] = calculate_sf_coherence( windowed_signals, spike_times_this_unit ...
        , matching_event_times, min_ts, max_ts, chronux_params );
      
      coh_labels = make_coh_labels( matching_labels, unit_labels );
      
      if ( params.remove_nan_trials )
        non_nan_trial = ~isnan( matching_event_times );
        non_nan_coh = ~all( all(isnan(coh), 2), 3 );
        non_nan = non_nan_coh(:) & non_nan_trial(:);
        
        coh = coh(non_nan, :, :);
        keep( coh_labels, find(non_nan) );
      end
      
      all_coh{end+1} = coh;
      all_coh_labels{end+1} = coh_labels;
      all_freqs{end+1} = freqs;
      all_times{end+1} = min_ts;
    end
  end
end

labels = vertcat( fcat, all_coh_labels{:} );
[labs, categories] = categorical( labels );

out = struct();
out.params = params;
out.coherence = vertcat( all_coh{:} );
out.labels = labs;
out.categories = categories;
out.unified_filename = lfp_file.unified_filename;

if ( isempty(all_freqs) )
  warning( 'All coherence values were nan.' );
  
  out.f = [];
  out.t = [];
else
  out.f = all_freqs{1};
  out.t = all_times{1};
end

end

function [I, C] = remove_matching_channels(I, C, spike_channels, lfp_channel)

spk_channel = strrep( lfp_channel, 'FP', 'SPK' );

is_matching = strcmp( spike_channels, spk_channel );

I = I(~is_matching);
C = C(:, ~is_matching);

end

function lfp_labels = make_coh_labels(lfp_labels, spike_labels)

spike_region = sprintf( 'spike_%s', char(combs(spike_labels, 'regions')) );
spike_channel = char( combs(spike_labels, 'channels') );

spike_cats = { 'spike_regions', 'spike_channels' };
spike_labs = { spike_region, spike_channel };

addcat( lfp_labels, spike_cats );

for i = 1:numel(spike_cats)
  setcat( lfp_labels, spike_cats{i}, spike_labs{i} );
end

join( lfp_labels, spike_labels );

end

function [coh, freqs, any_non_nan] = calculate_sf_coherence(windowed_signals, spikes, events, min_ts, max_ts, params)

assert( numel(min_ts) == numel(max_ts) && numel(min_ts) == size(windowed_signals, 3) );
any_non_nan = false;

for i = 1:numel(min_ts)
  
  look_back = min_ts(i);
  look_ahead = max_ts(i);

  spikes_in_trials = convert_spike_times_to_trials( spikes, events, look_back, look_ahead );
  one_window_signals = squeeze( windowed_signals(:, :, i)' );
  
  [C,~,~,~,~,freqs] = coherencycpt( one_window_signals, spikes_in_trials, params );
  
  if ( i == 1 )
    coh = nan( size(C, 2), size(C, 1), numel(min_ts) );
  end
  
  coh(:, :, i) = C';
  
  any_non_nan = any_non_nan || any( ~reshape(isnan(C), [], 1) );
end

end

function spikes = convert_spike_times_to_trials(spike_times, event_times, look_back, look_ahead)

spikes = [];

for i = 1:numel(event_times)
  evt = event_times(i);
  
  tmp_spikes = struct( 'spikes', [] );
  
  if ( ~isnan(evt) )
    min_evt = evt + look_back;
    max_evt = evt + look_ahead;

    is_in_bounds_spike = spike_times >= min_evt & spike_times < max_evt;
    use_spikes = spike_times(is_in_bounds_spike);
    use_spikes = use_spikes - min_evt;

    tmp_spikes.spikes = reshape( use_spikes, [], 1 );
  end

  if ( isempty(spikes) )
    spikes = tmp_spikes;
  else
    spikes(end+1, 1) = tmp_spikes;
  end
end

end

function [signals, labels] = handle_filtering_and_referencing(signals, labels, params)

if ( params.filter )
  f1 = params.f1;
  f2 = params.f2;
  filt_order = params.filter_order;
  fs = params.sample_rate;
  signals = dsp3.zpfilter( signals, f1, f2, fs, filt_order );
end

if ( ~params.reference_subtract )
  return
end

is_not_ref = findnone( labels, 'ref' );
[I, C] = findall( labels, {'days', 'regions', 'channels', 'sites'}, is_not_ref );

for i = 1:numel(I)
  day_lab = C{1, i};
  
  ref_ind = find( labels, 'ref', find(labels, day_lab) );
  
  assert( numel(ref_ind) == numel(I{i}), 'Reference does not correspond to other channel.' );
  
  signals(I{i}, :) = signals(I{i}, :) - signals(ref_ind, :);
end

signals = signals(is_not_ref, :);
keep( labels, is_not_ref );

end

function [data, labs] = measure_to_pair(measure)

data = measure.data;
labs = fcat.from( measure.labels );

end