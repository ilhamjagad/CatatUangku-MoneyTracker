# Panduan Setup Firebase untuk CatatUangku!

## Langkah 1: Buat Firebase Project

1. Buka **Firebase Console**: https://console.firebase.google.com/
2. Klik **"Add project"** atau **"+ Tambahkan proyek"**
3. Masukkan nama project, contoh: `CatatUangku`
4. Matikan Google Analytics (opsional, untuk simplify)
5. Klik **"Buat Proyek"** / **"Create project"**
6. Tunggu sampai project selesai dibuat

## Langkah 2: Tambahkan App Android

1. Setelah project dibuat, klik icon **Android** untuk menambahkan app Android
2. Masukkan data berikut:
   - **Android package name**: `com.jagadtech.catatuangku`
   - **App nickname** (opsional): `CatatUangku`
3. Klik **"Register app"**

## Langkah 3: Download google-services.json

1. Pada langkah berikutnya, Anda akan diminta untuk download file `google-services.json`
2. Download file tersebut
3. Simpan ke folder: `android/app/google-services.json` (replace file yang ada)

## Langkah 4: Aktifkan Firebase Auth

1. Di Firebase Console, klik menu **Authentication** (menu左上)
2. Klik tab **Sign-in method**
3. Klik **"Add new provider"** atau **"Tambah penyedia baru"**
4. Pilih **Email/Password**
5. Aktifkan:
   - **Email/Password**: Enable
   - **Email link (passwordless sign-in)**: Opsional
6. Klik **"Save"**

## Langkah 5: Setup Firestore (Opsional untuk data cloud)

1. Di Firebase Console, klik menu **Firestore Database**
2. Klik **"Create database"**
3. Pilih lokasi (sesuai preferensi, contoh: asia-southeast2)
4. Pilih **Start in test mode** (untuk development)
5. Klik **"Create"**

## Langkah 6: Aktifkan Firebase Storage (Untuk upload foto profile)

1. Di Firebase Console, klik menu **Storage**
2. Klik **"Get started"** atau **"Mulai"**
3. Pilih lokasi (sesuai preferensi, contoh: asia-southeast2)
4. Pilih **Start in test mode** (untuk development)
5. Klik **"Done"**

**Catatan Penting - Firebase Storage Rules:**
Jika Anda ingin membatasi siapa yang bisa upload, Anda bisa mengedit Rules:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      // Allow all for test mode:
      allow read, write: if true;
      
      // Atau untuk production, gunakan:
      // allow read, write: if request.auth != null;
    }
  }
}
```

## Langkah 7: Rebuild App

Setelah setup Firebase:

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

---

## Troubleshooting

### Jika masih error API key:
- Pastikan package name di Firebase Console sama dengan: `com.jagadtech.catatuangku`
- Pastikan file `google-services.json` sudah di-download dan replace dengan benar

### Jika error "XML parser error":
- Buka `google-services.json` dengan text editor
- Pastikan format JSON valid

---

## Struktur google-services.json yang Benar

File yang Anda download dari Firebase akan memiliki format seperti ini:

```json
{
  "project_info": {
    "project_number": "123456789012",
    "project_id": "nama-project-anda",
    "storage_bucket": "nama-project-anda.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789012:android:abc123def456",
        "android_client_info": {
          "package_name": "com.jagadtech.catatuangku"
        }
      },
      "oauth_client": [...],
      "api_key": [
        {
          "current_key": "AIzaSyBxxxxx_xxxxx_xxxxx"
        }
      ],
      "services": {
        "appinvite_service": {...}
      }
    }
  ],
  "configuration_version": "1"
}
```

Pastikan `package_name` adalah `com.jagadtech.catatuangku`!
