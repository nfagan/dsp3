function outs = corr(x, y, labels, each, varargin)

%   CORR -- Correlations for each subset.
%
%     outs = dsp3.corr( x, y, labels, each ); correlates matched subsets of
%     vectors `x` and `y`, for subsets identified by each unique 
%     combination of labels in `each` categories. `labels` is an fcat
%     object with the same number of rows as `x` and `y`, used to generate
%     the combinations.
%
%     `outs` is a struct with fields 'corr_tables', 'corr_labels', and
%     'params'. These are:
%
%       - 'corr_tables' (cell array of table) -- Mx1 cell array of tables
%         with variables 'rho' and 'p'.
%       - 'corr_labels' (fcat) -- MxN fcat object identifying each row of
%         'corr_tables'.
%       - 'params' (struct) -- Parameters used to generate the
%         correlations.
%
%     outs = ... corr( 'name', value ) specifies additional paired
%     inputs. Valid inputs are:
%
%       - 'mask' (double, uint64) -- Applies a mask to the data and labels
%         so that combinations are restricted to the rows identified by the
%         mask.
%       - 'corr_inputs' (cell) -- Cell array of inputs that will be passed
%         into the `corr` function. For example, 
%         dsp3.corr(..., 'corr_inputs', {'type', 'Spearman'}); will use a
%         Spearman correlation.
%
%     Specify `each` as an empty cell array ({}) to perform the analysis
%     once using the complete vectors `x` and `y`.
%
%     See also dsp3.ttest2, dsp3.anovan, dsp3.signrank1, dsp3.anova1

assert_ispair( x, labels );
assert_ispair( y, labels );
assert_hascat( labels, each );

defaults.mask = rowmask( labels );
defaults.corr_inputs = {};

params = dsp3.parsestruct( defaults, varargin );

data_classes = { 'double', 'single' };
data_attrs = { '2d', 'column' };

validateattributes( x, data_classes, data_attrs, mfilename, 'x' );
validateattributes( y, data_classes, data_attrs, mfilename, 'y' );

mask = params.mask;
corr_inputs = params.corr_inputs;

[corr_labels, I] = dsp3.keepeach_or_one( labels', each, mask );
corr_tables = cell( size(I) );

for i = 1:numel(I)
  x_subset = x(I{i});
  y_subset = y(I{i});
  
  [rho, p] = corr( x_subset, y_subset, corr_inputs{:} );
  corr_tables{i} = table( rho, p );
end

outs.corr_tables = corr_tables;
outs.corr_labels = corr_labels;
outs.params = params;

end