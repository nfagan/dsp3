function [all_data, all_labels, freqs, t] = convert_cc_pdc(pdc)

freqs = 1:100;
t = -500:50:500;

% 35:43, 45, 47 for unipolar vs. bipolar

all_data = {};
all_labels = fcat();

% (1, 2, :) = bla -> acc
% (2, 1, :) = acc -> bla

condition_strs = { 'self', 'both', 'other', 'none' };
condition_nums = 1:4;
condition_map = containers.Map( condition_nums, condition_strs );

for i = 1:numel(pdc)
  shared_utils.general.progress( i, numel(pdc) );
  
  if ( isempty(pdc{i}) )
    continue;
  end
  
  num_conditions = numel( pdc{i} );
  day_label = sprintf( 'day-%d', i );
  
  for j = 1:num_conditions
    num_sites = numel( pdc{i}{j} );
    condition_label = condition_map(j);
    
    for k = 1:num_sites
      num_time_points = numel( pdc{i}{j}{k} );
      site_label = sprintf( 'site-%d', k );
      
      for h = 1:num_time_points
        a = pdc{i}{j}{k}{h};
        
        bla_acc = columnize( squeeze(a(1, 2, :)) )';
        acc_bla = columnize( squeeze(a(2, 1, :)) )';
        
        if ( h == 1 )
          tmp_dat = nan( 2, numel(bla_acc), numel(pdc{i}{j}{k}) );
        end
        
        tmp_dat(1, :, h) = bla_acc;
        tmp_dat(2, :, h) = acc_bla;
        
        if ( h == num_time_points )
          all_data{end+1, 1} = tmp_dat;
          
          tmp_labels = fcat.create( ...
            'days', day_label ...
            , 'outcomes', condition_label ...
            , 'sites', site_label ...
            , 'regions', {'bla_acc', 'acc_bla'} ...
          );
      
          append( all_labels, tmp_labels );
        end
      end
    end
  end
end

all_data = vertcat( all_data{:} );
assert_ispair( all_data, all_labels );

assert( size(all_data, 2) == numel(freqs), 'Freqs do not match.' );
assert( size(all_data, 3) == numel(t), 'Time doesn''t match.' );

end