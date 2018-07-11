function [usedat, labs, newcats] = get_gaze_counts( data, labs, datakey )

assert_rowsmatch( data, labs );

N = rows( labs );

look_periods = { 'late' };
looks_to = { '', 'Bottle' };
look_measures = { 'LookCount' };

inds = combvec( 1:numel(look_periods), 1:numel(looks_to), 1:numel(look_measures) );
n_inds = size( inds, 2 );

repmat( labs, n_inds );
rowi = 1:N;

usedat = rownan( n_inds * N );

newcats = { 'look_period', 'looks_to', 'look_measure' };

addcat( labs, newcats );

for i = 1:n_inds
  lookp = look_periods{ inds(1, i) };
  lookt = looks_to{ inds(2, i) };
  lookm = look_measures{ inds(3, i) };
  
  key = strjoin( {lookp, lookt, lookm}, '' );
  
  if ( isempty(lookt) )
    lookt = 'bottle';
  elseif ( strcmpi(lookt, 'bottle') )
    lookt = 'monkey';
  end
  
  col_ind = datakey( key );
  row_inds = rowi + (N * (i-1));
  
  usedat(row_inds) = data(:, col_ind);
  
  setcat( labs, 'look_period', lookp, row_inds );
  setcat( labs, 'looks_to', lookt, row_inds );
  setcat( labs, 'look_measure', lookm, row_inds );
end

prune( labs );

end