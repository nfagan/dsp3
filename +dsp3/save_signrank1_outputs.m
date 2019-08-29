function save_signrank1_outputs(sr_outs, pathstr, filenames_are, varargin)

if ( nargin < 3 || (iscell(filenames_are) && isempty(filenames_are)) )
  if ( isfield(sr_outs, 'descriptive_specificity') )
    filenames_are = sr_outs.descriptive_specificity;
  else
    filenames_are = {};
  end
end

sr_table_p = fullfile( pathstr, 'signrank_tables' );
descriptives_p = fullfile( pathstr, 'descriptives' );

dsp3.write_stat_tables( sr_outs.sr_tables, sr_outs.sr_labels', sr_table_p ...
  , filenames_are, varargin{:} );
dsp3.write_stat_tables( sr_outs.descriptive_tables, sr_outs.descriptive_labels' ...
  , descriptives_p, filenames_are, varargin{:} );


end