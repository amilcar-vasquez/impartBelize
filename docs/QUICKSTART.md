# Quick Start Guide - Impart Belize UI

This guide will help you get the Flutter web app running quickly.

## Prerequisites

Make sure you have:
- Flutter SDK installed ([Install Flutter](https://docs.flutter.dev/get-started/install))
- Chrome browser installed
- Your Go API server running on `http://localhost:4000`

## Step 1: Navigate to the UI directory

```bash
cd ui
```

## Step 2: Install dependencies

```bash
flutter pub get
```

## Step 3: Configure API URL (if needed)

If your API is running on a different URL, edit `lib/config/app_config.dart`:

```dart
static const String apiBaseUrl = 'http://localhost:4000/v1';
```

## Step 4: Run the app

Start the development server:

```bash
flutter run -d chrome
```

The app should open automatically in Chrome.

## What You'll See

1. **Home Screen**: Navigation with 4 sections (Teachers, Districts, Institutions, Settings)
2. **Teachers Screen**: Displays a list of teachers fetched from your API
3. **Teacher Details**: Click on any teacher card to see detailed information in a modal sheet

## Expected Behavior

### If API is Running:
- Teachers will load and display in cards
- Click on a teacher to see full details
- Use the refresh button to reload data

### If API is Not Running:
- You'll see an error message: "Error loading teachers"
- The error will show connection details
- Click "Retry" once your API is running

## Troubleshooting

### "Failed to load teachers" Error
**Cause**: API server is not running or URL is incorrect

**Solution**:
1. Check if your Go API is running: `cd .. && go run ./cmd/api`
2. Verify the API URL in `lib/config/app_config.dart`
3. Check for CORS issues (API must allow web origins)

### CORS Issues
If you see CORS errors in the browser console, your Go API needs to allow web requests.

Add CORS middleware to your Go API:
```go
// Add to your routes.go or middleware.go
func (app *application) enableCORS(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Access-Control-Allow-Origin", "*")
        w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
        w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
        
        if r.Method == "OPTIONS" {
            w.WriteHeader(http.StatusOK)
            return
        }
        
        next.ServeHTTP(w, r)
    })
}
```

### Port Already in Use
If port 8080 is in use, specify a different port:
```bash
flutter run -d chrome --web-port=3000
```

## Building for Production

Create a production build:
```bash
flutter build web
```

The built files will be in `build/web/` and can be served by:
- Any static web server (nginx, Apache)
- Firebase Hosting
- Netlify
- Vercel
- GitHub Pages

## Next Steps

1. **Add Sample Data**: Add some teacher records through your API
2. **Test Responsiveness**: Resize the browser window to see responsive layouts
3. **Try Dark Mode**: Change your system theme to see dark mode in action
4. **Explore Navigation**: Click through different sections in the navigation

## Key Features to Try

- ✅ Responsive design (resize browser)
- ✅ Dark/light theme (system preference)
- ✅ Teacher list with search
- ✅ Teacher details modal
- ✅ Error handling
- ✅ Loading states
- ✅ Empty states

## Development Tips

### Hot Reload
Make changes to the code and save - the app will automatically reload in the browser!

### DevTools
Open Flutter DevTools for debugging:
```bash
flutter run -d chrome --dart-define=FLUTTER_WEB_USE_SKIA=false
```

### Debug Mode vs Release Mode
- Development: `flutter run -d chrome` (includes debug tools)
- Production: `flutter build web --release` (optimized)

## Common Commands

```bash
# Run app
flutter run -d chrome

# Run with hot reload on save
flutter run -d chrome --hot

# Build for production
flutter build web

# Run tests
flutter test

# Check for issues
flutter analyze

# Format code
flutter format lib/

# Clean build files
flutter clean
```

## Project Structure Overview

```
lib/
├── main.dart                 # App entry & theme
├── config/
│   └── app_config.dart       # Configuration constants
├── models/
│   └── teacher.dart          # Data models
├── services/
│   └── api_service.dart      # API client
└── screens/
    └── teachers_screen.dart  # UI screens
```

## Need Help?

- **Flutter Docs**: https://docs.flutter.dev
- **Material 3**: https://m3.material.io
- **Dart Packages**: https://pub.dev

Happy coding! 🚀
