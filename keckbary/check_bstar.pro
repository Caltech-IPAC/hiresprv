PRO check_bstar, inp_ra, inp_dec, isbstar

thresh = 0.0166667   ; 1 arcminute match radius

bstar_list = getenv("DOP_BSTARS")

bstars = read_csv(bstar_list, N_TABLE_HEADER=1, TABLE_HEADER=head)

dist_ra = (inp_ra - bstars.FIELD11)^2
dist_dec = (inp_dec - bstars.FIELD12)^2
dist = sqrt(dist_ra + dist_dec)

min_dist = min(dist, min_loc)

IF min_dist LE thresh THEN isbstar = 1 ELSE isbstar = 0

END