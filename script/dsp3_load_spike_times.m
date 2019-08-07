function outs = dsp3_load_spike_times(varargin)

defaults = dsp3.get_common_make_defaults();
defaults.configure_runner_func = @default_configure_runner;

inputs = 'units';

[params, runner] = dsp3.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @main );
outputs = shared_utils.pipeline.extract_outputs_from_results( results );

if ( isempty(outputs) )
  outs = struct();
  outs.spikes = [];
  outs.labels = fcat();
else
  outs = shared_utils.struct.soa( outputs );
end

end

function outs = main(files)

units_file = shared_utils.general.get( files, 'units' );
units = units_file.units;

spikes = {};
labels = fcat();

for i = 1:numel(units)
  unit = units(i);
  
  spikes(end+1, 1) = unit.times;
  append( labels, make_unit_labels(unit, i) );
end

outs.spikes = spikes;
outs.labels = labels;

end

function default_configure_runner(runner)

runner.get_identifier_func = @(varargin) varargin{1}.file;

end

function labs = make_unit_labels(unit, ind)

labs = fcat.create( ...
    'channel', unit.channel_str ...
  , 'region', unit.region ...
  , 'unit_rating', sprintf('unit_rating__%d', unit.rating) ...
  , 'pl2', unit.pl2_file ...
  , 'mda', unit.mda_file ...
  , 'day', unit.day ...
  , 'session_id', unit.session ...
  , 'unit_uuid', sprintf('unit_uuid__%d', unit.unit_uuid) ...
  , 'unit_index', sprintf('unit_index__%d', ind) ...
);

end
