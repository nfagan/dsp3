function [data, labels] = dsp3_get_converted_cc_sf_data(acc, bla, varargin)

[bladat, blalabs] = dsp3_convert_cc_sf( bla );

if ( isempty(blalabs) )
  n_sites = 1;
else
  n_sites = max( fcat.parse(blalabs('sites'), 'site__') );
end

[accdat, acclabs] = dsp3_convert_cc_sf( acc, n_sites, varargin{:} );

guard_empty( blalabs, @(x) addsetcat(x, 'regions', 'bla_spike_acc_field') );
guard_empty( acclabs, @(x) addsetcat(x, 'regions', 'acc_spike_bla_field') );

data = [ bladat; accdat ];
labels = extend( fcat(), blalabs, acclabs );

guard_empty( labels, @(x) standardize_labels(x) );

end

function standardize_labels(labels)

addsetcat( labels, 'trialtypes', 'choice' );
addsetcat( labels, 'administration', 'pre' );
addcat( labels, 'drugs' );
dsp3.add_context_labels( labels );

prune( labels );

end