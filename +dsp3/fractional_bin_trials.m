function labs = fractional_bin_trials(labs, frac, mask)

if ( nargin < 3 ), mask = rowmask( labs ); end

tcat = 'trials';
bincat = 'trial_bin';
binpattern = 'trial_bin__%d';

assert_hascat( labs, tcat );
trials = categorical( labs, tcat, mask );

ns = fcat.parse( cellstr(trials), 'trial__' );

assert( ~any(isnan(ns)), 'Failed to parse trial format.' );
assert( issorted(sort(ns), 'strictascend'), 'Trials cannot contain duplicates. ');

P = prctile( ns, (0:frac:1)*100 );

assert( max(P) >= max(ns) && min(P) == 1 );

addcat( labs, bincat );

for i = 1:numel(P)-1
  if ( i == 1 )
    ind = ns >= P(i) & ns <= P(i+1);
  else
    ind = ns > P(i) & ns <= P(i+1);
  end
  
  setcat( labs, bincat, sprintf(binpattern, i), mask(ind) );
end

end