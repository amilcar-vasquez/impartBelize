# Supabase File Upload Integration - Setup Guide

## ✅ Implementation Complete

The Supabase file upload has been fully integrated into your application. Follow these steps to configure it.

---

## 📋 Setup Steps

### 1. Install Dependencies

Run this command in your `ui` directory:

```bash
cd ui
flutter pub get
```

This will install:

-   `supabase_flutter: ^2.5.1` - Supabase SDK
-   `file_picker: ^8.0.0+1` - File selection
-   `path: ^1.9.0` - File path utilities

---

### 2. Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Click **"New project"**
3. Fill in:
    - **Project name**: `impart-belize` (or your choice)
    - **Database Password**: Create a strong password
    - **Region**: Choose closest to Belize (e.g., `us-east-1`)
4. Click **"Create project"** (takes ~2 minutes)

---

### 3. Get Your Credentials

Once your project is ready:

1. Go to **Settings** (⚙️ icon) → **API**
2. You'll see two important values:

    - **Project URL**: `https://xxxxxxxxxxxxx.supabase.co`
    - **anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (long string)

---

### 4. Configure Your App

Open `ui/lib/config/supabase_config.dart` and replace the placeholder values:

```dart
class SupabaseConfig {
  /// Your Supabase project URL
  static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';

  /// Your Supabase anon/public key
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

  /// Storage bucket name
  static const String teacherDocumentsBucket = 'teacher-documents';
}
```

**Example:**

```dart
static const String supabaseUrl = 'https://xyzcompany123.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh5emNvbXBhbnkxMjMiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY0MDk5NTIwMCwiZXhwIjoxOTU2NTcxMjAwfQ.dQw4w9WgXcQ';
```

---

### 5. Create Storage Bucket

In your Supabase dashboard:

1. Go to **Storage** (left sidebar)
2. Click **"New bucket"**
3. Fill in:
    - **Name**: `teacher-documents`
    - **Public bucket**: ✅ **CHECK THIS** (documents need to be publicly accessible)
4. Click **"Create bucket"**

---

### 6. Set Storage Policies (Security)

After creating the bucket:

1. Click on `teacher-documents` bucket
2. Go to **Policies** tab
3. Click **"New policy"**
4. Choose **"Custom"**
5. Create this policy:

**Policy Name**: `Allow authenticated uploads`

**Policy Definition**:

```sql
-- Allow INSERT for authenticated users
(auth.role() = 'authenticated')
```

**Target roles**: `authenticated`
**Operations**: ✅ INSERT

6. Create another policy for public reads:

**Policy Name**: `Allow public reads`

**Policy Definition**:

```sql
-- Allow SELECT for everyone
true
```

**Target roles**: `anon`, `authenticated`
**Operations**: ✅ SELECT

---

## 🎯 What Was Implemented

### Files Created/Modified:

✅ **`lib/config/supabase_config.dart`**

-   Configuration file for Supabase credentials

✅ **`lib/services/supabase_storage_service.dart`**

-   Complete file upload service
-   Handles PDF, images (JPG, PNG), DOC files
-   File size validation (10MB limit)
-   Unique filename generation with timestamps
-   Delete file functionality

✅ **`lib/widgets/document_upload_widget.dart`**

-   Real file picker integration
-   Shows file selection dialog
-   Validates file types and sizes
-   Displays selected files

✅ **`lib/screens/teachers/application_screen.dart`**

-   Uploads files to Supabase during form submission
-   Stores URLs in database

✅ **`lib/main.dart`**

-   Initializes Supabase on app startup

✅ **`pubspec.yaml`**

-   Added required dependencies

---

## 🔧 How It Works

### File Upload Flow:

1. **User selects file** → File picker opens
2. **File validation** → Size & type checked
3. **Form submission** → Teacher profile created first
4. **Files uploaded** → Each file uploaded to Supabase
5. **URLs saved** → Document records created with Supabase URLs
6. **Success** → User notified

### File Storage Structure:

```
teacher-documents/
└── teacher_1/
    ├── 1_birth_certificate_1732654321.pdf
    ├── 1_diploma_1732654322.jpg
    └── 1_police_record_1732654323.pdf
```

---

## 📱 Supported File Types

-   **PDF**: `.pdf`
-   **Images**: `.jpg`, `.jpeg`, `.png`
-   **Documents**: `.doc`, `.docx`

**File Size Limit**: 10MB per file

---

## ✅ Testing

1. Run `flutter pub get`
2. Update `supabase_config.dart` with your credentials
3. Create the `teacher-documents` bucket
4. Set up storage policies
5. Run the app: `flutter run -d emulator-5554`
6. Navigate to teacher application form
7. Try uploading a document

---

## 🔒 Security Notes

-   The **anon key** is safe to use in client apps
-   Storage policies control who can upload/read
-   Files are organized by teacher ID
-   Each file has a unique timestamp
-   Never use the **service_role key** in client apps

---

## 🚀 API Usage

The `SupabaseStorageService` can be used anywhere:

```dart
final storageService = SupabaseStorageService();

// Upload any file
final url = await storageService.uploadTeacherDocument(
  file: File('/path/to/file.pdf'),
  teacherId: 123,
  documentType: 'Diploma',
);

// Delete a file
await storageService.deleteTeacherDocument(url);
```

---

## ⚠️ Important

-   Make sure the bucket is **public** for read access
-   Files without proper policies won't upload
-   Test with small files first
-   Check Supabase dashboard logs if uploads fail

---

## 🎉 You're All Set!

Once configured, teachers can upload real documents that will be stored in Supabase and accessible via public URLs in your database.
