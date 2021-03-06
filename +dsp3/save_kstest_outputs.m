function save_kstest_outputs(sr_outs, pathstr, filenames_are)

if ( nargin < 3 && isfield(sr_outs, 'descriptive_specificity') )
  filenames_are = sr_outs.descriptive_specificity;
end

sr_table_p = fullfile( pathstr, 'ks_tables' );
descriptives_p = fullfile( pathstr, 'descriptives' );

dsp3.write_stat_tables( sr_outs.sr_tables, sr_outs.sr_labels', sr_table_p ...
  , filenames_are );
dsp3.write_stat_tables( sr_outs.descriptive_tables, sr_outs.descriptive_labels' ...
  , descriptives_p, filenames_are );


end