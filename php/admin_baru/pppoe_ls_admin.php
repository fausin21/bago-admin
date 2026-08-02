<?php
include "../kon.php";
// Aktifkan error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);


// Contoh link untuk PPPOE LS_ADMIN:
// http://210.79.146.50:1800/api/admin/pppoe_ls_admin.php?id=1 (untuk Bago)
// http://210.79.146.50:1800/api/admin/pppoe_ls_admin.php?id=2 (untuk Mulyadi)

// Function to format number into Rupiah currency
function rupiah($angka)
{
    $hasil_rupiah = "Rp " . number_format($angka, 2, ',', '.');
    return $hasil_rupiah;
}

if (!isset($_GET['id'])) {
    die("ID teknisi tidak ditemukan");
}

$id_teknisi = mysqli_real_escape_string($koneksi, $_GET['id']);

// SQL query - filter status LS_ADMIN
$ambil = "SELECT 
    p.id_pelanggan, 
    p.nama, 
    p.alamat, 
    p.no_hp, 
    t.id_tagihan, 
    t.bulan, 
    t.tahun, 
    t.tagihan, 
    t.status, 
    t.tgl_bayar,
    p.id_teknisi
FROM 
    tb_pelanggan p
INNER JOIN 
    tb_tagihan t ON p.id_pelanggan = t.id_pelanggan
WHERE 
    t.status = 'LS_ADMIN' 
    AND p.id_teknisi = '$id_teknisi'
ORDER BY 
    t.tgl_bayar ASC";

$hasil = mysqli_query($koneksi, $ambil);

if (!$hasil) {
    die("Query error: " . mysqli_error($koneksi));
}

$tampil = array();

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

while ($data = mysqli_fetch_assoc($hasil)) {
    $tampil[] = array(
        'id' => $data['id_tagihan'],
        'user' => $data['nama'],
        'tagihan' => $data['tagihan'],
        'bulan' => $data['bulan'],
        'tahun' => $data['tahun'],
        'tgl_bayar' => $data['tgl_bayar'],
        'status' => $data['status'],
        'no_hp' => $data['no_hp'],
        'teknisi_name' => isset($teknisi_names[$data['id_teknisi']]) ? $teknisi_names[$data['id_teknisi']] : ''
    );
}

// Output the JSON
header('Content-Type: application/json');
echo json_encode($tampil);
?>