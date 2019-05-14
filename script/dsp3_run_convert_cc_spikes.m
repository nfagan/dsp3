spike_file = load( '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/data/sfcoh/dictator_game_SUAdata_pre.mat' );

%%

events = spike_file.all_event_time;
spikes = spike_file.all_spike_time;

[combined_spikes, combined_events] = dsp3_convert_cc_spikes( spikes, events );

%%

mask = fcat.mask( combined_events.labels ...
  , @find, 'choice' ...
  , @findnone, 'errors' ...
);

look_around = 1;

cond_I = findall( combined_events.labels, 'outcomes', mask );

p_kept = [];
n_kept = [];
kept_labs = fcat();

for i = 1:numel(cond_I)
  [day_labs, day_I, day_C] = keepeach( combined_events.labels', 'days', cond_I{i} );  
  
  for j = 1:numel(day_I)
    spike_day_ind = find( combined_spikes.labels, day_C(:, j) );
    unit_I = findall( combined_spikes.labels, 'unit_number', spike_day_ind );
    
    assert( ~isempty(unit_I) );
    
    [matching_events, sorted_event_I] = sort( combined_events.data(day_I{j}, 4) );
    
    for k = 1:numel(unit_I)
      spike_ts = combined_spikes.data{unit_I{k}};
      nearest_event = bfw.find_nearest( matching_events, spike_ts );
      offsets = abs( matching_events(nearest_event)' - spike_ts );
      
      keep_spikes = offsets <= look_around;
      
      p_kept = [ p_kept; pnz(keep_spikes) ];
      n_kept = [ n_kept; nnz(keep_spikes) ];
    end
    
    append1( kept_labs, combined_events.labels, day_I{j}, numel(unit_I) );
  end
end


