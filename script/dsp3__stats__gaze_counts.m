function dsp3__stats__gaze_counts(varargin)

defaults = dsp3.get_behav_stats_defaults();
params = dsp3.parsestruct( defaults, varargin );

drug_type = params.drug_type;
do_save = params.do_save;
bs = params.base_subdir;
base_prefix = params.base_prefix;
conf = params.config;

path_components = { 'behavior', dsp3.datedir, bs, drug_type, 'gaze' };

if ( isempty(params.consolidated) )
  consolidated = dsp3.get_consolidated_data( conf );
else
  consolidated = params.consolidated;
end

labs = fcat.from( consolidated.trial_data.labels );

params.analysis_p = char( dsp3.analysisp(path_components, conf) );
params.plot_p = char( dsp3.plotp(path_components, conf) );

%%

[subsetlabs, I] = dsp3.get_subset( labs', drug_type );
subsetdata = consolidated.trial_data.data(I, :);
trialkey = consolidated.trial_key;

[countdat, countlabs, newcats] = dsp3.get_gaze_counts( subsetdata, subsetlabs', trialkey );

countdat = indexpair( countdat, countlabs, findnone(countlabs, params.remove) );

%   make binary
countdat(countdat > 0) = 1;

handle_gaze_counts( countdat, countlabs', params );

end

function handle_gaze_counts(usedat, uselabs, params)
%%

spec = { 'outcomes', 'trialtypes', 'days', 'drugs' ...
  , 'administration', 'looks_to', 'look_period' };

[plabs, I] = keepeach( uselabs', spec );
pdat = rowop( usedat, I, @pnz );

pl = plotlabeled.make_common();
pl.x_order = { 'self', 'both', 'other' };

mask = fcat.mask( plabs ...
  , @find, 'late' ...
  , @findnone, 'errors' ...
  , @find, 'choice' ...
);

xcats = { 'outcomes' };
gcats = { 'looks_to' };
pcats = { 'trialtypes' };

axs = pl.errorbar( pdat(mask), plabs(mask), xcats, gcats, pcats );

%%  Anova

factors = { 'looks_to', 'outcomes' };

anova_outs = dsp3.anovan( pdat, plabs, {}, factors, 'mask', mask );

dsp3.save_anova_outputs( anova_outs, params.analysis_p, factors );

end

