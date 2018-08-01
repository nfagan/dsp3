function labs = n_bin_trials(labs, window, step, mask)

if ( nargin < 3 ), mask = rowmask( labs ); end

tcat = 'trials';
bincat = 'trial_bin';
binpattern = 'trial_bin__%d';

assert_hascat( labs, tcat );
trials = categorical( labs, tcat, mask );

ns = fcat.parse( cellstr(trials), 'trial__' );

assert( ~any(isnan(ns)), 'Failed to parse trial format.' );
assert( issorted(sort(ns), 'strictascend'), 'Trials cannot contain duplicates. ');

start = 1;
stp = 1;
stop = start + window - 1;

N = numel( ns );

addsetcat( labs, bincat, sprintf(binpattern, NaN), mask );

while ( start <= N && stop <= N )
  ind = ns >= start & ns <= stop;
  
  setcat( labs, bincat, sprintf(binpattern, stp), mask(ind) );
  
  start = start + step;
  stop = start + window - 1;
  stp = stp + 1;
end


end