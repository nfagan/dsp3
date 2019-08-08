repadd( 'mvgc_v1.0' );
mvgc_startup;

if ( isempty(gcp('nocreate')) )
  parpool( feature('NumCores') );
end

conf = dsp3.config.load();
save_p = fullfile( dsp3.dataroot(conf), 'analyses', 'granger', dsp3.datedir() );
shared_utils.io.require_dir( save_p );

model_order_file = dsp3_gr.load_model_order_estimates( '080719' );
med_model_order = median( model_order_file.model_orders );

granger_outs = dsp3_gr.run_granger( 'targAcq-150-cc', med_model_order ...
  , 'is_parallel', true ...
  , 'files_containing', 'lfp_day__01042017_targacq' ...
  , 'var_mask_inputs', {@find, 'var_id__1'} ...
  , 'trial_mask_inputs', {@find, 'selfs'} ...
);

save( fullfile(save_p, 'granger.mat'), 'granger_outs', '-v7.3' );