function [out, region, pre_post_all] = decompose_mda_filename( file )

import shared_utils.assertions.*;

regions = { 'acc', 'bla', 'ref' };

assert__isa( file, 'char' );

reg_inds = cellfun( @(x) strfind(file, x), regions, 'un', false );
ns = cellfun( @numel, reg_inds );

assert( sum(ns) == 1, ['More or fewer than 1' ...
  , ' region among "%s" was found in "%s"'], strjoin(regions, ', '), file );

ind = ns == 1;
mda_ind = strfind( file, '.mda' );

assert( ~isempty(mda_ind), 'Could not locate ".mda" in "%s"', file );

lo_file = lower( file );
pre_ind = strfind( lo_file, 'pre' );
post_ind = strfind( lo_file, 'post' );
post2_ind = strfind( lo_file, 'post2' );
post_2_ind = strfind( lo_file, 'post_2' );

pre_post_all = 'all';

if ( ~isempty(pre_ind) )
  assert( isempty(post_ind) && isempty(post2_ind) && isempty(post_2_ind) ...
    , 'Found pre, but also post or post2 in "%s"', file );
  pre_post_all = 'pre';
end

if ( ~isempty(post_ind) )
  assert( isempty(pre_ind), 'Found post, but also pre in "%s"', file );
  if ( ~isempty(post2_ind) )
    assert( isempty(post_2_ind), 'Found post2 but also post_2 in "%s"', file );
    pre_post_all = 'post2';
  elseif ( ~isempty(post_2_ind) )
    assert( isempty(post2_ind), 'Found post_2 but also post2 in "%s"', file );
    pre_post_all = 'post2';
  else
    pre_post_all = 'post';
  end
end

region = regions{ind};
search_reg = [ region, '_' ];
out = strrep( strrep(file, search_reg, ''), '.mda', '.pl2' );

end