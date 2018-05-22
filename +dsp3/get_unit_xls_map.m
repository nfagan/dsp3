function map = get_unit_xls_map(conf)

if ( nargin < 1 )
  conf = dsp3.config.load();
end

data_p = fullfile( conf.PATHS.data_root, 'mountain_sort' );

xls_fullfile = shared_utils.io.find( data_p, '.xlsx' );

assert( numel(xls_fullfile) == 1, 'Found %d xls files; expected 1.', numel(xls_fullfile) );

[~, ~, xls_raw] = xlsread( xls_fullfile{1} );

map = dsp3.process_unit_xls_map( xls_raw );

end