function plot_latencies(latencies, labels, cell_type_labels, varargin)

defaults = dsp3.get_common_plot_defaults( dsp3.get_common_make_defaults() );
params = dsp3.parsestruct( defaults, varargin );

assert_ispair( latencies, labels );

plot_task_modulated( latencies, labels', cell_type_labels', params );
plot_per_outcome( latencies, labels', params );

end

function plot_task_modulated(latencies, labels, cell_type_labels, params)

%%

fcats = { 'region' };
pcats = { 'outcomes', 'trialtypes', 'cell_type' };

add_task_modulated_labels( labels, cell_type_labels );

outcomes = { 'self', 'both', 'other', 'none' };

if_nonempty = @(x, y) ternary(isempty(x), y, x);

cell_type_order = findall( labels, 'cell_type' );
cell_type_order = cellfun( ...
  @(x) cellfun(@(y) if_nonempty(find(labels, y, x), x), outcomes, 'un', 0) ...
  , cell_type_order, 'un', 0 );
cell_type_order = cellfun( @(x) vertcat(x{:}), cell_type_order, 'un', 0 );
cell_type_order = vertcat( cell_type_order{:} );

latencies = latencies(cell_type_order);
labels = labels(cell_type_order);

fig_I = findall_or_one( labels, fcats );

for i = 1:numel(fig_I)
  clf( gcf );
  
  pl = plotlabeled.make_common();
  pl.sort_combinations = false;
  
  pltlabs = prune( labels(fig_I{i}) );

  [axs, I] = pl.hist( latencies(fig_I{i}), pltlabs, pcats, 1e2 );
  add_medians( latencies, I, axs );
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( gcf );
    save_p = get_plot_p( params, 'task_modulated_vs_not' );
    dsp3.req_savefig( gcf, save_p, pltlabs, [pcats, fcats] );
  end
end

end

function plot_per_outcome(latencies, labels, params)

pl = plotlabeled.make_common();
pl.panel_order = { 'self', 'both', 'other' };
pcats = { 'outcomes', 'trialtypes', 'region' };

[axs, I] = pl.hist( latencies, labels, pcats, 1e2 );
add_medians( latencies, I, axs );

if ( params.do_save )
  shared_utils.plot.fullscreen( gcf );
  save_p = get_plot_p( params, 'all_cells' );
  dsp3.req_savefig( gcf, save_p, labels, pcats );
end

end

function save_p = get_plot_p(params, varargin)

save_p = fullfile( dsp3.dataroot(params.config), 'plots', 'cell_latencies' ...
  , dsp3.datedir, params.base_subdir, varargin{:} );

end

function labels = add_task_modulated_labels(labels, cell_type_labels)

labels = add_received_forgone_labels( labels, cell_type_labels );
task_modulated = find( labels, {'cell_type_received', 'cell_type_forgone'} );
setcat( labels, 'cell_type', 'cell_type_task_modulated', task_modulated );

end

function labels = add_received_forgone_labels(labels, cell_type_labels)

[unit_I, unit_C] = findall( labels, 'unit_uuid' );
kinds = { 'received', 'forgone', 'not_significant' };
addcat( labels, 'cell_type' );

for i = 1:numel(unit_I)
  cell_type_ind = find( cell_type_labels, unit_C(:, i) );
  inds = cellfun( @(x) find(cell_type_labels, x, cell_type_ind), kinds, 'un', 0 );
  counts = cellfun( @numel, inds );
  
  if ( nnz(counts) > 1 )
    error( 'Cell classified as received or forgone or not_significant' );
  end
  
  [~, kind_ind] = max( counts );
  
  setcat( labels, 'cell_type', sprintf('cell_type_%s', kinds{kind_ind}), unit_I{i} );
end

prune( labels );

end

function add_medians(data, I, axs)

meds = cellfun( @(x) nanmedian(data(x)), I );

for i = 1:numel(axs)
  lims = get( axs(i), 'ylim' );
  
  shared_utils.plot.hold( axs(i), 'on' );
  shared_utils.plot.add_vertical_lines( axs(i), meds(i) );
  
  lim_span = lims(2) - lims(1);
  text_y = lims(2) - lim_span * 0.1;
  
  text( axs(i), meds(i), text_y, sprintf('M = %0.2f', meds(i)) );
end

end