function tbl = multcompare_cell2table(c)

assert( iscell(c), 'multcompare output must be cell; was "%s".', class(c) );
assert( ismatrix(c) && size(c, 2) == 6, 'Invalid multcompare cell dimensionality.' );

header = { 'comparison', 'lb', 'estimate', 'ub', 'p_value' };

gnames = c(:, 1:2);

newc = cell( size(c, 1), size(c, 2)-1 );

for i = 1:size(gnames, 1)
  newc{i, 1} = strjoin( gnames(i, :), ' vs. ' );
  newc(i, 2:end) = c(i, 3:end);
end

tbl = cell2table( newc, 'VariableNames', header );

end