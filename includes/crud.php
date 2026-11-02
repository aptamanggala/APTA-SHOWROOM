<?php
// includes/crud.php — fungsi CRUD yang dipakai semua halaman tabel master.
// Definisi tabel ada di config/entities.php.

require_once __DIR__ . '/../config/database.php';

if (session_status() === PHP_SESSION_NONE) {
    session_start(); // hanya untuk pesan sukses/gagal sementara
}

// ---------- Utilitas ----------

function h($v): string
{
    return htmlspecialchars((string) $v, ENT_QUOTES, 'UTF-8');
}

function panjang_teks(string $teks): int
{
    return function_exists('mb_strlen') ? mb_strlen($teks) : strlen($teks);
}

function q(string $nama): string
{
    return '`' . str_replace('`', '', $nama) . '`';
}

function semua_entitas(): array
{
    static $e = null;
    return $e ??= require __DIR__ . '/../config/entities.php';
}

function entitas(string $kode): array
{
    $semua = semua_entitas();
    if (!isset($semua[$kode])) {
        http_response_code(404);
        exit('Tabel tidak dikenal.');
    }
    return $semua[$kode];
}

function daftar_menu(): array
{
    $m = [];
    foreach (semua_entitas() as $k => $e) {
        $m[$k] = $e['judul'];
    }
    $m['pengadaan'] = 'Pengadaan';
    $m['stok']      = 'Stok';
    return $m;
}

function pindah(string $url): void
{
    header('Location: ' . $url);
    exit;
}

function flash(string $tipe, string $teks): void
{
    $_SESSION['flash'] = [$tipe, $teks];
}

function tampil_flash(): void
{
    if (!empty($_SESSION['flash'])) {
        [$tipe, $teks] = $_SESSION['flash'];
        echo '<div class="pesan ' . h($tipe) . '">' . h($teks) . '</div>';
        unset($_SESSION['flash']);
    }
}

function tampil_nilai($nilai, string $format = ''): string
{
    if ($nilai === null || $nilai === '') {
        return '-';
    }
    switch ($format) {
        case 'status': // 1 / 0
            $on = (string) $nilai === '1';
            return '<span class="badge ' . ($on ? 'on' : 'off') . '">' . ($on ? 'Aktif' : 'Nonaktif') . '</span>';
        case 'badge': // teks 'Aktif' / 'Nonaktif' dari view
            $on = (string) $nilai === 'Aktif';
            return '<span class="badge ' . ($on ? 'on' : 'off') . '">' . h($nilai) . '</span>';
        case 'juta':
            return h('Rp ' . number_format((float) $nilai, 0, ',', '.') . ' juta');
        case 'persen':
            return h(rtrim(rtrim(number_format((float) $nilai, 2, ',', '.'), '0'), ',') . '%');
        default:
            return h($nilai);
    }
}

// ---------- Akses database ----------

function pesan_db(PDOException $e): string
{
    switch ((int) ($e->errorInfo[1] ?? 0)) {
        case 1644: return (string) ($e->errorInfo[2] ?? 'Proses ditolak oleh database.'); // SIGNAL dari SP
        case 1451: return 'Data tidak bisa dihapus karena masih dipakai di tabel lain.';
        case 1452: return 'Data rujukan (satuan, role, user, atau vendor) tidak ditemukan.';
        case 1062: return 'Data yang sama sudah ada.';
        case 1406: return 'Ada isian yang terlalu panjang.';
        case 1264: return 'Ada angka yang melebihi batas yang bisa disimpan.';
        case 1048: return 'Ada isian wajib yang kosong.';
        default:
            error_log($e->getMessage());
            return 'Terjadi kesalahan pada database. Periksa log server untuk detailnya.';
    }
}

function opsi_field(array $f): array
{
    if (is_array($f['opsi'])) {
        return $f['opsi'];
    }
    return db()->query($f['opsi'])->fetchAll(PDO::FETCH_KEY_PAIR); // [nilai => label]
}

function cari_baris(array $def, string $id): ?array
{
    $s = db()->prepare('SELECT * FROM ' . q($def['tabel']) . ' WHERE ' . q($def['pk']) . ' = ?');
    $s->execute([$id]);
    return $s->fetch() ?: null;
}

