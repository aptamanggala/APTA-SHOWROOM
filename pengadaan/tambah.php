<?php
// Input pengadaan: sp_tambah_pengadaan (header) lalu sp_tambah_detail_pengadaan per barang.
// Subtotal, PPN, dan total dihitung di database (fn_subtotal_pengadaan, fn_hitung_ppn, fn_total_pengadaan).
require __DIR__ . '/../includes/crud.php';

$pdo    = db();
$err    = [];
$vendor = $pdo->query("SELECT idvendor, nama_vendor FROM vendor WHERE status = 'A' ORDER BY nama_vendor")->fetchAll(PDO::FETCH_KEY_PAIR);
$users  = $pdo->query('SELECT iduser, username FROM `user` ORDER BY username')->fetchAll(PDO::FETCH_KEY_PAIR);
$barang = $pdo->query('SELECT idbarang, nama, harga FROM barang WHERE status = 1 ORDER BY nama')->fetchAll(PDO::FETCH_UNIQUE);

$pVendor = (string) ($_POST['vendor'] ?? '');
$pUser   = (string) ($_POST['user'] ?? '');
$pBarang = array_values((array) ($_POST['barang'] ?? []));
$pJumlah = array_values((array) ($_POST['jumlah'] ?? []));

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!isset($vendor[$pVendor])) { $err[] = 'Vendor wajib dipilih (hanya vendor aktif).'; }
    if (!isset($users[$pUser]))    { $err[] = 'User wajib dipilih.'; }

    $items = []; // idbarang => jumlah (barang yang sama digabung)
    foreach ($pBarang as $i => $b) {
        $b = (string) $b;
        $j = trim((string) ($pJumlah[$i] ?? ''));
        if ($b === '' && $j === '') { continue; }
        if (!isset($barang[$b])) { $err[] = 'Baris ' . ($i + 1) . ': barang tidak valid.'; continue; }
        if (filter_var($j, FILTER_VALIDATE_INT) === false || (int) $j <= 0) {
            $err[] = 'Baris ' . ($i + 1) . ': jumlah harus bilangan bulat lebih dari 0.';
            continue;
        }
        $items[$b] = ($items[$b] ?? 0) + (int) $j;
    }
    if (!$items && !$err) { $err[] = 'Minimal satu barang harus diisi.'; }

    if (!$err) {
        $id = 0;
        try {
            // Tidak memakai transaksi PHP: sp_tambah_detail_pengadaan sudah START TRANSACTION/COMMIT sendiri
            // (akan meng-commit transaksi luar). Kalau ada detail yang gagal, header + detail dibersihkan manual.
            $pdo->prepare('CALL sp_tambah_pengadaan(?, ?, @idpengadaan)')->execute([(int) $pUser, (int) $pVendor]);
            $id = (int) $pdo->query('SELECT @idpengadaan')->fetchColumn();
            $st = $pdo->prepare('CALL sp_tambah_detail_pengadaan(?, ?, ?)');
            foreach ($items as $idbarang => $jumlah) {
                $st->execute([$id, (int) $idbarang, $jumlah]);
            }
            flash('ok', 'Pengadaan #' . $id . ' berhasil dibuat.');
            pindah('detail.php?id=' . $id);
        } catch (PDOException $e) {
            if ($id > 0) {
                try {
                    $pdo->prepare('DELETE FROM detail_pengadaan WHERE idpengadaan = ?')->execute([$id]);
                    $pdo->prepare('DELETE FROM pengadaan WHERE idpengadaan = ?')->execute([$id]);
                } catch (PDOException $e2) {
                    error_log($e2->getMessage());
                }
            }
            $err[] = pesan_db($e);
        }
    }
}

$judul     = 'Tambah pengadaan';
$kodeAktif = 'pengadaan';
$base      = '../';
$jumlahBaris = max(1, count($pBarang));

include __DIR__ . '/../includes/header.php'; ?>
<?php foreach ($err as $e): ?><div class="pesan err"><?= h($e) ?></div><?php endforeach; ?>

<div class="kotak"><form method="post" class="form form-lebar" novalidate>
    <label>Vendor *
        <select name="vendor">
            <option value="">— pilih —</option>
            <?php foreach ($vendor as $id => $nama): ?>
                <option value="<?= h($id) ?>"<?= $pVendor === (string) $id ? ' selected' : '' ?>><?= h($nama) ?></option>
            <?php endforeach; ?>
        </select>
    </label>
    <label>Dibuat oleh *
        <select name="user">
            <option value="">— pilih —</option>
            <?php foreach ($users as $id => $nama): ?>
                <option value="<?= h($id) ?>"<?= $pUser === (string) $id ? ' selected' : '' ?>><?= h($nama) ?></option>
            <?php endforeach; ?>
        </select>
    </label>

    <div>
        <div style="font-weight:600;font-size:14px;margin-bottom:6px">Barang *</div>
        <div id="daftar-item">
            <?php for ($i = 0; $i < $jumlahBaris; $i++): ?>
                <div class="baris-item">
                    <select name="barang[]">
                        <option value="">— pilih barang —</option>
                        <?php foreach ($barang as $idb => $b): ?>
                            <option value="<?= h($idb) ?>"<?= (string) ($pBarang[$i] ?? '') === (string) $idb ? ' selected' : '' ?>>
                                <?= h($b['nama']) ?> — Rp <?= h(number_format((float) $b['harga'], 0, ',', '.')) ?> juta
                            </option>
                        <?php endforeach; ?>
                    </select>
                    <input type="number" name="jumlah[]" min="1" step="1" placeholder="Jumlah" value="<?= h($pJumlah[$i] ?? '') ?>">
                    <button class="btn bahaya" type="button" data-hapus>Hapus</button>
                </div>
            <?php endfor; ?>
        </div>
        <button class="btn" type="button" id="tambah-baris">+ Tambah barang</button>
    </div>

    <div><button class="btn utama" type="submit">Simpan pengadaan</button> <a class="btn" href="index.php">Batal</a></div>
</form></div>

<script>
(function () {
    var daftar = document.getElementById('daftar-item');
    var kosong = daftar.firstElementChild.cloneNode(true);
    kosong.querySelector('select').value = '';
    kosong.querySelector('input').value = '';

    document.getElementById('tambah-baris').addEventListener('click', function () {
        daftar.appendChild(kosong.cloneNode(true));
    });
    daftar.addEventListener('click', function (e) {
        if (!e.target.hasAttribute('data-hapus')) { return; }
        if (daftar.children.length > 1) {
            e.target.closest('.baris-item').remove();
        } else {
            var b = daftar.firstElementChild;
            b.querySelector('select').value = '';
            b.querySelector('input').value = '';
        }
    });
})();
</script>
<?php include __DIR__ . '/../includes/footer.php';
