function stats__gamma_beta_ratio(varargin)

defaults = dsp3.get_behav_stats_defaults();
defaults.do_plot = false;
defaults.meast = 'at_coherence';
defaults.drug_type = 'nondrug';
defaults.epochs = 'targacq';
defaults.manipulation = 'pro_v_anti';
defaults.is_z = false;

params = dsp3.parsestruct( defaults, varargin );

do_save = params.do_save;
do_plt = params.do_plot;

%%

meast = params.meast;
drugt = params.drug_type;
epochs = params.epochs;
per_mag = params.per_magnitude;
bs = params.base_subdir;
manip = params.manipulation;
is_z = params.is_z;

mag_type = ternary( per_mag, 'magnitude', 'non_magnitude' );
path_components = { 'gamma_beta_ratio', dsp3.datedir, bs, drugt, mag_type };

analysis_p = char( dsp3.analysisp(path_components) );

if ( is_z )
  p = dsp3.fullfiles( params.config.PATHS.dsp2_analyses, 'z_scored_coherence', epochs, drugt, manip );
  p = p( cellfun(@shared_utils.io.dexists, p) );
  mats = shared_utils.io.findmat( p );
  
  meas_func = @(x) x;
else
  intermediate_dirs = dsp3.fullfiles( meast, drugt, epochs );
  coh_p = dsp3.get_intermediate_dir( intermediate_dirs );
  mats = shared_utils.io.findmat( coh_p );
  
  meas_func = @(meas) meas.measure;
end

basespec = { 'measure', 'epochs' };

%%  load data

[data, labels, freqs, t] = dsp3.load_signal_measure( mats ...
  , 'get_meas_func', meas_func ...
);

if ( ~is_z )
  dsp3.add_context_labels( labels );
else
  if ( ~dsp3.isdrug(drugt) )
    collapsecat( labels, 'drugs' );
  end
end

data = indexpair( data, labels, findnone(labels, params.remove) );

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

base_band_mask = fcat.mask( bandlabs ...
  , @findnone, 'errors' ...
  , @findnot, {'cued', 'targAcq'} ...
  , @findnot, {'choice', 'targOn'} ...
);

%%  pro v anti

usedat = ratio;
uselabs = bandlabs';

subspec = csunion( basespec, {'trialtypes', 'channels', 'regions', 'sites', 'days' ...
  , 'drugs', 'administration', 'bands'} );

mask = base_band_mask;

