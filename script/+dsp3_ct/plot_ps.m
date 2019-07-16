function axs = plot_ps(ps, p_labels)

assert_ispair( ps, p_labels );

pcats = { 'region' };
gcats = { 'contexts' };
count_each = csunion( pcats, gcats );

sig_ps = ps < 0.05;

denom_I = findall( p_labels, pcats );

all_percents = [];
all_sig_labels = fcat();

for i = 1:numel(denom_I)
  denom_value = numel( findall(p_labels, 'unit_uuid'), denom_I{i} );

  [sig_labels, count_I] = keepeach( p_labels', count_each, denom_I{i} );
  sig_percents = zeros( numel(count_I), 1 );

  for j = 1:numel(count_I)
    sig_percents(j) = nnz( sig_ps(count_I{j}) ) / denom_value * 100;
  end

  all_percents = [ all_percents; sig_percents ];
  append( all_sig_labels, sig_labels );
end

pl = plotlabeled.make_common();
axs = pl.bar( all_percents, all_sig_labels, {}, gcats, pcats );

ylabel( axs(1), '% Significant cells' );

end