function results = save_lfp_aligned_to_look_events(varargin)

defaults = dsp3.make.defaults.aligned_lfp();
defaults.first_look_outputs = [];

params = dsp3.parsestruct( defaults, varargin );
conf = params.config;
event_name = params.event_name;

assert( ~isempty(event_name), 'Specify an "event_name".' );

if ( isempty(params.first_look_outputs) )
  first_look_outputs = get_look_outputs( params.config );
else
  first_look_outputs = params.first_look_outputs;
end

if ( isempty(params.consolidated_data) )
  consolidated_data = dsp3.get_consolidated_data( conf );
else
  consolidated_data = params.consolidated_data;
end

runner = shared_utils.pipeline.LoopedMakeRunner();
dsp3.make.configure.aligned_lfp( runner, params );
runner.get_filename_func = @(varargin) strrep(varargin{1}, '.pl2', '.mat');
runner.output_directory = ...
  fullfile( char(dsp3.get_intermediate_dir('aligned_lfp', conf)), event_name );

results = runner.run( @main, first_look_outputs, consolidated_data, params );

end

function look_outs = get_look_outputs(params)

look_outs = dsp3_find_iti_looks( ...
    'config', params.config ...
  , 'require_fixation', false ...
  , 'look_back', -3.3 ...
  , 'is_parallel', params.is_parallel ...
);

end

function events = get_event_times(look_outs, subset_ind)

min_func = @(x) ternary( isempty(x), nan, min(x) );

first_monk = cellfun( min_func, look_outs.monkey_starts(subset_ind) );
first_bottle = cellfun( min_func, look_outs.bottle_starts(subset_ind) );
events = min( first_monk, first_bottle );

end

function out = main(files, look_outs, consolidated_data, params)

align_params = shared_utils.struct.intersect( params, dsp3.make.defaults.aligned_lfp() );

lfp_file = shared_utils.general.get( files, 'lfp' );
lfp_event_ind = lfp_file.event_ind;
look_event_ind = look_outs.event_ind;

match_ind = arrayfun( @(x) find(look_event_ind == x), lfp_event_ind );
assert( numel(match_ind) == numel(lfp_event_ind), 'Some events did not match.' );

picto_event_times = get_event_times( look_outs, match_ind );
picto_event_labels = prune( look_outs.labels(match_ind) );

out = dsp3.make.aligned_lfp_custom_events( files ...
  , picto_event_times, picto_event_labels, consolidated_data, align_params );

out.params.look_event_ind = look_event_ind(match_ind(out.event_ind));

end