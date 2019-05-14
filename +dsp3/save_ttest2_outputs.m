function save_ttest2_outputs(t_outs, pathstr, filenames_are)

if ( nargin < 3 && isfield(t_outs, 'descriptive_specificity') )
  filenames_are = t_outs.descriptive_specificity;
end

t_table_p = fullfile( pathstr, 't_tables' );
descriptives_p = fullfile( pathstr, 'descriptives' );

dsp3.write_stat_tables( t_outs.t_tables, t_outs.t_labels', t_table_p ...
  , filenames_are );
dsp3.write_stat_tables( t_outs.descriptive_tables, t_outs.descriptive_labels' ...
  , descriptives_p, filenames_are );

end