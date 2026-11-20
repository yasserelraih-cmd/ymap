import 'package:flutter_test/flutter_test.dart';
import 'package:ymap/routing/route.dart';

/// يعمل على الجوال وفي المتصفح: `flutter test --platform chrome test/polyline_test.dart`
void main() {
  test('فك ترميز مسار حقيقي بفروق سالبة (الملز ← شمال الرياض)', () {
    final pts = decodePolyline6("wd_bn@yem`xAmShIbl@|jBEbAk@zBwApEs]lN_]nMc]hOuGjFeQdHgLdEgj@pUcAh@cGvBsXzJmc@bQqNhG{ErHs@~A]fBCjCh@vB~ApBbDr@dGw@tGqCzBcB~BiAxFsAnCSfg@iP|DkBhFgCx@[|KcE|Ak@vMeFlGmBb@OpFkBf@S|a@kPzQgHlDsAlq@iWfc@_S`HqDTM~PkH~Q_I|HsDtg@}U~f@cQh^mM~[kLzCoAzzAon@hGiCvmAue@`HiH~K{ErGcDrHsCzH}DvDaBjHaG|cAif@vs@{Zr`DmkA~DiApHyBlC_@bBc@|AOrB?vAFfBDdBb@x@TdAXrAZ~Af@bA|@rA|@|@rAbAhBl@bBp@dBl@|APlBNnBCvBOzBMfBKlBk@jBa@dB{@~AcAvAkApAsAfAwA|@_Br@aBh@eB\\gBRiBFiBEgBOgB[cBe@_Bq@yA{@sAeAmAmAeAwA_A}As@cB{CsGgT{p@oGmOqTao@g\\aw@oTct@gMo\\eRil@ox@shCoAkIqMga@es@}{B}d@mqAcQuk@kg@u`Bg^gkA}Uat@cNkb@inAycEu_@soAoPet@mNm{@wNedA}Uy`AcOq]ab@on@wReUmVqRqbAa{@yOiPmJaNyUe\\wR{c@oJgYuHsXqFg[gDiXuIoq@{AeQ_A_IyAeMeI}r@eGy_@_Ioa@aHq]yJqq@ci@_`FyV_`C{Gun@gI{n@kCkMuF{UqIiZeSae@gPg]qNaXuDeHwj@s~@ya@gs@c}AclCugB{{C_uB}nDkiAuqBasBcxDycA_nBkq@}oAsgDimGgo@slAqZck@yVee@oLyU{AeD_Yiu@yDeMcB{JiBgYG}k@Dm[Kwb@}@kKiC{LkCmIsFaI{E}FeMaNcJuGuRaJ}LiEuM_CiTaBwMSmOp@{JfA{M|A}MzF{LtGoM`JmGpHoJ~MsEtGiG|IwSvb@sMfVoK|NmOtPyL|Hyk@d\\saFhqBmaC|aAu_JbrDmFpBmZhNqjAne@yz@`^aeEz`B}tLr{E}a@pPa`OlaGu_LjqEq~Dt_BcjAld@iuBdx@}jCnfAo_F`qBe}B`_Aal@dVc`C~l@kW~IiVpBgHm@mG}BaJgRmIkYfp@iWdMeFdaDspAk[}cAa[ecAy^elAu\\_gAb`@gO");
    expect(pts.length, 260);
    final lats = pts.map((p) => p.lat);
    final lons = pts.map((p) => p.lon);
    expect(lats.reduce((a, b) => a < b ? a : b), closeTo(24.677364, 1e-6));
    expect(lats.reduce((a, b) => a > b ? a : b), closeTo(24.776614, 1e-6));
    expect(lons.reduce((a, b) => a < b ? a : b), closeTo(46.680574, 1e-6));
    expect(lons.reduce((a, b) => a > b ? a : b), closeTo(46.763103, 1e-6));
    expect(pts.last.lat, closeTo(24.774361, 1e-6));
    expect(pts.last.lon, closeTo(46.738751, 1e-6));
  });
}
