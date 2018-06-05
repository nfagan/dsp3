function save_complete_signals(varargin)

defaults = dsp3.get_common_make_defaults();
defaults.ref_type = 'none';
defaults.epochs = 'all';

params = dsp3.parsestruct( defaults, varargin );

ref_type = params.ref_type;

io = dsp2.io.get_dsp_h5();

base_input_p = io.fullfile( 'Signals', ref_type, 'complete' );
base_output_p = dsp3.get_intermediate_dir( fullfile('signals', ref_type) );

if ( strcmp(params.epochs, 'all') )
  epochs = io.get_component_group_names( base_input_p );
else
  epochs = shared_utils.cell.ensure_cell( params.epochs );
end

for i = 1:numel(epochs)
  fprintf( '\n %d of %d', i, numel(epochs) );
  
  epoch = epochs{i};
  
  output_p = fullfile( base_output_p, epoch );
  input_p = io.fullfile( base_input_p, epoch );
  
  days = io.get_days( input_p );
  
  for j = 1:numel(days)
    fprintf( '\n\t %d of %d', j, numel(days) );
    
    day = days{j};
    
    output_filename = fullfile( output_p, day );
    output_filename = sprintf( '%s.mat', output_filename );
    
    if ( dsp3.conditional_skip_file(output_filename, params.overwrite) )
      continue;
    end
    
    meas = io.read( input_p, 'only', day );
    
    meas = dsp2.process.format.fix_block_number( meas );
    meas = dsp2.process.format.fix_administration( meas );
    
    meas_file = struct();
    meas_file.measure = meas;
    meas_file.params = params;
    meas_file.unified_filename = day;
    
    shared_utils.io.require_dir( output_p );
    
    save( output_filename, 'meas_file' );
  end
end

end