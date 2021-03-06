//  FileHelper.swift
//  Created by Holger Hinzberg on 2022.03.01
//  Copyright (c) 2022 Holger Hinzberg. All rights reserved.

import Foundation



public class FileHelper
{
    public static let shared = FileHelper()
    
    private init() {
    }
    
    public func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    public func checkIfFolderDoesExists(folder:String, doCreate:Bool) -> Bool
    {
        let isDir:UnsafeMutablePointer<ObjCBool>? = nil
        let exists = FileManager.default.fileExists(atPath: folder, isDirectory: isDir)
        
        if exists == false && doCreate == true
        {
            var error: NSError?
            do
            {
                try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error1 as NSError
            {
                error = error1
            }
            print(error!.localizedDescription)
        }
        return true
    }
    
    public func getFilesCount(folderPath : String) -> Int
    {
        var fileCount = 0
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: folderPath)
        
        let fileURLs = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        fileCount = fileURLs?.count ?? 0
        
        return fileCount
    }
    
    public func getFilesURLFromFolder(_ folderURL: URL) -> [URL]?
    {
        let options: FileManager.DirectoryEnumerationOptions =
        [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants]
        
        let fileManager = FileManager.default
        let resourceValueKeys = [URLResourceKey.isRegularFileKey, URLResourceKey.typeIdentifierKey]
        
        guard let directoryEnumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: resourceValueKeys,
                                                               options: options, errorHandler: { url, error in
            print("`directoryEnumerator` error: \(error).")
            return true
        }) else { return nil }
        
        var urls: [URL] = []
        for case let url as URL in directoryEnumerator
        {
            do {
                let resourceValues = try (url as NSURL).resourceValues(forKeys: resourceValueKeys)
                guard let isRegularFileResourceValue = resourceValues[URLResourceKey.isRegularFileKey] as? NSNumber else { continue }
                guard isRegularFileResourceValue.boolValue else { continue }
                guard let fileType = resourceValues[URLResourceKey.typeIdentifierKey] as? String else { continue }
                guard UTTypeConformsTo(fileType as CFString, "public.image" as CFString) else { continue }
                urls.append(url)
            }
            catch
            {
                print("Unexpected error occured: \(error).")
            }
        }
        return urls
    }
    
    
    // MARK: - Copy
    
    public func copyFiles(sourceUrls:[URL], toUrl destinationUrl: URL) -> Int
    {
        var copyCounter = 0;
        
        for sourceUrl in sourceUrls
        {
            // Get only the Filename
            let originalFilename = sourceUrl.lastPathComponent;
            // Create an destinationpath with the filename
            let destinationFilename = destinationUrl.path + "/" + originalFilename;
            // Copy from source to destination
            
            self.copyFile(sourcePath: sourceUrl.path, destinationPath: destinationFilename) { result in
                switch result {
                case .success(_):
                    copyCounter += 1
                    break
                case .failure(FileHelperError.couldNotCopyFile(let source, let destination, let descrip)):
                    print("\(descrip) \(source!) \(destination!)")
                    break
                default:
                    break
                }
            }
        }
        return copyCounter;
    }
    
    public func copyFile(sourceUrl: URL, toPath destinationUrl: URL, completion: (Result<Bool, FileHelperError>) -> Void)
    {
        self.copyFile(sourcePath: sourceUrl.path, destinationPath: destinationUrl.path) { result in
            switch result {
            case .success(_):
                completion(.success(true))
                break
            case .failure(FileHelperError.couldNotCopyFile(let source, let destination, let descrip)):
                completion(.failure(FileHelperError.couldNotCopyFile(source: source, destination: destination, description: descrip)))
                break
            default:
                break
            }
        }
    }
    
    public func copyFile(sourcePath: String?, destinationPath: String? , completion: (Result<Bool, FileHelperError>) -> Void)
    {
        if let sourcePath = sourcePath, let destinationPath = destinationPath
        {
            let fileManager = FileManager.default
            do
            {
                try fileManager.copyItem(atPath: sourcePath, toPath: destinationPath)
                completion(.success(true))
            }
            catch let error as NSError
            {
                completion(.failure(FileHelperError.couldNotCopyFile(source: sourcePath, destination: destinationPath, description: error.localizedDescription)))
            }
        }
        else
        {
            completion(.failure(FileHelperError.couldNotCopyFile(source: nil, destination: nil, description:"Filepath could not be unwrapped. Possible NULL")))
        }
    }
    
    // MARK: - Delete
    
    public func deleteItemAtPath(sourcePath: String?) -> Bool
    {
        var success = true
        
        if let sourcePath = sourcePath
        {
            let fileManager = FileManager.default
            do
            {
                try fileManager.removeItem(atPath: sourcePath)
            }
            catch let error as NSError
            {
                print("Could not delete \(sourcePath) : \(error.localizedDescription)")
                success = false;
            }
        }
        else
        {
            print("Filepath could not be unwrapped. Possible NULL")
            success = false;
        }
        return success
    }
    
    
    
    
    
}
