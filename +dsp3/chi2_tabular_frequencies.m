function [chi2_info, chi2_labels] = chi2_tabular_frequencies(counts, labels, each, rows, cols, varargin)

defaults = struct();
defaults.mask = rowmask( labels );
params = dsp3.parsestruct( defaults, varargin );

assert_ispair( counts, labels );
validateattributes( counts, {'double'}, {'vector'}, mfilename, 'counts' );

[chi2_labels, chi_I] = keepeach_or_one( labels', each, params.mask );
ps = zeros( size(chi_I) );
chi2s = zeros( size(chi_I) );

for i = 1:numel(chi_I)
  t = tabular( labels, rows, cols, chi_I{i} );
  t = cellfun( @(x) counts(x), t );
  sr = sum( t, 1 );
  sc = sum( t, 2 );
  expect = sr .* (sc ./ sum(sc));
  chi2 = t - expect;
  chi2 = (chi2 .* chi2) ./ expect;
  chi2 = sum( sum(chi2) );
  df = (size(t, 1) - 1) * (size(t, 2) - 1);
  ps(i) = gammainc( chi2/2, df/2, 'upper' );
  chi2s(i) = chi2;
end

chi2_info = arrayfun( @(p, chi2) struct('p', p, 'chi2', chi2), ps, chi2s );

end