# Updating the Xcode Project

The watch target uses Xcode’s file-system-synchronised groups, so new files appear automatically on disk. When you need to add or remove Swift files, resources, or configuration plists, follow these steps to make sure the `WavelengthWatch Watch App` target stays in sync.

1. **Open the project**
   - Launch Xcode and open `frontend/WavelengthWatch/WavelengthWatch.xcodeproj`.
   - In the navigator, expand the `WavelengthWatch Watch App` group.

2. **Add new files**
   - Use *File → New → File…* and create Swift files (e.g., in `Models`, `Services`, or `ViewModels`) or property lists inside the corresponding folder on disk.
   - In the creation dialog, confirm the **Target Membership** checkbox for `WavelengthWatch Watch App`. For tests, also tick `WavelengthWatch Watch AppTests` if applicable.
   - If you add files outside of Xcode (e.g., via a script or from this repository), right-click the group in Xcode and choose **Synchronise with Disk** to refresh the navigator, then verify target membership in the File Inspector.

3. **Remove legacy assets**
   - Select the files you want to delete in Xcode and press delete. Choose “Move to Trash” so the repository stays clean.
   - Confirm that the files disappear from the “Compile Sources” or “Copy Bundle Resources” build phases by opening the target’s **Build Phases** tab.

4. **Verify build phases**
   - With the watch target selected, open **Build Phases → Compile Sources** and ensure each new Swift file appears exactly once.
   - Under **Build Phases → Copy Bundle Resources**, verify that configuration plists (such as `APIConfiguration.plist`) are listed. If a file is missing, drag it in from the navigator.

5. **Clean and build**
   - Run *Product → Clean Build Folder* and then build the `WavelengthWatch Watch App` scheme. Fix any target membership warnings that appear.

Following these steps keeps the `.xcodeproj` deterministic and ensures other developers (and CI) see the same structure.
