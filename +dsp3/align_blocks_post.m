function [labs, max_pre] = align_blocks_post(labs, mask)

if ( nargin < 2 )
  mask = rowmask( labs );
end

block_pref = 'block__';
blockcat = 'blocks';
admincat = 'administration';
daycat = 'days';
seshcat = 'sessions';

assert_hascat( labs, {blockcat, admincat, daycat, seshcat} );

pre_blocks = combs( labs, blockcat, find(labs, 'pre', mask) );
pre_blocks = fcat.parse( pre_blocks, block_pref );

max_pre = max( pre_blocks );
assert( min(pre_blocks) == 1 );

spec = daycat;

I = findall( labs, spec, mask );

for i = 1:numel(I)
  %   number of pre blocks for this combination of days, etc.
  n_pre_blocks = numel( findall(labs, blockcat, find(labs, 'pre', I{i})) );
  offset = max_pre - n_pre_blocks;
  
  %   2 block day
  if ( offset == 0 ), continue; end
  
  [block_I, block_C] = findall( labs, {seshcat, blockcat, daycat, admincat}, I{i} );
  
  block_ns = fcat.parse( block_C(2, :), block_pref );
  assert( ~any(isnan(block_ns)) );
  
  for j = 1:numel(block_I)
    block_str = sprintf( '%s%d', block_pref, block_ns(j)+offset );
    
    setcat( labs, blockcat, block_str, block_I{j} );    
  end
end

end