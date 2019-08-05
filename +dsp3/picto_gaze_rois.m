function rois = picto_gaze_rois()

%   PICTO_GAZE_ROIS -- Get pixel gaze rois used to establish looking to
%     monkey / bottle.
%
%     Note that unlike the raw data, these rois *are not flipped*:
%     bottle is really bottle, and monkey is monkey.

target_dims = [400, 400];
center_bottle = [ -200, 300 ];
center_monk = [ 1000, 300 ];

rois = struct();
rois.bottle = to_rect( center_bottle, target_dims );
rois.monkey = to_rect( center_monk, target_dims );

end

function r = to_rect(center, dims)

x0 = center(1) - dims(1)/2;
x1 = center(1) + dims(1)/2;

y0 = center(2) - dims(2)/2;
y1 = center(2) + dims(2)/2;

r = [ x0, y0, x1, y1 ];

end