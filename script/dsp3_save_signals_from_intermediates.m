function results = dsp3_save_signals_from_intermediates(output_p, varargin)

defaults = dsp3.get_common_make_defaults();
defaults.config = dsp3.config.load();
defaults.epochs = '';
defaults.is_reference_subtracted = false;
defaults.is_parallel = false;

params = dsp3.parsestruct( defaults, varargin );

conf = params.config;
epochs = cellstr( params.epochs );

results = [];

for i = 1:numel(epochs)
  input_id = sprintf( 'signals/none/%s', epochs{i} );
  
  runner = shared_utils.pipeline.LoopedMakeRunner;
  runner.is_parallel = params.is_parallel;

  runner.output_directory = output_p;
  runner.get_identifier_func = @get_identifier;
  runner.input_directories = dsp3.get_intermediate_dir( input_id, conf );
  
  result = runner.run( @get_measure, params, epochs{i} );
  
  results = [ results; result(:) ];
end

end

function id = get_identifier(loaded, filename)

epoch = lower( char(loaded.measure('epochs')) );
id = sprintf( 'lfp_%s_%s.mat', loaded.unified_filename, epoch );

end

function meas = get_measure(files, params, epoch)

meas_file = shared_utils.general.get( files, epoch );
meas = meas_file.measure;

if ( params.is_reference_subtracted )
  data = meas.data;
  labels = fcat.from( meas.labels );
  
  [data, labels] = dsp3.ref_subtract( data, labels );
  
  meas = Container( data, SparseLabels.from_fcat(labels) );
end

end