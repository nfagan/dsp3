function out = get_preference_index( cont, a, b )

import shared_utils.assertions.*;

assert__isa( cont, 'Container' );
assert__isa( a, 'char' );
assert__isa( b, 'char' );

out = one( cont );

n_a = sum( cont.where(a) );
n_b = sum( cont.where(b) );

out.data = (n_a - n_b) / (n_a + n_b);

out('outcomes') = sprintf( '%sOver%s', a, b );

end