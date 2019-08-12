repadd( 'mvgc_v1.0' );
mvgc_startup;

if ( isempty(gcp('nocreate')) )
  parpool( feature('NumCores') );
end

conf = dsp3.config.load();
save_p = fullfile( dsp3.dataroot(conf), 'analyses', 'granger', 'model_order_estimates', dsp3.datedir() );
shared_utils.io.require_dir( save_p );

model_order_outs = dsp3_gr.estimate_model_orders( 'targAcq-150-cc' ...
  , 'config', conf ...
  , 'is_parallel', true ...
  , 'max_model_order', 50 ...
  , 'use_all_time', false ...
  , 'time_window', [0, 150] ...
);

save( fullfile(save_p, 'model_orders.mat'), 'model_order_outs' );