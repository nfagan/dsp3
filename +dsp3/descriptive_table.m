function [tbl, tvals, labels] = descriptive_table( data, labels, spec, funcs, varargin )

%   DESCRIPTIVE_TABLE -- Create a table of descriptive statistics.
%
%     T = descriptive_table( data, labels, spec, funcs )
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

assert_rowsmatch( data, labels );

if ( nargin < 4 || isempty(funcs) )
  funcs = get_default_funcs();
else
  funcs = reqcell( funcs );
end

assert( numel(funcs) > 0, 'Specify at least one function.' );

[~, desc] = dsp3.make_new_cat( labels, 'descriptives' );

[labels, I] = keepeach( labels, spec, varargin{:} );

vals = cell( size(funcs) );
names = cellfun( @(x) cleanfunc(func2str(x)), funcs, 'un', 0 );

for i = 1:numel(funcs)
  vals{i} = rowop( data, I, funcs{i} );
end

addcat( labels, desc );
[t, rc] = tabular( labels, dsp3.nonun_or_other(labels, spec), desc );

repset( rc{2}, desc, names );

tvals = cellfun( @(x) cellrefs(x, t), vals, 'un', 0 );
tvals = horzcat( tvals{:} );

tbl = fcat.table( tvals, rc{:} );

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