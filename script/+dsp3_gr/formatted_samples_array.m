function [formatted, var_labs, trial_labs] = formatted_samples_array(data, labels, vars_are, mask)

if ( nargin < 4 )
  mask = rowmask( labels );
end

assert_ispair( data, labels );
validateattributes( data, {'double'}, {'2d'}, mfilename, 'data' );

[var_labs, var_I] = keepeach( labels', vars_are, mask );

if ( isempty(var_I) )
  num_trials = 0;
  trial_labs = prune( none(labels') );
else
  num_trials = unique( cellfun(@numel, var_I) );
  
  if ( numel(num_trials) ~= 1 )
    error( 'Each variable must have the same number of trials.' );
  end
  
  trial_labs = prune( labels(var_I{1}) );
  prune( collapsecat(trial_labs, vars_are) );
end

num_vars = numel( var_I );
num_obs = size( data, 2 );

formatted = zeros( num_vars, num_obs, num_trials );

for i = 1:num_vars
  formatted(i, :, :) = data(var_I{i}, :)';
end

end