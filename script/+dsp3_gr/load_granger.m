function granger = load_granger(subdir, conf)

if ( nargin < 2 )
  conf = dsp3.config.load();
end

granger_p = fullfile( dsp3.dataroot(conf), 'analyses', 'granger', subdir );

granger_full_filepath = fullfile( granger_p, 'granger.mat' );

if ( shared_utils.io.fexists(granger_full_filepath) )
  granger = shared_utils.io.fload( granger_full_filepath );
else
  granger = load_multipart_granger( granger_p );
end

end

function granger = load_multipart_granger(granger_p)

mats = shared_utils.io.findmat( granger_p );
granger = [];

for i = 1:numel(mats)
  if ( i == 1 )
    granger = shared_utils.io.fload( mats{i} );
  else
    granger(i) = shared_utils.io.fload( mats{i} );
    granger(i).f = granger(i).f(1:501);
    granger(i).t = granger(i).t(1, :);
  end
end

if ( ~isempty(granger) )
  granger = shared_utils.struct.soa( granger );
end

end