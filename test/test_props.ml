(*---------------------------------------------------------------------------
   Copyright (c) 2020 The qrc programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
  ---------------------------------------------------------------------------*)

let div_round_up x y = (x + y - 1) / y

(* The tables from ISO/IEC 18004:2015(E) are highly interdependent, in Qrc
   we try to recover them from a minimal table. These tests make sure we
   got the data right. *)

(* Alignement patterns *)

let version_align_pat =  (* Table E.1 in Annex E *)
  [| [||];
     [|6;18|];
     [|6;22|];
     [|6;26|];
     [|6;30|];
     [|6;34|];
     [|6;22;38|];
     [|6;24;42|];
     [|6;26;46|];
     [|6;28;50|];
     (**)
     [|6;30;54|];
     [|6;32;58|];
     [|6;34;62|];
     [|6;26;46;66|];
     [|6;26;48;70|];
     [|6;26;50;74|];
     [|6;30;54;78|];
     [|6;30;56;82|];
     [|6;30;58;86|];
     [|6;34;62;90|];
     (**)
     [|6;28;50;72;94|];
     [|6;26;50;74;98|];
     [|6;30;54;78;102|];
     [|6;28;54;80;106|];
     [|6;32;58;84;110|];
     [|6;30;58;86;114|];
     [|6;34;62;90;118|];
     [|6;26;50;74;98;122|];
     [|6;30;54;78;102;126|];
     [|6;26;52;78;104;130|];
     (**)
     [|6;30;56;82;108;134|];
     [|6;34;60;86;112;138|];
     [|6;30;58;86;114;142|];
     [|6;34;62;90;118;146|];
     [|6;30;54;78;102;126;150|];
     [|6;24;50;76;102;128;154|];
     [|6;28;54;80;106;132;158|];
     [|6;32;58;84;110;136;162|];
     [|6;26;54;82;110;138;166|];
     [|6;30;58;86;114;142;170|];
  |]

let test_align_pats (`V version as v) =
  if version = 1 then () else
  let pat_count = Qrc.Prop.align_pat_count v in
  let pat_last = Qrc.Prop.align_pat_last v in
  let pat_delta = Qrc.Prop.align_pat_delta v in
  let p = version_align_pat.(version - 1) in
  assert (pat_count = Array.length p);
  for i = 0 to pat_count - 1 do
    assert
      ((Qrc.Prop.align_pat_center ~pat_count ~pat_last ~pat_delta i) = p.(i));
    assert (p.(i) mod 2 = 0); (* We rely on that during data layout. *)
 done

(* Capacity and error correction blocks *)

let ec_level_of_idx = function
  | 0 -> `L | 1 -> `M | 2 -> `Q | 3 -> `H | _ -> assert false

let version_total_bytes =
  (* 'Total number of codewords' in table 9, indexed by version - 1 *)
  [| 26; 44; 70; 100; 134; 172; 196; 242; 292; 346; (**)
     404; 466; 532; 581; 655; 733; 815; 901; 991; 1085; (**)
     1156; 1258; 1364; 1474; 1588; 1706; 1828; 1921; 2051; (**)
     2185; 2323; 2465; 2611; 2761; 2876; 3034; 3196; 3362; 3532; 3706; |]

let test_total_bytes (`V v as version) =
  assert (Qrc.Prop.total_bytes version = version_total_bytes.(v -1))

