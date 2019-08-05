function [coh, coh_labs] = load_targacq_coh_for_over_time(varargin)

conf = dsp3.set_dataroot( '/Volumes/My Passport/NICK/Chang Lab 2016/dsp3/', varargin{:} );

[loaded_coh, loaded_coh_labs, freqs, t] = dsp3_sfq.load_per_day_sfcoh( conf );

coh_t_min = 0;
coh_t_max = 150;
coh_t_mask = mask_gele( t, coh_t_min, coh_t_max );

band_names = { 'beta', 'new_gamma' };
bands = dsp3.some_bands( band_names );

[coh, coh_labs] = dsp3.get_band_means( loaded_coh, loaded_coh_labs', freqs, bands, band_names );
coh = nanmean( coh(:, coh_t_mask), 2 );

dsp3_sfq.add_spike_lfp_region_labels( coh_labs );
dsp3_sfq.add_block_order( coh_labs );

end