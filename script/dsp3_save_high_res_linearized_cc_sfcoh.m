function dsp3_save_high_res_linearized_cc_sfcoh()

src_p = '/Volumes/external/data/changlab/dsp3/analyses/sfc_data_5ms';
dest_p = '/Volumes/external/data/changlab/dsp3/analyses/linearized_sfcoh_data_5ms';

shared_utils.io.require_dir( dest_p );

src_mats = shared_utils.io.findmat( src_p );
% src_mats = shared_utils.io.filter_files( src_mats, 'acc_' );

ts = [ -300, 300 ];
fs = [ 0, 100 ];

max_per_bin = 50;

for i = 1:31
  shared_utils.general.progress( i, numel(src_mats) );
  sfcoh_part = load( src_mats{i} );
  
  filename = shared_utils.io.filenames( src_mats{i} );
  region = filename(1:3);
  
  outcomes = { 'self', 'both', 'other', 'none' };
  num_subset = unique( cellfun(@numel, sfcoh_part.coher_data) );
  assert( numel(num_subset) == 1 );
  
  binned_inds = shared_utils.vector.slidebin( 1:num_subset, max_per_bin, max_per_bin );
  
  combs = combvec( 1:numel(binned_inds), 1:numel(outcomes) );
  num_combs = size( combs, 2 );
  
  for j = 1:num_combs
    subset_ind = combs(1, j);
    outcome_ind = combs(2, j);
    
    subset_start = min( binned_inds{subset_ind} );
    num_subset = numel( binned_inds{subset_ind} );
    
    [data, labels, f, t] = dsp3_linearize_high_res_cc_sfcoh( sfcoh_part, filename, region, outcome_ind, 1, subset_start, num_subset );
    t_ind = t >= ts(1) & t <= ts(2);
    f_ind = f >= fs(1) & f <= fs(2);

    data = data(:, f_ind, t_ind);
    t = t(t_ind);
    f = f(f_ind);

    dest_filepath = fullfile( dest_p, sprintf('%s-%d-%s.mat', outcomes{outcome_ind}, subset_ind, filename) );
    save( dest_filepath, 'data', 'labels', 'f', 't', '-v7.3' );
  end
end