function [model_orders, order_labels] = estimate_model_order(formatted, var_labs, max_model_order, regression_mode)

[order_labels, var_id_I] = keepeach( var_labs', 'var_id' );
model_orders = nan( size(var_id_I) );

parfor i = 1:numel(var_id_I)
  combined = vertcat( formatted{var_id_I{i}} );
  
  [~, ~, model_order, ~] = tsdata_to_infocrit( combined, max_model_order, regression_mode );
  model_orders(i) = model_order;
end

end