<?php
// Koneksi ke database
$koneksi = mysqli_connect("localhost", "fausin", "anggita", "app");

// Periksa koneksi
if(mysqli_connect_errno()){
    echo "Koneksi database gagal : " . mysqli_connect_error();
}

// Ambil nilai ID yang akan dihapus dari form
$id = $_POST['id'];

// Query untuk menghapus data dari tabel bulanan
$query = "DELETE FROM bulanan WHERE id='$id'";

$result = mysqli_query($koneksi, $query);

// Periksa apakah penghapusan data berhasil atau tidak
if($result){
    echo "Data berhasil dihapus.";
} else {
    echo "Error: " . $query . "<br>" . mysqli_error($koneksi);
}

// Tutup koneksi database
mysqli_close($koneksi);
?>
