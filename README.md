# MetadataSyncApp

A native macOS application for monitoring and managing file/directory metadata. Track directories, view file information, manage git repository status, and organize items with tags and priorities.

## Requirements

- macOS 14.0+
- Xcode 15+

## Build & Run

```bash
# Build the app
xcodebuild -project MetadataSyncApp.xcodeproj -scheme MetadataSyncApp -configuration Debug build

# Run the built app
open ~/Library/Developer/Xcode/DerivedData/MetadataSyncApp-*/Build/Products/Debug/MetadataSyncApp.app

# Clean build
xcodebuild -project MetadataSyncApp.xcodeproj -scheme MetadataSyncApp clean
```

## Features

- **Directory Tracking** - Add directories to monitor their contents
- **Live Monitoring** - FSEvents-based file system watching with automatic updates
- **File Metadata** - View size, creation/modification/access dates
- **Git Integration** - Detect git repositories and uncommitted changes
- **Organization** - Assign priorities, notes, and colored tags to items
- **Export** - Export data to CSV or Markdown formats

## Architecture

### Core Data Model

- **TrackedDirectory** - Directories being monitored
- **FileItem** - Files/folders with metadata (size, dates, priority, notes, git status)
- **Tag** - User-defined colored tags for categorizing items

### Services

- **PersistenceController** - Core Data stack with view/background contexts
- **FileSystemMonitor** - FSEvents wrapper for live file change detection
- **DirectoryScanner** - Reads file metadata with batch processing
- **GitStatusService** - Detects git repos and checks for uncommitted changes

### Views

Three-column NavigationSplitView layout:
1. Sidebar - List of tracked directories
2. Content - File list with sorting/filtering
3. Detail - Full metadata and editing

## Distribution

This app runs without sandbox for unrestricted file system access. Distribute outside the Mac App Store.
