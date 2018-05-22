function converted_units = make_units_to_picto_time( unit_info, align_cont, align_key )

import shared_utils.assertions.*;

assert__isa( unit_info, 'Container' );
assert__isa( align_cont, 'Container' );
assert__isa( align_key, 'containers.Map' );

converted_units = unit_info;

[I, C] = converted_units.get_indices( {'session_ids'} );

for i = 1:numel(I)
  subset_align = align_cont(C(i, :));
  assert( ~isempty(subset_align), 'No align data matched "%s".', strjoin(C(i, :), ', ') );
  subset_units = converted_units(I{i});
  
  picto_t = subset_align.data(:, align_key('picto'));
  plex_t = subset_align.data(:, align_key('plex'));
  
  unit_data = subset_units.data;
  
  func = @(x) shared_utils.sync.clock_a_to_b( x, plex_t, picto_t );
  
  converted_units.data(I{i}) = cellfun( func, unit_data, 'un', false );
end

end