function granger = load_granger(subdir, conf)

if ( nargin < 2 )
  conf = dsp3.config.load();
end

granger_p = fullfile( dsp3.dataroot(conf), 'analyses', 'granger', subdir );
granger = load_multipart_granger( granger_p );

end

function granger = load_multipart_granger(granger_p)

mats = shared_utils.io.findmat( granger_p );
granger = [];

for i = 1:numel(mats)
  if ( i == 1 )
    granger = shared_utils.io.fload( mats{i} );
  else
    granger(i) = shared_utils.io.fload( mats{i} );
  end
end

if ( ~isempty(granger) )
  out_granger = struct();
  out_granger.params = { granger.params };
  out_granger.granger_params = { granger.granger_params };
  out_granger.data = vertcat( granger.data );
  out_granger.labels = vertcat( fcat(), granger.labels );
  out_granger.t = { granger.t };
  out_granger.f = { granger.f };
  
  granger = out_granger;
else
  granger = struct();
  granger.params = struct( [] );
  granger.granger_params = struct( [] );
  granger.data = [];
  granger.labels = fcat();
  granger.t = {};
  granger.f = {};
end

end