xls_p = fullfile( dsp3.dataroot(), 'xls', 'KURO_HITCH_Sites Coordinates_with_unit_ids.xlsx' );
[~, ~, xls_raw] = xlsread( xls_p );

[anatomy, anatomy_labels] = dsp3_anatomy_xls_to_data_and_labels( xls_raw );

%%

dsp3.save_unit_anatomy( anatomy, anatomy_labels );