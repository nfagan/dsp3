function [chi2_info, chi2_labels] = chi2_gof(counts, labels, each, category, varargin)

defaults = struct();
defaults.mask = rowmask( labels );
params = dsp3.parsestruct( defaults, varargin );

assert_ispair( counts, labels );
validateattributes( counts, {'double'}, {'vector'}, mfilename, 'counts' );

[chi2_labels, chi_I] = keepeach_or_one( labels', each, params.mask );
ps = zeros( size(chi_I) );
chi2s = zeros( size(chi_I) );

for i = 1:numel(chi_I)
  chi_inds = findall( labels, category, chi_I{i} );
  ind_counts = cellfun( @numel, chi_inds );
  
  if ( ~all(ind_counts == 1) )
    error( 'Indices in the target category must match exactly one frequency value.' );
  end
  
  vs = counts(vertcat(chi_inds{:}));
  expected = repmat( mean(vs), size(vs) );
  [~, p, stats] = chi2gof( 0:(numel(vs)-1) ,'frequency', vs, 'expected', expected );
  
  ps(i) = p;
  chi2s(i) = stats.chi2stat;
end

chi2_info = arrayfun( @(p, chi2) struct('p', p, 'chi2', chi2), ps, chi2s );

end