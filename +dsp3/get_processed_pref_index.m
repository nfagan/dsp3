function pref = get_processed_pref_index( subset )

pref_each = { 'days', 'administration', 'trialtypes', 'contexts' };

pref_sb = only( subset, {'self', 'both'} );
pref_on = only( subset, {'other', 'none'} );

pref_sb = for_each( pref_sb, pref_each, @(x) dsp3.get_preference_index(x, 'both', 'self') );
pref_on = for_each( pref_on, pref_each, @(x) dsp3.get_preference_index(x, 'other', 'none') );

pref = append( pref_sb, pref_on );

pref(isnan(pref.data) | isinf(pref.data)) = [];

end