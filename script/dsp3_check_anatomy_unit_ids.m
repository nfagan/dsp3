%%
xls_p = fullfile( dsp3.dataroot(), 'xls', 'KURO_HITCH_Sites Coordinates_with_unit_ids.xlsx' );
[~, ~, xls_raw] = xlsread( xls_p );

[anatomy, anatomy_labels] = dsp3_anatomy_xls_to_data_and_labels( xls_raw );

%%  clustering

unique_channel_indices = findall( anatomy_labels, {'channel', 'region', 'days'} ...
  , find(anatomy_labels, 'bla') );
unique_channel_indices = cellfun( @(x) x(1), unique_channel_indices );

to_cluster_anatomy = anatomy(unique_channel_indices, :);

eva = evalclusters( to_cluster_anatomy, 'kmeans', 'CalinskiHarabasz', 'KList', 1:15 );

n_clusters = eva.OptimalK;

[cluster_indices, cluster_centroids, cluster_distances] = ...
  kmeans( to_cluster_anatomy, n_clusters );

x_anat = to_cluster_anatomy(:, 1);
y_anat = to_cluster_anatomy(:, 2);
z_anat = to_cluster_anatomy(:, 3);

color_map = spring( n_clusters );

figure(1); clf();

for i = 1:n_clusters
  is_current_cluster = cluster_indices == i;
  curr_x = x_anat(is_current_cluster);
  curr_y = y_anat(is_current_cluster);
  curr_z = z_anat(is_current_cluster);
  
  scatter3( curr_x, curr_y, curr_z, [], color_map(i, :), 'filled' );
  
  hold on;
end

for i = 1:size(cluster_centroids, 1)
  xc = cluster_centroids(i, 1);
  yc = cluster_centroids(i, 2);
  zc = cluster_centroids(i, 3);
  
  scatter3( xc, yc, zc, 50, color_map(i, :), 'o' );
end

%%

unit_mats = shared_utils.io.findmat( dsp3.get_intermediate_dir('unit_conts') );

unit_data = [];
unit_labels = fcat();

for i = 1:numel(unit_mats)
  shared_utils.general.progress( i, numel(unit_mats) );
  
  unit_file = shared_utils.io.fload( unit_mats{i} );
  
  unit_data = [ unit_data; unit_file.units.data ];
  append( unit_labels, fcat.from(unit_file.units.labels) );
end

%%

only_units = rowmask( unit_labels );  % use all units

[unit_I, unit_file_uuids] = findall( unit_labels, 'unit_uuid', only_units );
[anat_I, anatomy_uuids] = findall( anatomy_labels, 'unit_uuid' );

for i = 1:numel(unit_I)
  anatomy_mask = find( anatomy_labels, unit_file_uuids{i} );
  
  if ( isempty(anatomy_mask) )
    continue;
  end
  
  unit_file_reg = combs( unit_labels, {'region', 'channel'}, unit_I{i} );
  anatomy_reg = combs( anatomy_labels, {'region', 'channel'}, anatomy_mask );
  
  % Ensure regions + channels are the same for each unit uuid
  assert( numel(unit_file_reg) == 2 && numel(anatomy_reg) == 2 );
  assert( all(strcmp(anatomy_reg, unit_file_reg)) );
end