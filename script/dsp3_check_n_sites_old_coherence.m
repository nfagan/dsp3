p = dsp3.get_intermediate_dir( 'at_coherence/nondrug_nanmedian/targacq' );
mats = shared_utils.io.findmat( p );

[~, labels, freqs, t] = dsp3.load_signal_measure( mats, 'get_meas_func', @(x) x.measure, 'is_cached', false );
setdisp( labels, 'short' );

%%

labs = keepeach( labels', {'monkeys', 'days', 'sites', 'channels', 'regions'} );

[t, rc] = tabular( labs, 'monkeys', 'regions' );

tbl = fcat.table( cellfun(@numel, t), rc{:} );

%%

consolidated = dsp3.get_consolidated_data();

%%

trial_labs = fcat.from( consolidated.trial_data.labels );

dsp2_conf = dsp2.config.load;
dsp2_conf.PATHS.database = '/mnt/dunham/media/chang/T1/data/dsp2/database';

pairs = dsp2.io.get_site_pairs( dsp2_conf );

%%

chan_labs = fcat();
tmp = fcat.with( categories, 2 );
days = pairs.days;
channels = pairs.channels;
bla_ind = strcmp( pairs.channel_key, 'bla' );
acc_ind = strcmp( pairs.channel_key, 'acc' );

categories = { 'channels', 'regions', 'days', 'sites' };
site_stp = 1;

for i = 1:numel(days)
  channels_this_day = channels{i};
  
  for j = 1:rows(channels_this_day)
    bla_chan = channels_this_day{bla_ind};
    acc_chan = channels_this_day{acc_ind};
    
    site = sprintf( 'site__%d', site_stp );
    
    setcat( tmp, categories, {bla_chan, 'bla', days{i}, site}, 1 );
    setcat( tmp, categories, {acc_chan, 'acc', days{i}, site}, 2 );
    
    match_ind = find( trial_labs, days{i} );
    join( tmp, prune(one(trial_labs(match_ind))) );
    
    append( chan_labs, tmp );   
    
    site_stp = site_stp + 1;
  end
end

prune( chan_labs );

%%

labs = keepeach( chan_labs', {'monkeys', 'sites', 'days', 'channels', 'regions'} );

[t, rc] = tabular( labs, 'monkeys', 'regions' );

tbl = fcat.table( cellfun(@numel, t), rc{:} );
