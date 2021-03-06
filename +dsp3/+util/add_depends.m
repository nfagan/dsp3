
function add_depends()

%   ADD_DEPENDS -- Add dependencies as defined in the config file.

conf = dsp3.config.load();

repos = conf.DEPENDS.repositories;
repo_dir = conf.PATHS.repositories;

for i = 1:numel(repos)
  addpath( genpath(fullfile(repo_dir, repos{i})) );
end

if ( isfield(conf.DEPENDS, 'others') )
  try
    cellfun( @(x) addpath(genpath(x)), conf.DEPENDS.others );
  catch err
    warning( err.message );
  end
end

end