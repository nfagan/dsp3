%%

conf = dsp3.config.load();
consolidated = dsp3.get_consolidated_data();

%%

preflabs = fcat.from( consolidated.trial_data.labels );
addcat( preflabs, {'channels', 'regions', 'sites'} );

dsp3.get_subset( preflabs, 'nondrug' );

[prefdat, preflabs] = dsp3.get_pref( preflabs );

%%

epoch = { 'reward', 'targacq' };
manip = 'pro_v_anti';
drug_type = 'nondrug';

p = fullfile( conf.PATHS.dsp2_analyses, 'z_scored_coherence', epoch, drug_type, manip );

mats = shared_utils.io.find( p, '.mat' );

%%

labs = cell( size(mats) );
dat = cell( size(labs) );
freqs = [];
t = [];

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats) );
  
  meas = shared_utils.io.fload( mats{i} );
  
  t = meas.get_time_series();
  freqs = meas.frequencies;
  
  t_ind = t >= -500 & t <= 500;
  f_ind = freqs <= 100;
  
  labs{i} = fcat.from( meas.labels );
  dat{i} = meas.data(:, f_ind, t_ind);
  
  freqs = freqs(f_ind);
  t = t(t_ind);
end

labels = vertcat( fcat(), labs{:} );
data = vertcat( dat{:} );

assert_rowsmatch( data, labels );

%%

f_ind = freqs >= 0 & freqs <= 100;
t_ind = t >= -250 & t <= 0;

roi_dat = squeeze( nanmean(data(:, f_ind, t_ind), 3) );

%%

pltdat = roi_dat;
pltlabs = labels';

mask = find( pltlabs, {'choice'} );

collapsecat( pltlabs, 'drugs' );

pl = plotlabeled();
pl.one_legend = true;
pl.x = freqs(f_ind);
pl.error_func = @plotlabeled.nansem;
pl.y_lims = [ -0.2, 0.2 ];

groups = 'outcomes';
panels = { 'trialtypes', 'epochs', 'drugs' };

axs = pl.lines( rowref(pltdat, mask), pltlabs(mask), groups, panels );
set( axs, 'nextplot', 'add' );

shared_utils.plot.add_horizontal_lines( axs, 0 );

%%  match pref & coherence

unique_to_coh = { 'channels', 'regions', 'sites' };
common = { 'days', 'outcomes', 'trialtypes', 'administration' };
combined = [ unique_to_coh, common ];

[I, C] = findall( labels, [unique_to_coh, common] );
[~, match_inds] = ismember( common, combined );

full_inds = rowzeros( rows(labels) );

for i = 1:numel(I)
  ind_pref = find( preflabs, C(match_inds, i) );
  assert( numel(ind_pref)==1 );
  full_inds(I{i}) = ind_pref;
end

matchlabs = preflabs(full_inds);
matchdat = prefdat(full_inds);

join( rmcat(matchlabs, unique_to_coh), labels );

%%

tdim = 3;
t_ind = t >= -250 & t <= 0;

t_meaned = squeeze( nanmean(dimref(data, t_ind, tdim), tdim) );

[banddat, bandlabs, I] = dsp3.get_band_means( t_meaned, labels', freqs, bands, bandnames );
bandpref = matchdat(I);

%%  optionally reduce to day-level

meanspec = { 'days', 'trialtypes', 'outcomes', 'administration', 'bands', 'epochs' };
[meanlabs, I] = keepeach( bandlabs', meanspec );

meancoh = rownanmean( banddat, I );
meanpref = rownanmean( bandpref, I );

%%  full data

pltlabs = bandlabs';
X = banddat;
Y = bandpref;

%%  mean data

pltlabs = meanlabs';
X = meancoh;
Y = meanpref;

%%  plot

[~, mask] = only( pltlabs, {'targAcq', 'choice'} );
X = X(mask);
Y = Y(mask);

pl = plotlabeled( 'shape', [3, 2], 'one_legend', true );

gcats = 'epochs';
pcats = { 'outcomes', 'trialtypes', 'bands' };

[axs, ids] = pl.scatter( X, Y, pltlabs, gcats, pcats );

plotlabeled.scatter_addcorr( ids, X, Y );


