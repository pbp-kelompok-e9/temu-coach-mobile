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
- Auth:
  - POST /api/auth/login/
  - POST /api/auth/register/
  - POST /api/auth/logout/
- Coach:
  - GET /api/coach/
  - GET /api/coach/<id>/
- Booking:
  - GET /api/bookings/ (semua / bisa pakai ?mine=1)
  - POST /api/bookings/ (create)
  - PUT /api/bookings/<id>/ (edit note)
  - DELETE /api/bookings/<id>/ (cancel)
- Review:
  - GET /api/reviews/?coach=<id>
  - POST /api/reviews/
  - PUT /api/reviews/<id>/
  - DELETE /api/reviews/<id>/
- Schedule:
  - GET /api/schedule/?coach=<id>
  - POST /api/schedule/
  - PUT /api/schedule/<id>/
  - DELETE /api/schedule/<id>/
- Chat:
  - GET /api/chat/contacts/
  - GET /api/chat/rooms/
  - GET /api/chat/messages/?room=<id>
  - POST /api/chat/send/   (room_id, message)
  - PUT /api/chat/messages/<id>/   (edit pesan)
  - DELETE /api/chat/messages/<id>/ (hapus pesan)
- Admin:
  - PUT /api/admin/coach/<id>/flag/ (ubah flag/status)
  - POST /api/admin/ban-coach/<id>/
  - POST /api/admin/verify-coach/<id>/
  - DELETE /api/admin/reports/<id>/ (hapus report)

## Design (Figma)
[Link Figma](https://www.figma.com/design/Kl4YECItsI2E932xoYIP8O/TemuCoach-UI-UX-Design?node-id=0-1&p=f&t=wNcKrVE8xbU9RZCe-0)




