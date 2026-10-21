USE db_pbd;


-- v_satuan
CREATE OR REPLACE VIEW v_satuan AS
SELECT
  s.idsatuan,
  s.nama_satuan,
  CASE s.status
    WHEN 1 THEN 'Aktif'
    ELSE 'Nonaktif'
  END AS status
FROM satuan s;
 
SELECT * FROM v_satuan;

--  v_role 
CREATE OR REPLACE VIEW v_role AS
SELECT
  r.idrole,
  r.nama_role
FROM role r;

SELECT * FROM v_role;


--  v_user
CREATE OR REPLACE VIEW v_user AS
SELECT
  u.iduser,
  u.username,
  u.idrole,
  r.nama_role
FROM `user` u
JOIN role r ON r.idrole = u.idrole;
 
SELECT * FROM v_user;

-- v_vendor 
CREATE OR REPLACE VIEW v_vendor AS
SELECT
  v.idvendor,
  v.nama_vendor,
  CASE v.badan_hukum
    WHEN 'P' THEN 'PT'
    WHEN 'C' THEN 'CV'
    WHEN 'U' THEN 'UD/Perorangan'
    ELSE v.badan_hukum
  END AS badan_hukum,
  CASE v.status
    WHEN 'A' THEN 'Aktif'
    WHEN 'N' THEN 'Nonaktif'
    ELSE v.status
  END AS status
FROM vendor v;
 
SELECT * FROM v_vendor;
 
-- v_barang 
CREATE OR REPLACE VIEW v_barang AS
SELECT
  b.idbarang,
  CASE b.jenis
    WHEN 'B' THEN 'Baru'
    WHEN 'S' THEN 'Bekas'
    ELSE b.jenis
  END AS jenis,
  b.nama,
  b.idsatuan,
  s.nama_satuan,
  CASE b.status
    WHEN 1 THEN 'Aktif'
    ELSE 'Nonaktif'
  END AS status,
  b.harga
FROM barang b
JOIN satuan s ON s.idsatuan = b.idsatuan;
 
SELECT * FROM v_barang;
 
--  v_margin_penjualan 
CREATE OR REPLACE VIEW v_margin_penjualan AS
SELECT
  m.idmargin_penjualan,
  m.persen,
  m.status,
  m.iduser,
  u.username,
  m.created_at,
  m.updated_at
FROM margin_penjualan m
JOIN `user` u ON u.iduser = m.iduser;
 
SELECT * FROM v_margin_penjualan;