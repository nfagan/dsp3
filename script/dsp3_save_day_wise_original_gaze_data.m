function dsp3_save_day_wise_original_gaze_data(varargin)

defaults = dsp3.get_common_make_defaults();
params = dsp3.parsestruct( defaults, varargin );

gaze_p = fullfile( dsp3.dataroot(params.config), 'data', 'gaze' );
save_p = char( dsp3.get_intermediate_dir('gaze', params.config) );

labels = shared_utils.io.fload( fullfile(gaze_p, 'labels.mat') );
non_matched_labels = shared_utils.io.fload( fullfile(gaze_p, 'non_matched_labels.mat') );

data_types = { 't', 'x', 'y' };

[day_I, day_C] = findall( labels, 'days' );

for i = 1:numel(data_types)
  shared_utils.general.progress( i, numel(data_types) );
  
  data_filename = sprintf( '%s.mat', data_types{i} );
  data = shared_utils.io.fload( fullfile(gaze_p, data_filename) );
  
  full_save_p = fullfile( save_p, data_types{i} );
  shared_utils.io.require_dir( full_save_p );
  
  for j = 1:numel(day_I)
    save_filename = sprintf( '%s.mat', day_C{j} );
    
    day_ind = day_I{j};
    label_subset = prune( labels(day_ind) );
    non_matched_label_subset = prune( non_matched_labels(day_ind) );
    data_subset = data(day_ind, :);
    
    pair = struct();
    pair.data = data_subset;
    pair.labels = label_subset;
    pair.non_matched_labels = non_matched_label_subset;
    pair.data_type = data_types{i};
    pair.src_filename = day_C{j};
    
    save( fullfile(full_save_p, save_filename), 'pair' );
  end
end

end