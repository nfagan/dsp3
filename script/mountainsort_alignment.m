%%  convert spike times -> picto time

unit_info = dsp3.get_unit_container( units );

converted_units = unit_info;

[I, C] = converted_units.get_indices( {'session_ids'} );

for i = 1:numel(I)
  subset_align = align_cont(C(i, :));
  assert( ~isempty(subset_align) );
  subset_units = converted_units(I{i});
  
  picto_t = subset_align.data(:, align_key('picto'));
  plex_t = subset_align.data(:, align_key('plex'));
  
  unit_data = subset_units.data;
  
  func = @(x) shared_utils.sync.clock_a_to_b( x, plex_t, picto_t );
  
  converted_units.data(I{i}) = cellfun( func, unit_data, 'un', false );
end

%%

desired_epoch = 'rwdOn';
look_back = -0.5;
look_ahead = 0.5;

one_epoch_data = set_data( event_data_cont, event_data_cont.data(:, event_info_key(desired_epoch)) );

[I, C] = converted_units.get_indices( {'session_ids'} );

for i = 1:numel(I)
  subset_units = converted_units(I{i});
  subset_events = one_epoch_data(C(i, :));
  
  assert( ~isempty(subset_events) );
  
  unit_data = subset_units.data;
  
  for j = 1:numel(unit_data)
    c_times = unit_data{j};
    
  end
end


