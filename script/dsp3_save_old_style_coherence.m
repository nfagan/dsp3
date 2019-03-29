function dsp3_save_old_style_coherence(varargin)

defaults = struct();
defaults.kinds = { 'nanmedian', 'nanmean', 'meaned' };
defaults.epochs = { 'targacq' };
defaults.config = dsp3.config.load();
defaults.dsp2_config = dsp2.config.load();

params = dsp3.parsestruct( defaults, varargin );

kinds = cellstr( params.kinds );
epochs = cellstr( params.epochs );
conf = params.config;
dsp2_conf = params.dsp2_config;

dsp3.util.assertions.assert__is_config( conf );

C = dsp3.numel_combvec( kinds, epochs );

base_p = char( dsp3.get_intermediate_dir('at_coherence', conf) );
io = dsp2.io.get_dsp_h5( 'config', dsp2_conf );

for i = 1:size(C, 2)
  shared_utils.general.progress( i, size(C, 2) );
  
  kind = kinds{C(1, i)};
  epoch = epochs{C(2, i)};
  
  try    
    pathstr = dsp2.io.get_path( 'measures', 'coherence', kind, epoch, 'config', dsp2_conf );
    
    measure = io.read( pathstr );
    
    %   fix labels, identify blocks to remove, etc., after loading in the
    %   raw data
    measure( 'epochs' ) = epoch;
    measure = dsp2.process.format.fix_block_number( measure );
    measure = dsp2.process.format.fix_administration( measure );
    measure = measure.rm( 'errors' );
    
    measure = measure.remove_nans_and_infs();
    measure = dsp2.process.format.rm_bad_days( measure );
    measure.labels = dsp2.process.format.fix_channels( measure.labels );
    measure = dsp2.process.format.only_pairs( measure );
    
    measure = dsp2.process.manipulations.non_drug_effect( measure );
    
  catch err
    warning( err.message );
    continue;
  end
  
  folder_id = sprintf( 'nondrug_%s', kind );
  subfolders = fullfile( folder_id, epoch );
  full_intermediate_p = fullfile( base_p, subfolders );
  shared_utils.io.require_dir( full_intermediate_p );
  
  [I, days] = get_indices( measure, 'days' );
  
  for j = 1:numel(I)
    fprintf( '\n   Saving ... %d of %d', j, numel(I) );
    
    to_save = struct();
    to_save.measure = measure(I{j});
    to_save.params = struct();
    to_save.unified_filename = days{j};
    
    filename = sprintf( '%s.mat', days{j} );
    
    shared_utils.io.psave( fullfile(full_intermediate_p, filename), to_save );
  end
end

end