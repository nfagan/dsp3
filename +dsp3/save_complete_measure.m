function save_complete_measure(varargin)

defaults = dsp3.get_common_make_defaults();
defaults.meas_type = 'coherence';

params = dsp3.parsestruct( defaults, varargin );

meas_type = params.meas_type;

base_input_p = dsp2.io.get_path( 'measures', meas_type, 'complete' );
base_output_p = dsp3.get_intermediate_dir( meas_type );

io = dsp2.io.get_dsp_h5();

epochs = io.get_component_group_names( base_input_p );

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
    
    if ( strcmp(meas_type, 'coherence') )
      meas = dsp2.process.format.fix_channels( meas );
      meas = dsp2.process.format.only_pairs( meas );
    end
    
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