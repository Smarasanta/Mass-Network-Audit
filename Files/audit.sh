#!/bin/bash

# --- Konfigurasi ---
DB_FILE="host.txt"
MAX_THREADS=10  # Jumlah pengecekan bersamaan
BOT_TOKEN="7790428558:AAE1eG7vHK6U7jvdorSVVAH9YFPWWKZreTY"
CHAT_ID="8151047414"

echo "=================================================="
echo "    MASS NETWORK AUDIT TOOL v8.0 (FINAL REPORT)   "
echo "=================================================="

if [ ! -f "$DB_FILE" ]; then
    echo -e "\033[0;31m[!] Error: File '$DB_FILE' tidak ditemukan!\033[0m"
    exit 1
fi

# --- CEK JARINGAN / OPERATOR ---
echo -e "\033[1;36m[*] Memeriksa informasi jaringan...\033[0m"
ISP=$(curl -s --connect-timeout 5 "http://ip-api.com/line?fields=isp")
IP_PUB=$(curl -s --connect-timeout 5 "http://ip-api.com/line?fields=query")

ISP=${ISP:-"Tidak diketahui / Offline"}
IP_PUB=${IP_PUB:-"Unknown"}

echo -e " -> Operator : \033[1;32m$ISP\033[0m"
echo -e " -> IP Publik: \033[1;32m$IP_PUB\033[0m"
echo "--------------------------------------------------"

# Fungsi pengecekan murni per satu target
audit_single_target() {
    local target=$1
    target=$(echo "$target" | tr -d '\r' | tr -d ' ')
    [[ -z "$target" ]] && return

    # 1. Uji HTTP (Port 80)
    local http_res=$(curl -s -I --connect-timeout 2 --max-time 3 "http://$target/" -A "Mozilla/5.0")
    local status_code=$(echo "$http_res" | grep -i "HTTP/" | tail -n 1 | awk '{print $2}')
    local server_type=$(echo "$http_res" | grep -i "server:" | head -n 1 | awk '{print $2}')

    if [ "$status_code" -eq 200 ] 2>/dev/null; then
        echo "HTTP_200|$target|Server: ${server_type:-Unknown}"
    elif [ "$status_code" -eq 301 ] 2>/dev/null || [ "$status_code" -eq 302 ] 2>/dev/null; then
        local loc=$(echo "$http_res" | grep -i "location:" | awk '{print $2}' | tr -d '\r')
        echo "HTTP_REDI|Target: $target (Redirect $status_code -> ${loc:0:30}...)"
    fi

    # 2. Uji HTTPS/TLS (Port 443)
    local tls_res=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 --max-time 3 --tls-max 1.3 "https://$target/")
    if [ "$tls_res" -ne 000 ] 2>/dev/null && [ -n "$tls_res" ]; then
        echo "TLS_OK|$target|Status: $tls_res"
    fi
}
export -f audit_single_target

# --- ANIMASI LOADING ---
start_spinner() {
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    while true; do
        for frame in "${frames[@]}"; do
            echo -ne "\r\033[1;33m[*] Memindai $DB_FILE secara background... $frame \033[0m"
            sleep 0.1
        done
    done
}

# Mulai animasi di background
start_spinner &
SPINNER_PID=$!

# Pengaman CTRL+C
trap 'kill $SPINNER_PID > /dev/null 2>&1; echo -e "\n\033[0;31m[!] Pemindaian dibatalkan!\033[0m"; exit 1' SIGINT

# Menjalankan scanning
ram_buffer=$(cat "$DB_FILE" | sed -e 's|^http://||' -e 's|^https://||' -e 's|:.*||' -e '/^$/d' | sort -u | xargs -P "$MAX_THREADS" -I {} bash -c "$(declare -f audit_single_target); audit_single_target \"{}\"")

# Matikan animasi
kill $SPINNER_PID > /dev/null 2>&1
echo -ne "\r\033[K" 
trap - SIGINT

# --- PROSES MONITOR DAN TAMPILAN AKHIR ---

REPORT="🌐 MASS NETWORK AUDIT REPORT 🌐
==============================
📡 Operator : $ISP
🖥️ IP Publik: $IP_PUB
🎯 Total Target: $(wc -l < "$DB_FILE" | tr -d ' ') host (Disortir Unik)
=============================="

REPORT+="\n\n✅ HOST LIVE / HTTP 200 OK:\n"
HTTP_RES=$(echo "$ram_buffer" | grep "^HTTP_200" | awk -F'|' '{print " -> " $2 " [" $3 "]"}')
if [ -z "$HTTP_RES" ]; then REPORT+=" (Tidak ada host HTTP 200)\n"; else REPORT+="$HTTP_RES\n"; fi

REPORT+="\n✅ HOST OPOK / TLS SUCCESS (443):\n"
TLS_RES=$(echo "$ram_buffer" | grep "^TLS_OK" | awk -F'|' '{print " -> " $2 " (" $3 ")"}')
if [ -z "$TLS_RES" ]; then REPORT+=" (Tidak ada host TLS yang sukses)\n"; else REPORT+="$TLS_RES\n"; fi

# TAMPILKAN HASIL PENUH DI TERMINAL
echo -e "\033[0;32m[+] Analisis selesai! Berikut rangkuman host aktif:\033[0m"
echo -e "$REPORT"
echo "=================================================="

# --- PENGIRIMAN KE TELEGRAM (MODE DOCUMENT/FILE) ---
echo -e "\n\033[1;36m[*] Mencoba mengirim file backup ke Telegram...\033[0m"

TELEGRAM_URL="https://api.telegram.org/bot$BOT_TOKEN/sendDocument"
FILE_NAME="Hasil_Audit_$(date +%d%m%Y_%H%M).txt"
CAPTION="📊 Hasil Audit Jaringan ($ISP)"

# Buat file teks sementara
echo -e "$REPORT" > "$FILE_NAME"

# Kirim file ke Telegram (max time 10 detik agar tidak hang jika offline)
SEND_STATUS=$(curl -s --max-time 10 -X POST "$TELEGRAM_URL" \
    -F "chat_id=$CHAT_ID" \
    -F "caption=$CAPTION" \
    -F "document=@$FILE_NAME")

# Hapus file teks sementara dari penyimpanan lokal
rm -f "$FILE_NAME"

# Validasi status pengiriman
if echo "$SEND_STATUS" | grep -q '"ok":true'; then
    echo -e "\033[1;32m[✓] Sukses! File laporan berhasil di-backup ke Telegram.\033[0m\n"
else
    echo -e "\033[0;31m[!] Gagal mengirim ke Telegram (Abaikan jika jaringan memblokir akses ke API Telegram).\033[0m\n"
fi
