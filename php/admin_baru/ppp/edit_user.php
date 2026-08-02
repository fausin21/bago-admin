<?php
include 'kon.php'; // File koneksi database (sesuaikan dengan nama file yang sesuai)

// Ambil data dari permintaan POST
$id_pelanggan = $_POST['id_pelanggan'];
$nama = $_POST['nama'];
$alamat = $_POST['alamat'];
$no_hp = $_POST['no_hp'];
$email = $_POST['email'];
$password = $_POST['password'];
$level = $_POST['level'];
$id_paket = $_POST['id_paket'];
$id_teknisi = $_POST['id_teknisi'];

// Query untuk mengedit data pengguna berdasarkan id_pelanggan
$sql = "UPDATE tb_pelanggan 
        SET nama='$nama', alamat='$alamat', no_hp='$no_hp', email='$email', password='$password', level='$level', id_paket='$id_paket', id_teknisi='$id_teknisi'
        WHERE id_pelanggan='$id_pelanggan'";

// Eksekusi query
if (mysqli_query($koneksi, $sql)) {
    echo json_encode(array('message' => 'User updated successfully'));
} else {
    echo json_encode(array('error' => 'Failed to update user'));
}

// Tutup koneksi database
mysqli_close($koneksi);
?>
