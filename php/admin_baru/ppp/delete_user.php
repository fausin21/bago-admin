<?php
include 'kon.php'; // File koneksi database (sesuaikan dengan nama file yang sesuai)

// Ambil data dari permintaan POST
$id_pelanggan = $_POST['id_pelanggan'];

// Query untuk menghapus data pengguna berdasarkan id_pelanggan
$sql = "DELETE FROM tb_pelanggan WHERE id_pelanggan='$id_pelanggan'";

// Eksekusi query
if (mysqli_query($koneksi, $sql)) {
    echo json_encode(array('message' => 'User deleted successfully'));
} else {
    echo json_encode(array('error' => 'Failed to delete user'));
}

// Tutup koneksi database
mysqli_close($koneksi);
?>
