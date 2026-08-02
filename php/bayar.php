<?php
include "kon.php";
$tanggal = date("Y-m-d");

if (isset($_GET['kode'])) {
    $sql_cek = "SELECT * FROM tb_tagihan_voucher WHERE id_tagihan='" . $_GET['kode'] . "'";
    $query_cek = mysqli_query($koneksi, $sql_cek);
    $data_cek = mysqli_fetch_array($query_cek, MYSQLI_BOTH);
}

$status = 'LS_ADMIN';

$sql_ubah = "UPDATE tb_tagihan_voucher SET
		status='$status',
        tgl_bayar='" . $tanggal . "'
        WHERE id_tagihan='" . $_GET['kode'] . "'";
$query_ubah = mysqli_query($koneksi, $sql_ubah);

if ($query_ubah) {
    echo "<script>
        Swal.fire({title: 'Pembayaran Berhasil',text: '',icon: 'success',confirmButtonText: 'OK'
        }).then((result) => {
            if (result.value) {
                window.location = 'index.php?page=ls-voucher';
            }
        })</script>";
} else {
    echo "<script>
        Swal.fire({title: 'Pembayaran Gagal',text: '',icon: 'error',confirmButtonText: 'OK'
        }).then((result) => {
            if (result.value) {
                window.location = 'index.php?page=ls-voucher';
            }
        })</script>";
}

?>