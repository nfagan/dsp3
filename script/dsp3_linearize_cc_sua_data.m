function out = dsp3_linearize_cc_sua_data(sua_data)

events = sua_data.all_event_time;
spikes = sua_data.all_spike_time;

n_events = numel( events );

assert( n_events == numel(spikes), 'Number of spike and event arrays mismatch.' );

all_event_times = cell( 1, n_events );
all_event_labels = cell( 1, n_events );
all_spike_times = cell( 1, n_events );
all_spike_labels = cell( 1, n_events );

unit_id = 1;

for i = 1:n_events
  event_cont = events{i}.event;
  
  event_labels = fcat.from( event_cont.labels );
  
  all_event_times{i} = event_cont.data;
  all_event_labels{i} = event_labels;
  
  units = spikes{i}.data;
  mda_filename = char( spikes{i}.filename );
  
  spike_times = cell( numel(units), 1 );
  spike_labels = fcat();
  
  for j = 1:numel(units)
    spike_times{j} = units{j}.data;
    
    unit_info = units{j}.name;
    unit_labels = make_unit_labels( event_labels, unit_info, mda_filename, j, unit_id );
    append( spike_labels, unit_labels );
    
    unit_id = unit_id + 1;
  end
  
  all_spike_labels{i} = spike_labels;
  all_spike_times{i} = spike_times;
end

spike_times = vertcat( all_spike_times{:} );
spike_labels = vertcat( fcat, all_spike_labels{:} );

event_times = vertcat( all_event_times{:} );
event_labels = vertcat( fcat, all_event_labels{:} );

assert_ispair( spike_times, spike_labels );
assert_ispair( event_times, event_labels );

out = struct();
out.event_times = event_times;
out.event_labels = event_labels;
out.spike_times = spike_times;
out.spike_labels = spike_labels;

end

function f = make_unit_labels(event_labels, name, mda_filename, index, id)

reg = name{1};
chan = name{2};

f = append1( fcat(), event_labels );

additional_categories = { 'regions', 'channels', 'mda_filenames', 'unit_index', 'unit_id' };
unit_index = sprintf( 'unit_index__%d', index );
unit_id = sprintf( 'unit_id__%d', id );

addcat( f, additional_categories );
setcat( f, additional_categories, {reg, chan, mda_filename, unit_index, unit_id} );

end