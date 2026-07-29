#!/usr/bin/env bash
#
# web-load-tester.sh
# Load tester sederhana berbasis curl untuk menguji beban sebuah URL.
#
# Penggunaan:
#   ./web-load-tester.sh -u <url> [-n total_requests] [-c concurrency] [-m method] [-H "header"] [-d "body"] [-t timeout]
#
# Contoh:
#   ./web-load-tester.sh -u https://example.com -n 500 -c 20
#   ./web-load-tester.sh -u https://api.example.com/login -m POST -d '{"user":"a"}' -H "Content-Type: application/json" -n 200 -c 10
#
set -euo pipefail

URL=""
TOTAL=100
CONCURRENCY=10
METHOD="GET"
HEADERS=()
BODY=""
TIMEOUT=10
COOKIE=""
REFERER=""
JITTER=0
RETRIES=0
OUTDIR=$(mktemp -d)

# Daftar User-Agent untuk dirotasi acak tiap request.
USER_AGENTS=(
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:126.0) Gecko/20100101 Firefox/126.0"
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
  "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36"
  "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edg/124.0.0.0 Safari/537.36"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0 Safari/537.36"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Safari/537.36"
  "Mozilla/5.0 (Windows NT 11.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0 Safari/537.36"
  "Mozilla/5.0 (X11; Linux x86_64; rv:125.0) Gecko/20100101 Firefox/125.0"
  "Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5; rv:126.0) Gecko/20100101 Firefox/126.0"
  "Mozilla/5.0 (iPad; CPU OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Mobile/15E148 Safari/604.1"
  "Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36"
  "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0 Mobile Safari/537.36"
  "Mozilla/5.0 (Linux; Android 14; SM-A546E) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36 EdgA/124.0"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edg/123.0.0.0 Safari/537.36"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) OPR/109.0.0.0 Safari/537.36"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/537.36 (KHTML, like Gecko) OPR/109.0.0.0 Safari/537.36"
  "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
  "Mozilla/5.0 (X11; CrOS x86_64 15393.85.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
  "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36"
  "Mozilla/5.0 (Windows Phone 10.0; Android 10.0; Microsoft; Lumia 950) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36 Edge/124.0"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6 Safari/605.1.15"
  "Mozilla/5.0 (Linux; Android 12; M2101K6G) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Mobile Safari/537.36"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0 Safari/537.36"
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15"
  "Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36"
  "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"
)

# Daftar Referer acak (dipakai kalau -r tidak diisi).
REFERERS=(
  "https://www.google.com/"
  "https://www.bing.com/"
  "https://www.facebook.com/"
  "https://twitter.com/"
  "https://www.instagram.com/"
  "https://www.youtube.com/"
  "https://duckduckgo.com/"
  "https://www.linkedin.com/"
  "https://www.reddit.com/"
  "https://www.tiktok.com/"
  "https://www.yahoo.com/"
  "https://www.pinterest.com/"
  "https://news.google.com/"
  "https://www.baidu.com/"
  "https://www.whatsapp.com/"
)

# Header default bawaan (otomatis dipakai di setiap request).
# Edit di sini kalau mau ubah default, atau override lewat -H saat menjalankan script.
DEFAULT_HEADERS=(
  -H "Accept: text/html,application/json,*/*;q=0.9"
  -H "Accept-Language: id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7"
  -H "Connection: keep-alive"
  -H "Accept-Encoding: gzip, deflate, br"
  -H "Cache-Control: no-cache"
  -H "Pragma: no-cache"
  -H "Upgrade-Insecure-Requests: 1"
  -H "Sec-Fetch-Dest: document"
  -H "Sec-Fetch-Mode: navigate"
  -H "Sec-Fetch-Site: none"
  -H "Sec-Fetch-User: ?1"
  -H "Sec-Ch-Ua: \"Chromium\";v=\"124\", \"Not:A-Brand\";v=\"99\""
  -H "DNT: 1"
)