let version_data_bytes =
  (* 'Number of data codewords' in table 7, indexed by version - 1 and
     ec level. *)
  [| [|19;16;13;9|];
     [|34;28;22;16|];
     [|55;44;34;26|];
     [|80;64;48;36|];
     [|108;86;62;46|];
     [|136;108;76;60|];
     [|156;124;88;66|];
     [|194;154;110;86|];
     [|232;182;132;100|];
     [|274;216;154;122|];
     (**)
     [|324;254;180;140|];
     [|370;290;206;158|];
     [|428;334;244;180|];
     [|461;365;261;197|];
     [|523;415;295;223|];
     [|589;453;325;253|];
     [|647;507;367;283|];
     [|721;563;397;313|];
     [|795;627;445;341|];
     [|861;669;485;385|];
     (**)
     [|932;714;512;406|];
     [|1006;782;568;442|];
     [|1094;860;614;464|];
     [|1174;914;664;514|];
     [|1276;1000;718;538|];
     [|1370;1062;754;596|];
     [|1468;1128;808;628|];
     [|1531;1193;871;661|];
     [|1631;1267;911;701|];
     [|1735;1373;985;745|];
     (**)
     [|1843;1455;1033;793|];
     [|1955;1541;1115;845|];
     [|2071;1631;1171;901|];
     [|2191;1725;1231;961|];
     [|2306;1812;1286;986|];
     [|2434;1914;1354;1054|];
     [|2566;1992;1426;1096|];
     [|2702;2102;1502;1142|];
     [|2812;2216;1582;1222|];
     [|2956;2334;1666;1276|] |]

