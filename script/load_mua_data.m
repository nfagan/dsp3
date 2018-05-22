addpath( 'C:\Users\changLab\Repositories\dsp2' );
addpath( 'C:\Users\changLab\Repositories\dsp3' );

conf = dsp2.config.load();

io = dsp2.io.get_dsp_h5();

h5_path = conf.PATHS.H5.signals;
ref_type = conf.SIGNALS.reference_type;

if ( strcmp(ref_type, 'none') || strcmp(ref_type, 'non_common_averaged') )
  load_reftype = 'none';
else
  load_reftype = ref_type;
end

load_path = io.fullfile( h5_path, load_reftype, 'complete' );
load_path_wideband = io.fullfile( h5_path, load_reftype, 'wideband' );

%   get raw event times, raw trial data
consolidated_data = dsp3.get_consolidated_data();

%%

conf3 = dsp3.config.load();

save_p = 'H:\data\cc_dictator\mua\';

epoch = 'reward';

full_loadpath = io.fullfile( load_path, epoch );
full_loadpath_wideband = io.fullfile( load_path_wideband, epoch );

days = io.get_days( full_loadpath );

save( fullfile(save_p, sprintf('days_%s.mat', epoch)), 'days' );

mua_cutoffs = conf.SIGNALS.mua_filter_frequencies;
mua_devs = conf.SIGNALS.mua_std_threshold;

for i = 19:numel(days)
  fprintf( '\n %s (%d of %d)', days{i}, i, numel(days) );
  
  lfp = io.read( full_loadpath, 'only', days{i} );
  
  try
    wideband = io.read( full_loadpath_wideband, 'only', days{i} );
  catch err
    warning( err.message );
    continue;
  end
  
  spikes = wideband.filter( 'cutoffs', mua_cutoffs );
  spikes = spikes.update_range();

  wideband = wideband.filter();
  wideband = wideband.update_range();
  
  binned_wb = wideband.windowed_data();
  binned_spk = spikes.windowed_data();
  
  one_window_spk = binned_spk{1};
  one_trial = find( one_window_spk(1, :) );
  
  sample_rate = wideband.fs;
  start_t = wideband.start;
  stop_t = wideband.stop;
  window_ms = wideband.window_size;
  step_ms = wideband.step_size;

  spikes = dsp2.process.spike.get_mua_psth( spikes, mua_devs );
  
  spike_fname = sprintf( 'mua_spikes_%s_%s.mat', days{i}, epoch );
  lfp_fname = sprintf( 'lfp_%s_%s.mat', days{i}, epoch );
  
  save( fullfile(save_p, spike_fname), 'spikes' );
  save( fullfile(save_p, lfp_fname), 'lfp' );
end

%%

start_t = -500;
stop_t = 500;
sample_factor = wideband.fs / 1e3;
ws = 150;
t = start_t:1/sample_factor:stop_t+ws;










