conf = dsp2.config.load();

io = dsp2.io.get_dsp_h5();

load_reftype = 'none';

epoch = 'targacq';

h5_path = conf.PATHS.H5.signals;

load_path_wideband = io.fullfile( h5_path, load_reftype, 'wideband', epoch );

days = io.get_days( load_path_wideband );

all_measures = Container();

for i = 1:numel(days)
  wideband = io.read( load_path_wideband, 'only', days{i} );

  mua_cutoffs = conf.SIGNALS.mua_filter_frequencies;
  mua_devs = conf.SIGNALS.mua_std_threshold;

  signal_container_params = conf.SIGNALS.signal_container_params;

  wideband.params = signal_container_params;

  wideband = update_min( update_max(wideband) );

  spikes = wideband.filter( 'cutoffs', mua_cutoffs );
  spikes = spikes.update_range();

  wideband = wideband.filter();
  wideband = wideband.update_range();

  spikes = dsp2.process.spike.get_mua_psth( spikes, mua_devs );

  regs = { 'bla'; 'acc' };
  reg_combs = dsp2.util.general.allcomb( {regs, regs} );
  dups = strcmp( reg_combs(:, 1), reg_combs(:, 2) );
  reg_combs( dups, : ) = [];
  n_combs = size( reg_combs, 1 );

  measure = cell( 1, n_combs );

  for j = 1:n_combs
    row = reg_combs(j, :);
    spike = only( spikes, row{1} );
    signal = only( wideband, row{2} );
    sfcoh = spike.run_sfcoherence( signal );
    measure{j} = sfcoh;
  end

  measure = extend( measure{:} );
  measure = dsp2.process.format.fix_channels( measure );
  measure = dsp2.process.format.only_pairs( measure );
  
  all_measures = append( all_measures, measure );
end

%%  plot

meaned_measures = each1d( all_measures, {'outcomes', 'drugs'}, @rowops.nanmean );

spectrogram( meaned_measures, {'outcomes', 'drugs'} ...
  , 'frequencies', [0, 100] ...
  , 'time', [-500, 500] ...
);