[sbdat, sblabs] = dsp3.a_summary_minus_b( usedat, uselabs', subspec, 'self', 'both', @nanmean, mask );
[ondat, onlabs] = dsp3.a_summary_minus_b( usedat, uselabs', subspec, 'other', 'none', @nanmean, mask );

setcat( sblabs, 'outcomes', 'anti' );
setcat( onlabs, 'outcomes', 'pro' );

prodat = [ sbdat; ondat ];
prolabs = [ sblabs'; onlabs ];

funcs = { @mean, @median, @rows, @signrank };
tblspec = csunion( cssetdiff(subspec, {'days', 'sites', 'channels'}), 'outcomes' );

try
  [m_tbl, ~, mlabs] = dsp3.descriptive_table( prodat, prolabs', tblspec, funcs );

  if ( do_save )
    dsp3.savetbl( m_tbl, analysis_p, mlabs, tblspec, 'proanti_descriptives' );
  end
catch err
  warning( err.message );
end

%%  1-way anova, outcome

usedat = ratio;
uselabs = bandlabs';

anovaspec = csunion( basespec, {'trialtypes', 'drugs', 'regions', 'administration'} );
factor = 'outcomes';

mask = base_band_mask;

outs = dsp3.anova1( usedat, uselabs', anovaspec, factor, 'mask', mask );

m_tbl = outs.descriptive_tables;
mlabs = outs.descriptive_labels';

a_tbls = outs.anova_tables;
alabs = outs.anova_labels';

c_tbls = outs.comparison_tables;

if ( do_save )
  dsp3.savetbl( m_tbl, analysis_p, mlabs, anovaspec, 'descriptives' );
  
  for i = 1:numel(a_tbls)
    dsp3.savetbl( a_tbls{i}, analysis_p, alabs(i), anovaspec, 'anova_table' );
    dsp3.savetbl( c_tbls{i}, analysis_p, alabs(i), anovaspec, 'comparisons' );
  end
end

%%  t-test per context

usedat = ratio;
uselabs = bandlabs';

tspec = csunion( basespec, {'trialtypes', 'drugs', 'regions', 'administration', 'contexts'} );
factor = 'outcomes';

mask = base_band_mask;

[tlabs, I] = keepeach( uselabs', tspec, mask );

tbls = cell( size(I) );
t_success = true;

for i = 1:numel(I)
  [inds, C] = findall( uselabs, factor, I{i} );
  
  if ( numel(inds) ~= 2 )
    warning( 'Expected 2 outcomes per context; got %d.', numel(I) );
    t_success = false;
    break;
  end
  
  [~, p, ~, stats] = ttest2( usedat(inds{1}), usedat(inds{2}) );
  stats.p = p;
  
  setcat( tlabs, factor, sprintf('%s vs %s', C{:}), i );
  
  tbls{i} = struct2table( stats );
end

if ( t_success && do_save )
  for i = 1:numel(tbls)
    dsp3.savetbl( tbls{i}, analysis_p, tlabs(i), tspec, 'per_context_ttest' );
  end
end

%%  1-way anova, outcome

compcat = 'comparison';

usedat = ratio;
uselabs = addcat( bandlabs', compcat );

alpha = params.alpha;

mask = base_band_mask;

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
  
  mask = base_band_mask;

  pl = plotlabeled.make_common();
  pl.x_order = { 'self', 'both', 'other' };

  axs = pl.bar( rowref(pltdat, mask), pltlabels(mask), 'outcomes', {}, 'trialtypes' );
  set( axs, 'YLim', [0.94, 0.96] );
end

%%  drug ttests

if ( dsp3.isdrug(drugt) )
  
  base_prefix = 'drug_ttest';
  
  usedat = ratio;
  uselabs = bandlabs';
  
  sub_a = 'post';
  sub_b = 'pre';
  
  %   full spec
  drug_subspec = csunion( basespec, {'trialtypes', 'channels', 'regions' ...
    , 'sites', 'days', 'drugs', 'bands', 'outcomes'} );
  %   except sites & drugs
  t_spec = cssetdiff( drug_subspec, {'channels', 'regions', 'sites', 'days', 'drugs'} );
  %   except outcomes
  pro_subspec = cssetdiff( drug_subspec, 'outcomes' );
  
  pairs = { {'self', 'both'}, {'other', 'none'} };
  
  choice_mask = find( uselabs, {'choice', 'targAcq'}, base_band_mask );
  cued_mask = find( uselabs, {'cued', 'targOn'}, base_band_mask );
  
  mask = union( choice_mask, cued_mask );
  
  opfunc = @minus;
  sfunc = @nanmean;
  
  [subdat, sublabs] = dsp3.sbop( usedat, uselabs', drug_subspec, sub_a, sub_b, opfunc, sfunc, mask );
  
  dat = [];
  labs = fcat();
  
  for i = 1:numel(pairs)
    a = pairs{i}{1};
    b = pairs{i}{2};
    
    [outdat, outlabs] = dsp3.sbop( subdat, sublabs', pro_subspec, a, b, opfunc, sfunc );
    setcat( outlabs, 'outcomes', sprintf('%s - %s', a, b) );
    
    dat = [ dat; outdat ];
    append( labs, outlabs );
  end
  
  outs = dsp3.ttest2( dat, labs', t_spec, 'saline', 'oxytocin' );
  
  if ( do_save )
    m_tbls = outs.descriptive_tables;
    m_labs = outs.descriptive_labels;
    t_tbls = outs.t_tables;
    t_labs = outs.t_labels;
    
    dsp3.savetbl( m_tbls, analysis_p, m_labs, tspec, sprintf('%s__descriptives', base_prefix) );

    for i = 1:numel(t_tbls)
      dsp3.savetbl( t_tbls{i}, analysis_p, t_labs(i), tspec, sprintf('%s__t_tables', base_prefix) );
    end
  end
  
end
