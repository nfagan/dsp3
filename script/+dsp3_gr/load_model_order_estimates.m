function model_orders = load_model_order_estimates(subdir, conf)

if ( nargin < 2 )
  conf = dsp3.config.load();
end

filepath = fullfile( dsp3.dataroot(conf), 'analyses', 'granger', 'model_order_estimates', subdir ...
  , 'model_orders.mat' );

model_orders = shared_utils.io.fload( filepath );

end