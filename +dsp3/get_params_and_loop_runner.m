function [params, runner] = get_params_and_loop_runner(inputs, output, defaults, varargin)

import shared_utils.struct.field_or;

params = dsp3.parsestruct( defaults, varargin );

if ( ~isfield(params, 'config') )
  conf = dsp3.config.load();
else
  conf = params.config;
end

runner = shared_utils.pipeline.LoopedMakeRunner();
runner.files_aggregate_type = 'containers.Map';

runner.save = field_or( params, 'save', true );
runner.overwrite = field_or( params, 'overwrite', false );
runner.is_parallel = field_or( params, 'is_parallel', true );
runner.get_identifier_func = ...
  @(varargin) shared_utils.char.require_end(varargin{1}.src_filename, '.mat');
runner.get_filename_func = ...
  @(varargin) shared_utils.char.require_end(strrep(varargin{1}, '.pl2', '.mat'), '.mat');
runner.input_directories = dsp3.get_intermediate_dir( inputs, conf );
runner.output_directory = char( dsp3.get_intermediate_dir(output, conf) );
runner.filter_files_func = ...
  @(files) shared_utils.io.filter_files( files, params.files_containing, params.files_not_containing );

if ( isfield(params, 'skip_existing') && params.skip_existing )
  runner.set_skip_existing_files();
end

if ( isfield(params, 'configure_runner_func') )
  params.configure_runner_func( runner );
end

end