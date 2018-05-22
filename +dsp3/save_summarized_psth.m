function save_summarized_psth(varargin)

defaults = dsp3.get_common_make_defaults();
defaults.summary_func = @nanmean;
defaults.alias = 'standard';
defaults.within = { 'unit_uuid', 'outcomes', 'trialtypes', 'days' };
defaults.allow_new_alias = false;

params = dsp3.parsestruct( defaults, varargin );

alias = params.alias;

psth_p = dsp3.get_intermediate_dir( 'per_trial_psth' );
output_p = dsp3.get_intermediate_dir( 'summarized_psth' );

psth_mats = dsp3.require_intermediate_mats( params.files, psth_p, params.files_containing );

for i = 1:numel(psth_mats)
  fprintf( '\n %d of %d', i, numel(psth_mats) );

  psth_file = shared_utils.io.fload( psth_mats{i} );

  output_file = fullfile( output_p, psth_file.file );

  if ( dsp3.conditional_skip_file(output_file, params.overwrite) )
    continue;
  end

  if ( shared_utils.io.fexists(output_file) && params.append )
    fprintf( '\n Loading "%s"', psth_file.file );
    summarized_psth = shared_utils.io.fload( output_file );

    if ( ~summarized_psth.psths.isKey(alias) )
      assert( params.allow_new_alias, ['File "%s" exists, but new alias' ...
        , ' "%s" does not exist within it, and `allow_new_alias` is false.'] ...
        , psth_file.file, alias );
    end
  else
    summarized_psth = struct();
    summarized_psth.file = psth_file.file;
    summarized_psth.params_per_alias = containers.Map();    
    summarized_psth.psths = containers.Map();
  end

  keys = psth_file.psths.keys();

  all_psths = containers.Map();
  
  for j = 1:numel(keys)
    c_psth = psth_file.psths(keys{j});
    c_psth.psth = c_psth.psth.each1d( params.within, params.summary_func );
    c_psth.raster = c_psth.raster.each1d( params.within, params.summary_func );
    all_psths(keys{j}) = c_psth;
  end

  summarized_psth.psths(alias) = all_psths;
  summarized_psth.params_per_alias(alias) = params;

  shared_utils.io.require_dir( output_p );

  do_save( output_file, summarized_psth );
end

end

function do_save( filename, summarized_psth )
save( filename, 'summarized_psth' );
end