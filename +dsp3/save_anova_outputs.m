function save_anova_outputs(anova_outs, pathstr, filenames_are)

anova_table_p = fullfile( pathstr, 'anova_tables' );
comparison_p = fullfile( pathstr, 'comparisons' );
descriptives_p = fullfile( pathstr, 'descriptives' );

write_one( anova_outs.anova_tables, anova_outs.anova_labels', anova_table_p ...
  , filenames_are );
write_one( anova_outs.descriptive_tables, anova_outs.descriptive_labels' ...
  , descriptives_p, filenames_are );
write_one( anova_outs.comparison_tables, anova_outs.anova_labels' ...
  , comparison_p, filenames_are );

end

function write_one(tables, labels, pathstr, filenames_are)

if ( iscell(tables) )
  for i = 1:numel(tables)  
    dsp3.savetbl( tables{i}, pathstr, prune(labels(i)), filenames_are );
  end
else
  dsp3.savetbl( tables, pathstr, prune(labels), filenames_are );
end

end