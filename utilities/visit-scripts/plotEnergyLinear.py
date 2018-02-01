# Copyright (c) 2012-2018, University of Strathclyde
# Authors: Lawrence T. Campbell & Jonathan Smith (Tech-X UK Ltd)
# License: BSD-3-Clause

"""
Plots the radiated energy as a function of distance through the undulator.
Plotted on a lnear scale.
The script reads in the grouped power and energy data file produced by 
the powPrep.py script, so this must be run before calling this script.
"""

import sys
import getDBNames
import visitLoc

localVisItDir, localPythonPackageDir = visitLoc.visitLoc()
sys.path.insert(0,localPythonPackageDir)

import visit

def plotEnergyLinear(localPowerAllDB):
  data=visit.OpenDatabase(localPowerAllDB,0,'Vs')
  visit.AddPlot('Curve','Energy')
  AnnotationAtts = visit.AnnotationAttributes()
  AnnotationAtts.axes2D.yAxis.grid = 0
  AnnotationAtts.axes2D.xAxis.grid = 0
  AnnotationAtts.axes2D.xAxis.title.userTitle = 1
  AnnotationAtts.axes2D.xAxis.title.userUnits = 1
  AnnotationAtts.axes2D.xAxis.title.title = "z"
  AnnotationAtts.axes2D.xAxis.title.units = "m"
  AnnotationAtts.axes2D.yAxis.title.userTitle = 1
  AnnotationAtts.axes2D.yAxis.title.userUnits = 1
  AnnotationAtts.axes2D.yAxis.title.title = "Energy"
  AnnotationAtts.axes2D.yAxis.title.units = "J"
  AnnotationAtts.userInfoFlag = 0
  AnnotationAtts.databaseInfoFlag = 0
  AnnotationAtts.legendInfoFlag = 0
  visit.SetAnnotationAttributes(AnnotationAtts)
  visit.DrawPlots()
  CurveAtts = visit.CurveAttributes()
  CurveAtts.showLines = 1
  CurveAtts.lineStyle = CurveAtts.SOLID  # SOLID, DASH, DOT, DOTDASH
  CurveAtts.lineWidth = 2
  CurveAtts.curveColorSource = CurveAtts.Custom  # Cycle, Custom
  CurveAtts.curveColor = (255, 0, 0, 255)
  CurveAtts.showLabels = 0
  CurveAtts.showLegend = 0
  visit.SetPlotOptions(CurveAtts)

if __name__ == '__main__':
    pBaseName=sys.argv[1]
    eDB, fDB, iDB, localPowerAllDB = getDBNames.getDBNames(pBaseName)
    visit.Launch(vdir=localVisItDir)
    plotEnergyLinear(localPowerAllDB)
    visit.OpenGUI()




