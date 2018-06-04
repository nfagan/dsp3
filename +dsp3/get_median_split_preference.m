function med_split = get_median_split_preference( pref )

mean_spec = { 'days', 'drugs', 'administration', 'contexts', 'trialtypes' };
med_spec = setdiff( mean_spec, 'days' );

day_means = each1d( pref, mean_spec, @rowops.nanmean );

[I, C] = get_indices( day_means, med_spec );

med_split = Container();

day_mean_dat = day_means.data;

for i = 1:numel(I)
  med = nanmedian( day_mean_dat(I{i}) );
  
  below_med = I{i} & day_mean_dat <= med;
  above_med = I{i} & day_mean_dat > med;
  
  below_days = day_means( 'days', below_med );
  above_days = day_means( 'days', above_med );
  
  both_days = { below_days, above_days, med, C(i, :) };
  
  med_split = append( med_split, set_data(one(day_means(I{i})), both_days) );
end

end