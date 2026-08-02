<?php
include "../kon.php";
	$tanggal = date("Y-m-d");

    if(isset($_GET['kode'])){
        $sql_cek = "SELECT * FROM tb_tagihan WHERE id_tagihan='".$_GET['kode']."'";
        $query_cek = mysqli_query($koneksi, $sql_cek);
        $data_cek = mysqli_fetch_array($query_cek,MYSQLI_BOTH);
	}

    // Default status LS, jika admin kirim parameter sts=LS_ADMIN maka pakai LS_ADMIN
    if(isset($_GET['sts']) && $_GET['sts'] == 'LS_ADMIN'){
        $status_bayar = 'LS_ADMIN';
    } else {
        $status_bayar = 'LS';
    }
	
    $sql_ubah = "UPDATE tb_tagihan SET
		status='".$status_bayar."',
        tgl_bayar='".$tanggal."'
        WHERE id_tagihan='".$_GET['kode']."'";
    $query_ubah = mysqli_query($koneksi, $sql_ubah);
    echo "sukses Update";

    ?>
 
