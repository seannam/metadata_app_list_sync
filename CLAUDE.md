# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the app
xcodebuild -project MetadataSyncApp.xcodeproj -scheme MetadataSyncApp -configuration Debug build

# Run the built app
open ~/Library/Developer/Xcode/DerivedData/MetadataSyncApp-*/Build/Products/Debug/MetadataSyncApp.app

# Clean build
xcodebuild -project MetadataSyncApp.xcodeproj -scheme MetadataSyncApp clean
```

## Architecture

This is a native macOS SwiftUI app (macOS 14+) that syncs file/directory metadata from the filesystem.

### Core Data Model
- **TrackedDirectory** - Directories being monitored (path, name, isActive, lastScannedAt)
- **FileItem** - Files/folders with metadata (size, dates, priority, notes, git status)
- **Tag** - User-defined tags for items

### Key Services
- **PersistenceController** - Core Data stack with view/background contexts
- **FileSystemMonitor** - FSEvents API wrapper for live file change detection (0.5s debounce)
- **DirectoryScanner** - Reads file metadata using URL resource values, batch processing (50 items)
- **GitStatusService** - Detects .git folders and runs `git status --porcelain` with 30s TTL cache

### View Architecture
Uses NavigationSplitView with three columns:
1. **SidebarView** - List of tracked directories
2. **FileListView** - Items in selected directory with sorting/filtering
3. **FileDetailView** - Full metadata and editing for selected item

### Data Flow
- ViewModels use `@Published` properties and `@FetchRequest` for Core Data integration
- Background context used for scanning operations, auto-merges to view context
- FSEvents triggers incremental updates via DirectoryScanner.updateItem()

## Non-Sandboxed
The app runs without sandbox (see MetadataSyncApp.entitlements) for unrestricted file access. Distribute outside App Store.
