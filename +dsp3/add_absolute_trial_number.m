function labs = add_absolute_trial_number(labs, varargin)

cats = { 'sessions', 'blocks', 'days' };
tcat = 'trials';

assert_hascat( labs, cshorzcat(cats, tcat) );

[I, C] = findall( labs, cats, varargin{:} );

sesh = fcat.parse( C(1, :), 'session__' );
blck = fcat.parse( C(2, :), 'block__' );
day = regexprep( C(3, :), 'day__', '' );
dnum = datenum( day, 'mmddyyyy' );

assert( ~any(isnan(sesh) | isnan(blck)), 'Failed to parse session or block format.' );

mat = [ dnum(:), sesh(:), blck(:) ];
[~, sort_ind] = sortrows( mat );

I = I(sort_ind);
C = C(:, sort_ind);

start = 1;
dups = false( size(I) );

for i = 1:numel(I)
  trials = categorical( labs, tcat, I{i} );
  ns = fcat.parse( cellstr(trials), 'trial__' );
  N = numel( ns );
  
  assert( ~any(isnan(ns)), 'Failed to parse trials.' );
  
  new_trials = arrayfun( @(x) sprintf('trial__%d', x), start:start+N-1, 'un', 0 );
  
  setcat( labs, tcat, new_trials, I{i} );
  
  dups(i) = ~issorted( ns );
  
  start = start + N;
end

end