function [newdat, newlabs, kept_I] = bipoloar_derivation_reference(data, labels, mask)

assert_ispair( data, labels );

if ( nargin < 3 )
  mask = rowmask( labels );
end

reg_I = findall( labels, {'days', 'regions'}, mask );
kept_I = {};

newdat = {};
newlabs = fcat();

for i = 1:numel(reg_I)
  [chan_I, chan_C] = findall( labels, 'channels', reg_I{i} );
  
  if ( numel(chan_I) > 1 )
    try
      chan_nums = cellfun( @(x) str2double(x(3:end)), chan_C );
      [~, order] = sort( chan_nums );      
      chan_I = chan_I(order);
      
      for j = 1:numel(chan_I)-1
        ind_a = chan_I{j+1};
        ind_b = chan_I{j};
        
        referenced = rowref( data, ind_a ) - rowref( data, ind_b );
        
        append( newlabs, labels, chan_I{j+1} );
        newdat{end+1, 1} = referenced;
        kept_I{end+1, 1} = chan_I{j+1};
      end
      
    catch err
      warning( err.message );
    end
  end
end

newdat = vertcat( newdat{:} );
kept_I = vertcat( kept_I{:} );

assert_ispair( newdat, newlabs );

end