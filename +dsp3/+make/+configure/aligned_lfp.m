function aligned_lfp(runner, params)

runner.is_parallel = params.is_parallel;
runner.input_directories = { fullfile(dsp3.dataroot(params.config), 'raw', 'lfp') };
runner.get_identifier_func = @(varargin) varargin{1}.src_filename;
runner.overwrite = params.overwrite;

end