function save_unit_anatomy(anatomy, anatomy_labels, varargin)

defaults = dsp3.get_common_make_defaults();
defaults.config = dsp3.config.load();

params = dsp3.parsestruct( defaults, varargin );

conf = params.config;

assert_ispair( anatomy, anatomy_labels );

output_p = char( dsp3.get_intermediate_dir('unit_anatomy', conf) );
output_file = fullfile( output_p, 'unit_anatomy.mat' );

if ( shared_utils.io.fexists(output_file) && ~params.overwrite )
  fprintf( '\n Skipping "%s" because it already exists.', output_file );
  return
end

shared_utils.io.require_dir( output_p );

[labels, categories] = categorical( anatomy_labels );

anatomy_file = struct( 'anatomy', anatomy, 'labels', labels, 'categories', {categories} );

save( output_file, 'anatomy_file' );

end