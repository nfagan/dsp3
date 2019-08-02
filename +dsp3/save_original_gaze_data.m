function save_original_gaze_data(gaze_data, varargin)

defaults = dsp3.get_common_make_defaults();
defaults.data_type = 'x';

params = dsp3.parsestruct( defaults, varargin );
data_type = validatestring( params.data_type, {'x', 'y', 't'}, mfilename, 'data type' );
conf = params.config;

save_p = fullfile( dsp3.dataroot(conf), 'data', 'gaze' );
shared_utils.io.require_dir( save_p );

%%

use_data = only( gaze_data, data_type );

x_conts = use_data.data;

size_func = @(x) cat_expanded( 1, cellfun(@(x) size(x.data), x, 'un', 0) );

x_sizes = size_func( x_conts );
num_rows = sum( x_sizes(:, 1) );
num_cols = max( x_sizes(:, 2) );

xs = nan( num_rows, num_cols );
labels = fcat();

stp = 1;

for i = 1:numel(x_conts)
  shared_utils.general.progress( i, numel(x_conts) );
  
  curr_x_dat = x_conts{i}.data;
  
  new_num_rows = size( curr_x_dat, 1 );
  new_num_cols = size( curr_x_dat, 2 );
  
  xs(stp:stp+new_num_rows-1, 1:new_num_cols) = curr_x_dat;
  
  tmp_labs = fcat.from( x_conts{i}.labels );
  append( labels, tmp_labs );
  
  stp = stp + new_num_rows;
end

cats_to_validate = { 'days', 'drugs', 'magnitudes', 'trials', 'trialtypes', 'outcomes' };
orig_labels = fcat.from( dsp3_load_cc_targacq_labels(conf) );
labels = dsp3_match_cc_targacq_trial_labels_for_behavior( orig_labels, labels, cats_to_validate );

save( fullfile(save_p, sprintf('%s.mat', data_type)), 'xs', '-v7.3' );
save( fullfile(save_p, 'labels.mat'), 'labels' );

end