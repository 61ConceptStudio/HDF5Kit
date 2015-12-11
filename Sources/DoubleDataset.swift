// Copyright © 2015 Venture Media Labs. All rights reserved.
//
// This file is part of HDF5Kit. The full HDF5Kit copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import CHDF5

public class DoubleDataset: Dataset {
    public subscript(slices: HyperslabIndexType...) -> [Double] {
        // There is a problem with Swift where it gives a compiler error if `set` is implemented here
        return (try? read(slices)) ?? []
    }

    public subscript(slices: [HyperslabIndexType]) -> [Double] {
        get {
            return (try? read(slices)) ?? []
        }
        set {
            try! write(newValue, to: slices)
        }
    }
    
    public func read(slices: [HyperslabIndexType]) throws -> [Double] {
        let filespace = space
        filespace.select(slices)
        return try read(memSpace: Dataspace(dims: filespace.selectionDims), fileSpace: filespace)
    }

    public func write(data: [Double], to slices: [HyperslabIndexType]) throws {
        let filespace = space
        filespace.select(slices)
        try write(data, memSpace: Dataspace(dims: filespace.selectionDims), fileSpace: filespace)
    }

    /// Read data using an optional memory Dataspace and an optional file Dataspace
    ///
    /// - precondition: The `selectionSize` of the memory Dataspace is the same as for the file Dataspace
    public func read(memSpace memSpace: Dataspace? = nil, fileSpace: Dataspace? = nil) throws -> [Double] {
        let size: Int
        if let memspace = memSpace {
            size = memspace.size
        } else if let filespace = fileSpace {
            size = filespace.selectionSize
        } else {
            size = space.selectionSize
        }

        var result = [Double](count: size, repeatedValue: 0.0)
        try readInto(&result, memSpace: memSpace, fileSpace: fileSpace)
        return result
    }

    /// Read data using an optional memory Dataspace and an optional file Dataspace
    ///
    /// - precondition: The `selectionSize` of the memory Dataspace is the same as for the file Dataspace and there is enough memory available for it
    public func readInto(pointer: UnsafeMutablePointer<Double>, memSpace: Dataspace? = nil, fileSpace: Dataspace? = nil) throws {
        try super.readInto(pointer, type: .Double, memSpace: memSpace, fileSpace: fileSpace)
    }

    /// Write data using an optional memory Dataspace and an optional file Dataspace
    ///
    /// - precondition: The `selectionSize` of the memory Dataspace is the same as for the file Dataspace and the same as `data.count`
    public func write(data: [Double], memSpace: Dataspace? = nil, fileSpace: Dataspace? = nil) throws {
        let size: Int
        if let memspace = memSpace {
            size = memspace.size
        } else if let filespace = fileSpace {
            size = filespace.selectionSize
        } else {
            size = space.selectionSize
        }
        precondition(data.count == size, "Data size doesn't match Dataspace dimensions")

        try writeFrom(UnsafePointer<Double>(data), memSpace: memSpace, fileSpace: fileSpace)
    }

    /// Write data using an optional memory Dataspace and an optional file Dataspace
    ///
    /// - precondition: The `selectionSize` of the memory Dataspace is the same as for the file Dataspace
    public func writeFrom(pointer: UnsafePointer<Double>, memSpace: Dataspace? = nil, fileSpace: Dataspace? = nil) throws {
        try super.writeFrom(pointer, type: .Double, memSpace: memSpace, fileSpace: fileSpace)
    }
}


// MARK: GroupType extension for DoubleDataset

extension GroupType {
    /// Create a DoubleDataset
    public func createDoubleDataset(name: String, dataspace: Dataspace) -> DoubleDataset? {
        guard let datatype = Datatype(type: Double.self) else {
            return nil
        }
        let datasetID = name.withCString{ name in
            return H5Dcreate2(id, name, datatype.id, dataspace.id, 0, 0, 0)
        }
        return DoubleDataset(id: datasetID)
    }

    /// Create a chunked DoubleDataset
    public func createDoubleDataset(name: String, dataspace: Dataspace, chunkDimensions: [Int]) -> DoubleDataset? {
        guard let datatype = Datatype(type: Double.self) else {
            return nil
        }
        precondition(dataspace.dims.count == chunkDimensions.count)

        let plist = H5Pcreate(H5P_CLS_DATASET_CREATE_ID_g)
        H5Pset_chunk(plist, Int32(chunkDimensions.count), ptr(chunkDimensions))
        defer {
            H5Pclose(plist)
        }

        let datasetID = name.withCString{ name in
            return H5Dcreate2(id, name, datatype.id, dataspace.id, 0, plist, 0)
        }
        return DoubleDataset(id: datasetID)
    }

    /// Create a Double Dataset and write data
    public func createAndWriteDataset(name: String, dims: [Int], data: [Double]) throws -> DoubleDataset {
        let space = Dataspace.init(dims: dims)
        let set = createDoubleDataset(name, dataspace: space)!
        try set.write(data)
        return set
    }

    /// Open an existing DoubleDataset
    public func openDoubleDataset(name: String) -> DoubleDataset? {
        let datasetID = name.withCString{ name in
            return H5Dopen2(id, name, 0)
        }
        guard datasetID >= 0 else {
            return nil
        }
        return DoubleDataset(id: datasetID)
    }
}
