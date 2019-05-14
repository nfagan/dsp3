function [kept_spikes, kept_labs] = dsp3_bin_sta_spikes_by_condition(combined_events, combined_spikes, cond_I, look_around)

kept_spikes = {};
kept_labs = fcat();

for i = 1:numel(cond_I)
  [day_labs, day_I, day_C] = keepeach( combined_events.labels', {'days', 'session_ids'}, cond_I{i} );  
  
  for j = 1:numel(day_I)
    spike_day_ind = find( combined_spikes.labels, day_C(:, j) );
    unit_I = findall( combined_spikes.labels, 'unit_number', spike_day_ind );
    assert( ~isempty(unit_I) );
    
    one_event_labs = prune( day_labs(j) );
    
    matching_events = sort( combined_events.data(day_I{j}, 4) );
    
    for k = 1:numel(unit_I)
      spike_ts = combined_spikes.data{unit_I{k}};
      nearest_event = bfw.find_nearest( matching_events, spike_ts );
      offsets = abs( matching_events(nearest_event)' - spike_ts );
      
      keep_spikes = offsets <= look_around;
      
      if ( nnz(keep_spikes) == 0 )
        continue;
      end
      
      kept_spikes{end+1, 1} = spike_ts(keep_spikes);
      
      unit_labs = prune( one(combined_spikes.labels(unit_I{k})) );
      merge( unit_labs, one_event_labs );
      append( kept_labs, unit_labs );
    end
  end
end

prune( kept_labs );

assert_ispair( kept_spikes, kept_labs );

end