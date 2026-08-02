<?php
include "kon.php";

$query = mysqli_query($koneksi, "SELECT s.id, n.user, n.tagihan, n.nohp, n.cabang, s.tgl, s.voucher, n.cabang, n.tagihan + s.voucher AS jumlah 
FROM bulanan n 
JOIN voucher s ON n.user = s.user 
WHERE s.sts = 0
AND (n.cabang = 'sentul' OR n.cabang = 'bago');
");
$data = array();
while ($row = mysqli_fetch_assoc($query)) {
    // id,user,tagihan,nohp,cabang,tgl,voucher,cabang,tagihan + voucher as jumlah
    $id= $row['id'];
    $user = $row['user'];
    $tagihan = $row['tagihan'];
    $nohp = $row['nohp'];
    $cabang = $row['cabang'];
    $tgl = $row['tgl'];
    $voucher = $row['voucher'];
    if ($voucher == "") {
        $voucher = 0;
    }
    $jumlah = $row['jumlah'];
    $data[] = array(
        'id' => $id,
        'user' => $user,
        'tagihan' => $tagihan,
        'nohp' => $nohp,
        'cabang' => $cabang,
        'tgl' => $tgl,
        'voucher' => $voucher,
        'jumlah' => $jumlah
    );
}
echo json_encode($data);
?>
