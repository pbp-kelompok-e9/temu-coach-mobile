# Temu Coach Mobile

[![Build Status](https://app.bitrise.io/app/69c63ba6-60f0-49ad-9321-9fb85ada77c9/status.svg?token=ikodLQfnbZvRGAeBuL-U2A&branch=master)](https://app.bitrise.io/app/69c63ba6-60f0-49ad-9321-9fb85ada77c9)

## Download APK
Versi terbaru: [Download APK](https://app.bitrise.io/app/69c63ba6-60f0-49ad-9321-9fb85ada77c9/installable-artifacts/7a6c40d0dda186e6/public-install-page/69aa58a41dd7200efaffe6ef4b716b7a)

## Anggota Kelompok
- Mohammad Aly Haidarulloh - 2406425804
- Alvino Revaldi - 2406438933
- Erico Putra Bani Mahendra - 2406423181
- Benedictus Lucky Win Ziraluo - 2406355174
- Muhammad Rayyan Basalamah - 2406496372

## Deskripsi Aplikasi
Temu Coach Mobile adalah aplikasi Flutter yang menghubungkan pengguna dengan pelatih (coach) sepak bola. Pengguna dapat:
- Menjelajah dan mencari coach
- Melihat profil, keahlian, pengalaman, dan rating
- Melakukan booking sesi latihan
- Mengelola jadwal dan melihat slot yang sudah diblok
- Memberi review & rating
- Chat (contact list + chat room one-to-one)
Aplikasi ini merupakan versi mobile dari platform Temu Coach berbasis web.

## Daftar Modul & Pembagian Kerja
| Modul | Fitur Inti | Penanggung Jawab |
|-------|------------|------------------|
| Booking | List / detail / buat / batal | Benedictus Lucky Win Ziraluo |
| Review & Rating | List review, tambah, edit | Erico Putra Bani Mahendra |
| Schedule Coach | Tampilkan & kelola schedule | Mohammad Aly Haidarulloh |
| Chat | Contact list (daftar kontak), chat room one-to-one | - |
| Admin | Blokir / verifikasi coach / report| Alvino Revaldi |
| Auth | Login / register / sesi / logout | Benedictus Lucky Win Ziraluo |

## Peran / Aktor
- Customer:
  - Booking coach
  - Memberi review & rating
  - Mengelola booking
  - Chat dengan coach
  - Melaporkan coach
- Coach:
  - Membuat, mengedit, menghapus jadwal
  - Chat dengan customer
- Admin:
  - Ban coach
  - Mengelola laporan
  - Verifikasi pendaftaran coach

## Integrasi Data dengan Web (PWS)
Aplikasi mobile berkomunikasi dengan backend Django (PWS) melalui web service (JSON):

### Auth
- POST /accounts/api/login/
- POST /accounts/api/register/
- POST /accounts/api/logout/
- GET /accounts/api/get-current-user/

### Coach
- GET /api/coach/
- GET /api/coach/<id>/
- GET /coach/api/coach-profile/ (untuk coach yang login)

### Booking
- GET /api/booking/
- GET /api/booking/<id>/
- POST /api/booking/create/
- POST /api/booking/<id>/update/
- POST /api/booking/<id>/delete/

### Schedule
- GET /api/schedule/?coach=<id>
- GET /coach/api/schedule/ (untuk coach yang login)
- POST /coach/api/schedule/create/
- PUT /coach/api/schedule/<id>/update/
- DELETE /coach/api/schedule/<id>/delete/

### Review & Rating
- GET /api/reviews/?coach=<id>
- POST /api/reviews/create/
- PUT /api/reviews/<id>/update/
- DELETE /api/reviews/<id>/delete/

### Chat
- GET /chat/api/conversations/ - Daftar percakapan
- GET /chat/api/contacts/ - Daftar kontak yang bisa dihubungi
- GET /chat/api/<receiver_id>/ - Ambil pesan dengan user tertentu
- POST /chat/api/<receiver_id>/ - Kirim pesan
- PUT /chat/api/message/<message_id>/edit/ - Edit pesan (dalam 5 menit)
- DELETE /chat/api/message/<message_id>/delete/ - Hapus pesan (dalam 5 menit)

### Admin
- GET /my_admin/api/reports/
- GET /my_admin/api/coach-requests/
- POST /my_admin/api/coach/<id>/approve/
- POST /my_admin/api/coach/<id>/reject/
- POST /my_admin/api/coach/<id>/ban/
- POST /my_admin/api/report/<id>/delete/

## Design (Figma)
[Link Figma](https://www.figma.com/design/Kl4YECItsI2E932xoYIP8O/TemuCoach-UI-UX-Design?node-id=0-1&p=f&t=wNcKrVE8xbU9RZCe-0)




