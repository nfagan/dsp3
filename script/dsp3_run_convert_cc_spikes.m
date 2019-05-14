spike_path = fullfile( dsp3.dataroot, 'analyses', 'processed_spikes', 'dictator_game_SUAdata_pre.mat' );

spike_file = load( spike_path );

%%

events = spike_file.all_event_time;
spikes = spike_file.all_spike_time;

[combined_spikes, combined_events] = dsp3_convert_cc_spikes( spikes, events );

%%

mask = fcat.mask( combined_events.labels ...
  , @find, 'choice' ...
  , @findnone, 'errors' ...
);

cond_spec = 'outcomes';
cond_I = findall( combined_events.labels, cond_spec, mask );

look_around = 1;

[kept_spikes, kept_labs] = ...
  dsp3_bin_sta_spikes_by_condition( combined_events, combined_spikes, cond_I, look_around );

kept_chans = combs( kept_labs, 'channel' );
for i = 1:numel(kept_chans)
  replace( kept_labs, kept_chans{i}, strrep(kept_chans{i}, 'SPK', 'FP') );
end

%%

[pl2_files, pl2_labels] = dsp3_get_signal_table_info();

%%

look_back = -500;
look_ahead = 500; % samples (ms)

unit_spec = csunion( cond_spec, {'unit_number', 'session_ids'} );

unit_I = findall( kept_labs, unit_spec );
assert( all(unique(cellfun(@numel, unit_I)) == 1) );

lfp_dat = {};
lfp_labs = fcat();

for i = 1:numel(unit_I)
  shared_utils.general.progress( i, numel(unit_I) );
  
  selectors = combs( kept_labs, {'channel', 'session_ids', 'region'}, unit_I{i} );
  pl2_ind = find( pl2_labels, selectors );
  
  if ( numel(pl2_ind) ~= 1 )
    continue;
  end
  
  % session_id, but with ref
  ref_selectors = { selectors{2}, 'ref' };
  ref_ind = find( pl2_labels, ref_selectors );
  assert( numel(ref_ind) == 1 );
  
  pl2_file = pl2_files{pl2_ind};
  pl2_chan = selectors{1};
  
  ref_file = pl2_files{ref_ind};
  ref_chan = char( combs(pl2_labels, 'channel', ref_ind) );
  assert( strcmp(ref_file, pl2_file) );
  
  lfp = PL2Ad( pl2_file, pl2_chan );
  ref_lfp = PL2Ad( pl2_file, ref_chan );
  
  % Ref subtract
  raw_lfp = lfp.Values - ref_lfp.Values;
  
  ts = (0:numel(lfp.Values)-1) .* (1/lfp.ADFreq);
  assert( lfp.ADFreq == 1e3 );  
  
  spike_ts = kept_spikes{unit_I{i}};
  
  t0_inds = bfw.find_nearest( ts, spike_ts );
  start_inds = t0_inds + look_back;
  stop_inds = t0_inds + look_ahead;
  
  tmp_dat = nan( numel(start_inds), look_ahead - look_back + 1 );
  
  for j = 1:numel(start_inds)
    tmp_dat(j, :) = zscore( raw_lfp(start_inds(j):stop_inds(j)) );
  end
  
  append1( lfp_labs, kept_labs, unit_I{i} );
  lfp_dat{end+1, 1} = tmp_dat;
end

%%

sta_labs = fcat();
for i = 1:numel(lfp_dat)
  append1( sta_labs, lfp_labs, i, size(lfp_dat{i}, 1) );
end

sta_lfp = vertcat( lfp_dat{:} );
assert_ispair( sta_lfp, sta_labs );

%%

save_labs = gather( sta_labs );

save_p = fullfile( dsp3.dataroot, 'analyses', 'sta_lfp' );
shared_utils.io.require_dir( save_p );

save( fullfile(save_p, 'sta_lfp.mat'), 'save_labs', 'sta_lfp' );