let test_data_bytes (`V v as version) ec_level_idx =
  assert (Qrc.Prop.data_bytes version (ec_level_of_idx ec_level_idx) =
          version_data_bytes.(v - 1).(ec_level_idx))

let version_block_spec = (* Table 9 *)
  (* From table 9, 'Number of error correction blocks',
     'total codewords (c)', 'data codewords (k)' once (only 1 group)
     or twice (two groups). Indexed by version-1 and ec_level *)
  [|
    [| [|1; 26; 19|]; [|1; 26; 16|]; [|1; 26; 13|]; [|1; 26; 9|]; |];
    [| [|1; 44; 34|]; [|1; 44; 28|]; [|1; 44; 22|]; [|1; 44; 16|]; |];
    [| [|1; 70; 55|]; [|1; 70; 44|]; [|2; 35; 17|]; [|2; 35; 13|]; |];
    [| [|1; 100; 80|]; [|2; 50; 32|]; [|2; 50; 24|]; [|4; 25; 9|]; |];
    [| [|1; 134; 108|]; [|2; 67; 43|]; [|2; 33; 15; 2; 34; 16|];
       [|2; 33; 11; 2; 34; 12|]; |];
    [| [|2; 86; 68|]; [|4; 43; 27|]; [|4; 43; 19|]; [|4; 43; 15|]; |];
    [| [|2; 98; 78|]; [|4; 49; 31|]; [|2; 32; 14; 4; 33; 15|];
       [|4; 39; 13; 1; 40; 14|] |];
    [| [|2; 121; 97|]; [|2; 60; 38; 2; 61; 39|];
       [|4; 40; 18; 2; 41; 19|]; [|4; 40; 14; 2; 41; 15|]; |];
    [| [|2; 146; 116|]; [|3; 58; 36; 2; 59; 37|]; [|4; 36; 16; 4; 37; 17|];
       [|4; 36; 12; 4; 37; 13|]; |];
    [| [|2; 86; 68; 2; 87; 69|]; [|4; 69; 43; 1; 70; 44|];
       [|6; 43; 19; 2; 44; 20|]; [|6; 43; 15; 2; 44; 16|]; |];
    (**)
    [| [|4; 101; 81|]; [|1; 80; 50; 4; 81; 51|]; [|4; 50; 22; 4; 51; 23|];
       [|3; 36; 12; 8; 37; 13|]; |];
    [| [|2; 116; 92; 2; 117; 93|]; [|6; 58; 36; 2; 59; 37|];
       [|4; 46; 20; 6; 47; 21|]; [|7; 42; 14; 4; 43; 15|]; |];
    [| [|4; 133; 107|]; [|8; 59; 37; 1; 60; 38|];
       [|8; 44; 20; 4; 45; 21|]; [|12; 33; 11; 4; 34; 12|]; |];
    [| [|3; 145; 115; 1; 146; 116|]; [|4; 64; 40; 5; 65; 41|];
       [|11; 36; 16; 5; 37; 17|]; [|11; 36; 12; 5; 37; 13|]; |];
    [| [|5; 109; 87; 1; 110; 88|]; [|5; 65; 41; 5; 66; 42|];
       [|5; 54; 24; 7; 55; 25|]; [|11; 36; 12; 7; 37; 13|]; |];
    [| [|5; 122; 98; 1; 123; 99|]; [|7; 73; 45; 3; 74; 46|];
       [|15; 43; 19; 2; 44; 20|]; [|3; 45; 15; 13; 46; 16|]; |];
    [| [|1; 135; 107; 5; 136; 108|]; [|10; 74; 46; 1; 75; 47|];
       [|1; 50; 22; 15; 51; 23|]; [|2; 42; 14; 17; 43; 15|] |];
    [| [|5; 150; 120; 1; 151; 121|]; [|9; 69; 43; 4; 70; 44|];
       [|17; 50; 22; 1; 51; 23|]; [|2; 42; 14; 19; 43; 15|]; |];
    [| [|3; 141; 113; 4; 142; 114|]; [|3; 70; 44; 11; 71; 45|];
       [|17; 47; 21; 4; 48; 22|]; [|9; 39; 13; 16; 40; 14|]; |];
    [| [|3; 135; 107; 5; 136; 108|]; [|3; 67; 41; 13; 68; 42|];
       [|15; 54; 24; 5; 55; 25|]; [|15; 43; 15; 10; 44; 16|]; |];
    (**)
    [| [|4; 144; 116; 4; 145; 117|]; [|17; 68; 42|];
       [|17; 50; 22; 6; 51; 23|]; [|19; 46; 16; 6; 47; 17|]; |];
    [| [|2; 139; 111; 7; 140; 112|]; [|17; 74; 46|]; [|7; 54; 24; 16; 55; 25|];
       [|34; 37; 13|]; |];
    [| [|4; 151; 121; 5; 152; 122|]; [|4; 75; 47; 14; 76; 48|];
       [|11; 54; 24; 14; 55; 25|]; [|16; 45; 15; 14; 46; 16|]; |];
    [| [|6; 147; 117; 4; 148; 118|]; [|6; 73; 45; 14; 74; 46|];
       [|11; 54; 24; 16; 55; 25|]; [|30; 46; 16; 2; 47; 17|] |];
    [| [|8; 132; 106; 4; 133; 107|]; [|8; 75; 47; 13; 76; 48|];
       [|7; 54; 24; 22; 55; 25|]; [|22; 45; 15; 13; 46; 16|]; |];
    [| [|10; 142; 114; 2; 143; 115|]; [|19; 74; 46; 4; 75; 47|];
       [|28; 50; 22; 6; 51; 23|]; [|33; 46; 16; 4; 47; 17|]; |];
    [| [|8; 152; 122; 4; 153; 123|]; [|22; 73; 45; 3; 74; 46|];
       [|8; 53; 23; 26; 54; 24|]; [|12; 45; 15; 28; 46; 16|]; |];
    [| [|3; 147; 117; 10; 148; 118|]; [|3; 73; 45; 23; 74; 46|];
       [|4; 54; 24; 31; 55; 25|]; [|11; 45; 15; 31; 46; 16|]; |];
    [| [|7; 146; 116; 7; 147; 117|]; [|21; 73; 45; 7; 74; 46|];
       [|1; 53; 23; 37; 54; 24|]; [|19; 45; 15; 26; 46; 16|]; |];
    [| [|5; 145; 115; 10; 146; 116|]; [|19; 75; 47; 10; 76; 48|];
       [|15; 54; 24; 25; 55; 25|]; [|23; 45; 15; 25; 46; 16|]; |];
    (**)
    [| [|13; 145; 115; 3; 146; 116|]; [|2; 74; 46; 29; 75; 47|];
       [|42; 54; 24; 1; 55; 25|]; [|23; 45; 15; 28; 46; 16|]; |];
    [| [|17; 145; 115|]; [|10; 74; 46; 23; 75; 47|];
       [|10; 54; 24; 35; 55; 25|]; [|19; 45; 15; 35; 46; 16|]; |];
    [| [|17; 145; 115; 1; 146; 116|]; [|14; 74; 46; 21; 75; 47|];
       [|29; 54; 24; 19; 55; 25|]; [|11; 45; 15; 46; 46; 16|]; |];
    [| [|13; 145; 115; 6; 146; 116|]; [|14; 74; 46; 23; 75; 47|];
       [|44; 54; 24; 7; 55; 25|]; [|59; 46; 16; 1; 47; 17|]; |];
    [| [|12; 151; 121; 7; 152; 122|]; [|12; 75; 47; 26; 76; 48|];
       [|39; 54; 24; 14; 55; 25|]; [|22; 45; 15; 41; 46; 16|]; |];
    [| [|6; 151; 121; 14; 152; 122|]; [|6; 75; 47; 34; 76; 48|];
       [|46; 54; 24; 10; 55; 25|]; [|2; 45; 15; 64; 46; 16|]; |];
    [| [|17; 152; 122; 4; 153; 123|]; [|29; 74; 46; 14; 75; 47|];
       [|49; 54; 24; 10; 55; 25|]; [|24; 45; 15; 46; 46; 16|]; |];
    [| [|4; 152; 122; 18; 153; 123|]; [|13; 74; 46; 32; 75; 47|];
       [|48; 54; 24; 14; 55; 25|]; [|42; 45; 15; 32; 46; 16|]; |];
    [| [|20; 147; 117; 4; 148; 118|]; [|40; 75; 47; 7; 76; 48|];
       [|43; 54; 24; 22; 55; 25|]; [|10; 45; 15; 67; 46; 16|]; |];
    [| [|19; 148; 118; 6; 149; 119|]; [|18; 75; 47; 31; 76; 48|];
       [|34; 54; 24; 34; 55; 25|]; [|20; 45; 15; 61; 46; 16|]; |]
  |]

type block_spec =
  { ec_bytes_per_block : int;
    g1_blocks : int;
    g1_data_bytes : int;
    g2_blocks : int; (* Those are larger by 1 *)
    g2_data_bytes : int }

let block_spec v ec_level =
  let dm = Qrc.Prop.total_bytes v in
  let blocks = Qrc.Prop.ec_blocks v ec_level in
  let ec_bytes_per_block = Qrc.Prop.ec_bytes v ec_level / blocks in
  let g1_blocks = blocks - (dm mod blocks) in
  let g2_blocks = dm mod blocks in
  let g1_data_bytes = (dm / blocks) - ec_bytes_per_block in
  let g2_data_bytes = if g2_blocks = 0 then 0 else g1_data_bytes + 1
  in
  { ec_bytes_per_block;
    g1_blocks; g1_data_bytes;
    g2_blocks; g2_data_bytes; }

let test_block_spec (`V v as version) ec_level_idx =
  let ec_level = ec_level_of_idx ec_level_idx in
  let f = version_block_spec.(v - 1).(ec_level_idx) in
  let b = block_spec version ec_level in
  assert (f.(0) = b.g1_blocks);
  assert (f.(1) = b.g1_data_bytes + b.ec_bytes_per_block);
  assert (f.(2) = b.g1_data_bytes);
  if b.g2_blocks = 0 then assert (Array.length f = 3) else
  begin
    assert (f.(3) = b.g2_blocks);
    assert (f.(4) = b.g2_data_bytes + b.ec_bytes_per_block);
    assert (f.(5) = b.g2_data_bytes);
  end

