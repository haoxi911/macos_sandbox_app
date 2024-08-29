//
//  ViewController.swift
//  SandboxedApp
//
//  Created by Hao Xi on 8/16/24.
//

import Cocoa
import Photos

class ViewController: NSViewController {

    @IBOutlet var _sandboxedApp: NSTextField!;
    @IBOutlet var _downloadsAccess: NSTextField!;
    @IBOutlet var _picturesAccess: NSTextField!;
    @IBOutlet var _moviesAccess: NSTextField!;
    @IBOutlet var _musicAccess: NSTextField!;
    @IBOutlet var _desktopAccess: NSTextField!;
    @IBOutlet var _documentsAccess: NSTextField!;
    @IBOutlet var _photosLibraryAccess: NSTextField!;
    @IBOutlet var _usbDriveAccess: NSTextField!;
    
    @IBAction func onTestDownloadsAccess(sender: Any?) {
        testUserFolder(folder: .downloadsDirectory, label: _downloadsAccess)
    }
    
    @IBAction func onTestPicturesAccess(sender: Any?) {
        testUserFolder(folder: .picturesDirectory, label: _picturesAccess)
    }
    
    @IBAction func onTestMoviesAccess(sender: Any?) {
        testUserFolder(folder: .moviesDirectory, label: _moviesAccess)
    }
    
    @IBAction func onTestMusicAccess(sender: Any?) {
        testUserFolder(folder: .musicDirectory, label: _musicAccess)
    }
    
    @IBAction func onTestDesktopAccess(sender: Any?) {
        testUserFolder(folder: .desktopDirectory, label: _desktopAccess)
    }
    
    @IBAction func onTestDocumentsAccess(sender: Any?) {
        testUserFolder(folder: .documentDirectory, label: _documentsAccess)
    }
    
    @IBAction func onTestPhotosLibraryAccess(sender: Any?) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .notDetermined:
            requestPhotosAccess()
        case .authorized, .limited:
            _photosLibraryAccess.stringValue = "PASS"
            _photosLibraryAccess.textColor = NSColor(red: 0, green: 0.5, blue: 0, alpha: 1.0)
        default:
            _photosLibraryAccess.stringValue = "The operation couldn't be completed. Operation not permitted"
            _photosLibraryAccess.textColor = .red
        }
        
        if status == .authorized || status == .limited {
            if #available(macOS 10.15, *) {
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
                let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
                let numberOfPhotos = fetchResult.count
                print("Number of photos: \(numberOfPhotos)")
            }
        }
    }
    
    @IBAction func onTestUSBDriveAccess(sender: Any?) {
        // Attempt to read the contents of the USB drive
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "/Volumes/TEST"), includingPropertiesForKeys: nil)
            _usbDriveAccess.stringValue = "PASS"
            _usbDriveAccess.textColor = NSColor(red: 0, green: 0.5, blue: 0, alpha: 1.0)
            print ("Folder: /Volumes/TEST")
            for item in contents {
                print(item)
            }
        } catch {
            _usbDriveAccess.stringValue = getUnderlyingErrorDescription(error)
            _usbDriveAccess.textColor = .red
            print(error)
        }
    }
    
    @IBAction func onGrantAccessToFolder(sender: Any?) {
        openFolderPanel()
    }
    
    @IBAction func onResetBookmarks(sender: Any?) {
        UserDefaults.standard.removeObject(forKey: "Bookmarks")
    }
    
    @IBAction func onTestAllLocations(sender: Any?) {
        self.testAll()
    }
    
    func testAll() {
        onTestDownloadsAccess(sender: nil)
        onTestPicturesAccess(sender: nil)
        onTestMoviesAccess(sender: nil)
        onTestMusicAccess(sender: nil)
        onTestDesktopAccess(sender: nil)
        onTestDocumentsAccess(sender: nil)
        onTestPhotosLibraryAccess(sender: nil)
        onTestUSBDriveAccess(sender: nil)
    }
    
    func testUserFolder(folder: FileManager.SearchPathDirectory, label: NSTextField) {
        // Get the URL for the user folder
        guard var folderURL = FileManager.default.urls(for: folder, in: .userDomainMask).first else {
            label.stringValue = "Unable to get folder URL"
            return
        }
        
        // Get the actual user folder (not the one in the app container)
        folderURL = URL(fileURLWithPath: folderURL.path.replacingOccurrences(of: "Library/Containers/com.simplifieditproducts.SandboxedApp/Data/", with: ""))
        
        // Attempt to read the contents of the user folder
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            print ("Folder: \(folderURL)")
            for item in contents {
                print(item)
            }
            label.stringValue = "PASS"
            label.textColor = NSColor(red: 0, green: 0.5, blue: 0, alpha: 1.0)
        } catch {
            label.stringValue = getUnderlyingErrorDescription(error)
            label.textColor = .red
            print(error)
        }
    }
    
    func requestPhotosAccess() {
        PHPhotoLibrary.requestAuthorization() { status in
            DispatchQueue.main.async {
                self.onTestPhotosLibraryAccess(sender: nil)
            }
        }
    }
    
    func getUnderlyingErrorDescription(_ error: Error) -> String {
        let nsError = error as NSError
        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            return underlyingError.localizedDescription
        } else {
            return error.localizedDescription
        }
    }
    
    func testSandbox() {
        if let _ = ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] {
            _sandboxedApp.stringValue = "YES"
            _sandboxedApp.textColor = .orange
        } else {
            _sandboxedApp.stringValue = "NO"
            _sandboxedApp.textColor = .gray
        }
    }
    
    func openFolderPanel() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Please select a folder to grant access"
        openPanel.prompt = "Grant Access"
        
        openPanel.begin { (result) in
            if result == .OK {
                guard let url = openPanel.url else { return }
                self.testAll()
                self.grantAccessToFolder(url: url)
            }
        }
    }
    
    func grantAccessToFolder(url: URL) {
        do {
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access the resource")
                return
            }
            
            // Create a security-scoped bookmark
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            var bookmarks: [Data] = {
                if let data = UserDefaults.standard.array(forKey: "Bookmarks") as? [Data] {
                    return data
                }
                return []
            }()
            bookmarks.append(bookmarkData)
            UserDefaults.standard.set(bookmarks, forKey: "Bookmarks")
            
            print("Access granted to folder: \(url.path)")
            
            // Perform any operations with the folder here
            
            // Stop accessing the security-scoped resource when you're done
            //url.stopAccessingSecurityScopedResource()
        } catch {
            print("Error creating bookmark: \(error)")
        }
    }

    // To use the saved bookmark later:
    func accessSavedFolder() {
        let bookmarks: [Data] = {
            if let data = UserDefaults.standard.array(forKey: "Bookmarks") as? [Data] {
                return data
            }
            return []
        }()
        
        for bookmarkData in bookmarks {
            
            do {
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if isStale {
                    print("Bookmark is stale")
                    // You might want to ask the user to select the folder again
                    return
                }
                
                guard url.startAccessingSecurityScopedResource() else {
                    print("Failed to access the resource")
                    return
                }
                
                // Perform operations with the folder
                print("Accessed folder: \(url.path)")
                
                // Don't forget to stop accessing when done
                //url.stopAccessingSecurityScopedResource()
            } catch {
                print("Error resolving bookmark: \(error)")
            }
            
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.testSandbox()
        self.accessSavedFolder()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

