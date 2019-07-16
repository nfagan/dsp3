function plot_psth(latencies, t, labels, cell_type_labels, varargin)

defaults = dsp3.get_common_plot_defaults( dsp3.get_common_make_defaults() );
params = dsp3.parsestruct( defaults, varargin );

assert_ispair( latencies, labels );

plot_task_modulated( latencies, t, labels', cell_type_labels', params );

end

function plot_task_modulated(latencies, t, labels, cell_type_labels, params)

fcats = { 'region', 'trialtypes' };
gcats = { 'outcomes' };
pcats = { 'trialtypes', 'cell_type', 'region' };

add_task_modulated_labels( labels, cell_type_labels );

outcomes = { 'self', 'both', 'other', 'none' };

if_nonempty = @(x, y) ternary(isempty(x), y, x);

cell_type_order = findall( labels, 'cell_type' );
cell_type_order = cellfun( ...
  @(x) cellfun(@(y) if_nonempty(find(labels, y, x), x), outcomes, 'un', 0) ...
  , cell_type_order, 'un', 0 );
cell_type_order = cellfun( @(x) vertcat(x{:}), cell_type_order, 'un', 0 );
cell_type_order = vertcat( cell_type_order{:} );

latencies = latencies(cell_type_order, :);
labels = labels(cell_type_order);

fig_I = findall_or_one( labels, fcats );

for i = 1:numel(fig_I)
  clf( gcf );
  
  pl = plotlabeled.make_common();
  pl.sort_combinations = false;
  pl.x = t(1, :);
  pl.add_smoothing = true;
  pl.smooth_func = @(x) smooth( x, 5 );
  
  pltlabs = prune( labels(fig_I{i}) );

  [axs, I] = pl.lines( latencies(fig_I{i}, :), pltlabs, gcats, pcats );
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( gcf );
    save_p = get_plot_p( params, 'task_modulated_vs_not' );
    dsp3.req_savefig( gcf, save_p, pltlabs, [pcats, fcats] );
  end
end

end

function save_p = get_plot_p(params, varargin)

save_p = fullfile( dsp3.dataroot(params.config), 'plots', 'cell_type_psth' ...
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