// ---------- Validasi ----------

// Mengembalikan [data_bersih, daftar_error].
function validasi(array $def, array $post, string $id = ''): array
{
    $data = [];
    $err  = [];

    foreach ($def['field'] as $nama => $f) {
        if (!empty($f['hanya_ubah']) && $id === '') {
            continue;
        }

        $label = $f['label'];
        $v     = trim((string) ($post[$nama] ?? ''));

        if ($f['tipe'] === 'password') {
            if ($v === '') {
                if ($id === '') {
                    $err[] = "$label wajib diisi.";
                }
                continue; // saat ubah: kosong = password lama dipertahankan
            }
            $data[$nama] = password_hash($v, PASSWORD_DEFAULT);
            continue;
        }

        if ($v === '') {
            if (!empty($f['wajib'])) {
                $err[] = "$label wajib diisi.";
            }
            $data[$nama] = null;
            continue;
        }

        if (isset($f['panjang']) && panjang_teks($v) > $f['panjang']) {
            $err[] = "$label maksimal {$f['panjang']} karakter.";
            continue;
        }

        if ($f['tipe'] === 'number') {
            if (!empty($f['bulat']) ? filter_var($v, FILTER_VALIDATE_INT) === false : !is_numeric($v)) {
                $err[] = "$label harus berupa angka" . (!empty($f['bulat']) ? ' bulat.' : '.');
                continue;
            }
            if (isset($f['min']) && $v < $f['min']) {
                $err[] = "$label minimal {$f['min']}.";
                continue;
            }
            if (isset($f['maks']) && $v > $f['maks']) {
                $err[] = "$label maksimal {$f['maks']}.";
                continue;
            }
        }

        if ($f['tipe'] === 'select' && !array_key_exists($v, opsi_field($f))) {
            $err[] = "$label tidak valid.";
            continue;
        }

        if (!empty($f['unik'])) {
            $s = db()->prepare('SELECT COUNT(*) FROM ' . q($def['tabel']) . ' WHERE ' . q($nama) . ' = ? AND ' . q($def['pk']) . ' <> ?');
            $s->execute([$v, $id === '' ? -1 : $id]);
            if ($s->fetchColumn() > 0) {
                $err[] = "$label \"$v\" sudah dipakai.";
                continue;
            }
        }

        $data[$nama] = $v;
    }
    return [$data, $err];
}

// ---------- Simpan ----------

function simpan_baru(array $def, array $data): void
{
    $pdo = db();

    if (!empty($def['sp_tambah'])) { // tambah lewat stored procedure (parameter terakhir = OUT id)
        $sp     = $def['sp_tambah']['sp'];
        $param  = $def['sp_tambah']['param'];
        $nilai  = array_map(fn($p) => $data[$p], $param);
        $marks  = implode(', ', array_fill(0, count($param), '?'));
        $pdo->prepare("CALL $sp($marks, @idbaru)")->execute($nilai);
        return;
    }

    $kol = array_map('q', array_keys($data));
    $ph  = array_fill(0, count($data), '?');
    $pdo->prepare('INSERT INTO ' . q($def['tabel']) . ' (' . implode(',', $kol) . ') VALUES (' . implode(',', $ph) . ')')
        ->execute(array_values($data));
}

function simpan_ubah(array $def, string $id, array $data): void
{
    $set = [];
    foreach (array_keys($data) as $k) {
        $set[] = q($k) . ' = ?';
    }
    $sql = 'UPDATE ' . q($def['tabel']) . ' SET ' . implode(', ', $set) . ' WHERE ' . q($def['pk']) . ' = ?';
    db()->prepare($sql)->execute(array_merge(array_values($data), [$id]));
}

// ---------- Halaman ----------

// Membangun query string filter (hanya parameter berawalan f_).
function url_filter(array $ubah = []): string
{
    $p = [];
    foreach ($_GET as $k => $v) {
        if (strpos((string) $k, 'f_') === 0 && is_string($v) && $v !== '') {
            $p[$k] = $v;
        }
    }
    foreach ($ubah as $k => $v) {
        if ($v === '') {
            unset($p[$k]);
        } else {
            $p[$k] = $v;
        }
    }
    return $p ? '?' . http_build_query($p) : '?';
}

