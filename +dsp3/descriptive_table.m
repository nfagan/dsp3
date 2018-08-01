function [tbl, tvals, labels, I] = descriptive_table( data, labels, spec, funcs, varargin )

%   DESCRIPTIVE_TABLE -- Create a table of descriptive statistics.
%
%     T = descriptive_table( data, labels, cats ) creates a table `T` whose
%     columns are selected descriptive statistics of `data`, and whose rows
%     are label combinations (groups) drawn from `cats` categories of 
%     `labels`. `labels` is an fcat object with the same number of rows as
%     `data`; `cats` is a cell array of strings or char.
%     
%     For each group, the number of rows (N), mean, median, and std 
%     deviation of `data` associated with that group is calculated.
%
%     T = descriptive_table( ..., funcs ) uses `funcs` to generate columns
%     of `T`. `funcs` is a cell array of function_handle, or a scalar
%     function_handle. Specify `funcs` as the empty array ([]) to use the 
%     default functions as above.
%
%     T = descriptve_table( ..., mask ) applies the uint64 index vector
%     `mask` to `labels`, such that rows are only drawn from the `mask`
%     subset of total rows of `data`.
%
%     [..., vals] = descriptive_table(...) also returns the contents of the
%     table as a matrix.
%
%     [..., labs] = descriptive_table(...) also returns an fcat object
%     `labs` that contains one row for each group drawn from `cats`.
%
%     [..., I] = descriptive_table(...) also returns a cell array of uint64
%     indices `I` giving the rows of `data` associated with each group in
%     `labs`.
%
%     See also fcat.table, fcat/keepeach, fcat, dsp3.descriptive_funcs
%
%     IN:
%       - `data` (/T/)
%       - `labels` (fcat)
%       - `spec` (cell array of strings, char)
%       - `funcs` (function_handle, cell array of function_handle)
%       - `mask` (uint64) |OPTIONAL|
%     OUT:
%       - `tbl` (table)
%       - `tval` (cell array of T)
%       - `labels` (fcat)
%       - `I` (cell array of uint64)

assert_ispair( data, labels );
assert_hascat( labels, spec );

if ( nargin < 4 || isempty(funcs) )
  funcs = get_default_funcs();
else
  funcs = reqcell( funcs );
end

assert( numel(funcs) > 0, 'Specify at least one function.' );

[~, desc] = dsp3.make_new_cat( labels, 'descriptives' );
[labels, I] = dsp3.keepeach_or_one( labels, spec, varargin{:} );

vals = cell( size(funcs) );
names = cellfun( @(x) cleanfunc(func2str(x)), funcs, 'un', 0 );

for i = 1:numel(funcs)
  vals{i} = rowop( data, I, funcs{i} );
end

addcat( labels, desc );
[t, rc] = tabular( labels, dsp3.nonun_or_all(labels, spec), desc );

repset( rc{2}, desc, names );

tvals = cellfun( @(x) cellrefs(x, t), vals, 'un', 0 );
tvals = horzcat( tvals{:} );

tbl = sortrows( fcat.table(tvals, rc{:}), 'RowNames' );

end

function funcs = get_default_funcs()
  funcs = { ...
      @rows ...
    , @(x) mean(x, 1) ...
    , @(x) median(x, 1) ...
    , @(x) std(x, [], 1) ...
  };
end

function name = cleanfunc(name)
try
  name = prune_dots( prune_parens(name) );
catch err
  warning( err.message );
end
end

function name = prune_parens(name)

first_lparens = min( strfind(name, ')') );

if ( isempty(first_lparens) ), return; end

first_rparens = strfind( name, '(' );
first_rparens(first_rparens < first_lparens) = [];

if ( isempty(first_rparens) ), return; end

name = name(first_lparens+1:first_rparens-1);

end

function a = prune_dots(name)

ind = max( strfind(name, '.') );
if ( isempty(ind) || ind == numel(name) ), a = name; return; end
a = name(ind+1:end);

end