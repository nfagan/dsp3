function all_keep = find_first_trials(labs, first_n, mask)

if ( nargin < 3 ), mask = 1:length(labs); end

non_errs = setdiff( mask, find(labs, 'errors') );

poss_cats = { 'days', 'channels', 'regions', 'sites' };
poss_cats = poss_cats( hascat(labs, poss_cats) );

I = findall( labs, poss_cats, non_errs );

all_keep = trueat( labs, [] );

for i = 1:numel(I)
  ci = I{i};
  
  block_ind = findor( labs, {'block__1', 'block__2'}, ci );
  
  trials = partcat( labs, 'trials', block_ind );
  trial_ns = cellfun( @(x) str2double(x(numel('trial__')+1:end)), trials );
  
  assert( ~any(isnan(trial_ns)), 'Some trial labels were not formatted correctly.' );
  
  unqs = unique( diff(trial_ns) );
  n_unqs = numel( unqs );

  assert( n_unqs == 2 || n_unqs == 1, 'Too many blocks included.' );
  
  keep_of_blocks = 1:min(first_n-1, numel(trial_ns));
  to_keep = block_ind(keep_of_blocks);
  
  all_keep(to_keep) = true;
end

all_keep = find( all_keep );

end