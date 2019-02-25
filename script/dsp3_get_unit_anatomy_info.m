function [anatomy, anatomy_labels] = dsp3_get_unit_anatomy_info(conf)

if ( nargin < 1 || isempty(conf) )
  conf = dsp3.config.load();
end

xls_filename = 'KURO_HITCH_Sites Coordinates_with_unit_ids.xlsx';

xls_p = fullfile( dsp3.dataroot(conf), 'xls', xls_filename );
[~, ~, xls_raw] = xlsread( xls_p );

[anatomy, anatomy_labels] = dsp3_anatomy_xls_to_data_and_labels( xls_raw );

end