<?php
require __DIR__ . '/../includes/crud.php';

$id = (int) ($_GET['id'] ?? 0);

$s = db()->prepare(
    "SELECT p.idpengadaan, p.`timestamp` AS waktu, p.status, p.subtotal_nilai, p.ppn, p.total_nilai,
            v.nama_vendor, u.username
     FROM pengadaan p
     JOIN vendor v ON v.idvendor = p.vendor_idvendor
     JOIN `user` u ON u.iduser = p.user_iduser
     WHERE p.idpengadaan = ?"
);
$s->execute([$id]);
$p = $s->fetch();

if (!$p) {
    flash('err', 'Pengadaan tidak ditemukan.');
    pindah('index.php');
}

$d = db()->prepare(
    'SELECT b.nama, s.nama_satuan, dp.harga_satuan, dp.jumlah, dp.sub_total
     FROM detail_pengadaan dp
     JOIN barang b ON b.idbarang = dp.idbarang
     JOIN satuan s ON s.idsatuan = b.idsatuan
     WHERE dp.idpengadaan = ?
     ORDER BY dp.iddetail_pengadaan'
);
$d->execute([$id]);
$detail = $d->fetchAll();

$nama_status = ['P' => 'Proses', 'S' => 'Selesai'];
$judul     = 'Pengadaan #' . $p['idpengadaan'];
$kodeAktif = 'pengadaan';
$base      = '../';

include __DIR__ . '/../includes/header.php'; ?>
<div class="ringkas">
    <div><small>Vendor</small><?= h($p['nama_vendor']) ?></div>
    <div><small>Dibuat oleh</small><?= h($p['username']) ?></div>
    <div><small>Waktu</small><?= h($p['waktu']) ?></div>
    <div><small>Status</small><?= h($nama_status[$p['status']] ?? $p['status']) ?></div>
</div>

<div class="kotak"><table>
    <tr><th>Barang</th><th>Satuan</th><th class="angka">Harga satuan</th><th class="angka">Jumlah</th><th class="angka">Sub total</th></tr>
    <?php if (!$detail): ?><tr><td colspan="5" class="kosong">Belum ada detail.</td></tr><?php endif; ?>
    <?php foreach ($detail as $r): ?>
        <tr>
            <td><?= h($r['nama']) ?></td>
            <td><?= h($r['nama_satuan']) ?></td>
            <td class="angka"><?= tampil_nilai($r['harga_satuan'], 'juta') ?></td>
            <td class="angka"><?= h($r['jumlah']) ?></td>
            <td class="angka"><?= tampil_nilai($r['sub_total'], 'juta') ?></td>
        </tr>
    <?php endforeach; ?>
    <tr><td colspan="4" class="angka"><b>Subtotal</b></td><td class="angka"><?= tampil_nilai($p['subtotal_nilai'], 'juta') ?></td></tr>
    <tr><td colspan="4" class="angka"><b>PPN 11%</b></td><td class="angka"><?= tampil_nilai($p['ppn'], 'juta') ?></td></tr>
    <tr><td colspan="4" class="angka"><b>Total</b></td><td class="angka"><b><?= tampil_nilai($p['total_nilai'], 'juta') ?></b></td></tr>
</table></div>
<div class="bar"><a class="btn" href="index.php">Kembali</a></div>
<?php include __DIR__ . '/../includes/footer.php';
