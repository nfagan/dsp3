function [spike_ts, spike_labels, event_ts, event_labels, new_to_original] = linearize_sua(sua)

events = sua.all_event_time;
spikes = sua.all_spike_time;

assert( numel(events) == numel(spikes) );

spike_ts = {};
spike_labels = fcat();

event_ts = [];
event_labels = fcat();

unit_stp = 1;
new_to_original = [];

for i = 1:numel(events)
  evt_labels = fcat.from( events{i}.event.labels );
  
  unit_labels = one( evt_labels' );
  units = spikes{i}.data;
  
  addcat( unit_labels, {'region', 'channel', 'unit_uuid'} );
  
  for j = 1:numel(units)
    unit = units{j};
    
    setcat( unit_labels, {'region', 'channel'}, unit.name );
    setcat( unit_labels, 'unit_uuid', sprintf('unit_uuid__%d', unit_stp) );
    
    spike_ts{end+1, 1} = unit.data;
    append( spike_labels, unit_labels );
    
    new_to_original(end+1, :) = [i, j];
    
    unit_stp = unit_stp + 1;
  end
  
  append( event_labels, evt_labels );
  event_ts = [ event_ts; events{i}.event.data ];
end

end