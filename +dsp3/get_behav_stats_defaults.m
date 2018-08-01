function d = get_behav_stats_defaults(varargin)

d = struct();
d.config = dsp3.config.load();
d.consolidated = [];
d.rev_type = '';
d.remove = {};
d.per_magnitude = false;
d.per_monkey = false;
d.drug_type = 'nondrug';
d.base_subdir = '';
d.base_prefix = '';
d.do_save = false;
d.alpha = 0.05;
d.funcs = {};

if ( nargin > 0 )
  d = dsp3.parsestruct( d, varargin );
end

end