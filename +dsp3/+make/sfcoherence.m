function out = sfcoherence(files, event_name, spike_ts, spike_labels, varargin)

defaults = dsp3.make.defaults.coherence();
params = dsp3.parsestruct( defaults, varargin );

lfp_file = shared_utils.general.get( files, event_name );

event_ts = get_event_times( lfp_file );

reg_combs = { {'acc', 'bla'}, {'bla', 'acc'} };

step_size = params.step_size;
window_size = lfp_file.params.window_size;

[lfp_data, lfp_labels, kept_I] = handle_lfp( lfp_file, params );
t = get_time_series( lfp_file, step_size );

units_this_session = find( spike_labels, combs(lfp_labels, 'session_ids') );

all_coh = {};
all_labels = {};
f = [];

for i = 1:numel(reg_combs)
  ind_spk = find( spike_labels, reg_combs{i}{1}, units_this_session );
  ind_lfp = find( lfp_labels, reg_combs{i}{2} );
  
  unit_inds = findall( spike_labels, {'unit_uuid', 'channel', 'region'}, ind_spk );
  assert( all(unique(cellfun(@numel, unit_inds)) == 1) );
  
  lfp_inds = findall( lfp_labels, {'channels', 'regions', 'days'}, ind_lfp );
  
  comb_inds = dsp3.numel_combvec( unit_inds, lfp_inds );
  num_combs = size( comb_inds, 2 );
  
  for j = 1:num_combs
    comb_ind = comb_inds(:, j);
    
    curr_spk_ind = unit_inds{comb_ind(1)};
    curr_lfp_ind = lfp_inds{comb_ind(2)};
    
    curr_spk = reshape( spike_ts{curr_spk_ind}, [], 1 );
    curr_events = event_ts;
    
    num_trials = numel( curr_lfp_ind );
    spike_counts = nan( num_trials, size(lfp_data, 3) );
    
    assert( num_trials == numel(event_ts), 'Event times mismatch.' );
    
    for k = 1:size(lfp_data, 3)
      data_a = lfp_data(curr_lfp_ind, :, k);
      
      min_t = t(k) - window_size/2;
      max_t = t(k) + window_size/2;
      
      data_b = get_spikes( curr_spk, curr_events, min_t, max_t );
      
      [C, ~, ~, ~, ~, f] = coherencycpt( data_a', data_b', params.chronux_params );
      
      if ( k == 1 )
        tmp_coh = nan( num_trials, numel(f), size(lfp_data, 3) );
      end
      
      tmp_coh(:, :, k) = C';
      spike_counts(:, k) = arrayfun( @(x) numel(x.times), data_b );
    end
    
    all_coh{end+1, 1} = tmp_coh;
    all_labels{end+1, 1} = make_labels( lfp_labels, spike_labels, curr_lfp_ind, curr_spk_ind ); 
  end
end

out = struct();
out.params = params;
out.lfp_params = lfp_file.params;
out.src_filename = lfp_file.src_filename;
out.data = vertcat( all_coh{:} );
out.labels = vertcat( fcat(), all_labels{:} );
out.t = t;
out.f = f;

if ( isempty(out.data) )
  out.t = [];
end

end

function t = get_time_series(lfp_file, step_size)

t = lfp_file.params.min_t:step_size:lfp_file.params.max_t;

end

function events = get_event_times(lfp_file)

events = lfp_file.event_times;

end

function [data, labels, kept_I] = handle_lfp(lfp_file, params)

data = lfp_file.data;

labels = lfp_file.labels';
renamecat( labels, 'region', 'regions' );
renamecat( labels, 'channel', 'channels' );

if ( params.reference_subtract )
  [data, labels, kept_I] = params.reference_func( data, labels' );
else
  kept_I = rowmask( labels );
end

if ( params.filter )
  data = dsp3.zpfilter( data, params.f1, params.f2, lfp_file.sample_rate, params.filter_order );
end

window_size = lfp_file.params.window_size * lfp_file.sample_rate;
step_size = params.step_size * lfp_file.sample_rate;

data = shared_utils.array.bin3d( data, window_size, step_size );

end

function labs = make_labels(lfp_labs, spk_labs, lfp_ind, spk_ind)

labs = append( fcat(), lfp_labs, lfp_ind );

reg_lfp = combs( labs, 'regions' );
reg_spk = combs( spk_labs, 'region', spk_ind );

shared_labs = intersect( getlabs(spk_labs), getlabs(lfp_labs) );
lfp_cats = cellfun( @(x) whichcat(lfp_labs, x), shared_labs );
spk_cats = cellfun( @(x) whichcat(spk_labs, x), shared_labs );

non_matching = cellfun( @(x, y) ~strcmp(x, y), lfp_cats, spk_cats );

to_join = prune( rmcat(spk_labs(spk_ind), spk_cats(non_matching)) );
join( labs, to_join );

if ( ~isempty(labs) )
  setcat( labs, 'regions', sprintf('%s_%s', char(reg_spk), char(reg_lfp)) );
end

end

function spikes = get_spikes(spikes, events, min_t, max_t)

filtered_spikes = arrayfun( @(x) spikes(spikes >= x + min_t & spikes < x + max_t) - x - min_t, events, 'un', 0 );
spikes = struct( 'times', filtered_spikes );
spikes = spikes(:);

end