function save_self_vs_other_selective_labels(filename, cc_labels, conf)

if ( nargin < 3 || isempty(conf) )
  conf = dsp3.config.load();
else
  dsp3.util.assertions.assert__is_config( conf );
end

save_p = fullfile( dsp3.dataroot(conf), 'analyses', 'cell_type_self_vs_other' ...
  , dsp3.datedir );
shared_utils.io.require_dir( save_p );

save( fullfile(save_p, sprintf('cc_%s', filename)), 'cc_labels' );

end