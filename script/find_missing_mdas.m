spike_p = dsp3.get_intermediate_dir( 'summarized_psth' );
spike_mats = dsp3.require_intermediate_mats( [], spike_p, [] );

epoch = 'targAcq';
alias = 'standard';

psth = Container();

for i = 1:numel(spike_mats)
  fprintf( '\n %d of %d', i, numel(spike_mats) );

  spike_file = shared_utils.io.fload( spike_mats{i} );

  psths = spike_file.psths(alias);

  psth = append( psth, psths(epoch) );
end

%%

unit_p = dsp3.get_intermediate_dir( 'unit_conts' );
unit_mats = dsp3.require_intermediate_mats( [], unit_p, [] );

unit_mats = cellfun( @shared_utils.io.fload, unit_mats, 'un', false );
unit_mats = cellfun( @(x) x.units, unit_mats, 'un', false );

units = Container.concat( unit_mats );

%%

all_mda_files = shared_utils.io.dirnames( fullfile(conf.PATHS.data_root, 'mountain_sort', 'firings'), '.mda' );
current_mda_files = units( 'mda_file' );

missing_mdas = setdiff( all_mda_files, current_mda_files );

