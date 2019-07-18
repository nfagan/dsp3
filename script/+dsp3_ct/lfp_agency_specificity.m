function out = lfp_agency_specificity(event_name, varargin)

defaults = dsp3.get_common_make_defaults();
defaults.psd_subdir = 'original_per_trial_psd';
defaults.t_window = [];

params = dsp3.parsestruct( defaults, varargin );

if ( isempty(params.t_window) )
  error( 'Specify a `t_window`.' );
end

inputs = { fullfile(params.psd_subdir, event_name) };

[~, runner] = dsp3.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @main, event_name, params );
outputs = [ results([results.success]).output ];

if ( isempty(outputs) )
  out = struct();
  out.anova_tables = {};
  out.anova_labels = fcat();
  out.comparison_tables = {};
else
  out = shared_utils.struct.soa( outputs );
end

out.params = params;

end

function out = main(files, event_name, params)

psd_file = shared_utils.general.get( files, event_name );
psd = psd_file.data;
psd_labs = psd_file.labels;
freqs = psd_file.f;

[bands, band_names] = get_bands();
[band_psd, band_labs] = dsp3.get_band_means( psd, psd_labs', freqs, bands, band_names );

t_ind = psd_file.t >= params.t_window(1) & psd_file.t <= params.t_window(2);
band_psd = nanmean( band_psd(:, t_ind), 2 );

anova_outs = dsp3_ct.lfp_agent_specificity_anova( band_psd, band_labs' );

out = struct();
out.anova_tables = anova_outs.anova_tables;
out.anova_labels = anova_outs.anova_labels;
out.comparison_tables = anova_outs.comparison_tables;

end

function [bands, band_names] = get_bands()

band_map = dsp3.get_bands( 'map' );
band_names = { 'new_gamma', 'beta' };
bands = cellfun( @(x) band_map(x), band_names, 'un', 0 );

end