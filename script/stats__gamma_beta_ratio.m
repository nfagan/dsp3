function stats__gamma_beta_ratio(varargin)

defaults = dsp3.get_behav_stats_defaults();
defaults.do_plot = false;
defaults.meast = 'at_coherence';
defaults.drugt = 'nondrug';
defaults.epochs = 'targacq';

params = dsp3.parsestruct( defaults, varargin );

do_save = params.do_save;
do_plt = params.do_plot;

%%

meast = params.meast;
drugt = params.drugt;
epochs = params.epochs;

path_components = { 'gamma_beta_ratio', dsp3.datedir, drugt };
analysis_p = char( dsp3.analysisp(path_components) );

intermediate_dirs = dsp3.fullfiles( meast, drugt, epochs );
coh_p = dsp3.get_intermediate_dir( intermediate_dirs );
mats = shared_utils.io.find( coh_p, '.mat' );

basespec = { 'measure', 'epochs' };

%%  load data

[data, labels, freqs, t] = dsp3.load_signal_measure( mats ...
  , 'get_meas_func', @(meas) meas.measure ...
);

%%

t_ind = t >= -250 & t <= 0;
t_dim = 3;
t_meaned = nanmean( dimref(data, t_ind, t_dim), t_dim );

bands = dsp3.get_bands( 'map' );

[bandmeans, bandlabs] = dsp3.get_band_means( t_meaned, labels', freqs, bands );

gamma_ind = find( bandlabs, 'gamma' );
beta_ind = find( bandlabs, 'beta' );

ratio = bandmeans(gamma_ind) ./ bandmeans(beta_ind);
bandlabs = setcat( bandlabs(gamma_ind), 'bands', 'gamma div beta' );

%%  pro v anti

usedat = ratio;
uselabs = bandlabs';

subspec = csunion( basespec, {'trialtypes', 'channels', 'regions', 'sites', 'days' ...
  , 'drugs', 'administration', 'bands'} );

mask = findnot( uselabs, {'cued', 'targAcq'} );

[sbdat, sblabs] = dsp3.a_summary_minus_b( usedat, uselabs', subspec, 'self', 'both', @nanmean, mask );
[ondat, onlabs] = dsp3.a_summary_minus_b( usedat, uselabs', subspec, 'other', 'none', @nanmean, mask );

setcat( sblabs, 'outcomes', 'anti' );
setcat( onlabs, 'outcomes', 'pro' );

prodat = [ sbdat; ondat ];
prolabs = [ sblabs'; onlabs ];

funcs = { @mean, @median, @rows, @signrank };
tblspec = csunion( cssetdiff(subspec, {'days', 'sites', 'channels'}), 'outcomes' );
[m_tbl, ~, mlabs] = dsp3.descriptive_table( prodat, prolabs', tblspec, funcs );

if ( do_save )
  dsp3.savetbl( m_tbl, analysis_p, mlabs, tblspec, 'proanti_descriptives' );
end

%%  1-way anova, outcome

compcat = 'comparison';

usedat = ratio;
uselabs = addcat( bandlabs', compcat );

alpha = params.alpha;

mask = findnone( uselabs, 'errors', findnot(uselabs, {'cued', 'targAcq'}) );

anovaspec = csunion( basespec, {'trialtypes', 'drugs', 'regions', 'administration'} );
[alabs, I] = keepeach( uselabs', anovaspec, mask );

c_tbls = cell( size(I) );
a_tbls = cell( size(I) );

for i = 1:numel(I)
  grp = removecats( categorical(uselabs, 'outcomes', I{i}) );
  
  [p, tbl, stats] = anova1( usedat(I{i}), grp, 'off' );
  [cc, c] = dsp3.multcompare( stats );
  
  issig = c(:, end) < alpha;
  sig_comparisons = cc(issig, :);
  
  a_tbls{i} = dsp3.anova_cell2table( tbl );
  c_tbls{i} = dsp3.multcompare_cell2table( sig_comparisons );
end

funcs = { @mean, @median, @rows, @plotlabeled.sem };
tblspec = csunion( anovaspec, 'outcomes' );
[m_tbl, ~, mlabs] = dsp3.descriptive_table( usedat, uselabs', tblspec, funcs, mask );

if ( do_save )
  dsp3.savetbl( m_tbl, analysis_p, mlabs, anovaspec, 'descriptives' );
  
  for i = 1:numel(a_tbls)
    dsp3.savetbl( a_tbls{i}, analysis_p, alabs(i), anovaspec, 'anova_table' );
    dsp3.savetbl( c_tbls{i}, analysis_p, alabs(i), anovaspec, 'comparisons' );
  end
end

%%  plot

if ( do_plt )
  pltdat = ratio;
  pltlabels = bandlabs';

  mask = findnone( pltlabels, {'errors', 'cued'} );

  pl = plotlabeled.make_common();
  pl.x_order = { 'self', 'both', 'other' };

  axs = pl.bar( rowref(pltdat, mask), pltlabels(mask), 'outcomes', {}, 'trialtypes' );
  set( axs, 'YLim', [0.94, 0.96] );
end