function halaman_daftar(string $kode): void
{
    $def       = entitas($kode);
    $judul     = $def['judul'];
    $kodeAktif = $kode;
    $base      = '../';
    $baris     = [];
    $errDb     = '';

    $where = [];
    $par   = [];
    foreach ($def['filter'] ?? [] as $kol => $fd) {
        $v = (string) ($_GET['f_' . $kol] ?? '');
        if ($v !== '' && isset($fd['opsi'][$v])) {
            $where[] = q($kol) . ' = ?';
            $par[]   = $v;
        }
    }
    $sql = 'SELECT * FROM ' . q($def['view']) . ($where ? ' WHERE ' . implode(' AND ', $where) : '') . ' ORDER BY ' . q($def['pk']);

    try {
        $s = db()->prepare($sql);
        $s->execute($par);
        $baris = $s->fetchAll();
    } catch (PDOException $e) {
        $errDb = pesan_db($e);
    }

    include __DIR__ . '/header.php'; ?>
    <?php if ($errDb): ?><div class="pesan err"><?= h($errDb) ?></div><?php endif; ?>

    <?php foreach ($def['filter'] ?? [] as $kol => $fd): $sekarang = (string) ($_GET['f_' . $kol] ?? ''); ?>
        <div class="filter">
            <span class="label"><?= h($fd['label']) ?></span>
            <div class="pills">
                <a class="pill<?= $sekarang === '' ? ' aktif' : '' ?>" href="<?= h(url_filter(['f_' . $kol => ''])) ?>">Semua</a>
                <?php foreach ($fd['opsi'] as $nilai => $label): ?>
                    <a class="pill<?= $sekarang === (string) $nilai ? ' aktif' : '' ?>"
                       href="<?= h(url_filter(['f_' . $kol => (string) $nilai])) ?>"><?= h($label) ?></a>
                <?php endforeach; ?>
            </div>
        </div>
    <?php endforeach; ?>

    <div class="bar">
        <span><?= count($baris) ?> data</span>
        <a class="btn utama" href="tambah.php">Tambah <?= h(strtolower($judul)) ?></a>
    </div>
    <div class="kotak"><table>
        <tr><?php foreach ($def['kolom'] as $k): ?><th><?= h($k[1]) ?></th><?php endforeach; ?><th></th></tr>
        <?php if (!$baris): ?>
            <tr><td colspan="<?= count($def['kolom']) + 1 ?>" class="kosong">Tidak ada data.</td></tr>
        <?php endif; ?>
        <?php foreach ($baris as $r): $id = $r[$def['pk']]; ?>
            <tr>
                <?php foreach ($def['kolom'] as $k): ?><td><?= tampil_nilai($r[$k[0]] ?? null, $k[2] ?? '') ?></td><?php endforeach; ?>
                <td class="aksi">
                    <?php if (!empty($def['aktifkan']) && (string) ($r['status'] ?? '') !== '1'): ?>
                        <form method="post" action="aktifkan.php">
                            <input type="hidden" name="id" value="<?= h($id) ?>">
                            <button class="btn" type="submit">Aktifkan</button>
                        </form>
                    <?php endif; ?>
                    <a class="btn" href="edit.php?id=<?= urlencode((string) $id) ?>">Ubah</a>
                    <form method="post" action="hapus.php" onsubmit="return confirm('Hapus data dengan ID <?= h($id) ?>? Tindakan ini tidak bisa dibatalkan.')">
                        <input type="hidden" name="id" value="<?= h($id) ?>">
                        <button class="btn bahaya" type="submit">Hapus</button>
                    </form>
                </td>
            </tr>
        <?php endforeach; ?>
    </table></div>
    <?php include __DIR__ . '/footer.php';
}

