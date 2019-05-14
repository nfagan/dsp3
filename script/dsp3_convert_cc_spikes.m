function [combined_spikes, combined_events] = dsp3_convert_cc_spikes(spikes, events)

assert( numel(spikes) == numel(events), 'Spikes & events must match.' );

all_spike_labels = fcat();
all_spikes = {};

all_event_labels = fcat();
all_event_times = [];

unit_stp = 1;

for i = 1:numel(spikes)
  day_spikes = spikes{i};
  day_events = events{i};
  
  event_labels = fcat.from( day_events.event.labels );
  spike_labels = prune( one(event_labels') );
  addcat( spike_labels, {'region', 'channel', 'unit_number'} );
  
  units = day_spikes.data;
  
  for j = 1:numel(units)
    all_spikes{end+1, 1} = units{j}.data;
    
    region = units{j}.name{1};
    channel = units{j}.name{2};
    unit_number_str = sprintf( 'unit_number_%d', unit_stp );
    
    setcat( spike_labels, 'region', region );
    setcat( spike_labels, 'channel', channel );
    setcat( spike_labels, 'unit_number', unit_number_str );
    
    append( all_spike_labels, spike_labels );
    
    unit_stp = unit_stp + 1;
  end
  
  append( all_event_labels, event_labels );
  all_event_times = [ all_event_times; day_events.event.data ];
end

assert_ispair( all_spikes, all_spike_labels );
assert_ispair( all_event_times, all_event_labels );

combined_spikes = struct();
combined_spikes.data = all_spikes;
combined_spikes.labels = all_spike_labels;

combined_events = struct();
combined_events.data = all_event_times;
combined_events.labels = all_event_labels;


end