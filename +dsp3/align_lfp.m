function aligned = align_lfp(varargin)

defaults = dsp3.make.defaults.aligned_lfp();

params = dsp3.parsestruct( defaults, varargin );
conf = params.config;

if ( isempty(params.consolidated_data) )
  consolidated_data = dsp3.get_consolidated_data( conf );
else
  consolidated_data = params.consolidated_data;
end

runner = shared_utils.pipeline.LoopedMakeRunner();
dsp3.make.configure.aligned_lfp( runner, params );
runner.convert_to_non_saving_with_output();

results = runner.run( @dsp3.make.aligned_lfp, consolidated_data, params );
outputs = [ results([results.success]).output ];

aligned = struct();

if ( isempty(outputs) )
  aligned.params = params;
  aligned.data = [];
  aligned.t = [];
  aligned.labels = fcat();
  aligned.has_partial_data = logical( [] );
  aligned.sample_rate = [];
else
  aligned.params = outputs(1).params;
  aligned.data = vertcat( outputs.data );
  aligned.t = outputs(1).t;
  aligned.labels = vertcat( fcat, outputs.labels );
  aligned.has_partial_data = vertcat( outputs.has_partial_data );
  aligned.sample_rate = outputs(1).sample_rate;
end

end