<?php
//koneksi ke database
$koneksi = mysqli_connect("localhost", "fausin", "anggita", "app");

//cek koneksi
if(mysqli_connect_errno()){
    echo "Koneksi database gagal : " . mysqli_connect_error();
}

//ambil nilai dari form
// user,nohp,tagihan,tgl_masuk,cabang
$id = $_POST['id'];
$user = $_POST['user'];
$nohp = $_POST['nohp'];
$tagihan = $_POST['tagihan'];
$tgl_masuk = $_POST['tgl_masuk'];
$cabang = $_POST['cabang'];



//update data pada tabel user
$query = "UPDATE bulanan SET user='$user', nohp='$nohp', tagihan='$tagihan', tgl_masuk='$tgl_masuk', cabang='$cabang' WHERE id='$id'";

$result = mysqli_query($koneksi, $query);

//cek apakah update data berhasil atau tidak
if($result){
    echo "Update data sukses.";
} else {
    echo "Error: " . $query . "<br>" . mysqli_error($koneksi);
}

//tutup koneksi database
mysqli_close($koneksi);
?>
