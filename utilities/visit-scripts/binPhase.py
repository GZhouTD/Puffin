# Copyright (c) 2012-2018, University of Strathclyde
# Authors: Lawrence T. Campbell & Jonathan Smith (Tech-X UK Ltd)
# License: BSD-3-Clause

"""
This script takes the macroparticle beam files and bins the particles in a 
2D mesh in the particle z vs energy phase space, and plots the resulting 
density mesh in visit.
"""

import sys
import getDBNames
import visitLoc

localVisItDir, localPythonPackageDir = visitLoc.visitLoc()
sys.path.insert(0,localPythonPackageDir)

import visit


def binPhase(eDB):
  visit.OpenDatabase(eDB, 0)
  visit.AddPlot("Pseudocolor", "operators/DataBinning/2D/electrons", 1, 1)
  DataBinningAtts = visit.DataBinningAttributes()
  DataBinningAtts.numDimensions = DataBinningAtts.Two  # One, Two, Three
  DataBinningAtts.dim1BinBasedOn = DataBinningAtts.Variable  # X, Y, Z, Variable
  DataBinningAtts.dim1Var = "electrons_zSI"
  DataBinningAtts.dim1SpecifyRange = 1
  DataBinningAtts.dim1MinRange = 0
  DataBinningAtts.dim1MaxRange = 1.0E-7
  DataBinningAtts.dim1NumBins = 100
  DataBinningAtts.dim2BinBasedOn = DataBinningAtts.Variable  # X, Y, Z, Variable
  DataBinningAtts.dim2Var = "electrons_gamma"
  DataBinningAtts.dim2SpecifyRange = 1
  DataBinningAtts.dim2MinRange = 0.991
  DataBinningAtts.dim2MaxRange = 1.005
  DataBinningAtts.dim2NumBins = 100
  DataBinningAtts.outOfBoundsBehavior = DataBinningAtts.Clamp  # Clamp, Discard
  DataBinningAtts.reductionOperator = DataBinningAtts.Sum  # Average, Minimum, Maximum, StandardDeviation, Variance, Sum, Count, RMS, PDF
  DataBinningAtts.varForReduction = "electrons_chargeSI"
  DataBinningAtts.emptyVal = 0
  DataBinningAtts.outputType = DataBinningAtts.OutputOnBins  # OutputOnBins, OutputOnInputMesh
  DataBinningAtts.removeEmptyValFromCurve = 1
  visit.SetOperatorOptions(DataBinningAtts, 1)
  visit.SetTimeSliderState(0)
  visit.SetTimeSliderState(1)
  PseudocolorAtts = visit.PseudocolorAttributes()
  PseudocolorAtts.centering = PseudocolorAtts.Nodal  # Natural, Nodal, Zonal
  PseudocolorAtts.opacityType = PseudocolorAtts.Ramp  # ColorTable, FullyOpaque, Constant, Ramp, VariableRange
  PseudocolorAtts.colorTableName = "hot_desaturated"
  visit.SetPlotOptions(PseudocolorAtts)

  View2DAtts = visit.View2DAttributes()
  View2DAtts.fullFrameActivationMode = View2DAtts.On
#  View2DAtts.fullFrameAutoThreshold = 100
  visit.SetView2D(View2DAtts)
  visit.ResetView()

  AnnotationAtts = visit.AnnotationAttributes()
  AnnotationAtts.axes2D.yAxis.grid = 0
  AnnotationAtts.axes2D.xAxis.grid = 0
  AnnotationAtts.axes2D.xAxis.title.userTitle = 1
  AnnotationAtts.axes2D.xAxis.title.userUnits = 1
  AnnotationAtts.axes2D.xAxis.title.title = "ct-z"
  AnnotationAtts.axes2D.xAxis.title.units = "m"
  AnnotationAtts.axes2D.yAxis.title.userTitle = 1
  AnnotationAtts.axes2D.yAxis.title.userUnits = 1
  AnnotationAtts.axes2D.yAxis.title.title = "gamma"
  AnnotationAtts.axes2D.yAxis.title.units = ""
  AnnotationAtts.userInfoFlag = 0
  AnnotationAtts.databaseInfoFlag = 0
  # AnnotationAtts.legendInfoFlag = 0
  visit.SetAnnotationAttributes(AnnotationAtts)
  visit.DrawPlots()


if __name__ == '__main__':
    pBaseName=sys.argv[1]
    eDB, fDB, iDB, localPowerAllDB = getDBNames.getDBNames(pBaseName)
    visit.Launch(vdir=localVisItDir)
    binPhase(eDB)
    visit.OpenGUI()