usage() {
  echo "Usage: $0 -u <url> [-n total] [-c concurrency] [-m method] [-H 'Header: value'] [-d 'body'] [-t timeout_seconds] [-b 'cookie_string'] [-r referer_url] [-j jitter_max_seconds] [-R retries]"
  exit 1
}

while getopts "u:n:c:m:H:d:t:b:r:j:R:h" opt; do
  case "$opt" in
    u) URL="$OPTARG" ;;
    n) TOTAL="$OPTARG" ;;
    c) CONCURRENCY="$OPTARG" ;;
    m) METHOD="$OPTARG" ;;
    H) HEADERS+=("-H" "$OPTARG") ;;
    d) BODY="$OPTARG" ;;
    t) TIMEOUT="$OPTARG" ;;
    b) COOKIE="$OPTARG" ;;
    r) REFERER="$OPTARG" ;;
    j) JITTER="$OPTARG" ;;
    R) RETRIES="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

[[ -z "$URL" ]] && usage

echo "=================================================="
echo " Web Load Tester"
echo "=================================================="
echo " URL          : $URL"
echo " Method       : $METHOD"
echo " Total Req    : $TOTAL"
echo " Concurrency  : $CONCURRENCY"
echo " Timeout (s)  : $TIMEOUT"
echo " Output dir   : $OUTDIR"
echo " Default Hdr  : $((${#DEFAULT_HEADERS[@]}/2)) header bawaan aktif (edit di bagian DEFAULT_HEADERS)"
echo " User-Agent   : rotasi acak (${#USER_AGENTS[@]} pilihan)"
echo " Referer      : $([[ -n "$REFERER" ]] && echo "$REFERER (tetap)" || echo "rotasi acak (${#REFERERS[@]} pilihan)")"
echo " Cookie       : $([[ -n "$COOKIE" ]] && echo "$COOKIE" || echo "(tidak ada)")"
echo " Jitter       : 0 - ${JITTER}s per request"
echo " Retry        : $RETRIES kali jika gagal"
echo "=================================================="
echo

do_request() {
  local id=$1

  # Random delay (jitter) sebelum request, biar pola traffic tidak seragam.
  if [[ "$JITTER" != "0" ]]; then
    local delay
    delay=$(awk -v max="$JITTER" 'BEGIN{srand(systime()+PROCINFO["pid"]); printf "%.3f", rand()*max}' 2>/dev/null || awk -v max="$JITTER" 'BEGIN{srand(); printf "%.3f", rand()*max}')
    sleep "$delay"
  fi

  local -a uas refs default_hdrs custom_hdrs
  mapfile -t uas < "$OUTDIR/user_agents.txt"
  mapfile -t refs < "$OUTDIR/referers.txt"
  mapfile -t default_hdrs < "$OUTDIR/default_headers.txt"
  mapfile -t custom_hdrs < "$OUTDIR/custom_headers.txt"

  local ua="${uas[$((RANDOM % ${#uas[@]}))]}"
  local ref="$REFERER"
  if [[ -z "$ref" ]]; then
    ref="${refs[$((RANDOM % ${#refs[@]}))]}"
  fi

  local METHOD_UPPER
  METHOD_UPPER=$(echo "$METHOD" | tr '[:lower:]' '[:upper:]')

  local args=(-s -o /dev/null -w "%{http_code} %{time_total}\n" --max-time "$TIMEOUT")
  if [[ "$METHOD_UPPER" == "HEAD" ]]; then
    # HEAD: jangan ambil/expect body sama sekali.
    args+=(--head)
  else
    args+=(-X "$METHOD_UPPER")
    if [[ -n "$BODY" ]]; then
      args+=(-d "$BODY")
    fi
  fi
  # Default headers dulu, baru custom headers (-H) di belakang supaya bisa override curl duplicate header behavior.
  local h
  for h in "${default_hdrs[@]}"; do
    [[ -n "$h" ]] && args+=(-H "$h")
  done
  args+=(-H "User-Agent: $ua")
  args+=(-H "Referer: $ref")
  if [[ -n "$COOKIE" ]]; then
    args+=(-H "Cookie: $COOKIE")
  fi
  for h in "${custom_hdrs[@]}"; do
    [[ -n "$h" ]] && args+=(-H "$h")
  done

  local attempt=0
  local output=""
  local rc=1
  while [[ $attempt -le $RETRIES ]]; do
    if output=$(curl "${args[@]}" "$URL" 2>>"$OUTDIR/errors.txt"); then
      rc=0
      break
    fi
    attempt=$((attempt + 1))
    sleep 0.3
  done

  if [[ $rc -eq 0 ]]; then
    echo "$output $attempt" >> "$OUTDIR/results.txt"
  else
    echo "000 0 $attempt" >> "$OUTDIR/results.txt"
  fi
}
export -f do_request
export METHOD BODY TIMEOUT URL OUTDIR COOKIE REFERER JITTER RETRIES

START_TIME=$(date +%s.%N)

# Simpan semua list/array ke file, karena array bash tidak bisa di-export
# ke subshell yang dibuat xargs/bash -c.
printf '%s\n' "${USER_AGENTS[@]}" > "$OUTDIR/user_agents.txt"
printf '%s\n' "${REFERERS[@]}" > "$OUTDIR/referers.txt"
: > "$OUTDIR/default_headers.txt"
for ((i=1; i<${#DEFAULT_HEADERS[@]}; i+=2)); do
  echo "${DEFAULT_HEADERS[$i]}" >> "$OUTDIR/default_headers.txt"
done
: > "$OUTDIR/custom_headers.txt"
for ((i=1; i<${#HEADERS[@]}; i+=2)); do
  echo "${HEADERS[$i]}" >> "$OUTDIR/custom_headers.txt"
done

seq 1 "$TOTAL" | xargs -P "$CONCURRENCY" -I{} bash -c 'do_request "$@"' _ {}

END_TIME=$(date +%s.%N)
DURATION=$(awk "BEGIN {printf \"%.2f\", $END_TIME - $START_TIME}")

echo
echo "=================================================="
echo " Hasil"
echo "=================================================="

TOTAL_DONE=$(wc -l < "$OUTDIR/results.txt" | tr -d ' ')
SUCCESS=$(awk '$1 ~ /^2/ {c++} END{print c+0}' "$OUTDIR/results.txt")
FAILED=$((TOTAL_DONE - SUCCESS))
AVG_TIME=$(awk '{sum+=$2; n++} END{if(n>0) printf "%.4f", sum/n; else print "0"}' "$OUTDIR/results.txt")
MIN_TIME=$(awk '{print $2}' "$OUTDIR/results.txt" | sort -n | head -1)
MAX_TIME=$(awk '{print $2}' "$OUTDIR/results.txt" | sort -n | tail -1)
RPS=$(awk "BEGIN {if ($DURATION>0) printf \"%.2f\", $TOTAL_DONE/$DURATION; else print 0}")
TOTAL_RETRIES=$(awk '{sum+=$3} END{print sum+0}' "$OUTDIR/results.txt")

echo " Total selesai   : $TOTAL_DONE"
echo " Sukses (2xx)    : $SUCCESS"
echo " Gagal           : $FAILED"
echo " Total retry     : $TOTAL_RETRIES"
echo " Waktu total     : ${DURATION}s"
echo " Requests/detik  : $RPS"
echo " Latency rata2   : ${AVG_TIME}s"
echo " Latency min     : ${MIN_TIME}s"
echo " Latency max     : ${MAX_TIME}s"
echo
echo " Distribusi status code:"
awk '{print $1}' "$OUTDIR/results.txt" | sort | uniq -c | sort -rn | while read -r count code; do
  echo "   $code : $count"
done
echo "=================================================="
echo " Detail mentah tersimpan di: $OUTDIR/results.txt"
echo "=================================================="
