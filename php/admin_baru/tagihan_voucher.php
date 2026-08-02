<?php
include "../kon.php";
error_reporting(E_ALL);
 

// Function to format number into Rupiah currency
function rupiah($angka) {
    $hasil_rupiah = "Rp " . number_format($angka, 2, ',', '.');
    return $hasil_rupiah;
}
// SQL query
$ambil = "SELECT id_tagihan, user, cabang, bulan, tahun, t_bulan, t_voucher, total, status, tgl_bayar 
          FROM tb_tagihan_voucher 
          WHERE status='BL' AND (cabang='bago' OR cabang='sentul' OR cabang='betek' OR cabang='dandang')";

$hasil = mysqli_query($koneksi, $ambil);
$tampil = array();
if (!$hasil) {
    die("Query error: " . mysqli_error($koneksi));
}

// Mapping array for technician names
$teknisi_names = array(
    1 => 'bago',
    2 => 'MULYADI',
    3 => 'BUMAN',
    4 => 'mail',
    5 => 'as',
    6 => 'nurin',
    8 => 'mashur',
    9 => 'lukman',
    5003 => 'sudi',
    5007 => 'sohip',
    5009 => 'fausin'
);

while ($data = mysqli_fetch_array($hasil)) {
    $id = $data['id_tagihan'];
    $user = $data['user'];
    $bulan = $data['bulan'];
    $tahun = $data['tahun'];
    $t_bulan = $data['t_bulan'];
    $t_voucher = $data['t_voucher'];
    $total = $data['total'];
    $status = $data['status'];
    $cabang = $data['cabang'];
    
    // Get technician name from the mapping array
    //$teknisi_name = isset($teknisi_names[$id_teknisi]) ? $teknisi_names[$id_teknisi] : '';

    $tampil[] = array(
        'id_tagihan' => $id,
        'user' => $user,
        'bulan' => $bulan,
        'tahun' => $tahun,
        't_bulan' => $t_bulan,
        't_voucher' => $t_voucher,
        'total' => $total,
        'cabang' => $cabang
    );
}

// Output the JSON
header('Content-Type: application/json');
echo json_encode($tampil);

?>
