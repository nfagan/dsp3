function save_anova_outputs(anova_outs, pathstr, filenames_are, varargin)

anova_table_p = fullfile( pathstr, 'anova_tables' );
comparison_p = fullfile( pathstr, 'comparisons' );
descriptives_p = fullfile( pathstr, 'descriptives' );

dsp3.write_stat_tables( anova_outs.anova_tables, anova_outs.anova_labels', anova_table_p ...
  , filenames_are, varargin{:} );
dsp3.write_stat_tables( anova_outs.descriptive_tables, anova_outs.descriptive_labels' ...
  , descriptives_p, filenames_are, varargin{:} );
dsp3.write_stat_tables( anova_outs.comparison_tables, anova_outs.anova_labels' ...
  , comparison_p, filenames_are, varargin{:} );

end