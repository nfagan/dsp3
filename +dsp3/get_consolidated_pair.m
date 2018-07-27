function [dat, labs, key] = get_consolidated_pair(varargin)

cons = dsp3.get_consolidated_data( varargin{:} );

dat = cons.trial_data.data;
labs = fcat.from( cons.trial_data.labels );
key = cons.trial_key;

end