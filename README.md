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
- Autentikasi: endpoint login (session + cookie) 
- Registrasi: endpoint register 
- Listing coach: GET /api/coach/ 
- Detail coach: GET /api/coach/<id>/ 
- Booking:
  - GET /api/bookings/?mine=1 (hanya booking milik user)
  - POST /api/bookings/ (buat booking)
  - DELETE /api/bookings/<id>/ (batal)
- Review & Rating:
  - GET /api/reviews/?coach=<id>
  - POST /api/reviews/
- Schedule:
  - GET /api/schedule/?coach=<id>
  - POST /api/schedule/
- Chat:
  - GET /api/chat/contacts/ (daftar kontak yang dapat dihubungi)
  - GET /api/chat/rooms/ 
  - GET /api/chat/messages/?room=<id>
  - POST /api/chat/send/ (body: room_id, message)
- Admin:
  - POST /api/admin/ban-coach/<id>/
  - POST /api/admin/verify-coach/<id>/

## Design (Figma)
[Link Figma](https://www.figma.com/design/Kl4YECItsI2E932xoYIP8O/TemuCoach-UI-UX-Design?node-id=0-1&p=f&t=wNcKrVE8xbU9RZCe-0)




