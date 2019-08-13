function results = save_aligned_lfp(output_subdir, varargin)

defaults = dsp3.make.defaults.aligned_lfp();

params = dsp3.parsestruct( defaults, varargin );
conf = params.config;

params.event_name = validatestring( params.event_name, {'fixOn', 'cueOn', 'targOn', 'targAcq', 'rwdOn'} );

if ( isempty(params.consolidated_data) )
  consolidated_data = dsp3.get_consolidated_data( conf );
else
  consolidated_data = params.consolidated_data;
end

runner = shared_utils.pipeline.LoopedMakeRunner();
dsp3.make.configure.aligned_lfp( runner, params );
runner.get_filename_func = @(varargin) strrep(varargin{1}, '.pl2', '.mat');
runner.output_directory = ...
  fullfile( char(dsp3.get_intermediate_dir('aligned_lfp', conf)), output_subdir );

results = runner.run( @dsp3.make.aligned_lfp, consolidated_data, params );

end