function halaman_form(string $kode, string $mode): void
{
    $def   = entitas($kode);
    $edit  = $mode === 'edit';
    $id    = $edit ? trim((string) ($_GET['id'] ?? '')) : '';
    $baris = [];
    $err   = [];

    if ($edit) {
        $baris = cari_baris($def, $id);
        if ($baris === null) {
            flash('err', 'Data tidak ditemukan.');
            pindah('index.php');
        }
    }

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        [$data, $err] = validasi($def, $_POST, $id);
        if (!$err) {
            try {
                $edit ? simpan_ubah($def, $id, $data) : simpan_baru($def, $data);
                flash('ok', $edit ? 'Perubahan disimpan.' : 'Data ditambahkan.');
                pindah('index.php');
            } catch (PDOException $e) {
                $err[] = pesan_db($e);
            }
        }
        $baris = array_merge($baris ?? [], $_POST); // pertahankan isian saat ada error
    }

    $judul     = ($edit ? 'Ubah ' : 'Tambah ') . strtolower($def['judul']);
    $kodeAktif = $kode;
    $base      = '../';

    include __DIR__ . '/header.php'; ?>
    <?php foreach ($err as $e): ?><div class="pesan err"><?= h($e) ?></div><?php endforeach; ?>
    <div class="kotak"><form method="post" class="form" novalidate>
        <?php foreach ($def['field'] as $nama => $f):
            if (!empty($f['hanya_ubah']) && !$edit) { continue; }
            $v = $baris[$nama] ?? ''; ?>
            <label><?= h($f['label']) ?><?= !empty($f['wajib']) || ($f['tipe'] === 'password' && !$edit) ? ' *' : '' ?>
            <?php if ($f['tipe'] === 'select'): ?>
                <select name="<?= h($nama) ?>">
                    <option value="">— pilih —</option>
                    <?php foreach (opsi_field($f) as $nilai => $label): ?>
                        <option value="<?= h($nilai) ?>"<?= (string) $v === (string) $nilai ? ' selected' : '' ?>><?= h($label) ?></option>
                    <?php endforeach; ?>
                </select>
            <?php elseif ($f['tipe'] === 'password'): ?>
                <input type="password" name="<?= h($nama) ?>" autocomplete="new-password">
            <?php elseif ($f['tipe'] === 'number'): ?>
                <input type="number" name="<?= h($nama) ?>" value="<?= h($v) ?>" step="<?= !empty($f['bulat']) ? '1' : 'any' ?>"
                    <?= isset($f['min']) ? 'min="' . h($f['min']) . '"' : '' ?> <?= isset($f['maks']) ? 'max="' . h($f['maks']) . '"' : '' ?>>
            <?php else: ?>
                <input type="text" name="<?= h($nama) ?>" value="<?= h($v) ?>"<?= isset($f['panjang']) ? ' maxlength="' . (int) $f['panjang'] . '"' : '' ?>>
            <?php endif; ?>
            </label>
        <?php endforeach; ?>
        <div><button class="btn utama" type="submit">Simpan</button> <a class="btn" href="index.php">Batal</a></div>
    </form></div>
    <?php include __DIR__ . '/footer.php';
}

function proses_hapus(string $kode): void
{
    $def = entitas($kode);
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        pindah('index.php');
    }
    $id = trim((string) ($_POST['id'] ?? ''));

    try {
        if (!empty($def['aktifkan'])) { // margin yang sedang aktif tidak boleh dihapus
            $c = db()->prepare('SELECT COUNT(*) FROM ' . q($def['tabel']) . ' WHERE ' . q($def['pk']) . ' = ? AND status = 1');
            $c->execute([$id]);
            if ($c->fetchColumn() > 0) {
                flash('err', 'Margin yang sedang aktif tidak bisa dihapus. Aktifkan margin lain terlebih dahulu.');
                pindah('index.php');
            }
        }
        $s = db()->prepare('DELETE FROM ' . q($def['tabel']) . ' WHERE ' . q($def['pk']) . ' = ?');
        $s->execute([$id]);
        $s->rowCount() > 0 ? flash('ok', 'Data berhasil dihapus.') : flash('err', 'Data tidak ditemukan.');
    } catch (PDOException $e) {
        flash('err', pesan_db($e));
    }
    pindah('index.php');
}

// Mengaktifkan satu margin lewat sp_ganti_margin_aktif.
function proses_aktifkan(string $kode): void
{
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        pindah('index.php');
    }
    $id = (int) ($_POST['id'] ?? 0);
    try {
        db()->prepare('CALL sp_ganti_margin_aktif(?)')->execute([$id]);
        flash('ok', 'Margin berhasil diaktifkan.');
    } catch (PDOException $e) {
        flash('err', pesan_db($e));
    }
    pindah('index.php');
}
