function out = coherence(files, event_name, site_pairs, varargin)

defaults = dsp3.make.defaults.coherence();
defaults.step_size = 0.05;

params = dsp3.parsestruct( defaults, varargin );

lfp_file = shared_utils.general.get( files, event_name );
data = lfp_file.data;

labels = lfp_file.labels';
renamecat( labels, 'region', 'regions' );
renamecat( labels, 'channel', 'channels' );

if ( params.reference_subtract )
  [data, labels] = dsp3.ref_subtract( data, labels' );
end

if ( params.filter )
  data = dsp3.zpfilter( data, params.f1, params.f2, lfp_file.sample_rate, params.filter_order );
end

window_size = lfp_file.params.window_size * lfp_file.sample_rate;
step_size = params.step_size * lfp_file.sample_rate;

windowed_data = shared_utils.array.bin3d( data, window_size, step_size );

time_series = get_time_series( lfp_file, params.step_size );
assert( numel(time_series) == size(windowed_data, 3), 'Time series mismatch.' );

[inds_a, inds_b] = get_pair_indices( labels, site_pairs );

num_time_bins = numel( time_series );
num_pairs = numel( inds_a );
total_num_trials = sum( cellfun(@numel, inds_a) );

is_first = true;
stp = 1;

coh_labels = fcat();

for i = 1:num_pairs
  ind_a = inds_a{i};
  ind_b = inds_b{i};
  num_trials = numel( ind_a );
  assign_idx = stp:stp+num_trials-1;
  
  for j = 1:num_time_bins
    data_a = windowed_data(ind_a, :, j);
    data_b = windowed_data(ind_b, :, j);
    
    [C, ~, ~, ~, ~, f] = coherencyc( data_a', data_b', params.chronux_params );
    
    if ( is_first )
      coh = nan( total_num_trials, numel(f), num_time_bins );
      is_first = false;
    end
    
    coh(assign_idx, :, j) = C';
  end
  
  region_str = strjoin_pair( labels, 'regions', ind_a, ind_b );
  channel_str = strjoin_pair( labels, 'channels', ind_a, ind_b );
  
  append( coh_labels, labels, ind_a );
  setcat( coh_labels, 'regions', region_str, assign_idx );
  setcat( coh_labels, 'channels', channel_str, assign_idx );
  
  stp = stp + num_trials;
end

prune( coh_labels );

out = struct();
out.params = params;
out.data = coh;
out.labels = coh_labels;
out.t = time_series;
out.f = f;

end

function label = strjoin_pair(labels, category, ind_a, ind_b)

labels_a = strjoin( combs(labels, category, ind_a), '_' );
labels_b = strjoin( combs(labels, category, ind_b), '_' );
label = sprintf( '%s_%s', labels_a, labels_b );

end

function [inds_a, inds_b] = get_pair_indices(labels, site_pairs)

[day_I, day_C] = findall( labels, 'days' );
site_pair_days = site_pairs.days;

inds_a = {};
inds_b = {};

for i = 1:numel(day_I)
  one_day = day_C{i};
  day_ind = strcmp( site_pair_days, one_day );
  
  if ( nnz(day_ind) ~= 1 )
    error( '%d days matched "%s".', one_day, nnz(day_ind) );
  end

  channels = site_pairs.channels{day_ind};
  num_pairs = size( channels, 1 );
  
  for j = 1:num_pairs
    ind_a = find( labels, channels{j, 1}, day_I{i} );
    ind_b = find( labels, channels{j, 2}, day_I{i} );
    
    if ( numel(ind_a) ~= numel(ind_b) )
      error( 'Trial number mismatch for day: "%s".', one_day );
    end
    
    inds_a{end+1, 1} = ind_a;
    inds_b{end+1, 1} = ind_b;
  end
end

end

function t = get_time_series(lfp_file, step_size)

t = lfp_file.params.min_t:step_size:lfp_file.params.max_t;

end