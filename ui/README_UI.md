# Impart Belize UI

A Flutter web application for managing teacher information in Belize, built with Material 3 design principles.

## Features

- **Material 3 Design**: Modern, accessible UI using Material Design 3 components
- **Responsive Layout**: Adapts to different screen sizes with NavigationRail (desktop) and NavigationBar (mobile)
- **Dark Mode Support**: Automatic theme switching based on system preferences
- **Teacher Management**: View detailed teacher information including:
  - Contact details
  - Employment status
  - Institution and district assignment
  - Personal information

## Project Structure

```
ui/
├── lib/
│   ├── main.dart                    # App entry point with Material 3 theme
│   ├── models/
│   │   └── teacher.dart             # Teacher data model
│   ├── services/
│   │   └── api_service.dart         # HTTP client for API communication
│   └── screens/
│       └── teachers_screen.dart     # Teachers list and details screen
├── web/                             # Web-specific files
└── pubspec.yaml                     # Dependencies
```

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Chrome or another web browser for development

### Installation

1. Navigate to the ui directory:
   ```bash
   cd ui
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Update the API base URL in `lib/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'http://localhost:4000/v1';
   ```

### Running the App

Start the development server:
```bash
flutter run -d chrome
```

Or build for production:
```bash
flutter build web
```

The built files will be in `build/web/` and can be served by any static web server.

## API Integration

The app expects the following API endpoints:

- `GET /v1/teachers` - Fetch all teachers
- `GET /v1/teachers/:id` - Fetch a single teacher
- `POST /v1/teachers` - Create a new teacher
- `PATCH /v1/teachers/:id` - Update a teacher
- `DELETE /v1/teachers/:id` - Delete a teacher

Make sure your Go API server is running on `http://localhost:4000` (or update the base URL accordingly).

## Material 3 Features Used

- **Color Scheme**: Dynamic theming with seed colors
- **Typography**: Material 3 text styles
- **Components**:
  - NavigationRail & NavigationBar for navigation
  - Cards with elevated surfaces
  - FilledButton, FilledButton.tonal, and OutlinedButton
  - CircleAvatar for user initials
  - Modal bottom sheets for details
  - Icons from Material Symbols

## Responsive Design

The app uses responsive layouts:
- **Desktop (≥640px)**: NavigationRail on the left
- **Mobile (<640px)**: NavigationBar at the bottom
- **Teacher List**:
  - Grid view on larger screens (>840px)
  - List view on smaller screens

## Development Notes

### Adding New Screens

1. Create a new screen file in `lib/screens/`
2. Add the screen to the `_screens` list in `main.dart`
3. Add a corresponding NavigationDestination

### Customizing Theme

Edit the theme settings in `lib/main.dart`:
```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,  // Change this for different colors
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  // ... other theme properties
),
```

## Testing

Run tests:
```bash
flutter test
```

## Future Enhancements

- [ ] Add teacher creation form
- [ ] Implement edit functionality
- [ ] Add search and filter capabilities
- [ ] Implement pagination for large datasets
- [ ] Add districts and institutions screens
- [ ] Implement authentication
- [ ] Add data export functionality
- [ ] Offline support with local caching

## License

This project is part of the Impart Belize system.
