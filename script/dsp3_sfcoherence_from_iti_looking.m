function results = dsp3_sfcoherence_from_iti_looking(spike_ts, spike_labels, look_outs, varargin)

assert_ispair( spike_ts, spike_labels );

defaults = dsp3.get_common_lfp_defaults( dsp3.get_common_make_defaults() );
defaults.event_name = 'first-look';
defaults.step_size = 0.05;
defaults.consolidated = [];
defaults.check_events = true;

params = dsp3.parsestruct( defaults, varargin );

consolidated = conditional( @() ~isempty(params.consolidated) ...
  , @() params.consolidated, @() dsp3.get_consolidated_data() );

inputs = fullfile( 'aligned_lfp', params.event_name );
output = fullfile( 'per_trial_spike_field_coherence', params.event_name );

[~, runner] = dsp3.get_params_and_loop_runner( inputs, output, defaults, varargin );
runner.save_func = @(path, var) save(path, 'var', '-v7.3');

results = runner.run( @main, spike_ts, spike_labels, look_outs, consolidated, params );

end

function t = get_time_series(lfp_file, step_size)

t = lfp_file.params.min_t:step_size:lfp_file.params.max_t;

end

function events = get_event_times(look_outs, consolidated, align_ind)

min_func = @(x) ternary( isempty(x), nan, min(x) );

first_monk = cellfun( min_func, look_outs.monkey_starts );
first_bottle = cellfun( min_func, look_outs.bottle_starts );
events = min( first_monk, first_bottle );

align_plex = consolidated.align.data(align_ind, consolidated.align_key('plex'));
align_picto = consolidated.align.data(align_ind, consolidated.align_key('picto'));

if ( nnz(align_ind) == 0 )
  events(:) = nan;
else
  events = shared_utils.sync.cinterp( events, align_picto, align_plex );
end

end

function [data, labels, kept_I] = handle_lfp(lfp_file, params)

data = lfp_file.data;

labels = lfp_file.labels';
renamecat( labels, 'region', 'regions' );
renamecat( labels, 'channel', 'channels' );

if ( params.reference_subtract )
  [data, labels, kept_I] = dsp3.ref_subtract( data, labels' );
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

function out = main(files, spike_ts, spike_labels, look_outs, consolidated, params)

lfp_file = shared_utils.general.get( files, params.event_name );

look_event_ind = look_outs.event_ind;
lfp_event_ind = lfp_file.params.look_event_ind;

match_ind = arrayfun( @(x) find(look_event_ind == x), lfp_event_ind );
assert( numel(match_ind) == numel(lfp_event_ind), 'Some events did not match.' );

pl2_filename = combs( lfp_file.labels, 'pl2' ); 

units_this_session = find( spike_labels, pl2_filename );
sesh_id = combs( spike_labels, 'session_id', units_this_session );
assert( numel(sesh_id) == 1 || numel(sesh_id) == 0, '%d units matched this session.', numel(sesh_id) );
align_this_session = where( consolidated.align, sesh_id );

event_ts = get_event_times( look_outs, consolidated, align_this_session );

reg_combs = { {'acc', 'bla'}, {'bla', 'acc'} };

step_size = params.step_size;
window_size = lfp_file.params.window_size;

[lfp_data, lfp_labels, kept_I] = handle_lfp( lfp_file, params );
t = get_time_series( lfp_file, step_size );

all_coh = {};
all_labels = {};
all_event_inds = {};
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
    kept_lfp_ind = kept_I(curr_lfp_ind);
    
    curr_match_ind = match_ind(kept_lfp_ind);
    curr_spk = reshape( spike_ts{curr_spk_ind}, [], 1 );
    curr_events = event_ts(curr_match_ind);
    
    num_trials = numel( curr_lfp_ind );
    spike_counts = nan( num_trials, size(lfp_data, 3) );
    
    for k = 1:size(lfp_data, 3)
      data_a = lfp_data(curr_lfp_ind, :, k);
      
      if ( params.check_events )
        nan_data = all( isnan(data_a), 2 );
        nan_evts = isnan( curr_events );
        assert( isequal(nan_data, nan_evts), 'NaN events were not equal.' );
      end
      
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
    all_event_inds{end+1, 1} = look_event_ind(curr_match_ind);
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
out.event_ind = vertcat( all_event_inds{:} );

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