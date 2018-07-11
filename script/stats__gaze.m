consolidated = dsp3.get_consolidated_data();

labs = fcat.from( consolidated.trial_data.labels );

analysis_p = dsp3.analysisp( {'behavior', dsp3.datedir} );

%%

drug_type = 'nondrug';
per_mag = false;

spec = { 'outcomes', 'trialtypes', 'days', 'drugs', 'administration' };

if ( per_mag ), spec{end+1} = 'magnitudes'; end

[subsetlabs, I] = dsp3.get_subset( labs', drug_type );
subsetdata = consolidated.trial_data.data(I, :);

[countdat, countlabs, newcats] = dsp3.get_gaze_counts( subsetdata, subsetlabs', consolidated.trial_key );

%   make binary
countdat(countdat > 0) = 1;

spec = union( spec, newcats );

%%

uselabs = countlabs';
usedat = countdat;

[plabs, I] = keepeach( uselabs', spec );
pdat = rowop( usedat, I, @pnz );

%%
