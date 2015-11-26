//  Copyright © 2015 Venture Media. All rights reserved.

import Foundation

import Peak
import FeatureExtraction
import HDF5Kit
import Upsurge

func midiNoteLabel(notes: Range<Int>, note: Int) -> Int {
    return note - notes.startIndex + 1
}

class FeatureCompiler {
    let rootNoisePath = "../AudioData/Noise/"
    let rootMonoPath = "../AudioData/Monophonic/"
    let rootPolyPath = "../AudioData/Polyphonic/"
    let testingFolders = [
        "Arachno",
        "VenturePianoQuiet1",
        "VentureFast1",
        "mozart",
        "muss",
        "alfred40829",
        "godow",
        "alfred42458"
    ]

    var trainingFileName = "training.h5"
    var testingFileName = "testing.h5"
    let trainingDatabase: FeatureDatabase
    let testingDatabase: FeatureDatabase

    var existingFolders: [String]
    var featureBuilder = FeatureBuilder()

    init(overwrite: Bool) {
        trainingDatabase = FeatureDatabase(filePath: trainingFileName, overwrite: overwrite)
        testingDatabase = FeatureDatabase(filePath: testingFileName, overwrite: overwrite)
        existingFolders = trainingDatabase.folders + testingDatabase.folders

        print("\nWorking Directory: \(NSFileManager.defaultManager().currentDirectoryPath)\n")
    }

    func compileNoiseFeatures() {
        let name = (rootNoisePath as NSString).lastPathComponent
        if existingFolders.contains(name) {
            return
        }

        let exampleBuilder = MonoExampleBuilder()

        var features = [FeatureData]()
        exampleBuilder.forEachNoiseInFolder(rootNoisePath, action: { example in
            let featureData = FeatureData(example: example)
            featureData.features = self.featureBuilder.generateFeatures(example)
            features.append(featureData)
        })

        trainingDatabase.appendFeatures(features, folder: name)
        existingFolders.append(name)
    }

    func compileMonoFeatures() {
        let folders = loadFolders(rootMonoPath)

        let exampleBuilder = MonoExampleBuilder()
        for folder in folders {
            let name = (folder as NSString).lastPathComponent
            if existingFolders.contains(name) {
                continue
            }

            var features = [FeatureData]()
            exampleBuilder.forEachNoteInFolder(folder, action: { example in
                let featureData = FeatureData(example: example)
                featureData.features = self.featureBuilder.generateFeatures(example)
                features.append(featureData)
            })

            if testingFolders.contains(name) {
                testingDatabase.appendFeatures(features, folder: name)
            } else {
                trainingDatabase.appendFeatures(features, folder: name)
            }

            existingFolders.append(name)
        }
    }

    func compilePolyFeatures() {
        let folders = loadFolders(rootPolyPath)

        let exampleBuilder = PolyExampleBuilder()
        for folder in folders {
            let name = (folder as NSString).lastPathComponent
            if existingFolders.contains(name) {
                continue
            }

            var features = [FeatureData]()
            exampleBuilder.forEachExampleInFolder(folder, action: { example in
                let featureData = FeatureData(example: example)
                featureData.features = self.featureBuilder.generateFeatures(example)
                features.append(featureData)
            })

            if testingFolders.contains(name) {
                testingDatabase.appendFeatures(features, folder: name)
            } else {
                trainingDatabase.appendFeatures(features, folder: name)
            }

            existingFolders.append(name)
        }
    }

    func loadFolders(root: String) -> [String] {

        let fileManager = NSFileManager.defaultManager()
        guard let folders = try? fileManager.contentsOfDirectoryAtURL(NSURL.fileURLWithPath(root), includingPropertiesForKeys: [NSURLNameKey], options: NSDirectoryEnumerationOptions.SkipsHiddenFiles) else {
            fatalError()
        }
        return folders.map{ $0.path! }
    }

    func shuffle(chunkSize chunkSize: Int, passes: Int) {
        let isTTY = isatty(fileno(stdin)) != 0
        let eraseLastLineCommand = "\u{1B}[A\u{1B}[2K"

        if isTTY {
            print("Shuffling...")
        }

        trainingDatabase.shuffle(chunkSize: chunkSize, passes: passes) { progress in
            if isTTY {
                print("\(eraseLastLineCommand)Shuffling training data...\(round(progress * 10000) / 100)%")
            }
        }

        testingDatabase.shuffle(chunkSize: chunkSize, passes: passes) { progress in
            if isTTY {
                print("\(eraseLastLineCommand)Shuffling testing data...\(round(progress * 10000) / 100)%")
            }
        }
    }
}
