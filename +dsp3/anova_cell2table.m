function tbl = anova_cell2table(t)

header = matlab.lang.makeValidName( t(1, :) );
rest = t(2:end, :);
tbl = cell2table( rest, 'VariableNames', header );

end