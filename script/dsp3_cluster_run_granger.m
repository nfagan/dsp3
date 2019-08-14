repadd( 'mvgc_v1.0' );
mvgc_startup;

if ( isempty(gcp('nocreate')) )
  parpool( feature('NumCores') );
end

min_slice = 42;
max_slice = 42;

conf = dsp3.config.load();
save_p = fullfile( dsp3.dataroot(conf), 'analyses', 'granger', dsp3.datedir() );
shared_utils.io.require_dir( save_p );

event_name = 'targAcq-150-cc';

source_p = dsp3.get_intermediate_dir( fullfile('original_aligned_lfp', event_name), conf );
use_files = shared_utils.io.filenames( shared_utils.io.findmat(source_p) );

if ( isempty(max_slice) ), max_slice = numel( use_files ); end
if ( isempty(min_slice) ), min_slice = 1; end

if ( ~isempty(use_files) )
  max_slice = min( numel(use_files), max_slice );
  use_files = use_files(min_slice:max_slice);
end

% model_order_file = dsp3_gr.load_model_order_estimates( '080719' );
model_order_file = dsp3_gr.load_model_order_estimates( '081219' );
med_model_order = median( model_order_file.model_orders );

granger_outs = dsp3_gr.run_granger( event_name, med_model_order ...
  , 'is_parallel', false ...
  , 'files_containing', use_files ...
  , 'verbose', true ...
);

granger_filename = sprintf( 'granger-%d-%d.mat', min_slice, max_slice );

save( fullfile(save_p, granger_filename), 'granger_outs', '-v7.3' );
