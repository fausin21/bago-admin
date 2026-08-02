<?php
include 'kon.php'; // File koneksi database

// Ambil parameter pencarian jika ada
$query = isset($_GET['nama']) ? $_GET['nama'] : '';

// Query untuk menampilkan data pelanggan dengan join ke tb_paket dan teknisi
$sql = "SELECT p.*, pk.paket, pk.tarif, t.id, t.nama as nama_teknisi, t.nomer, t.cabang
        FROM tb_pelanggan p 
        LEFT JOIN tb_paket pk ON p.id_paket = pk.id_paket
        LEFT JOIN teknisi t ON p.id_teknisi = t.id";
if (!empty($query)) {
    $sql .= " WHERE p.nama LIKE '%$query%' OR p.no_hp LIKE '%$query%'";
}

// Eksekusi query
$result = mysqli_query($koneksi, $sql);

// Mengecek apakah query berhasil dieksekusi
if ($result) {
    $response = array();
    while ($row = mysqli_fetch_assoc($result)) {
        $response[] = $row;
    }
    echo json_encode($response);
} else {
    echo json_encode(array('error' => 'Failed to fetch user list'));
}

// Tutup koneksi database
mysqli_close($koneksi);
?>
