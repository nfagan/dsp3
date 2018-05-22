function [all_binned, all_bins] = add_trial_bin(cont, bin_size, step_size, start_over_at, increment_for)

import shared_utils.assertions.*;

assert__isa( cont, 'Container' );
assert__isa( bin_size, 'double' );
assert__isa( step_size, 'double' );
assert__is_cellstr_or_char( start_over_at );
assert__is_cellstr_or_char( increment_for );

[I, C] = cont.get_indices( start_over_at );

all_binned = Container();
all_bins = [];

for i = 1:numel(I)
  subset = cont(I{i});
  
  start_from = 1;
  
  increment_inds = subset.get_indices( increment_for );
  
  for j = 1:numel(increment_inds)
    [binned, bin_ns] = dsp2.process.format.add_trial_bin( subset(increment_inds{j}), bin_size, start_from, step_size );
    
    if ( isempty(binned) ), continue; end
    
    bins = binned( 'trial_bin' );
    bins_ = zeros( size(bins) );
    
    for h = 1:numel(bins)
      bins_(h) = str2double(bins{h}(numel('trial_bin__')+1:end)); 
    end
    
    start_from = max( bins_ ) + 1;
    
    all_binned = all_binned.append( binned );
    all_bins = [all_bins(:); bin_ns(:)];
  end
end

end