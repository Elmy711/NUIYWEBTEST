# Web Load Tester

Script bash sederhana berbasis `curl` untuk load testing sebuah URL/endpoint.

## Fitur

- Concurrency & total request configurable
- Rotasi otomatis User-Agent (8 pilihan) & Referer (5 pilihan)
- 14 header default bawaan (Accept, Sec-Fetch-*, dll)
- Support cookie, header custom, method, dan body
- Random delay (jitter) antar request
- Retry otomatis kalau request gagal
- Laporan: total sukses/gagal, RPS, latency min/avg/max, distribusi status code, total retry

## Requirement

- Bash, `curl`, `awk`, `xargs` (standar di Linux/macOS)

## Instalasi

```bash
chmod +x nuiytest.sh
```

## Penggunaan

```bash
bash nuiytest.sh -u <url> [opsi]
```

| Opsi | Keterangan | Default |
|---|---|---|
| `-u` | URL target (wajib) | - |
| `-n` | Total request | 100 |
| `-c` | Concurrency | 10 |
| `-m` | HTTP method | GET |
| `-H` | Header custom (bisa berulang) | - |
| `-d` | Body request | - |
| `-t` | Timeout (detik) | 10 |
| `-b` | Cookie string | - |
| `-r` | Referer tetap (kosong = acak) | acak |
| `-j` | Jitter max (detik) | 0 |
| `-R` | Jumlah retry | 0 |

## Contoh

```bash
bash nuiytest.sh -u https://example.com -n 500 -c 20

bash nuiytest.sh -u https://api.example.com/login \
  -m POST -d '{"user":"a"}' \
  -H "Content-Type: application/json" \
  -b "session=abc123" -j 0.5 -R 3
```
