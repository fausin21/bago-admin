<?php
// Koneksi ke database dan query untuk menghitung jumlah pengguna
include 'kon.php';

// Query untuk menghitung jumlah pengguna
$sql = "SELECT COUNT(*) AS total FROM tb_pelanggan";

$result = mysqli_query($koneksi, $sql);

if ($result) {
    // Ambil nilai total
    $row = mysqli_fetch_assoc($result);
    $total = (int) $row['total']; // Pastikan nilai total diubah menjadi integer

    // Format respons JSON
    $response = array(
        'total' => $total
    );

    // Mengubah array respons menjadi format JSON dan mencetaknya
    echo json_encode($response);
} else {
    // Jika terjadi kesalahan dalam eksekusi query, mengirim respons error
    echo json_encode(array('error' => 'Failed to fetch total user count'));
}

// Tutup koneksi database
mysqli_close($koneksi);
?>
