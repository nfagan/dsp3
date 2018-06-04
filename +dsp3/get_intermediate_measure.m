function [data, labs, t, freqs] = get_intermediate_measure( p )

mats = dsp3.require_intermediate_mats( p );

data = [];
labs = fcat();

for i = 1:numel(mats)
  dsp3.progress( i, numel(mats) );
  
  coh = shared_utils.io.fload( mats{i} );
  meas = coh.measure;
  
  data = [ data; meas.data ];
  append( labs, fcat.from(meas.labels) );
end

t = get_time_series( meas );
freqs = meas.frequencies;

end