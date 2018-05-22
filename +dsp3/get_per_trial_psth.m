function out = get_per_trial_psth( units, events, bin_size, look_back, look_ahead )

import shared_utils.assertions.*;

assert__isa( units, 'Container' );
assert__isa( events, 'Container' );
assert__isa( bin_size, 'double' );
assert__isa( look_back, 'double' );
assert__isa( look_ahead, 'double' );
assert__isa( units.data, 'cell' );

assert( shape(events, 2) == 1, 'Data in events must be a column vector.' );

[I, C] = units.get_indices( {'session_ids'} );

psth_t = look_back:bin_size:look_ahead;
psth_t = psth_t(1:end-1);

cats_to_add = setdiff( events.categories(), units.categories() );

full_psth_cont = Container();
full_raster_cont = Container();
full_counts_cont = Container();

for i = 1:numel(I)
  subset_units = units(I{i});
  subset_events = events(C(i, :));
  
  assert( ~isempty(subset_events), 'No events matched "%s"', strjoin(C(i, :), ', ') );
  
  unit_data = subset_units.data;
  event_times = subset_events.data;

  c_full_psth = nan( numel(event_times) * numel(unit_data), numel(psth_t) );
  c_full_counts = nan( size(c_full_psth) );

  unit_labs = SparseLabels();
  repeated_event_labs = SparseLabels();

  stp = 1;
  raster_stp = 1;

  first_raster = true;

  for j = 1:numel(unit_data)
    c_spike_times = unit_data{j};

    for h = 1:numel(event_times)
      c_event_time = event_times(h);

      if ( c_event_time == 0 )
        stp = stp + 1;
        continue;
      end

      c_full_psth(stp, :) = looplessPSTH( c_spike_times, c_event_time, look_back, look_ahead, bin_size );
      c_full_counts(stp, :) = looplessPSTHCounts( c_spike_times, c_event_time, look_back, look_ahead, bin_size );

      stp = stp + 1;
    end

    [c_raster, raster_t] = dsp3.get_raster( c_spike_times, event_times, look_back, look_ahead, 1e3 );

    if ( first_raster )
      c_full_raster = false( numel(event_times) * numel(unit_data), numel(raster_t) );
      first_raster = false;
    end

    c_full_raster(raster_stp:raster_stp+numel(event_times)-1, :) = c_raster;
    raster_stp = raster_stp + numel(event_times);

    repeated_event_labs = append( repeated_event_labs, subset_events.labels );

    repeated_unit_labels = repeat( get_labels(subset_units(j)), numel(event_times) );
    unit_labs = append( unit_labs, repeated_unit_labels );
  end

  for j = 1:numel(cats_to_add)
    c_cat = cats_to_add{j};
    unit_labs = unit_labs.add_category( c_cat );
    cat_to_copy = repeated_event_labs.full_fields( c_cat );
    unit_labs = unit_labs.set_category( c_cat, cat_to_copy );
  end

  psth_cont = Container( c_full_psth, unit_labs );
  counts_cont = Container( c_full_counts, unit_labs );
  raster_cont = Container( c_full_raster, unit_labs );
  
  full_counts_cont = append( full_counts_cont, counts_cont );
  full_psth_cont = append( full_psth_cont, psth_cont );
  full_raster_cont = append( full_raster_cont, raster_cont );
end

out.counts = full_counts_cont;
out.psth = full_psth_cont;
out.psth_t = psth_t;
out.raster = full_raster_cont;
out.raster_t = raster_t;

end