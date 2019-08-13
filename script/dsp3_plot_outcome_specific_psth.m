ct_labels = shared_utils.io.fload( ...
  fullfile(dsp3.dataroot(), 'analyses', 'cell_type_self_vs_other', '080919', 'choice_or_cued_testing_4_outcomes.mat') );
cell_type_labels = fcat.from( ct_labels.labels );
ct_labels.cell_types(strcmp(ct_labels.cell_types, 'self_vs_other_selective')) = {'outcome_selective'};
ct_labels.cell_types(strcmp(ct_labels.cell_types, 'non_self_vs_other_selective')) = {'non_selective'};

%%

[spikes, events, event_key] = dsp3_ct.load_linearized_sua();

%%

targ_epoch = 'targAcq';
selective_cat = 'outcome_selective';

targ_ts = events.data(:, event_key(targ_epoch));
base_ts = events.data(:, event_key('cueOn'));

targ_min_t = -0.3;
targ_max_t = 0.3;
bin_width = 0.01;

include_raster = true;

targ_events = mkpair( targ_ts, events.labels' );
[targ_psth, targ_labels, t, targ_rasters] = ...
  dsp3_ct.psth( spikes, targ_events, targ_min_t, targ_max_t, bin_width, include_raster );

targ_psth = targ_psth / bin_width;

[unit_I, unit_C] = findall( targ_labels, 'unit_uuid' );
addcat( targ_labels, selective_cat );

for i = 1:numel(unit_I)
  match_ind = find( cell_type_labels, unit_C{i} );
  cell_type = ct_labels.cell_types{match_ind};  
  setcat( targ_labels, selective_cat, cell_type, unit_I{i} );
end

%%

dsp3_ct.plot_agent_selective_psth( targ_psth, targ_rasters, targ_labels', t ...
  , 'do_save', true ...
  , 'base_subdir', '' ...
  , 'selectivity_subdir', 'cell_type_outcome_selectivity' ...
  , 'selectivity_cat', selective_cat ...
  , 'rasters_in_separate_figure', true ...
  , 'make_rasters', false ...
);