<?php
include 'kon.php';
session_start();
// menangkap data yang dikirim dari form
$username = $_POST['username'];
$password = $_POST['password'];
// menyeleksi data admin dengan username dan password yang sesuai
$data = mysqli_query($koneksi,"select * from teknisi where nomer='$username' and nomer='$password'");
// menghitung jumlah data yang ditemukan
$cek = mysqli_num_rows($data);
 // cek apakah username dan password di temukan pada database ke json
if($cek > 0){
    $_SESSION['username'] = $username;
    $_SESSION['status'] = "login";
    // ambil data dari database
    $query = mysqli_query($koneksi,"SELECT * FROM teknisi WHERE nomer='$username' and nomer='$password'");
    $data = mysqli_fetch_array($query);
    $id = $data['id'];
    $nama = $data['nama'];
    $nomer = $data['nomer'];
    echo $nama;
    
    
}
else{
  echo json_encode(array('message'=>'Username atau Password Salah'));

}


?>