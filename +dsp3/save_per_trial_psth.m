function save_per_trial_psth(varargin)

defaults = dsp3.get_common_make_defaults();
defaults.epochs = 'all';
defaults.look_back = -0.5;
defaults.look_ahead = 0.5;
defaults.bin_size = 0.01;

params = dsp3.parsestruct( defaults, varargin );

bin_size = params.bin_size;
look_back = params.look_back;
look_ahead = params.look_ahead;

consolidated = dsp3.get_consolidated_data();

epochs = params.epochs;
event_key = consolidated.event_key;
evt_keys = event_key.keys();

if ( strcmp(epochs, 'all') )
  epochs = evt_keys;
else
  epochs = shared_utils.cell.ensure_cell( params.epochs );
  for i = 1:numel(epochs)
    assert( event_key.isKey(epochs{i}), 'The epoch "%s" does not exist.', epochs{i} );
  end
end

events = consolidated.events;

unit_p = dsp3.get_intermediate_dir( 'unit_conts' );
output_p = dsp3.get_intermediate_dir( 'per_trial_psth' );

unit_mats = dsp3.require_intermediate_mats( params.files, unit_p, params.files_containing );

parfor i = 1:numel(unit_mats)
  fprintf( '\n %d of %d', i, numel(unit_mats) );

  unit_file = shared_utils.io.fload( unit_mats{i} );

  output_file = fullfile( output_p, unit_file.file );

  if ( dsp3.conditional_skip_file(output_file, params.overwrite) )
    continue;
  end

  if ( shared_utils.io.fexists(output_file) && params.append )
    fprintf( '\n Loading "%s"', unit_file.file );
    per_trial_psth = shared_utils.io.fload( output_file );
  else
    per_trial_psth = struct();
    per_trial_psth.psths = containers.Map();
    per_trial_psth.file = unit_file.file;
    per_trial_psth.params_per_epoch = containers.Map();
  end

  units = unit_file.units_to_picto_time;

  for j = 1:numel(epochs)
    epoch_col = event_key( epochs{j} );

    c_events = set_data( events, events.data(:, epoch_col) );
    c_events = c_events.require_fields( 'epochs' );
    c_events('epochs') = epochs{j};

    out_psth = dsp3.get_per_trial_psth( units, c_events, bin_size, look_back, look_ahead );
    out_psth.raster.labels = out_psth.psth.labels;

    per_trial_psth.psths(epochs{j}) = out_psth;
    per_trial_psth.params_per_epoch(epochs{j}) = params;
  end

  shared_utils.io.require_dir( output_p );

  do_save( output_file, per_trial_psth );
end

end

function do_save( filename, psth )
save( filename, 'psth' );
end