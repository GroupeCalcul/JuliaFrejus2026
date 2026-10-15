struct Mesh
    points::Matrix{Float64}
    cells::Vector{Vector{Int32}}
end
using PyCall
@pyimport vtk
function readMeshFromFileVtk(fileName::String)
    reader=vtk.vtkUnstructuredGridReader()
    reader["SetFileName"](fileName)
    reader["Update"]()
    out  = reader[:GetOutput]()
    clls = out[:GetCells]()
    pts  = out[:GetPoints]()
    pointsData = pts[:GetData]()
    cllData = clls[:GetData]()
    nbCells = out[:GetNumberOfCells]()
    i=1 ; cellIdx = 1
    cells = fill(Int32[], nbCells) 
    while i < length(cllData)
         currentCellSize = cllData[i]
         cells[cellIdx] = cllData[i+1:i+currentCellSize]
         i += currentCellSize+1
         cellIdx += 1
    end
    return Mesh(pointsData, cells)
end
