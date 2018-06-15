function save_at_measure(varargin)

defaults = dsp3.get_common_make_defaults();
defaults.meas_type = '';
defaults.epoch = '';
defaults.mean_spec = dsp3.get_default_mean_spec();

params = dsp3.parsestruct( defaults, varargin );

meas_type = field_or_err( params, 'meas_type' );
epoch = field_or_err( params, 'epoch' );
mean_spec = params.mean_spec;

input_p = dsp3.get_intermediate_dir( fullfile(meas_type, epoch) );
output_p = dsp3.get_intermediate_dir( fullfile(sprintf('at_%s', meas_type), epoch) );

mats = dsp3.require_intermediate_mats( params.files, input_p, params.files_containing );

parfor i = 1:numel(mats)
  dsp3.progress( i, numel(mats) );
  
  meas_file = shared_utils.io.fload( mats{i} );
  un_filename = shared_utils.char.require_end( meas_file.unified_filename, '.mat' );
  
  output_filename = fullfile( output_p, un_filename );
  
  if ( dsp3.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  meas = meas_file.measure;
  
  data = meas.data;
  labs = fcat.from( meas.labels );
  
  [y, I] = keepeach( labs', mean_spec );
  
  meaned = rowop( data, I, @(x) nanmean(x, 1) );
  
  meaned_file = struct();
  meaned_file.measure = set_data_and_labels( meas, meaned, SparseLabels.from_fcat(y) );
  meaned_file.params = params;
  meaned_file.unified_filename = meas_file.unified_filename;
  
  shared_utils.io.require_dir( output_p );
  shared_utils.io.psave( output_filename, meaned_file );
end

end

function val = field_or_err(s, name)
val = dsp3.field_or_default( s, name, '' );
if ( isempty(val) ), error( 'Specify a "%s".', name ); end
end