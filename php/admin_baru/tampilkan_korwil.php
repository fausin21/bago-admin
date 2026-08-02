<?php
// Koneksi ke database
$servername = "localhost";
$username = "fausin"; // Ganti dengan username database Anda
$password = "anggita"; // Ganti dengan password database Anda
$dbname = "app"; // Ganti dengan nama database Anda

// Buat koneksi
$conn = mysqli_connect($servername, $username, $password, $dbname);

// Periksa koneksi
if (!$conn) {
    die("Koneksi gagal: " . mysqli_connect_error());
}

// Ambil bulan dan tahun saat ini
$bulan_ini = date('Y-m');

// Query untuk mengambil data setoran_korwil pada bulan ini
$sql = "SELECT id, korwil, no_hp, bulanan, voucher, pppoe, total, ket 
        FROM setoran_korwil 
        WHERE DATE_FORMAT(ket, '%Y-%m') = '$bulan_ini'";

$result = mysqli_query($conn, $sql);

if (!$result) {
    die("Error: " . mysqli_error($conn));
}

// Simpan hasil query dalam array
$results = [];
while ($row = mysqli_fetch_assoc($result)) {
    $results[] = $row;
}

// Mengubah array menjadi JSON
header('Content-Type: application/json');
echo json_encode($results);

// Tutup koneksi
mysqli_close($conn);
?>