(* Galois field and Reed-Solomon generator polynomials *)

let test_gf_256 () =
  let module Gf_256 = Qrc.Gf_256 in
  let f = Lazy.force Qrc.Prop.field in
  for i = 0 to 254 do
    assert (Gf_256.log f (Gf_256.exp f i) = i);
    assert (Gf_256.log f (Gf_256.exp f (i + 255)) = i);
  done;
  for i = 1 to 255 do
    assert (Gf_256.exp f (Gf_256.log f i) = i);
    assert (Gf_256.mul f i (Gf_256.inv f i) = 1);
  done;
  assert (Gf_256.exp f 0 = 1);
  assert (Gf_256.log f 0 = 255);
  assert (Gf_256.inv f 0 = 0);
  ()

let generator_polynomial_exps =
  (* Table A.1, 'Number of error correction codewords',
     'Generator polynomial' (exponents, the coefficient is 2^e)
     Trimmed to to actual number of error correction bytes used in QR codes. *)
  [
    7,  [|0; 87; 229; 146; 149; 238; 102; 21|];
    10, [|0; 251; 67; 46; 61; 118; 70; 64; 94; 32; 45|];
    13, [|0; 74; 152; 176; 100; 86; 100; 106; 104; 130; 218; 206; 140; 78|];
    15, [|0; 8; 183; 61; 91; 202; 37; 51; 58; 58; 237; 140; 124; 5; 99; 105|];
    16, [|0; 120; 104; 107; 109; 102; 161; 76; 3; 91; 191; 147; 169; 182; 194;
          225; 120|];
    17, [|0; 43; 139; 206; 78; 43; 239; 123; 206; 214; 147; 24; 99; 150; 39;
          243; 163; 136|];
    18, [|0; 215; 234; 158; 94; 184; 97; 118; 170; 79; 187; 152; 148; 252;
          179; 5; 98; 96; 153|];
    20, [|0; 17; 60; 79; 50; 61; 163; 26; 187; 202; 180; 221; 225; 83; 239; 156;
          164; 212; 212; 188; 190|];
    22, [|0; 210; 171; 247; 242; 93; 230; 14; 109; 221; 53; 200; 74; 8; 172; 98;
          80; 219; 134; 160; 105; 165; 231|];
    24, [|0; 229; 121; 135; 48; 211; 117; 251; 126; 159; 180; 169; 152; 192;
          226; 228; 218; 111; 0; 117; 232; 87; 96; 227; 21|];
    26, [|0; 173; 125; 158; 2; 103; 182; 118; 17; 145; 201; 111; 28; 165; 53;
          161; 21; 245; 142; 13; 102; 48; 227; 153; 145; 218; 70|];
    28, [|0; 168; 223; 200; 104; 224; 234; 108; 180; 110; 190; 195; 147; 205;
          27; 232; 201; 21; 43; 245; 87; 42; 195; 212; 119; 242; 37; 9; 123|];
    30, [|0; 41; 173; 145; 152; 216; 31; 179; 182; 50; 48; 110; 86; 239; 96;
          222; 125; 42; 173; 226; 193; 224; 130; 156; 37; 251; 216; 238; 40;
          192; 180|]
  ]

