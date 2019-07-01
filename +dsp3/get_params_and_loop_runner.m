function [params, runner] = get_params_and_loop_runner(inputs, output, defaults, varargin)

import shared_utils.struct.field_or;

params = dsp3.parsestruct( defaults, varargin );

if ( ~isfield(params, 'config') )
  conf = dsp3.config.load();
else
  conf = params.config;
end

runner = shared_utils.pipeline.LoopedMakeRunner();

runner.save = field_or( params, 'save', true );
runner.overwrite = field_or( params, 'overwrite', false );
runner.is_parallel = field_or( params, 'is_parallel', true );
runner.get_identifier_func = @(varargin) varargin{1}.src_filename;
runner.get_filename_func = @(varargin) strrep(varargin{1}, '.pl2', '.mat');
runner.input_directories = dsp3.get_intermediate_dir( inputs, conf );
runner.output_directory = char( dsp3.get_intermediate_dir(output, conf) );

end