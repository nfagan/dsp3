function eeg2 = xcorrfilter(eeg1, lf, hf, fs)

order = round( fs );

if ( mod(order, 2) ~= 0 )
  order = order-1;
end

nyq = floor( fs/2 );
b = fir1( order, [lf, hf]/nyq );

eeg2 = filter( b, 1, eeg1 );

end