let test_generator_polynomials () =
  let field = Lazy.force Qrc.Prop.field in
  let of_exp (ec, exps) = ec, Array.map (Qrc.Gf_256.exp field) exps in
  let gens = List.map of_exp generator_polynomial_exps in
  let ec_dom = (* Check we only use these [ec] byte counts *)
    let module Iset = Set.Make (Int) in
    let acc = ref Iset.empty in
    for v = 1 to 40 do
      for ec_level = 0 to 3 do
        let ec_level = ec_level_of_idx ec_level in
        let ec_bytes = Qrc.Prop.ec_bytes (`V v) ec_level in
        let ec_blocks = Qrc.Prop.ec_blocks (`V v) ec_level in
        acc := Iset.add (ec_bytes / ec_blocks) !acc
      done
    done;
    Iset.elements !acc
  in
  let gens' = List.map (fun ec -> ec, Qrc.Prop.gen field ec) ec_dom in
  assert (gens = gens');
  ()

let main () =
  for v = 1 to 40 do
    let v = (`V v) in
    test_align_pats v;
    test_total_bytes v;
    for ec_level = 0 to 3 do
      test_data_bytes v ec_level;
      test_block_spec v ec_level;
    done;
  done;
  test_gf_256 ();
  test_generator_polynomials ();
  Printf.printf "Success!\n%!";
  ()

let () = if !Sys.interactive then () else main ()

(*---------------------------------------------------------------------------
   Copyright (c) 2020 The qrc programmers

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
